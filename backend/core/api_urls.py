"""
Event recovery URL routes.

Mounted under ``/api/events/`` by the project ``core/urls.py`` (the project
root urls.py is kept separate from this feature-level module to preserve
the Thin Views / Fat Services convention used elsewhere in the codebase).
"""
from django.urls import path

from core.views.event_views import (
    EventAckView,
    EventSyncView,
    UnacknowledgedCriticalView,
)

app_name = "core_events"

urlpatterns = [
    path("sync/", EventSyncView.as_view(), name="sync"),
    path("ack/", EventAckView.as_view(), name="ack"),
    path("unacknowledged/", UnacknowledgedCriticalView.as_view(), name="unacknowledged"),
]
