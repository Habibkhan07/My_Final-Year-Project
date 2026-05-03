"""
EventDispatchService — the single emitter for all real-time events.

Contract (invariants every caller can rely on):

    * The EventLog row is written **before** any network I/O, so the event
      is recoverable via ``GET /api/events/sync/`` even if both barrels fail.
    * Channels and FCM network calls are each wrapped in a narrowly-scoped
      try/except. Redis or Celery outages are absorbed; the caller's DB
      transaction is never rolled back by a notification failure.
    * Coding errors *above* the network call (bad config, malformed payload,
      missing user.id) are deliberately *not* swallowed — they surface so
      bugs stay debuggable instead of vanishing into a barrel.
"""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timedelta, timezone as dt_timezone
from typing import Any, Iterable

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from realtime.constants.event_types import get_event_meta
from realtime.constants.groups import USER_GROUP_TEMPLATE
from realtime.models import EventLog

logger = logging.getLogger(__name__)

#: Must match the handler method ``system_event`` in SystemEventConsumer
#: (Channels maps ``system.event`` → ``system_event``).
CHANNEL_EVENT_TYPE = "system.event"


def _to_iso_z(dt: datetime) -> str:
    """ISO-8601 UTC string with trailing ``Z`` (Flutter-friendly)."""
    return dt.isoformat().replace("+00:00", "Z")


class EventDispatchService:
    """
    Dispatch one real-time event to one user across two barrels
    (WebSocket + FCM) plus persist it for recovery.
    """

    @staticmethod
    def broadcast_event(
        *,
        user,
        target_role: str,
        event_type: str,
        payload: dict[str, Any],
        expires_in_seconds: int | None = None,
    ) -> dict[str, Any]:
        """
        Fire one event. Returns the built envelope so the caller can
        reference ``envelope["id"]`` if it needs to correlate later.

        Parameters
        ----------
        user:
            Recipient User instance. Must be a concrete authenticated user —
            never ``AnonymousUser``.
        target_role:
            ``"customer"`` or ``"technician"``. Drives client-side routing.
        event_type:
            Registered key from ``core.constants.event_types.EventType``.
            Unknown keys are tolerated (forward-compat) but will use the
            default non-critical metadata.
        payload:
            Feature-specific dict. Must be JSON-serializable.
        expires_in_seconds:
            SLA window for events that go stale (e.g. job offers). Drives
            ``envelope["expires_at"]`` and the denormalized ``EventLog.expires_at``
            column so ``/api/events/sync/`` replays the same instant. The
            frontend pipeline drops past-expiry frames at ``SystemEventNotifier``
            ingress (server-anchored clock). Pass ``None`` for events with no
            SLA; the field will surface as ``null`` on the wire. See flag #19.
        """
        meta = get_event_meta(event_type)
        # Pin "now" once so envelope.timestamp, envelope.expires_at, and the
        # persisted EventLog row's expires_at all reference the same instant.
        # Otherwise a slow EventLog.objects.create could produce a row whose
        # expires_at trails the envelope by milliseconds, causing /sync/ replay
        # to disagree with the original WS frame.
        now = datetime.now(tz=dt_timezone.utc)
        expires_at = (
            now + timedelta(seconds=expires_in_seconds)
            if expires_in_seconds is not None
            else None
        )
        envelope: dict[str, Any] = {
            # ``kind`` discriminates events from streams on the same socket.
            # Frontend dispatcher switches on this field. See STREAM_DISPATCH_API.md.
            "kind": "event",
            "id": str(uuid.uuid4()),
            "rawType": event_type,
            "targetRole": target_role,
            "timestamp": _to_iso_z(now),
            # Recipient identity — defence-in-depth against multi-account
            # device FCM tap races. Always set; channel-layer routing is
            # the primary gate, this field is the second one.
            "recipient_user_id": user.id,
            # Absolute expiry — null when caller has no SLA.
            "expires_at": _to_iso_z(expires_at) if expires_at is not None else None,
            "payload": payload,
        }

        # --- Step 1: Persist first (sacred DB write). ----------------------
        # Any exception here is allowed to bubble — if we cannot record the
        # event, we must not pretend to have dispatched it.
        #
        # We store the *inner* payload only. EventLogSerializer rebuilds the
        # envelope shell (kind/rawType/targetRole/timestamp) from the row's
        # columns, so /api/events/sync/ output matches the §1.2 single-envelope
        # wire contract feature mappers consume. Storing the full envelope here
        # was a doubly-nested-payload bug that silently broke every reconnect-
        # replayed event.
        #
        # ``expires_at`` is denormalized onto the row (not recomputed from
        # ``payload['expires_in_seconds']`` + ``created_at``) so the wire
        # value is the single source of truth — sync replay can't drift from
        # the original dispatch.
        EventLog.objects.create(
            id=envelope["id"],
            user=user,
            event_type=event_type,
            target_role=target_role,
            payload=payload,
            is_critical=meta["is_critical"],
            expires_at=expires_at,
        )

        # --- Step 2: WebSocket (Barrel 1) ----------------------------------
        # Narrow try/except lives inside ``_push_to_channel_layer`` —
        # scoped to the ``group_send`` network call only.
        EventDispatchService._push_to_channel_layer(user.id, envelope)

        # --- Step 3: FCM via Celery (Barrel 2) -----------------------------
        try:
            EventDispatchService._queue_fcm(user.id, envelope)
        except Exception:  # noqa: BLE001 — broker outages must not crash caller
            logger.exception(
                "FCM queue failed for event %s → user %s",
                envelope["id"],
                user.id,
            )

        return envelope

    @staticmethod
    def broadcast_to_multiple(
        *,
        users: Iterable,
        target_role: str,
        event_type: str,
        payload: dict[str, Any],
        expires_in_seconds: int | None = None,
    ) -> list[dict[str, Any]]:
        """
        Fan-out helper. Typical use: nearby-technician notifications for a
        new job. Each recipient gets its own EventLog row + envelope id.
        ``expires_in_seconds`` applies uniformly across the cohort.
        """
        envelopes: list[dict[str, Any]] = []
        for user in users:
            envelopes.append(
                EventDispatchService.broadcast_event(
                    user=user,
                    target_role=target_role,
                    event_type=event_type,
                    payload=payload,
                    expires_in_seconds=expires_in_seconds,
                )
            )
        return envelopes

    # ------------------------------------------------------------------ #
    # internals                                                          #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _push_to_channel_layer(user_id: int, envelope: dict[str, Any]) -> None:
        channel_layer = get_channel_layer()
        if channel_layer is None:
            logger.warning("No channel layer configured; skipping WS dispatch.")
            return
        group_name = USER_GROUP_TEMPLATE.format(user_id=user_id)
        message = {"type": CHANNEL_EVENT_TYPE, "message": envelope}
        # Narrow swallow: only the network call. Anything raised before this
        # line (bad config, formatting bugs) is allowed to propagate so it
        # gets caught in dev instead of disappearing into a log line.
        try:
            async_to_sync(channel_layer.group_send)(group_name, message)
        except Exception:  # noqa: BLE001 — Redis outage must not crash caller
            logger.exception(
                "Channels group_send failed for event %s → user %s",
                envelope["id"],
                user_id,
            )

    @staticmethod
    def _queue_fcm(user_id: int, envelope: dict[str, Any]) -> None:
        # Imported lazily — avoids a module-load-time Celery dependency in
        # code paths (e.g. selectors) that never dispatch events.
        from realtime.devices.tasks import send_fcm_notification

        send_fcm_notification.delay(user_id, envelope)
