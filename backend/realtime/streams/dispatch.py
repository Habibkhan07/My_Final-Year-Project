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


def publish_stream(
    *,
    user=None,
    group: str | None = None,
    stream_type: str,
    payload: dict[str, Any],
) -> None:
    """
    Push one transient stream frame to a channel-layer group.

    Group resolution (exactly one of ``group`` or ``user`` must be supplied):
        * ``group``: send to the named group directly. Used for booking-scoped
          subgroups like ``tracking_job_{id}`` where multiple users (the
          customer plus the assigned tech, plus a future admin watcher)
          subscribe to the same fan-out.
        * ``user``: send to the user's own ``USER_GROUP_TEMPLATE`` group —
          the original single-recipient stream behavior.

    Parameters
    ----------
    user:
        Recipient User instance. Mutually exclusive with ``group``.
    group:
        Channel-layer group name string. Mutually exclusive with ``user``.
    stream_type:
        Open string identifying the stream (e.g. ``"telemetry"``,
        ``"wallet_balance"``, ``"tech_gps"``). No registry yet — document
        new types in ``STREAM_DISPATCH_API.md`` as they are added.
    payload:
        Stream-specific dict. Must be JSON-serializable.

    Returns nothing. Network failures are absorbed; the caller can treat
    this as fire-and-forget.
    """
    if (user is None) == (group is None):
        # Both or neither — programming error. Raise so the bug surfaces in
        # dev; the network-call try/except below is intentionally narrow.
        raise ValueError(
            "publish_stream requires exactly one of `user` or `group`."
        )

    # SECURITY: when ``user`` is the resolver, the group is always scoped
    # to ``user.id``, so a stream frame can only ever reach the intended
    # user's sockets. When ``group`` is supplied directly, the caller (a
    # service or view) is responsible for membership-gating before
    # publishing — the consumer's subscribe path enforces this for
    # tracking subgroups.
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

    group_name = group if group is not None else USER_GROUP_TEMPLATE.format(user_id=user.id)
    message = {"type": CHANNEL_STREAM_TYPE, "message": envelope}
    # Narrow swallow: only the network call. Anything raised before this
    # line (bad config, formatting bugs) is allowed to propagate.
    try:
        async_to_sync(channel_layer.group_send)(group_name, message)
    except Exception as exc:  # noqa: BLE001 — Redis outage must not crash caller
        logger.warning(
            "Stream dispatch failed for group %s (stream_type=%s): %s",
            group_name,
            stream_type,
            exc,
        )
