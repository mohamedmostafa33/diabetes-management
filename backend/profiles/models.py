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
    doctor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='patients')
    patient = models.OneToOneField(User, on_delete=models.CASCADE, related_name='doctors')

    def clean(self):
        if not hasattr(self.doctor, 'doctorprofile'):
            raise ValidationError("The selected doctor must have a DoctorProfile (must be a doctor).")
        if not hasattr(self.patient, 'patientprofile'):
            raise ValidationError("The selected patient must have a PatientProfile (must be a patient).")

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)

    class Meta:
        constraints = [
            CheckConstraint(
                check=~Q(doctor=F('patient')),
                name='doctor_patient_different'
            )
        ]

    def __str__(self):
        return f"Doctor {self.doctor.username} - Patient {self.patient.username}"