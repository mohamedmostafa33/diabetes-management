from django.db import models
from django.contrib.auth.models import User
from django.db.models import CheckConstraint, Q, F
from django.core.exceptions import ValidationError

class PatientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    first_name = models.CharField(max_length=30, blank=True, null=True)  
    last_name = models.CharField(max_length=30, blank=True, null=True)
    medical_history = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"Patient: {self.first_name} {self.last_name} ({self.user.email})"
    
class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    first_name = models.CharField(max_length=30, blank=True, null=True)
    last_name = models.CharField(max_length=30, blank=True, null=True)
    specialization = models.CharField(max_length=255)

    def __str__(self):
        return f"Doctor: {self.first_name} {self.last_name} - {self.specialization}"


class DoctorPatientRelation(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
    ]

    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='doctor_relations')
    patient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patient_relations')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now=True)

    def clean(self):
        if not hasattr(self.doctor, 'doctorprofile'):
            raise ValidationError("The selected doctor must have a DoctorProfile.")
        if not hasattr(self.patient, 'patientprofile'):
            raise ValidationError("The selected patient must have a PatientProfile.")
        if self.doctor == self.patient:
            raise ValidationError("Doctor and patient cannot be the same user.")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    class Meta:
        constraints = [
            CheckConstraint(check=~Q(doctor=F('patient')), name='doctor_patient_different'),
            models.UniqueConstraint(fields=['doctor', 'patient'], name='unique_doctor_patient')
        ]

    def __str__(self):
        return f"{self.doctor.username} - {self.patient.username} ({self.status})"
