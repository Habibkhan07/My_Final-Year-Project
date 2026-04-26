from __future__ import annotations

from django.urls import path

from realtime.events.api.views import (
    EventAckView,
    EventSyncView,
    UnacknowledgedCriticalView,
)
from realtime.devices.api.views import (
    RegisterDeviceView,
    UnregisterDeviceView,
)

app_name = "realtime"

urlpatterns = [
    # Events
    path("events/sync/", EventSyncView.as_view(), name="events_sync"),
    path("events/ack/", EventAckView.as_view(), name="events_ack"),
    path("events/unacknowledged/", UnacknowledgedCriticalView.as_view(), name="events_unacknowledged"),
    
    # Devices
    path("devices/register/", RegisterDeviceView.as_view(), name="devices_register"),
    path("devices/unregister/", UnregisterDeviceView.as_view(), name="devices_unregister"),
]
