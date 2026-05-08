from decimal import Decimal

import factory
from catalog.models import Service, SubService


class ServiceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Service

    name = factory.Sequence(lambda n: f"Service {n}")
    icon_name = factory.Faker('word')
    display_order = factory.Sequence(lambda n: n)
    is_active = True
    base_inspection_fee = 500.00


class SubServiceFactory(factory.django.DjangoModelFactory):
    """Default = labor sub-service (``is_fixed_price=False``).

    ``max_price`` defaults to 2.5x ``base_price`` for labor rows so the
    orchestrator's quote-band check has a realistic ceiling. Fixed-price
    rows get ``max_price=None`` (the band check requires equality with
    ``base_price`` for those — see orchestrator.submit_quote).
    """
    class Meta:
        model = SubService

    service = factory.SubFactory(ServiceFactory)
    name = factory.Sequence(lambda n: f"SubService {n}")
    base_price = 1000.00
    is_fixed_price = False
    is_featured = False
    search_tags = []
    icon_name = factory.Faker('word')
    card_image_url = factory.Faker('url')
    max_price = factory.LazyAttribute(
        lambda o: None if o.is_fixed_price else Decimal(str(o.base_price)) * Decimal('2.5')
    )


class FixedPriceSubServiceFactory(SubServiceFactory):
    """Convenience factory for tests exercising the fixed-price band."""
    is_fixed_price = True
    max_price = None


class LaborSubServiceFactory(SubServiceFactory):
    """Convenience factory with explicit labor-band coordinates."""
    is_fixed_price = False
    base_price = Decimal('500.00')
    max_price = Decimal('1500.00')
