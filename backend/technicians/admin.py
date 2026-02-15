from django.contrib import admin

from .models import Service, SubService, TechnicianProfile, TechnicianSkill, TemporaryMedia

# Register your models here so they appear in the admin dashboard
admin.site.register(Service)
admin.site.register(SubService)
admin.site.register(TechnicianProfile)
admin.site.register(TechnicianSkill)
admin.site.register(TemporaryMedia)