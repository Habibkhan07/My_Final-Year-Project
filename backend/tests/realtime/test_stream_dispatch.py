"""
Stream publisher contract tests.

Locks in the architectural boundary between events and streams:
    * Streams build the right envelope (kind=stream, streamType set, ISO ts).
    * Streams call group_send with the dedicated channel-layer message type.
    * Streams do NOT write to EventLog (no persistence).
    * Streams do NOT queue FCM (no offline fallback).
    * Network failure is absorbed AND logged at WARNING (silent failure
      with no log is worse than a crash for debugging).
"""
from __future__ import annotations

import logging

import pytest

from realtime.constants.groups import USER_GROUP_TEMPLATE
from realtime.models import EventLog
from realtime.streams import publish_stream
from realtime.streams.dispatch import CHANNEL_STREAM_TYPE
from tests.factories.accounts import UserFactory


@pytest.fixture
def fake_channel_layer(mocker):
    """
    Replace the channel layer so group_send is observable without Redis.

    Uses an AsyncMock for group_send because the publisher invokes it via
    ``async_to_sync(channel_layer.group_send)`` — the wrapped callable
    must be an awaitable.
    """
    layer = mocker.MagicMock()
    layer.group_send = mocker.AsyncMock()
    mocker.patch(
        "realtime.streams.dispatch.get_channel_layer",
        return_value=layer,
    )
    return layer


@pytest.mark.django_db
def test_publish_stream_builds_correct_envelope(fake_channel_layer):
    user = UserFactory()

    publish_stream(
        user=user,
        stream_type="wallet_balance",
        payload={"balance": 4237},
    )

    fake_channel_layer.group_send.assert_called_once()
    group_name, message = fake_channel_layer.group_send.call_args.args

    assert group_name == USER_GROUP_TEMPLATE.format(user_id=user.id)
    assert message["type"] == CHANNEL_STREAM_TYPE

    envelope = message["message"]
    assert envelope["kind"] == "stream"
    assert envelope["streamType"] == "wallet_balance"
    assert envelope["payload"] == {"balance": 4237}
    assert envelope["timestamp"].endswith("Z")


@pytest.mark.django_db
def test_publish_stream_does_not_write_event_log(fake_channel_layer):
    user = UserFactory()

    publish_stream(
        user=user,
        stream_type="telemetry",
        payload={"lat": 24.8607, "lon": 67.0011},
    )

    # Streams are transient by definition — never persisted.
    assert EventLog.objects.count() == 0


@pytest.mark.django_db
def test_publish_stream_does_not_queue_fcm(fake_channel_layer, mocker):
    user = UserFactory()
    fcm_delay = mocker.patch("realtime.devices.tasks.send_fcm_notification.delay")

    publish_stream(
        user=user,
        stream_type="ai_chat_token",
        payload={"token": "Hello"},
    )

    # Streams have no offline-fallback policy. If the socket is down the
    # frame drops — FCM is only for events the user must be told about.
    fcm_delay.assert_not_called()


@pytest.mark.django_db
def test_publish_stream_swallows_channel_layer_failure_with_log(mocker, caplog):
    user = UserFactory()
    fake_layer = mocker.MagicMock()
    fake_layer.group_send = mocker.AsyncMock(side_effect=ConnectionError("redis is down"))
    mocker.patch(
        "realtime.streams.dispatch.get_channel_layer",
        return_value=fake_layer,
    )

    with caplog.at_level(logging.WARNING, logger="realtime.streams.dispatch"):
        # Must not raise — best-effort delivery.
        publish_stream(
            user=user,
            stream_type="telemetry",
            payload={},
        )

    # AND must log a warning. Silent failure is worse than a crash because
    # the failure becomes invisible — this assertion catches anyone who
    # later removes the log line.
    failure_records = [
        r for r in caplog.records
        if r.levelname == "WARNING" and "Stream dispatch failed" in r.message
    ]
    assert len(failure_records) == 1
    assert "telemetry" in failure_records[0].message


@pytest.mark.django_db
def test_publish_stream_warns_when_no_channel_layer_configured(mocker, caplog):
    user = UserFactory()
    mocker.patch("realtime.streams.dispatch.get_channel_layer", return_value=None)

    with caplog.at_level(logging.WARNING, logger="realtime.streams.dispatch"):
        publish_stream(
            user=user,
            stream_type="telemetry",
            payload={},
        )

    assert any(
        "No channel layer configured" in record.message
        for record in caplog.records
    )
