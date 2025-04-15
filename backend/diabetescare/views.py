from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .serializers import GlucoseTrackingSerializer
from profiles.models import PatientProfile
from .models import GlucoseTracking 

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