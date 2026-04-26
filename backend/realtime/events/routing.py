"""WebSocket URL routing — registered by core/asgi.py."""
from django.urls import re_path

from realtime.events.consumers import SystemEventConsumer

websocket_urlpatterns = [
    re_path(r"^ws/events/$", SystemEventConsumer.as_asgi()),
]
