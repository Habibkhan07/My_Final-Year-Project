"""
Read-side queries for the EventLog recovery endpoints.

All queries are scoped to a specific ``user`` — callers must pass
``request.user`` (never a user_id lifted from the request body) to preserve
IDOR safety.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from django.db.models import QuerySet

from core.models import EventLog

#: Hard ceiling on sync-endpoint page size. Prevents a misbehaving client
#: from dragging a huge backlog down in one request.
MAX_SYNC_LIMIT = 100
DEFAULT_SYNC_LIMIT = 50


def list_events_since(
    *,
    user,
    since: datetime,
    limit: Optional[int] = None,
) -> QuerySet[EventLog]:
    """
    Events for ``user`` created strictly after ``since``, oldest-first.

    Ordered ascending so the client replays them in the same order the
    server originally emitted them. Clamped to ``MAX_SYNC_LIMIT``.
    """
    effective_limit = min(limit or DEFAULT_SYNC_LIMIT, MAX_SYNC_LIMIT)
    return (
        EventLog.objects.filter(user=user, created_at__gt=since)
        .order_by("created_at")[:effective_limit]
    )


def list_unacknowledged_critical(*, user) -> QuerySet[EventLog]:
    """Critical events the user never ACK'd within the 24h window."""
    return EventLog.objects.unacknowledged_critical(user=user)
