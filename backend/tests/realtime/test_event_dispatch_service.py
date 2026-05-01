"""
Invariants covered:
    * EventLog row is persisted BEFORE any network I/O.
    * A Channels failure does not raise into the caller.
    * A Celery broker outage does not raise into the caller.
    * ``is_critical`` is auto-set from the event registry.
"""
from __future__ import annotations

from unittest.mock import patch

import pytest

from realtime.models import EventLog
from realtime.events.services import EventDispatchService
from tests.factories.accounts import UserFactory


@pytest.mark.django_db
def test_event_log_is_written_before_any_dispatch(mocker):
    user = UserFactory()
    # Both barrels are mocked — assert the DB row exists by the time they run.
    def assert_row_exists(*args, **kwargs):
        assert EventLog.objects.filter(user=user).exists()

    ws = mocker.patch.object(
        EventDispatchService, "_push_to_channel_layer", side_effect=assert_row_exists
    )
    fcm = mocker.patch.object(
        EventDispatchService, "_queue_fcm", side_effect=assert_row_exists
    )

    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="customer",
        event_type="job_accepted",
        payload={"job_id": "abc"},
    )

    assert ws.called and fcm.called
    # ``kind`` is the on-the-wire discriminator the frontend dispatcher
    # uses to tell events from streams. Lock it in here so a regression
    # that drops the field surfaces as a test failure, not a UI bug.
    assert envelope["kind"] == "event"
    row = EventLog.objects.get(id=envelope["id"])
    assert row.is_critical is True  # job_accepted is critical in the registry
    assert row.event_type == "job_accepted"
    # EventLog.payload stores the *inner* feature payload only — single-envelope
    # contract per EVENT_DISPATCH_API.md. The envelope shell is reconstituted by
    # EventLogSerializer on sync read, so storing it here too would double-nest.
    assert row.payload == {"job_id": "abc"}


@pytest.mark.django_db
def test_broadcast_event_swallows_channel_layer_failure(mocker):
    user = UserFactory()
    # Mock at the new narrow boundary: the group_send call itself.
    # Patching _push_to_channel_layer would replace the helper that *owns*
    # the try/except, masking the real swallow behavior we want to verify.
    fake_layer = mocker.MagicMock()
    fake_layer.group_send = mocker.AsyncMock(side_effect=ConnectionError("redis is down"))
    mocker.patch(
        "realtime.events.services.event_dispatch_service.get_channel_layer",
        return_value=fake_layer,
    )
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    # Must not raise — DB write already succeeded, and the narrow try/except
    # inside _push_to_channel_layer absorbs the Redis outage.
    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="customer",
        event_type="tech_arrived",
        payload={},
    )
    assert EventLog.objects.filter(id=envelope["id"]).exists()


@pytest.mark.django_db
def test_broadcast_event_swallows_celery_broker_failure(mocker):
    user = UserFactory()
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(
        EventDispatchService,
        "_queue_fcm",
        side_effect=OSError("broker unreachable"),
    )

    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="technician",
        event_type="job_new_request",
        payload={},
    )
    assert EventLog.objects.filter(id=envelope["id"]).exists()


@pytest.mark.django_db
def test_broadcast_to_multiple_fans_out(mocker):
    users = [UserFactory(), UserFactory(), UserFactory()]
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    envelopes = EventDispatchService.broadcast_to_multiple(
        users=users,
        target_role="technician",
        event_type="job_new_request",
        payload={"job_id": "fanout-1"},
    )

    assert len(envelopes) == len(users)
    assert EventLog.objects.filter(user__in=users).count() == len(users)
