from django.db import models
from profiles.models import PatientProfile  

class GlucoseTracking(models.Model):
    GLUCOSE_TYPES = (
        ('FBS', 'Fasting Blood Sugar'),
        ('PPBS', 'Postprandial Blood Sugar'),
        ('RBS', 'Random Blood Sugar'),
    )

    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='glucose_readings')
    glucose_type = models.CharField(max_length=4, choices=GLUCOSE_TYPES)
    glucose_value = models.FloatField() 
    timestamp = models.DateTimeField()

    def __str__(self):
        return f"{self.get_glucose_type_display()} - {self.glucose_value} mg/dL for {self.patient} at {self.timestamp}"
    
class AnalysisImage(models.Model):
    patient = models.ForeignKey(PatientProfile, on_delete=models.CASCADE, related_name='analysis_images')
    image = models.ImageField(upload_to='analysis_images/')
    description = models.TextField(blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Analysis Image for {self.patient} uploaded at {self.uploaded_at}"