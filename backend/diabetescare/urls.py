from django.urls import path
from . import views

urlpatterns = [
    path('glucose/add/', views.add_glucose_reading, name='add_glucose_reading'),
    path('glucose/list/', views.list_glucose_readings, name='add_glucose_reading'),
]