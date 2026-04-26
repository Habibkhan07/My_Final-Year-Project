"""
ASGI entry point — routes HTTP to Django and WebSocket to Channels.

WS handshakes are authenticated inside ``SystemEventConsumer.connect``
(token-based, see ``api.ws_auth``). The outer ``AllowedHostsOriginValidator``
blocks cross-origin handshakes from hosts not in ``ALLOWED_HOSTS``.
"""
from __future__ import annotations

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

# Initialize Django before importing anything that touches ORM / apps.
django_asgi_app = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402
from channels.security.websocket import AllowedHostsOriginValidator  # noqa: E402

from realtime.routing import websocket_urlpatterns  # noqa: E402

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": AllowedHostsOriginValidator(
            URLRouter(websocket_urlpatterns),
        ),
    }
)
