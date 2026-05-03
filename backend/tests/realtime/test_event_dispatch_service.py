"""
Invariants covered:
    * EventLog row is persisted BEFORE any network I/O.
    * A Channels failure does not raise into the caller.
    * A Celery broker outage does not raise into the caller.
    * ``is_critical`` is auto-set from the event registry.
    * Wire envelope carries ``recipient_user_id`` and ``expires_at`` (flag #19).
    * ``EventLog.expires_at`` denormalization matches the wire instant.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone as dt_timezone
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


# ---------------------------------------------------------------------------
# flag #19 — wire envelope carries recipient_user_id + expires_at
# ---------------------------------------------------------------------------


@pytest.mark.django_db
def test_envelope_includes_recipient_user_id(mocker):
    """Recipient identity is on the wire (defence-in-depth on multi-account devices)."""
    user = UserFactory()
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="customer",
        event_type="job_accepted",
        payload={"job_id": "abc"},
    )

    assert envelope["recipient_user_id"] == user.id


@pytest.mark.django_db
def test_envelope_expires_at_is_null_without_sla(mocker):
    """Events with no SLA surface ``expires_at: null`` — the row column is also null."""
    user = UserFactory()
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="customer",
        event_type="job_accepted",
        payload={"job_id": "abc"},
    )

    assert envelope["expires_at"] is None
    row = EventLog.objects.get(id=envelope["id"])
    assert row.expires_at is None


@pytest.mark.django_db
def test_envelope_expires_at_is_anchored_at_dispatch(mocker):
    """
    expires_in_seconds → envelope.expires_at == timestamp + delta.

    The envelope and the EventLog row must reference the *same* UTC instant
    so /sync/ replay never disagrees with the original WS frame.
    """
    user = UserFactory()
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    before = datetime.now(tz=dt_timezone.utc)
    envelope = EventDispatchService.broadcast_event(
        user=user,
        target_role="technician",
        event_type="job_new_request",
        payload={"job_id": "sla-1"},
        expires_in_seconds=300,
    )
    after = datetime.now(tz=dt_timezone.utc)

    # Envelope shape: both fields are ISO-8601 UTC strings with trailing Z.
    assert envelope["expires_at"].endswith("Z")
    assert envelope["timestamp"].endswith("Z")

    ts = datetime.fromisoformat(envelope["timestamp"].replace("Z", "+00:00"))
    exp = datetime.fromisoformat(envelope["expires_at"].replace("Z", "+00:00"))

    # exp - ts is exactly 300s because both derive from the same pinned ``now``.
    assert exp - ts == timedelta(seconds=300)
    # And the pinned ``now`` lives between the two wall-clock samples.
    assert before <= ts <= after

    # Denormalized row matches the envelope wire string exactly — single source
    # of truth (no sync-side re-derivation that could drift).
    row = EventLog.objects.get(id=envelope["id"])
    assert row.expires_at == exp


@pytest.mark.django_db
def test_broadcast_to_multiple_propagates_expires_in_seconds(mocker):
    """Cohort dispatch shares one SLA — every recipient gets the same delta."""
    users = [UserFactory(), UserFactory()]
    mocker.patch.object(EventDispatchService, "_push_to_channel_layer")
    mocker.patch.object(EventDispatchService, "_queue_fcm")

    envelopes = EventDispatchService.broadcast_to_multiple(
        users=users,
        target_role="technician",
        event_type="job_new_request",
        payload={"job_id": "fanout-sla"},
        expires_in_seconds=120,
    )

    for env in envelopes:
        ts = datetime.fromisoformat(env["timestamp"].replace("Z", "+00:00"))
        exp = datetime.fromisoformat(env["expires_at"].replace("Z", "+00:00"))
        assert exp - ts == timedelta(seconds=120)
    # Each recipient sees their own user.id on the wire.
    assert {env["recipient_user_id"] for env in envelopes} == {u.id for u in users}
