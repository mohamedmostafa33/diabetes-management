from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .serializers import GlucoseTrackingSerializer, AnalysisImageSerializer
from profiles.models import PatientProfile
from .models import GlucoseTracking, AnalysisImage
from .import predict
import json
import os

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_glucose_reading(request):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can add glucose readings."}, status=status.HTTP_403_FORBIDDEN)

    serializer = GlucoseTrackingSerializer(data=request.data)
    if serializer.is_valid():
        glucose_reading = serializer.save(patient=patient)

        all_readings = GlucoseTracking.objects.filter(patient=patient).order_by('timestamp')

        medical_history_entry = "Glucose Readings:\n"
        for reading in all_readings:
            reading_entry = (
                f"- {reading.get_glucose_type_display()}: {reading.glucose_value} mg/dL "
                f"on {reading.timestamp.strftime('%Y-%m-%d %H:%M')}"
            )
            medical_history_entry += f"{reading_entry}\n"

        patient.medical_history = medical_history_entry.strip()
        patient.save()

        return Response({
            "message": "Glucose reading added successfully!",
            "data": serializer.data
        }, status=status.HTTP_201_CREATED)

    return Response({
        "message": "Invalid data",
        "errors": serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_glucose_readings(request):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can access their glucose readings."}, status=status.HTTP_403_FORBIDDEN)

    readings = GlucoseTracking.objects.filter(patient=patient).order_by('-timestamp')
    serializer = GlucoseTrackingSerializer(readings, many=True)

    return Response({
        "message": "Glucose readings retrieved successfully!",
        "data": serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def predict_diabetes(request):
    try:
        data = json.loads(request.body)
        
        required_fields = ['Pregnancies', 'Glucose', 'BloodPressure', 'SkinThickness', 
                          'Insulin', 'BMI', 'DiabetesPedigreeFunction', 'Age']
        for field in required_fields:
            if field not in data:
                return Response({"error": f"Missing required field: {field}"}, status=status.HTTP_400_BAD_REQUEST)
        
        for field in required_fields:
            try:
                data[field] = float(data[field])
            except (ValueError, TypeError):
                return Response({"error": f"Invalid value for {field}. Must be a number."}, status=status.HTTP_400_BAD_REQUEST)
        
        result = predict.predict_diabetes(data)
        
        return Response(result, status=status.HTTP_200_OK)
    
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body"}, status=status.HTTP_400_BAD_REQUEST)
    except predict.FileNotFoundError as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({"error": f"An error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
from . import alternative_medicine

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def alternative_medicines(request):
    try:
        data = json.loads(request.body)
        
        if 'drug_name' not in data:
            return Response({"error": "Missing required field: drug_name"}, status=status.HTTP_400_BAD_REQUEST)
        
        drug_name = data['drug_name']
        if not isinstance(drug_name, str):
            return Response({"error": "drug_name must be a string"}, status=status.HTTP_400_BAD_REQUEST)
        
        result = alternative_medicine.recommend_info(drug_name)
        
        return Response(result, status=status.HTTP_200_OK)
    
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body"}, status=status.HTTP_400_BAD_REQUEST)
    except alternative_medicine.FileNotFoundError as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({"error": f"An error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def drug_suggestions(request):
    try:
        data = json.loads(request.body)
        
        if 'query' not in data:
            return Response({"error": "Missing required field: query"}, status=status.HTTP_400_BAD_REQUEST)
        
        query = data['query']
        if not isinstance(query, str):
            return Response({"error": "query must be a string"}, status=status.HTTP_400_BAD_REQUEST)
    
        drug_names = alternative_medicine.new_data['Drug Name'].tolist()
        
        suggestions = [
            drug for drug in drug_names
            if drug.lower().startswith(query.lower())
        ]
        
        return Response(suggestions, status=status.HTTP_200_OK)
    
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body"}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": f"An error occurred: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_analysis(request):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can upload analysis images."}, status=status.HTTP_403_FORBIDDEN)

    if 'image' not in request.FILES:
        return Response({"error": "No image file provided."}, status=status.HTTP_400_BAD_REQUEST)

    image = request.FILES['image']
    description = request.POST.get('description', '')

    analysis_image = AnalysisImage.objects.create(
        patient=patient,
        image=image,
        description=description
    )

    serializer = AnalysisImageSerializer(analysis_image)

    return Response({
        "message": "Analysis image uploaded successfully!",
        "data": serializer.data
    }, status=status.HTTP_201_CREATED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_analysis(request):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can view their analysis."}, status=status.HTTP_403_FORBIDDEN)

    analysis = AnalysisImage.objects.filter(patient=patient).order_by('-uploaded_at')
    serializer = AnalysisImageSerializer(analysis, many=True)

    return Response({
        "message": "Your analysis retrieved successfully!",
        "data": serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_analysis(request, analysis_id):
    user = request.user

    try:
        patient = PatientProfile.objects.get(user=user)
    except PatientProfile.DoesNotExist:
        return Response({"error": "Only patients can delete their analysis."}, status=status.HTTP_403_FORBIDDEN)

    try:
        analysis = AnalysisImage.objects.get(id=analysis_id, patient=patient)
    except AnalysisImage.DoesNotExist:
        return Response({"error": "Analysis image not found or not owned by you."}, status=status.HTTP_404_NOT_FOUND)

    if analysis.image and os.path.isfile(analysis.image.path):
        os.remove(analysis.image.path)

    analysis.delete()

    return Response({
        "message": "Analysis image deleted successfully!"
    }, status=status.HTTP_200_OK)