from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from .serializers import (
    PatientProfileUpdateSerializer, 
    DoctorProfileUpdateSerializer,
    DoctorSerializer,
    PatientProfileSerializer
)
from .models import DoctorPatientRelation
from diabetescare.models import AnalysisImage
from diabetescare.serializers import AnalysisImageSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile(request):
    user = request.user

    try:
        if hasattr(user, 'patientprofile'):
            serializer = PatientProfileSerializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        elif hasattr(user, 'doctorprofile'):
            serializer = DoctorSerializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            return Response(
                {"error": "Profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )
    except Exception as e:
        return Response(
            {"error": f"An unexpected error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user = request.user

    try:
        if hasattr(user, 'patientprofile'):
            profile = user.patientprofile
            serializer = PatientProfileUpdateSerializer(profile, data=request.data, partial=True)
            profile_type = "patient"
        elif hasattr(user, 'doctorprofile'):
            profile = user.doctorprofile
            serializer = DoctorProfileUpdateSerializer(profile, data=request.data, partial=True)
            profile_type = "doctor"
        else:
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                "message": f"{profile_type.capitalize()} profile updated successfully!",
                "data": serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response({
            "message": "Invalid data",
            "errors": serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        return Response({
            "error": f"An error occurred: {str(e)}"
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_doctors(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can search for doctors"}, status=status.HTTP_403_FORBIDDEN)

    query = request.GET.get('query', '')
    if not query:
        return Response([])

    doctors = User.objects.filter(
        doctorprofile__isnull=False, 
        doctorprofile__first_name__icontains=query  
    ) | User.objects.filter(
        doctorprofile__isnull=False,
        doctorprofile__last_name__icontains=query  
    ) | User.objects.filter(
        doctorprofile__isnull=False,
        doctorprofile__specialization__icontains=query
    )

    serializer = DoctorSerializer(doctors, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def link_patient_to_doctor(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can link to a doctor"}, status=status.HTTP_403_FORBIDDEN)

    doctor_id = request.data.get('doctor_id')
    if not doctor_id:
        return Response({"error": "Doctor ID is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        if DoctorPatientRelation.objects.filter(patient=user).exists():
            return Response(
                {"error": "You are already linked to a doctor. Please unlink first."},
                status=status.HTTP_400_BAD_REQUEST
            )

        doctor = User.objects.get(id=doctor_id, doctorprofile__isnull=False)
        if DoctorPatientRelation.objects.filter(doctor=doctor, patient=user).exists():
            return Response({"error": "You are already linked to this doctor"}, status=status.HTTP_400_BAD_REQUEST)

        relation = DoctorPatientRelation(doctor=doctor, patient=user)
        relation.save()
        return Response({"message": "Successfully linked to the doctor"}, status=status.HTTP_201_CREATED)
    except User.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def unlink_from_doctor(request):
    user = request.user
    if not hasattr(user, 'patientprofile'):
        return Response({"error": "Only patients can unlink from a doctor"}, status=status.HTTP_403_FORBIDDEN)

    doctor_id = request.data.get('doctor_id')
    if not doctor_id:
        return Response({"error": "Doctor ID is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        doctor = User.objects.get(id=doctor_id, doctorprofile__isnull=False)
        relation = DoctorPatientRelation.objects.filter(doctor=doctor, patient=user).first()
        if not relation:
            return Response({"error": "You are not linked to this doctor"}, status=status.HTTP_400_BAD_REQUEST)

        relation.delete()
        return Response({"message": "Successfully unlinked from the doctor"}, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_doctor(request):
    user = request.user

    try:
        if not user.patientprofile:
            return Response(
                {"error": "Only patients can view their doctors"},
                status=status.HTTP_403_FORBIDDEN
            )
    except AttributeError:
        return Response(
            {"error": "Only patients can view their doctors"},
            status=status.HTTP_403_FORBIDDEN
        )

    try:
        relation = DoctorPatientRelation.objects.filter(patient=user).first()
        if not relation:
            return Response(
                {"message": "You are not linked to any doctor"},
                status=status.HTTP_200_OK
            )

        doctor = relation.doctor
        serializer = DoctorSerializer(doctor)
        return Response(serializer.data, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": f"An unexpected error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_patients(request):
    user = request.user
    if not hasattr(user, 'doctorprofile'):
        return Response({"error": "Only doctors can view their patients"}, status=status.HTTP_403_FORBIDDEN)

    relations = DoctorPatientRelation.objects.filter(doctor=user)
    patients = [relation.patient for relation in relations]
    serializer = PatientProfileSerializer(patients, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_patient_health_record(request, patient_id):
    user = request.user
    if not hasattr(user, 'doctorprofile'):
        return Response({"error": "Only doctors can view patient health records"}, status=status.HTTP_403_FORBIDDEN)

    try:
        patient = User.objects.get(id=patient_id, patientprofile__isnull=False)
        if not DoctorPatientRelation.objects.filter(doctor=user, patient=patient).exists():
            return Response({"error": "This patient is not linked to you"}, status=status.HTTP_403_FORBIDDEN)

        serializer = PatientProfileSerializer(patient)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def patient_analysis(request, patient_id):
    user = request.user
    if not hasattr(user, 'doctorprofile'):
        return Response({"error": "Only doctors can view patient analysis"}, status=status.HTTP_403_FORBIDDEN)

    try:
        patient = User.objects.get(id=patient_id, patientprofile__isnull=False)
        if not DoctorPatientRelation.objects.filter(doctor=user, patient=patient).exists():
            return Response({"error": "This patient is not linked to you"}, status=status.HTTP_403_FORBIDDEN)

        analysis = AnalysisImage.objects.filter(patient=patient.patientprofile).order_by('-uploaded_at')
        serializer = AnalysisImageSerializer(analysis, many=True)

        return Response({
            "message": "Patient analysis retrieved successfully!",
            "data": serializer.data
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": f"An error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)