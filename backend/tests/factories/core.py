"""Factories for the core (EventLog) app."""
from __future__ import annotations

import factory

from realtime.models import EventLog
from tests.factories.accounts import UserFactory


class EventLogFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = EventLog

    user = factory.SubFactory(UserFactory)
    event_type = "job_new_request"
    target_role = EventLog.TARGET_TECHNICIAN
    is_critical = True
    acknowledged_at = None

    # EventLog.payload stores the *inner* feature payload only — the envelope
    # shell (kind/rawType/targetRole/timestamp) is rebuilt by EventLogSerializer
    # on read. Matches what EventDispatchService.broadcast_event persists.
    payload = {"job_id": "sample-job"}
