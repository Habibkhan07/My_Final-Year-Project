from django.urls import include, path
from .onboarding.views import (
    MediaUploadView,
    RegisterTechnicianView,
    OnboardingMetadataView,
    TechnicianStatusView,
)
from .dashboard.views import TechnicianDashboardView
from .metrics.views import TechnicianMetricsView
from .online.views import TechnicianOnlineToggleView
from .quote_catalog.views import QuotableSubServicesView
from .scheduled_jobs.views import (
    TechnicianScheduledJobsCountsView,
    TechnicianScheduledJobsListView,
)
from .skills.views import (
    MyServiceCategoriesView,
    MySkillsDetailView,
    MySkillsView,
)
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

    # User-initiated online toggle — counterpart to the ledger's
    # auto-offline gate (wallet/services/ledger.py:213). POST with
    # {is_online: bool}. Lockout-gated for is_online=true via the
    # same select_for_update the ledger uses; offline always allowed.
    path(
        'me/online/',
        TechnicianOnlineToggleView.as_view(),
        name='tech-online-toggle',
    ),

    # Work location — single ``GET``/``PATCH`` keyed to ``request.user``.
    # The matchmaker reads ``base_latitude`` / ``base_longitude`` directly,
    # so this endpoint is the only path that makes a newly-onboarded tech
    # discoverable on the customer side.
    path(
        'me/work-location/',
        TechnicianWorkLocationView.as_view(),
        name='tech-work-location',
    ),

    # Tech-side skills CRUD — backs the Profile tab's "My Skills" tile.
    # ``/me/`` shape (no PK in the URL) means the caller can only target
    # their own skill set. The detail route keys by ``sub_service_id``
    # (the catalog row), not by the bridge row PK — semantically the
    # operation is "remove this specialty from my skills."
    path(
        'me/skills/',
        MySkillsView.as_view(),
        name='tech-my-skills',
    ),
    path(
        'me/skills/<int:sub_service_id>/',
        MySkillsDetailView.as_view(),
        name='tech-my-skills-detail',
    ),

    # Picker catalog for the Add Skill screen — service tree filtered
    # to the categories the caller currently works in (parent services
    # of their existing ``TechnicianSkill`` rows). Same wire shape as
    # ``onboarding/metadata/`` so the FE can reuse its parser; the
    # difference is the access-gate filter.
    path(
        'me/service-categories/',
        MyServiceCategoriesView.as_view(),
        name='tech-service-categories',
    ),

    # Schedule tab — paginated list + counts of the tech's bookings.
    # Audience-flipped counterpart of the customer ``/api/bookings/``
    # contract. List + counts split mirrors that pattern.
    path(
        'me/scheduled-jobs/',
        TechnicianScheduledJobsListView.as_view(),
        name='tech-scheduled-jobs-list',
    ),
    path(
        'me/scheduled-jobs/counts/',
        TechnicianScheduledJobsCountsView.as_view(),
        name='tech-scheduled-jobs-counts',
    ),
]
