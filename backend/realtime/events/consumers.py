"""
SystemEventConsumer — logic-less WebSocket transport.

Server-to-client primary direction. Mirrors the "thin view" principle: all
business decisions live in the dispatch services. The consumer only:

    1. Authenticates the handshake via ``ws_auth.get_user_from_scope``.
    2. Subscribes the socket to the user's realtime group.
    3. Forwards ``system.event`` and ``system.stream`` channel-layer
       messages to the client.
    4. Accepts a narrow set of upstream messages — exclusively
       ``subscribe_tracking`` / ``unsubscribe_tracking`` — for joining /
       leaving per-booking tracking subgroups (live GPS fan-out).
       Every other client-originated payload is ignored.

Naming caveat
-------------
The class name (``SystemEventConsumer``) and the user-group suffix
(``_events``) predate streams support. Once streams started flowing
through the same socket, ``"events"`` here became shorthand for *the
user's realtime channel*, which now carries both event and stream
frames. The rename was deliberately deferred to avoid bundling a
coordinated frontend churn into the streams-introduction patch — the
frontend (``SystemEventNotifier``, ``EventUrgencyRouter``, Riverpod
providers, feature docs) references these names. If the misnomer
proves confusing in real use, rename in a focused future refactor with
its own test coverage.
"""
from __future__ import annotations

import json
import logging

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer

from realtime.constants.groups import (
    TRACKING_JOB_GROUP_TEMPLATE,
    USER_GROUP_TEMPLATE,
)
from realtime.events.ws_auth import get_user_from_scope

logger = logging.getLogger(__name__)


class SystemEventConsumer(AsyncWebsocketConsumer):
    """Per-user real-time event socket at ``ws/events/``."""

    async def connect(self) -> None:
        user = await get_user_from_scope(self.scope)
        if user is None:
            # SECURITY: reject unauthenticated handshakes before joining any
            # channel group — code 4001 signals "auth required" to the client.
            await self.close(code=4001)
            return

        self.user = user
        self.group_name = USER_GROUP_TEMPLATE.format(user_id=user.id)
        # Per-connection set of booking_ids whose tracking subgroup this
        # socket has joined. Cleaned up in ``disconnect``. The set is
        # connection-local — on reconnect the frontend must re-issue
        # ``subscribe_tracking`` for any booking it's still watching.
        self._tracking_subscriptions: set[int] = set()
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, code: int) -> None:
        # Clean up tracking subgroups BEFORE the user-group cleanup so an
        # in-flight tracking frame never fans out to a half-disconnected
        # socket. ``group_discard`` is idempotent so re-entry is safe.
        for booking_id in list(self._tracking_subscriptions):
            await self.channel_layer.group_discard(
                TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking_id),
                self.channel_name,
            )
        self._tracking_subscriptions.clear()

        group_name = getattr(self, "group_name", None)
        if group_name is not None:
            await self.channel_layer.group_discard(group_name, self.channel_name)

    async def receive(self, text_data: str | None = None, bytes_data: bytes | None = None) -> None:
        """Accept ``subscribe_tracking`` / ``unsubscribe_tracking`` upstream
        messages; ignore everything else.

        Wire shape:
            {"action": "subscribe_tracking",   "booking_id": 123}
            {"action": "unsubscribe_tracking", "booking_id": 123}

        Authorization: subscriber must be the booking's customer or
        assigned technician AND the booking must not be in a terminal
        status. Failures silently drop (no error frame back) to avoid
        leaking booking existence; a warning is logged for diagnosis.
        """
        if not text_data:
            return
        try:
            content = json.loads(text_data)
        except (TypeError, ValueError):
            return
        if not isinstance(content, dict):
            return

        action = content.get("action")
        booking_id = content.get("booking_id")
        if not isinstance(booking_id, int):
            return

        if action == "subscribe_tracking":
            allowed = await self._can_subscribe(self.user.id, booking_id)
            if not allowed:
                logger.warning(
                    "subscribe_tracking denied: user=%s booking=%s",
                    self.user.id,
                    booking_id,
                )
                return
            await self.channel_layer.group_add(
                TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking_id),
                self.channel_name,
            )
            self._tracking_subscriptions.add(booking_id)
            return

        if action == "unsubscribe_tracking":
            await self.channel_layer.group_discard(
                TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking_id),
                self.channel_name,
            )
            self._tracking_subscriptions.discard(booking_id)
            return

        # All other upstream messages: ignored (consumer remains
        # one-way for everything except tracking sub/unsub).

    @staticmethod
    @database_sync_to_async
    def _can_subscribe(user_id: int, booking_id: int) -> bool:
        """Booking-scoped authorization.

        Returns True when the user is the booking's customer or assigned
        tech AND the booking is in an actionable (non-terminal) status.
        Terminal statuses are blocked so a stale frontend cannot keep
        receiving GPS frames after a job is cancelled / completed
        (defense-in-depth — the tech app should stop publishing).
        """
        # Lazy import to avoid a module-load cycle between bookings and
        # realtime apps (bookings.services.orchestrator imports realtime
        # constants, so realtime cannot import bookings at module level).
        from bookings.models import JobBooking

        try:
            booking = (
                JobBooking.objects
                .only("id", "status", "customer_id", "technician_id")
                .select_related("technician")
                .get(id=booking_id)
            )
        except JobBooking.DoesNotExist:
            return False

        # Audit P2-07: tracking on terminal-status bookings is denied so
        # stale tech-side frames (sent during a transition window) cannot
        # leak the tech's location to a customer whose job already ended.
        if booking.status in JobBooking.TERMINAL_STATUSES:
            return False

        if booking.customer_id == user_id:
            return True
        # technician.user_id is the FK on TechnicianProfile.user; the
        # booking's technician_id is TechnicianProfile.id. Use the cheap
        # ``technician.user_id`` reverse instead of refetching User.
        if booking.technician.user_id == user_id:
            return True
        return False

    async def system_event(self, event: dict) -> None:
        """
        Channel-layer handler for ``type: "system.event"`` messages.

        The payload is already the final envelope built by
        ``EventDispatchService.broadcast_event`` — we serialize and forward.
        """
        message = event.get("message")
        if message is None:
            logger.warning("system_event received without 'message' key: %r", event)
            return
        await self.send(text_data=json.dumps(message))

    async def system_stream(self, event: dict) -> None:
        """
        Channel-layer handler for ``type: "system.stream"`` messages.

        Mirrors ``system_event`` exactly — the consumer is envelope-agnostic
        and does not inspect ``kind``. Fans out across both the user group
        AND any joined ``tracking_job_{id}`` subgroups; the same handler
        method serves both because Channels routes purely on the
        message ``type`` discriminator.
        """
        message = event.get("message")
        if message is None:
            logger.warning("system_stream received without 'message' key: %r", event)
            return
        await self.send(text_data=json.dumps(message))
