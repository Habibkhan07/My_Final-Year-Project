import factory
from django.utils import timezone
from bookings.models import JobBooking
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.accounts import UserFactory
from tests.factories.catalog import ServiceFactory


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
