from decimal import Decimal

import factory
from django.utils import timezone

from bookings.models import BookingItem, JobBooking, Quote, QuoteLineItem
from tests.factories.accounts import UserFactory
from tests.factories.catalog import ServiceFactory
from tests.factories.technicians import TechnicianProfileFactory


class JobBookingFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = JobBooking

    technician = factory.SubFactory(TechnicianProfileFactory)
    customer = factory.SubFactory(UserFactory)
    address = None  # nullable; override in tests that need a real address

    # Catalog refs. Tests can pass `sub_service=...` to make a Scenario A/B
    # booking; the LazyAttribute on `service` then derives the parent so
    # the two FKs stay coherent. Tests that pass neither get an inspection
    # booking (Scenario C) with a fresh parent Service.
    sub_service = None
    promotion = None
    service = factory.LazyAttribute(
        lambda o: o.sub_service.service if o.sub_service else ServiceFactory()
    )

    scheduled_start = factory.LazyFunction(timezone.now)
    scheduled_end = factory.LazyAttribute(
        lambda o: o.scheduled_start + timezone.timedelta(hours=1)
    )
    status = JobBooking.STATUS_CONFIRMED
    price_amount = factory.Faker('pydecimal', left_digits=4, right_digits=2, positive=True)
    price_context = 'Test booking'


# ---------------------------------------------------------------------------
# Status-progression chain.
#
# Each subclass moves the booking one step further down the orchestrator's
# happy-path lifecycle. Used by orchestrator tests to fabricate a booking
# in any from-state without manually stamping every prior phase timestamp.
# ---------------------------------------------------------------------------


class JobBookingConfirmedFactory(JobBookingFactory):
    status = JobBooking.STATUS_CONFIRMED
    accepted_at = factory.LazyFunction(timezone.now)


class JobBookingEnRouteFactory(JobBookingConfirmedFactory):
    status = JobBooking.STATUS_EN_ROUTE
    en_route_started_at = factory.LazyFunction(timezone.now)


class JobBookingArrivedFactory(JobBookingEnRouteFactory):
    status = JobBooking.STATUS_ARRIVED
    arrived_at = factory.LazyFunction(timezone.now)


class JobBookingInspectingFactory(JobBookingArrivedFactory):
    status = JobBooking.STATUS_INSPECTING
    inspection_started_at = factory.LazyFunction(timezone.now)


class JobBookingQuotedFactory(JobBookingInspectingFactory):
    status = JobBooking.STATUS_QUOTED
    quote_first_submitted_at = factory.LazyFunction(timezone.now)


class JobBookingInProgressFactory(JobBookingQuotedFactory):
    status = JobBooking.STATUS_IN_PROGRESS
    work_started_at = factory.LazyFunction(timezone.now)


class JobBookingCompletedFactory(JobBookingInProgressFactory):
    status = JobBooking.STATUS_COMPLETED
    completed_at = factory.LazyFunction(timezone.now)
    cash_collected_at = factory.LazyFunction(timezone.now)
    cash_collected_amount = Decimal('1500.00')


# ---------------------------------------------------------------------------
# Quote / line item / booking item factories.
# ---------------------------------------------------------------------------


class QuoteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Quote

    booking = factory.SubFactory(JobBookingInspectingFactory)
    revision_number = 1
    status = Quote.STATUS_SUBMITTED
    total_amount = Decimal('0.00')
    is_upsell = False
    submitted_at = factory.LazyFunction(timezone.now)


class QuoteLineItemFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = QuoteLineItem

    quote = factory.SubFactory(QuoteFactory)
    sub_service = factory.SubFactory('tests.factories.catalog.SubServiceFactory')
    quantity = 1
    priced_at = Decimal('500.00')
    line_total = Decimal('500.00')


class BookingItemFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BookingItem

    booking = factory.SubFactory(JobBookingInProgressFactory)
    sub_service = factory.SubFactory('tests.factories.catalog.SubServiceFactory')
    quantity = 1
    price_charged = Decimal('500.00')
    line_total = Decimal('500.00')
