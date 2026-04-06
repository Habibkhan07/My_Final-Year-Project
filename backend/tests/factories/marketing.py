import factory
from django.utils import timezone
from datetime import timedelta
from marketing.models import Promotion
from tests.factories.catalog import ServiceFactory

class PromotionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Promotion
    
    name = factory.Sequence(lambda n: f"Promo {n}")
    description = factory.Sequence(lambda n: f"Promo Description {n}")
    discount_type = Promotion.DiscountType.PERCENTAGE
    discount_value = 20.00
    target_service = factory.SubFactory(ServiceFactory)
    funded_by = Promotion.FundingSource.PLATFORM
    valid_from = factory.LazyFunction(lambda: timezone.now() - timedelta(days=1))
    valid_until = factory.LazyFunction(lambda: timezone.now() + timedelta(days=7))
    is_active = True
    is_featured_on_home = True
