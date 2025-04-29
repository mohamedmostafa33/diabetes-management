from django.contrib import admin
from django.utils.html import format_html
from .models import GlucoseTracking, AnalysisImage  

@admin.register(GlucoseTracking)
class GlucoseTrackingAdmin(admin.ModelAdmin):
    list_display = ('patient', 'glucose_type_display', 'glucose_value_colored', 'timestamp')
    
    list_filter = ('glucose_type', 'patient', 'timestamp')
    
    search_fields = ('patient__first_name', 'patient__last_name', 'glucose_type')
    
    list_display_links = ('patient', 'glucose_type_display')
    
    ordering = ('-timestamp',)
    
    fields = ('patient', 'glucose_type', 'glucose_value', 'timestamp')
    
    def glucose_type_display(self, obj):
        return obj.get_glucose_type_display()
    glucose_type_display.short_description = 'Glucose Type'
    
    def glucose_value_colored(self, obj):
        normal_ranges = {
            'FBS': (70, 99),   
            'PPBS': (0, 140),   
            'RBS': (0, 200),    
        }
        normal_range = normal_ranges.get(obj.glucose_type)
        if normal_range:
            if obj.glucose_value < normal_range[0] or obj.glucose_value > normal_range[1]:
                return format_html('<span style="color: red;">{}</span>', f"{obj.glucose_value} mg/dL")
            else:
                return format_html('<span style="color: green;">{}</span>', f"{obj.glucose_value} mg/dL")
        return f"{obj.glucose_value} mg/dL"
    glucose_value_colored.short_description = 'Glucose Value'
    
    def change_view(self, request, object_id, form_url='', extra_context=None):
        extra_context = extra_context or {}
        obj = self.get_object(request, object_id)
        if obj:
            normal_ranges = {
                'FBS': (70, 99),
                'PPBS': (0, 140),
                'RBS': (0, 200),
            }
            normal_range = normal_ranges.get(obj.glucose_type)
            if normal_range and (obj.glucose_value < normal_range[0] or obj.glucose_value > normal_range[1]):
                extra_context['warning'] = "This reading is abnormal. Please review."
        return super().change_view(request, object_id, form_url, extra_context=extra_context)

@admin.register(AnalysisImage)
class AnalysisImageAdmin(admin.ModelAdmin):
    list_display = ('patient', 'description', 'uploaded_at', 'image_preview')
    list_filter = ('patient', 'uploaded_at')
    search_fields = ('description', 'patient__first_name', 'patient__last_name')
    list_display_links = ('patient', 'description')
    ordering = ('-uploaded_at',)
    fields = ('patient', 'image', 'description', 'uploaded_at')
    readonly_fields = ('uploaded_at',)

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 50px;"/>', obj.image.url)
        return "No Image"
    image_preview.short_description = 'Image Preview'