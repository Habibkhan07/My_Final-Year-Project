"""
Background FCM dispatch — runs on Celery workers, never in-request.

Responsibilities:
    * Fan one event out to every active device belonging to a user.
    * Build per-platform FCM payloads (Android high-priority, iOS background-wake).
    * Prune stale tokens on UNREGISTERED / INVALID_ARGUMENT.
    * Retry transient FCM errors with exponential backoff (30s → 120s → 300s).
"""
from __future__ import annotations

import json
import logging
from typing import Any

from celery import shared_task

logger = logging.getLogger(__name__)

#: Retry delays (seconds). Indexed by attempt count — Celery's retry counter
#: starts at 0 for the first retry.
_RETRY_DELAYS = (30, 120, 300)

#: FCM error codes indicating a permanently dead token that should be pruned.
_DEAD_TOKEN_CODES = frozenset({"UNREGISTERED", "INVALID_ARGUMENT"})


def _stringify(value: Any) -> str:
    """FCM ``data`` fields must be strings. Nested structures → JSON."""
    if isinstance(value, str):
        return value
    if isinstance(value, (dict, list, tuple)):
        return json.dumps(value, default=str)
    return str(value)


def _build_notification_body(event_type: str, payload: dict[str, Any]) -> str:
    """
    Short human-readable body for the system notification tray.

    Kept here (not the registry) because bodies interpolate per-event payload
    fields, while the registry is pure metadata.
    """
    inner = payload.get("payload", {}) if isinstance(payload, dict) else {}
    if event_type == "chat_message":
        sender = inner.get("sender_name") or "Someone"
        return f"{sender} sent you a new message"
    if event_type == "job_new_request":
        return "A new job is available near you"
    if event_type == "job_accepted":
        # Payload key is `technician_display_name` — composed server-side by
        # `_build_job_accepted_payload` via `user.get_full_name()`. The
        # previous `technician_name` lookup never matched a real payload and
        # silently fell back to "A technician" on every push.
        tech = inner.get("technician_display_name") or "A technician"
        return f"{tech} accepted your job"
    if event_type == "quote_generated":
        return "A new quote is ready for your review"
    if event_type == "quote_approved":
        return "Your quote was approved"
    if event_type == "tech_en_route":
        return "Your technician is on the way"
    if event_type == "tech_arrived":
        return "Your technician has arrived"
    if event_type == "job_completed":
        return "Your job has been completed"
    if event_type == "payment_received":
        return "Payment received"
    if event_type == "dispute_opened":
        return "A dispute has been opened"
    if event_type == "dispute_resolved":
        return "A dispute has been resolved"
    if event_type == "wallet_low_balance":
        return "Your wallet balance is low — top up to keep accepting jobs"
    if event_type == "booking_rejected":
        # ``reason`` discriminator mirrors the FE banner-body switch in
        # ``event_urgency_router.dart``. Two real values today; any other
        # value falls through to a generic line so a future backend reason
        # doesn't render an empty/broken push.
        tech = inner.get("technician_display_name") or "Your technician"
        reason = inner.get("reason")
        if reason == "sla_timeout":
            return f"{tech} didn't respond in time"
        if reason == "technician_declined":
            return f"{tech} couldn't take your booking"
        return "Your booking is no longer available"
    return "You have a new notification"


@shared_task(bind=True, name="realtime.send_fcm_notification")
def send_fcm_notification(self, user_id: int, payload_dict: dict[str, Any]) -> None:
    """
    Push ``payload_dict`` to every active FCM device owned by ``user_id``.
    """
    # Lazy imports to keep worker startup fast and avoid circulars.
    from firebase_admin import messaging
    from firebase_admin.exceptions import FirebaseError

    from realtime.constants.event_types import get_event_meta
    from realtime.firebase import init_firebase
    from realtime.models.devices import FCMDevice
    from realtime.devices.selectors import active_devices_for_user

    init_firebase()

    devices = list(active_devices_for_user(user_id).only("id", "device_token", "device_type"))
    if not devices:
        logger.warning("No active FCM devices for user=%s; skipping.", user_id)
        return

    event_type = payload_dict.get("rawType", "")
    meta = get_event_meta(event_type)
    title = meta["display_name"]
    body = _build_notification_body(event_type, payload_dict)

    data_payload = {k: _stringify(v) for k, v in payload_dict.items()}

    tokens = [d.device_token for d in devices]
    message = messaging.MulticastMessage(
        tokens=tokens,
        data=data_payload,
        notification=messaging.Notification(title=title, body=body),
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(content_available=True, mutable_content=True),
            ),
        ),
    )

    try:
        response = messaging.send_each_for_multicast(message)
    except FirebaseError as exc:
        _maybe_retry(self, exc)
        return
    except Exception as exc:  # noqa: BLE001
        _maybe_retry(self, exc)
        return

    _reap_dead_tokens(devices, response.responses)


def _reap_dead_tokens(devices, responses) -> None:
    """Flip ``is_active=False`` for any token FCM declared dead."""
    from realtime.models.devices import FCMDevice

    dead_ids: list[int] = []
    for device, result in zip(devices, responses):
        if result.success:
            continue
        exc = result.exception
        code = getattr(exc, "code", None)
        if code in _DEAD_TOKEN_CODES:
            dead_ids.append(device.id)
        else:
            logger.warning(
                "Transient FCM error for device=%s: %s", device.id, exc
            )
    if dead_ids:
        FCMDevice.objects.filter(id__in=dead_ids).update(is_active=False)
        logger.info("Pruned %d stale FCM tokens.", len(dead_ids))


def _maybe_retry(task, exc: Exception) -> None:
    """Schedule the next retry slot or give up after ``len(_RETRY_DELAYS)``."""
    attempt = task.request.retries
    if attempt >= len(_RETRY_DELAYS):
        logger.exception("FCM send exhausted retries; giving up: %s", exc)
        return
    countdown = _RETRY_DELAYS[attempt]
    logger.warning("FCM send failed (attempt %d); retrying in %ds.", attempt + 1, countdown)
    raise task.retry(exc=exc, countdown=countdown, max_retries=len(_RETRY_DELAYS))
