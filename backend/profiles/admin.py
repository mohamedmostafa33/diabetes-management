from django.contrib import admin
from .models import PatientProfile, DoctorProfile
from django.contrib.auth.models import User

class PatientProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'first_name', 'last_name', 'age', 'medical_history']
    search_fields = ['user__email', 'first_name', 'last_name']
    
class DoctorProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'first_name', 'last_name', 'specialization']
    search_fields = ['user__email', 'first_name', 'last_name', 'specialization']

class UserAdmin(admin.ModelAdmin):
    list_display = ['email', 'get_account_type', 'is_active']
    search_fields = ['email']

    def get_account_type(self, obj):
        if hasattr(obj, 'patientprofile'):
            return 'Patient'
        elif hasattr(obj, 'doctorprofile'):
            return 'Doctor'
        return 'None'

    get_account_type.admin_order_field = 'account_type'
    get_account_type.short_description = 'Account Type'

# تسجيل الموديلات في صفحة الـ Admin
admin.site.unregister(User)
admin.site.register(User, UserAdmin)
admin.site.register(PatientProfile, PatientProfileAdmin)
admin.site.register(DoctorProfile, DoctorProfileAdmin)
