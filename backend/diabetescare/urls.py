from django.urls import path
from . import views

urlpatterns = [
    path('predict/', views.predict_diabetes, name='predict_diabetes'),
    path('glucose/add/', views.add_glucose_reading, name='add_glucose_reading'),
    path('glucose/list/', views.list_glucose_readings, name='add_glucose_reading'),
    path('alternative-medicine/', views.alternative_medicines, name='alternative_medicines'),
    path('drug-suggestions/', views.drug_suggestions, name='drug_suggestions'),
    path('upload-analysis/', views.upload_analysis, name='upload_analysis'),
    path('my-analysis/', views.my_analysis, name='my_analysis'),  
    path('delete-analysis/<int:analysis_id>/', views.delete_analysis, name='delete_analysis'),  
]