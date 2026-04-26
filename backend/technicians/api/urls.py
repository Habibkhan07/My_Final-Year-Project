from django.urls import path
from .onboarding.views import (
    MediaUploadView, 
    RegisterTechnicianView, 
    OnboardingMetadataView
)
from .dashboard.views import TechnicianDashboardView

urlpatterns = [
    # Dashboard
    path('dashboard/', TechnicianDashboardView.as_view(), name='tech-dashboard'),

    # Metadata: Matches Flutter!
    path('onboarding/metadata/', OnboardingMetadataView.as_view(), name='onboarding-metadata'),    
    
    # Change 'register' to 'onboarding' to match Flutter RemoteDataSource
    path('onboarding/upload-media/', MediaUploadView.as_view(), name='media-upload'),
    
    # Change 'register' to 'onboarding' to match Flutter RemoteDataSource
    path('onboarding/finalize/', RegisterTechnicianView.as_view(), name='tech-register'),
]