"""
SystemEventConsumer — logic-less WebSocket transport.

Server-to-client one-way channel. Mirrors the "thin view" principle: all
business decisions live in the dispatch services. The consumer only:

    1. Authenticates the handshake via ``ws_auth.get_user_from_scope``.
    2. Subscribes the socket to the user's realtime group.
    3. Forwards ``system.event`` and ``system.stream`` channel-layer
       messages to the client.

Naming caveat
-------------
The class name (``SystemEventConsumer``) and the group suffix (``_events``)
predate streams support. Once streams started flowing through the same
socket, ``"events"`` here became shorthand for *the user's realtime
channel*, which now carries both event and stream frames. The rename was
deliberately deferred to avoid bundling a coordinated frontend churn into
the streams-introduction patch — the frontend (``SystemEventNotifier``,
``EventUrgencyRouter``, Riverpod providers, feature docs) references
these names. If the misnomer proves confusing in real use, rename in a
focused future refactor with its own test coverage.
"""
from __future__ import annotations

import json
import logging

from channels.generic.websocket import AsyncWebsocketConsumer

from realtime.constants.groups import USER_GROUP_TEMPLATE
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
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, code: int) -> None:
        group_name = getattr(self, "group_name", None)
        if group_name is not None:
            await self.channel_layer.group_discard(group_name, self.channel_name)

    async def receive(self, text_data: str | None = None, bytes_data: bytes | None = None) -> None:
        """One-way socket — ignore everything the client sends."""
        return None

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
        and does not inspect ``kind``. The frontend dispatcher is what
        routes events vs. streams; here we just forward the bytes.
        """
        message = event.get("message")
        if message is None:
            logger.warning("system_stream received without 'message' key: %r", event)
            return
        await self.send(text_data=json.dumps(message))
