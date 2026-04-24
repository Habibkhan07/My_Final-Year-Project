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
