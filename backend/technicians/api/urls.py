from django.urls import include, path
from .onboarding.views import (
    MediaUploadView,
    RegisterTechnicianView,
    OnboardingMetadataView,
    TechnicianStatusView,
)
from .dashboard.views import TechnicianDashboardView
from .metrics.views import TechnicianMetricsView
from .quote_catalog.views import QuotableSubServicesView
from .work_location.views import TechnicianWorkLocationView

urlpatterns = [
    # Dashboard
    path('dashboard/', TechnicianDashboardView.as_view(), name='tech-dashboard'),

    # Metrics — dedicated endpoint for activity + earnings history.
    path('metrics/', TechnicianMetricsView.as_view(), name='tech-metrics'),

    # Wallet — balance read tonight; Thursday adds topups/withdrawals.
    # Mounted as a sub-include so the wallet app owns its URL surface.
    path('wallet/', include('wallet.api.urls')),

    # Tech-side quote builder catalog. The path uses `me/` (not a
    # technician_id param) so the endpoint is structurally incapable of
    # leaking another tech's skills.
    path(
        'me/quotable-sub-services/',
        QuotableSubServicesView.as_view(),
        name='quotable-sub-services',
    ),

    # Metadata: Matches Flutter!
    path('onboarding/metadata/', OnboardingMetadataView.as_view(), name='onboarding-metadata'),

    # Change 'register' to 'onboarding' to match Flutter RemoteDataSource
    path('onboarding/upload-media/', MediaUploadView.as_view(), name='media-upload'),

    # Change 'register' to 'onboarding' to match Flutter RemoteDataSource
    path('onboarding/finalize/', RegisterTechnicianView.as_view(), name='tech-register'),

    # Status endpoint — the Flutter router calls this on cold start to
    # decide between customer home, pending-approval, rejected, and the
    # technician dashboard. Returns has_profile=false for users who never
    # applied.
    path('me/status/', TechnicianStatusView.as_view(), name='tech-status'),

    # Work location — single ``GET``/``PATCH`` keyed to ``request.user``.
    # The matchmaker reads ``base_latitude`` / ``base_longitude`` directly,
    # so this endpoint is the only path that makes a newly-onboarded tech
    # discoverable on the customer side.
    path(
        'me/work-location/',
        TechnicianWorkLocationView.as_view(),
        name='tech-work-location',
    ),
]
