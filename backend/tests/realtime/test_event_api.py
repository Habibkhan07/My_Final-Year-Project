"""API contract tests for /api/events/sync, /ack, /unacknowledged."""
from __future__ import annotations

from datetime import timedelta
from uuid import uuid4

import pytest
from django.urls import reverse
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from realtime.models import EventLog
from tests.factories.accounts import UserFactory
from tests.factories.core import EventLogFactory


@pytest.fixture
def authed_client():
    user = UserFactory()
    token, _ = Token.objects.get_or_create(user=user)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
    return client, user


@pytest.mark.django_db
def test_sync_requires_authentication():
    client = APIClient()
    response = client.get(reverse("realtime:events_sync"), {"since": timezone.now().isoformat()})
    assert response.status_code == 401
    # Full error envelope
    assert set(response.data.keys()) >= {"status", "code", "message", "errors"}


@pytest.mark.django_db
def test_sync_filters_by_since_and_user(authed_client):
    client, user = authed_client
    other = UserFactory()

    # old & other-user events are noise
    old = EventLogFactory(user=user)
    EventLog.objects.filter(pk=old.pk).update(created_at=timezone.now() - timedelta(hours=2))
    EventLogFactory(user=other)

    fresh = EventLogFactory(user=user)
    cutoff = (timezone.now() - timedelta(hours=1)).isoformat()

    response = client.get(reverse("realtime:events_sync"), {"since": cutoff})
    assert response.status_code == 200
    results = response.data["results"]
    ids = [entry["id"] for entry in results]
    assert ids == [str(fresh.id)]
    assert response.data["next_cursor"] is not None
    # Sync output must include the ``kind`` discriminator so the frontend
    # dispatcher can use the same switch for replayed events as for live ones.
    assert all(entry["kind"] == "event" for entry in results)


@pytest.mark.django_db
def test_sync_rejects_invalid_since(authed_client):
    client, _ = authed_client
    response = client.get(reverse("realtime:events_sync"), {"since": "not-a-date"})
    assert response.status_code == 400
    assert response.data["code"] == "validation_error"


@pytest.mark.django_db
def test_ack_is_idempotent(authed_client):
    client, user = authed_client
    event = EventLogFactory(user=user, is_critical=True, acknowledged_at=None)

    for _ in range(2):
        response = client.post(
            reverse("realtime:events_ack"),
            data={"event_ids": [str(event.id)]},
            format="json",
        )
        assert response.status_code == 204

    event.refresh_from_db()
    assert event.acknowledged_at is not None


@pytest.mark.django_db
def test_ack_silently_ignores_foreign_user_ids(authed_client):
    client, user = authed_client
    foreign = EventLogFactory(is_critical=True, acknowledged_at=None)

    response = client.post(
        reverse("realtime:events_ack"),
        data={"event_ids": [str(foreign.id)]},
        format="json",
    )
    assert response.status_code == 204
    foreign.refresh_from_db()
    assert foreign.acknowledged_at is None  # unchanged — not ours to ack


@pytest.mark.django_db
def test_unacknowledged_returns_only_current_user(authed_client):
    client, user = authed_client
    mine = EventLogFactory(user=user, is_critical=True, acknowledged_at=None)
    EventLogFactory(is_critical=True, acknowledged_at=None)  # some other user

    response = client.get(reverse("realtime:events_unacknowledged"))
    assert response.status_code == 200
    results = response.data["results"]
    ids = [entry["id"] for entry in results]
    assert ids == [str(mine.id)]
    # Same envelope shape as the sync endpoint — kind discriminator present.
    assert all(entry["kind"] == "event" for entry in results)
