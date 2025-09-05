from django.urls import path
from .views import (
    GetProfile,
    UpdateProfile,
    SearchDoctors,
    LinkPatientToDoctor,
    UnlinkFromDoctor,
    GetMyDoctor,
    GetMyPatients,
    GetPatientHealthRecord,
    PatientAnalysis,
    RespondToPatientRequest,
    ListPendingRequests
)

urlpatterns = [
    path('profile/', GetProfile.as_view(), name='get-profile'),
    path('update-profile/', UpdateProfile.as_view(), name='update-profile'),
    path('search-doctors/', SearchDoctors.as_view(), name='search-doctors'),
    path('link-to-doctor/', LinkPatientToDoctor.as_view(), name='link-to-doctor'),
    path('unlink-from-doctor/', UnlinkFromDoctor.as_view(), name='unlink-from-doctor'),
    path('my-doctor/', GetMyDoctor.as_view(), name='my-doctor'),
    path('my-patients/', GetMyPatients.as_view(), name='my-patients'),
    path('patient-health-record/<int:patient_id>/', GetPatientHealthRecord.as_view(), name='patient-health-record'),
    path('patient-analysis/<int:patient_id>/', PatientAnalysis.as_view(), name='patient-analysis'),
    path('respond-to-patient-request/', RespondToPatientRequest.as_view(), name='respond-to-patient-request'),
    path('list-pending-requests/', ListPendingRequests.as_view(), name='list-pending-requests'),
]
