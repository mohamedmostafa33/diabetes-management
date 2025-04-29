from rest_framework import serializers
from .models import GlucoseTracking, AnalysisImage

class GlucoseTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = GlucoseTracking
        fields = ['glucose_type', 'glucose_value', 'timestamp']

    def validate_glucose_value(self, value):
        if value < 20 or value > 600:  
            raise serializers.ValidationError("Glucose value must be between 20 and 600 mg/dL.")
        return value

    def validate_glucose_type(self, value):
        valid_types = [choice[0] for choice in GlucoseTracking.GLUCOSE_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError("Invalid glucose type. Must be one of: FBS, PPBS, RBS.")
        return value

class AnalysisImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = AnalysisImage
        fields = ['id', 'image', 'description', 'uploaded_at']