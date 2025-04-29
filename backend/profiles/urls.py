from django.urls import path
from .views import (
    get_profile,
    update_profile, 
    search_doctors, 
    link_patient_to_doctor, 
    unlink_from_doctor,
    get_my_patients,
    get_patient_health_record,
    get_my_doctor,
    patient_analysis
)

urlpatterns = [
    path('profile/', get_profile, name='get-profile'),
    path('update-profile/', update_profile, name="update-profile"),
    path('search-doctors/', search_doctors, name="search-doctors"),
    path('link-to-doctor/', link_patient_to_doctor, name="link-to-doctor"),
    path('unlink-from-doctor/', unlink_from_doctor, name='unlink-from-doctor'),
    path('my-doctor/', get_my_doctor, name='my-doctors'),
    path('my-patients/', get_my_patients, name='my-patients'),  
    path('patient-health-record/<int:patient_id>/', get_patient_health_record, name='patient-health-record'),
    path('patient-analysis/<int:patient_id>/', patient_analysis, name='patient_analysis'),
]