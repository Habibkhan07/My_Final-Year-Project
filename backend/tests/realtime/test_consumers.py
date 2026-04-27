"""
Consumer tests — prove the auth gate rejects unauthenticated handshakes.

Uses Channels' in-memory channel layer override so no Redis is required.
"""
from __future__ import annotations

import pytest
from channels.testing import WebsocketCommunicator
from rest_framework.authtoken.models import Token

from core.asgi import application
from tests.factories.accounts import UserFactory

pytestmark = pytest.mark.asyncio


@pytest.fixture(autouse=True)
def _in_memory_channel_layer(settings):
    settings.CHANNEL_LAYERS = {
        "default": {"BACKEND": "channels.layers.InMemoryChannelLayer"},
    }


@pytest.mark.django_db(transaction=True)
async def test_missing_token_closes_with_4001():
    communicator = WebsocketCommunicator(application, "/ws/events/")
    connected, close_code = await communicator.connect()
    assert connected is False
    assert close_code == 4001


@pytest.mark.django_db(transaction=True)
async def test_bad_token_closes_with_4001():
    communicator = WebsocketCommunicator(application, "/ws/events/?token=not-a-real-token")
    connected, close_code = await communicator.connect()
    assert connected is False
    assert close_code == 4001


@pytest.mark.django_db(transaction=True)
async def test_valid_token_accepts_connection():
    from channels.db import database_sync_to_async

    user = await database_sync_to_async(UserFactory)()
    token = await database_sync_to_async(lambda: Token.objects.create(user=user))()

    communicator = WebsocketCommunicator(application, f"/ws/events/?token={token.key}")
    connected, _ = await communicator.connect()
    assert connected is True
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_system_event_message_is_forwarded_to_client():
    """
    A ``system.event`` channel-layer dispatch is JSON-encoded and sent to
    the client unchanged. The consumer is envelope-agnostic — it does not
    inspect or rewrite the payload.
    """
    from channels.db import database_sync_to_async
    from channels.layers import get_channel_layer

    from realtime.constants.groups import USER_GROUP_TEMPLATE

    user = await database_sync_to_async(UserFactory)()
    token = await database_sync_to_async(lambda: Token.objects.create(user=user))()

    communicator = WebsocketCommunicator(application, f"/ws/events/?token={token.key}")
    connected, _ = await communicator.connect()
    assert connected is True

    envelope = {
        "kind": "event",
        "id": "11111111-1111-1111-1111-111111111111",
        "rawType": "job_accepted",
        "targetRole": "customer",
        "timestamp": "2026-04-27T00:00:00Z",
        "payload": {"job_id": "abc"},
    }
    layer = get_channel_layer()
    await layer.group_send(
        USER_GROUP_TEMPLATE.format(user_id=user.id),
        {"type": "system.event", "message": envelope},
    )

    received = await communicator.receive_json_from()
    assert received == envelope
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_system_stream_message_is_forwarded_to_client():
    """
    A ``system.stream`` channel-layer dispatch flows through the same
    socket as events. The consumer's ``system_stream`` handler mirrors
    ``system_event`` — same forward, no special handling.
    """
    from channels.db import database_sync_to_async
    from channels.layers import get_channel_layer

    from realtime.constants.groups import USER_GROUP_TEMPLATE

    user = await database_sync_to_async(UserFactory)()
    token = await database_sync_to_async(lambda: Token.objects.create(user=user))()

    communicator = WebsocketCommunicator(application, f"/ws/events/?token={token.key}")
    connected, _ = await communicator.connect()
    assert connected is True

    envelope = {
        "kind": "stream",
        "streamType": "telemetry",
        "timestamp": "2026-04-27T00:00:00Z",
        "payload": {"lat": 24.8607, "lon": 67.0011},
    }
    layer = get_channel_layer()
    await layer.group_send(
        USER_GROUP_TEMPLATE.format(user_id=user.id),
        {"type": "system.stream", "message": envelope},
    )

    received = await communicator.receive_json_from()
    assert received == envelope
    await communicator.disconnect()
