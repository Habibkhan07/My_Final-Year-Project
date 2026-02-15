from django.contrib import admin
from .models import UserProfile, CustomerProfile,  SavedAddress

# This makes your custom tables visible at http://127.0.0.1:8000/admin
admin.site.register(UserProfile)
admin.site.register(CustomerProfile)
admin.site.register(SavedAddress)
