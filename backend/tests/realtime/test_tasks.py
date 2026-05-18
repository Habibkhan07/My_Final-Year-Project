"""
Unit tests for send_fcm_notification — all Firebase I/O mocked.

Covers:
    * Stale tokens (UNREGISTERED / INVALID_ARGUMENT) are marked is_active=False.
    * Valid tokens stay active.
    * No active devices → early return, no FCM call.
"""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest

from realtime.devices import tasks
from realtime.models import FCMDevice
from tests.factories.accounts import UserFactory
from tests.factories.fcm_devices import FCMDeviceFactory


def _fake_response(success: bool, code: str | None = None):
    exc = SimpleNamespace(code=code) if code else None
    return SimpleNamespace(success=success, exception=exc)


@pytest.mark.django_db
def test_stale_tokens_are_marked_inactive(mocker):
    user = UserFactory()
    dead = FCMDeviceFactory(user=user)
    alive = FCMDeviceFactory(user=user)

    mocker.patch("realtime.firebase.init_firebase")  # no-op
    # Replace firebase_admin.messaging.send_each_for_multicast
    messaging = mocker.patch("firebase_admin.messaging.send_each_for_multicast")
    # MulticastMessage / Notification / configs just need to construct cleanly
    mocker.patch("firebase_admin.messaging.MulticastMessage", MagicMock())
    mocker.patch("firebase_admin.messaging.Notification", MagicMock())
    mocker.patch("firebase_admin.messaging.AndroidConfig", MagicMock())
    mocker.patch("firebase_admin.messaging.APNSConfig", MagicMock())
    mocker.patch("firebase_admin.messaging.APNSPayload", MagicMock())
    mocker.patch("firebase_admin.messaging.Aps", MagicMock())

    messaging.return_value = SimpleNamespace(
        responses=[_fake_response(False, "UNREGISTERED"), _fake_response(True)]
    )

    envelope = {
        "id": "evt-1",
        "rawType": "job_new_request",
        "targetRole": "technician",
        "timestamp": "2026-04-24T00:00:00Z",
        "payload": {"job_id": "j1"},
    }

    # Call underlying function (bypass Celery wrapper)
    tasks.send_fcm_notification.run(user.id, envelope)

    dead.refresh_from_db()
    alive.refresh_from_db()
    assert dead.is_active is False
    assert alive.is_active is True


@pytest.mark.django_db
def test_no_active_devices_is_noop(mocker):
    user = UserFactory()  # no devices
    send = mocker.patch("firebase_admin.messaging.send_each_for_multicast")
    mocker.patch("realtime.firebase.init_firebase")

    tasks.send_fcm_notification.run(
        user.id,
        {"id": "x", "rawType": "chat_message", "targetRole": "customer", "timestamp": "t", "payload": {}},
    )
    send.assert_not_called()


class TestBuildNotificationBody:
    """Pure-function coverage for `_build_notification_body`.

    Wire envelope shape: top-level event fields + a nested ``payload`` dict
    that carries the per-event-type fields. The helper reads from that
    nested dict.
    """

    def _envelope(self, **payload):
        return {"payload": payload}

    def test_booking_rejected_sla_timeout_includes_tech_name(self):
        body = tasks._build_notification_body(
            "booking_rejected",
            self._envelope(
                technician_display_name="Ali Khan",
                reason="sla_timeout",
            ),
        )
        assert body == "Ali Khan didn't respond in time"

    def test_booking_rejected_technician_declined_includes_tech_name(self):
        body = tasks._build_notification_body(
            "booking_rejected",
            self._envelope(
                technician_display_name="Ali Khan",
                reason="technician_declined",
            ),
        )
        assert body == "Ali Khan couldn't take your booking"

    def test_booking_rejected_missing_name_falls_back(self):
        body = tasks._build_notification_body(
            "booking_rejected",
            self._envelope(reason="sla_timeout"),
        )
        assert body == "Your technician didn't respond in time"

    def test_booking_rejected_unknown_reason_falls_back(self):
        body = tasks._build_notification_body(
            "booking_rejected",
            self._envelope(
                technician_display_name="Ali Khan",
                reason="something_new",
            ),
        )
        assert body == "Your booking is no longer available"

    def test_unknown_event_type_falls_back(self):
        body = tasks._build_notification_body("totally_unknown", {})
        assert body == "You have a new notification"
