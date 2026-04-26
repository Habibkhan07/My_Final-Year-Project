"""Selector-level tests for event recovery queries."""
from __future__ import annotations

from datetime import timedelta

import pytest
from django.utils import timezone

from realtime.selectors.event_selectors import (
    MAX_SYNC_LIMIT,
    list_events_since,
    list_unacknowledged_critical,
)
from tests.factories.accounts import UserFactory
from tests.factories.core import EventLogFactory


@pytest.mark.django_db
def test_list_events_since_filters_by_user_and_timestamp(django_assert_num_queries):
    alice = UserFactory()
    bob = UserFactory()
    now = timezone.now()

    old_event = EventLogFactory(user=alice)
    EventLog = old_event.__class__
    EventLog.objects.filter(pk=old_event.pk).update(created_at=now - timedelta(hours=2))

    fresh = EventLogFactory(user=alice)
    EventLogFactory(user=bob)  # noise — must not appear in alice's results

    cutoff = now - timedelta(hours=1)
    with django_assert_num_queries(1):
        results = list(list_events_since(user=alice, since=cutoff))

    assert [e.id for e in results] == [fresh.id]


@pytest.mark.django_db
def test_list_events_since_clamps_limit():
    alice = UserFactory()
    for _ in range(MAX_SYNC_LIMIT + 5):
        EventLogFactory(user=alice)

    results = list(list_events_since(user=alice, since=timezone.now() - timedelta(days=1), limit=500))
    assert len(results) == MAX_SYNC_LIMIT


@pytest.mark.django_db
def test_unacknowledged_critical_excludes_ack_and_stale_and_noncritical():
    alice = UserFactory()

    pending = EventLogFactory(user=alice, is_critical=True)
    EventLogFactory(user=alice, is_critical=True, acknowledged_at=timezone.now())
    EventLogFactory(user=alice, is_critical=False)

    stale = EventLogFactory(user=alice, is_critical=True)
    stale.__class__.objects.filter(pk=stale.pk).update(
        created_at=timezone.now() - timedelta(hours=48)
    )

    results = list(list_unacknowledged_critical(user=alice))
    assert [e.id for e in results] == [pending.id]
