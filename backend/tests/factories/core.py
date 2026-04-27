"""Factories for the core (EventLog) app."""
from __future__ import annotations

import factory

from realtime.models import EventLog
from tests.factories.accounts import UserFactory


class EventLogFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = EventLog

    user = factory.SubFactory(UserFactory)
    event_type = "job_dispatched"
    target_role = EventLog.TARGET_TECHNICIAN
    is_critical = True
    acknowledged_at = None

    @factory.lazy_attribute
    def payload(self):
        return {
            "kind": "event",
            "id": str(factory.Faker("uuid4").evaluate(None, None, {"locale": "en"})),
            "rawType": self.event_type,
            "targetRole": self.target_role,
            "timestamp": "2026-04-24T00:00:00Z",
            "payload": {"job_id": "sample-job"},
        }
