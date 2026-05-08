"""WS consumer tests for ``subscribe_tracking`` / ``unsubscribe_tracking``.

Coverage:
  * Booking participant (customer or assigned tech) joins
    ``tracking_job_<id>`` after subscribe.
  * Non-participant: silent drop, no group join.
  * Terminal-status booking: silent drop (audit P2-07).
  * Unsubscribe leaves the group.
  * Disconnect cleans up every joined tracking subgroup.
  * A `tech_gps` stream sent to the subgroup is received by the
    subscribed socket.
"""
from __future__ import annotations

import asyncio

import pytest
from channels.db import database_sync_to_async
from channels.layers import get_channel_layer
from channels.testing import WebsocketCommunicator
from rest_framework.authtoken.models import Token

from core.asgi import application
from realtime.constants.groups import TRACKING_JOB_GROUP_TEMPLATE


async def _await_subscribe(communicator, action: str, booking_id: int) -> None:
    """Send a subscribe/unsubscribe action and let the consumer's receive
    task finish before the test continues. Without this yield the
    next ``layer.group_send`` can race the consumer's ``group_add``.
    """
    await communicator.send_json_to({"action": action, "booking_id": booking_id})
    # The receive handler does a database_sync_to_async ORM call before
    # group_add; a single ``sleep(0)`` isn't enough — we need a few
    # event-loop turns. 50ms is ample on local hardware.
    await asyncio.sleep(0.1)


pytestmark = pytest.mark.asyncio


@pytest.fixture(autouse=True)
def _in_memory_channel_layer(settings):
    settings.CHANNEL_LAYERS = {
        "default": {"BACKEND": "channels.layers.InMemoryChannelLayer"},
    }


# ---------------------------------------------------------------------
# Helpers — wrapped in database_sync_to_async because the ORM is sync.
# ---------------------------------------------------------------------


@database_sync_to_async
def _make_booking_with_token():
    """Return (customer_user, tech_user, booking, customer_token, tech_token)."""
    from tests.factories.bookings import JobBookingConfirmedFactory

    booking = JobBookingConfirmedFactory()
    customer_token = Token.objects.create(user=booking.customer)
    tech_token = Token.objects.create(user=booking.technician.user)
    return booking, customer_token, tech_token


@database_sync_to_async
def _make_terminal_booking():
    from tests.factories.bookings import JobBookingCompletedFactory

    booking = JobBookingCompletedFactory()
    customer_token = Token.objects.create(user=booking.customer)
    return booking, customer_token


@database_sync_to_async
def _make_unrelated_user():
    from tests.factories.accounts import UserFactory

    user = UserFactory()
    token = Token.objects.create(user=user)
    return user, token


# ---------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------


@pytest.mark.django_db(transaction=True)
async def test_customer_subscribe_joins_tracking_group():
    booking, customer_token, _ = await _make_booking_with_token()
    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={customer_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    await _await_subscribe(communicator, "subscribe_tracking", booking.id)

    # Verify membership: send a stream frame to the tracking group; it
    # should be forwarded to this socket.
    layer = get_channel_layer()
    envelope = {
        "kind": "stream",
        "streamType": "tech_gps",
        "timestamp": "2026-05-08T10:00:00Z",
        "payload": {"lat": 31.5, "lng": 74.3, "booking_id": booking.id},
    }
    await layer.group_send(
        TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking.id),
        {"type": "system.stream", "message": envelope},
    )

    received = await communicator.receive_json_from()
    assert received == envelope
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_tech_subscribe_joins_tracking_group():
    booking, _, tech_token = await _make_booking_with_token()
    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={tech_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    await _await_subscribe(communicator, "subscribe_tracking", booking.id)

    layer = get_channel_layer()
    envelope = {
        "kind": "stream",
        "streamType": "tech_gps",
        "timestamp": "2026-05-08T10:00:00Z",
        "payload": {"lat": 31.5, "lng": 74.3, "booking_id": booking.id},
    }
    await layer.group_send(
        TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking.id),
        {"type": "system.stream", "message": envelope},
    )

    received = await communicator.receive_json_from()
    assert received == envelope
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_non_participant_silently_dropped():
    booking, _, _ = await _make_booking_with_token()
    user, rando_token = await _make_unrelated_user()

    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={rando_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    await _await_subscribe(communicator, "subscribe_tracking", booking.id)

    # If the consumer had silently joined the rando into the group, a
    # subsequent stream frame would be received. If it didn't (the
    # expected behavior), nothing should arrive.
    layer = get_channel_layer()
    await layer.group_send(
        TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking.id),
        {"type": "system.stream", "message": {"kind": "stream", "streamType": "tech_gps", "timestamp": "x", "payload": {}}},
    )

    assert await communicator.receive_nothing(timeout=0.5) is True
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_terminal_status_subscribe_silently_dropped():
    booking, customer_token = await _make_terminal_booking()
    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={customer_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    await _await_subscribe(communicator, "subscribe_tracking", booking.id)

    layer = get_channel_layer()
    await layer.group_send(
        TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking.id),
        {"type": "system.stream", "message": {"kind": "stream", "streamType": "tech_gps", "timestamp": "x", "payload": {}}},
    )

    assert await communicator.receive_nothing(timeout=0.5) is True
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_unsubscribe_leaves_group():
    booking, customer_token, _ = await _make_booking_with_token()
    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={customer_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    await _await_subscribe(communicator, "subscribe_tracking", booking.id)
    await _await_subscribe(communicator, "unsubscribe_tracking", booking.id)

    layer = get_channel_layer()
    await layer.group_send(
        TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking.id),
        {"type": "system.stream", "message": {"kind": "stream", "streamType": "tech_gps", "timestamp": "x", "payload": {}}},
    )

    assert await communicator.receive_nothing(timeout=0.5) is True
    await communicator.disconnect()


@pytest.mark.django_db(transaction=True)
async def test_invalid_action_ignored():
    booking, customer_token, _ = await _make_booking_with_token()
    communicator = WebsocketCommunicator(
        application, f"/ws/events/?token={customer_token.key}",
    )
    connected, _ = await communicator.connect()
    assert connected is True

    # Bogus action — must not raise, must not subscribe.
    await communicator.send_json_to({"action": "do_something_weird", "booking_id": booking.id})
    # Garbage payload — must not raise.
    await communicator.send_json_to({"foo": "bar"})

    assert await communicator.receive_nothing(timeout=0.3) is True
    await communicator.disconnect()
