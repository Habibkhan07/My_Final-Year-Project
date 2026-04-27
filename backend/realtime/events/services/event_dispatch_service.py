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
from datetime import datetime, timezone as dt_timezone
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


def _utc_now_iso() -> str:
    """ISO-8601 UTC timestamp with trailing ``Z`` (Flutter-friendly)."""
    return datetime.now(tz=dt_timezone.utc).isoformat().replace("+00:00", "Z")


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
        """
        meta = get_event_meta(event_type)
        envelope: dict[str, Any] = {
            # ``kind`` discriminates events from streams on the same socket.
            # Frontend dispatcher switches on this field. See STREAM_DISPATCH_API.md.
            "kind": "event",
            "id": str(uuid.uuid4()),
            "rawType": event_type,
            "targetRole": target_role,
            "timestamp": _utc_now_iso(),
            "payload": payload,
        }

        # --- Step 1: Persist first (sacred DB write). ----------------------
        # Any exception here is allowed to bubble — if we cannot record the
        # event, we must not pretend to have dispatched it.
        EventLog.objects.create(
            id=envelope["id"],
            user=user,
            event_type=event_type,
            target_role=target_role,
            payload=envelope,
            is_critical=meta["is_critical"],
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
    ) -> list[dict[str, Any]]:
        """
        Fan-out helper. Typical use: nearby-technician notifications for a
        new job. Each recipient gets its own EventLog row + envelope id.
        """
        envelopes: list[dict[str, Any]] = []
        for user in users:
            envelopes.append(
                EventDispatchService.broadcast_event(
                    user=user,
                    target_role=target_role,
                    event_type=event_type,
                    payload=payload,
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
