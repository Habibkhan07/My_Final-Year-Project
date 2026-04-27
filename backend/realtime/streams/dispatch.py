"""
Stream publisher — the ``solo websocket data`` half of the realtime pipeline.

Streams are deliberately *not* events:

    * No ``EventLog`` row. Streams represent transient state (live GPS, the
      current wallet balance display, AI-chatbot tokens, typing indicators).
      A dropped frame is correctable by the next frame; persisting them
      would thrash the database for no benefit.
    * No FCM fallback. If the user's socket is closed, the stream is gone
      — that's the *correct* behavior for a state value. FCM is only for
      facts the user must be told about even when the app is closed.
    * No ACK contract. Nothing to acknowledge.
    * Best-effort, fire-and-forget at the transport layer: the only barrel
      is a narrow try/except around the ``group_send`` network call. Bugs
      above that line (bad config, formatting errors) propagate so they
      surface in dev instead of vanishing into a log line.

Distinguished from events on the wire by the ``kind`` field of the envelope.
The frontend dispatcher reads ``kind`` and routes accordingly. See
``realtime/api/STREAM_DISPATCH_API.md`` for the full contract.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone as dt_timezone
from typing import Any

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from realtime.constants.groups import USER_GROUP_TEMPLATE

logger = logging.getLogger(__name__)

#: Must match the handler method ``system_stream`` in SystemEventConsumer
#: (Channels maps ``system.stream`` → ``system_stream``).
CHANNEL_STREAM_TYPE = "system.stream"


def _utc_now_iso() -> str:
    """ISO-8601 UTC timestamp with trailing ``Z`` (Flutter-friendly)."""
    return datetime.now(tz=dt_timezone.utc).isoformat().replace("+00:00", "Z")


def publish_stream(*, user, stream_type: str, payload: dict[str, Any]) -> None:
    """
    Push one transient stream frame to ``user``'s realtime channel.

    Parameters
    ----------
    user:
        Recipient User instance. Must be a concrete authenticated user —
        the frame is delivered only to this user's group.
    stream_type:
        Open string identifying the stream (e.g. ``"telemetry"``,
        ``"wallet_balance"``, ``"ai_chat_token"``). No registry yet —
        document new types in ``STREAM_DISPATCH_API.md`` as they are added.
    payload:
        Stream-specific dict. Must be JSON-serializable.

    Returns nothing. Network failures are absorbed; the caller can treat
    this as fire-and-forget.
    """
    # SECURITY: group is always scoped to ``user.id``, so a stream frame
    # can only ever reach the intended user's sockets — no cross-user leak.
    envelope: dict[str, Any] = {
        "kind": "stream",
        "streamType": stream_type,
        "timestamp": _utc_now_iso(),
        "payload": payload,
    }

    channel_layer = get_channel_layer()
    if channel_layer is None:
        logger.warning("No channel layer configured; skipping stream dispatch.")
        return

    group_name = USER_GROUP_TEMPLATE.format(user_id=user.id)
    message = {"type": CHANNEL_STREAM_TYPE, "message": envelope}
    # Narrow swallow: only the network call. Anything raised before this
    # line (bad config, formatting bugs) is allowed to propagate.
    try:
        async_to_sync(channel_layer.group_send)(group_name, message)
    except Exception as exc:  # noqa: BLE001 — Redis outage must not crash caller
        logger.warning(
            "Stream dispatch failed for user %s (stream_type=%s): %s",
            user.id,
            stream_type,
            exc,
        )
