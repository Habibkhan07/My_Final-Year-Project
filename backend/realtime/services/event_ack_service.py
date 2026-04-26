"""
Acknowledge persisted events for a user.

ACK writes are idempotent: we only flip ``acknowledged_at`` on rows where
it is still NULL, so double-acking is a no-op (no last-write-wins drift).
"""
from __future__ import annotations

from uuid import UUID
from typing import Sequence

from django.db import transaction
from django.utils import timezone

from realtime.models import EventLog


class EventAckService:
    @staticmethod
    @transaction.atomic
    def acknowledge_events(*, user, event_ids: Sequence[UUID]) -> int:
        """
        Flip ``acknowledged_at = now`` for the user's unacknowledged rows
        whose ids are in ``event_ids``. Returns the count actually updated.
        """
        if not event_ids:
            return 0
        return EventLog.objects.filter(
            id__in=event_ids,
            user=user,
            acknowledged_at__isnull=True,
        ).update(acknowledged_at=timezone.now())
