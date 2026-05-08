"""Factory for ``TechReliabilityIncident``.

Standalone file (not in ``bookings.py``) because the tech-reliability flow
is a tangential audit channel — keeping its factory adjacent to its
consumer (orchestrator tests for cancel_by_tech / mark_no_show) makes the
test files easier to navigate.
"""

import factory

from bookings.models import TechReliabilityIncident


class TechReliabilityIncidentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechReliabilityIncident

    technician = factory.SelfAttribute('booking.technician')
    booking = factory.SubFactory('tests.factories.bookings.JobBookingFactory')
    incident_type = TechReliabilityIncident.INCIDENT_TECH_CANCEL
    phase = 'pre_arrival'
    notes = ''
