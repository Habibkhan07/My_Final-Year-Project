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
