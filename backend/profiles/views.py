from rest_framework.views import APIView
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
from .models import DoctorPatientRelation, DoctorProfile, PatientProfile
from diabetescare.models import AnalysisImage
from diabetescare.serializers import AnalysisImageSerializer

class GetProfile(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        try:
            if hasattr(user, 'patientprofile'):
                serializer = PatientProfileSerializer(user)
                return Response(serializer.data)
            elif hasattr(user, 'doctorprofile'):
                serializer = DoctorSerializer(user)
                return Response(serializer.data)
            else:
                return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UpdateProfile(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
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
                return Response({"message": f"{profile_type.capitalize()} profile updated successfully!", "data": serializer.data})
            return Response({"message": "Invalid data", "errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SearchDoctors(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
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

class LinkPatientToDoctor(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if not hasattr(user, 'patientprofile'):
            return Response({"error": "Only patients can link to a doctor"}, status=status.HTTP_403_FORBIDDEN)

        doctor_id = request.data.get('doctor_id')
        if not doctor_id:
            return Response({"error": "Doctor ID is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            if DoctorPatientRelation.objects.filter(patient=user,doctor__id=doctor_id).exists():
                return Response({"error": "You are already linked to a doctor. Please unlink first."}, status=status.HTTP_400_BAD_REQUEST)

            doctor = User.objects.get(id=doctor_id, doctorprofile__isnull=False)
            if DoctorPatientRelation.objects.filter(doctor=doctor, patient=user).exists():
                return Response({"error": "You are already linked to this doctor"}, status=status.HTTP_400_BAD_REQUEST)

            relation = DoctorPatientRelation(doctor=doctor, patient=user)
            relation.save()
            return Response({"message": "Successfully linked to the doctor"}, status=status.HTTP_201_CREATED)
        except User.DoesNotExist:
            return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)


class UnlinkFromDoctor(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
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
            return Response({"message": "Successfully unlinked from the doctor"})
        except User.DoesNotExist:
            return Response({"error": "Doctor not found"}, status=status.HTTP_404_NOT_FOUND)


class GetMyDoctor(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not hasattr(user, 'patientprofile'):
            return Response({"error": "Only patients can view their doctors"}, status=status.HTTP_403_FORBIDDEN)

        relation = DoctorPatientRelation.objects.filter(patient=user, status='accepted').first()
        if not relation:
            return Response({"message": "You are not linked to any doctor"})

        doctor = relation.doctor
        serializer = DoctorSerializer(doctor)
        return Response(serializer.data)


class GetMyPatients(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not hasattr(user, 'doctorprofile'):
            return Response({"error": "Only doctors can view their patients"}, status=status.HTTP_403_FORBIDDEN)

        relations = DoctorPatientRelation.objects.filter(doctor=user, status='accepted')
        patients = [relation.patient for relation in relations]
        serializer = PatientProfileSerializer(patients, many=True)
        return Response(serializer.data)


class GetPatientHealthRecord(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
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


class PatientAnalysis(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        user = request.user
        if not hasattr(user, 'doctorprofile'):
            return Response({"error": "Only doctors can view patient analysis"}, status=status.HTTP_403_FORBIDDEN)

        try:
            patient = User.objects.get(id=patient_id, patientprofile__isnull=False)
            if not DoctorPatientRelation.objects.filter(doctor=user, patient=patient).exists():
                return Response({"error": "This patient is not linked to you"}, status=status.HTTP_403_FORBIDDEN)

            analysis = AnalysisImage.objects.filter(patient=patient.patientprofile).order_by('-uploaded_at')
            serializer = AnalysisImageSerializer(analysis, many=True)
            return Response({"message": "Patient analysis retrieved successfully!", "data": serializer.data})

        except User.DoesNotExist:
            return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class RespondToPatientRequest(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if not hasattr(user, 'doctorprofile'):
            return Response({"error": "Only doctors can respond to requests"}, status=status.HTTP_403_FORBIDDEN)

        patient_id = request.data.get('patient_id')
        action = request.data.get('action')  # 'accept' or 'decline'

        if not patient_id or action not in ['accept', 'decline']:
            return Response({"error": "Patient ID and valid action ('accept' or 'decline') are required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            patient = User.objects.get(id=patient_id, patientprofile__isnull=False)
            relation = DoctorPatientRelation.objects.filter(doctor=user, patient=patient, status='pending').first()

            if not relation:
                return Response({"error": "No pending request found"}, status=status.HTTP_404_NOT_FOUND)

            relation.status = 'accepted' if action == 'accept' else 'declined'
            relation.save()

            return Response({"message": f"Request {relation.status} successfully."})

        except User.DoesNotExist:
            return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)


class ListPendingRequests(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if not hasattr(user, 'doctorprofile'):
            return Response({"error": "Only doctors can view pending requests"}, status=status.HTTP_403_FORBIDDEN)

        pending_requests = DoctorPatientRelation.objects.filter(doctor=user, status='pending')
        data = [
            {
                "patient_id": rel.patient.id,
                "patient_name": rel.patient.get_full_name(),
                "created_at": rel.created_at
            }
            for rel in pending_requests
        ]
        return Response(data)
