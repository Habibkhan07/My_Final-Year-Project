import factory
from customers.models import CustomerProfile, CustomerAddress
from tests.factories.accounts import UserFactory


class CustomerProfileFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = CustomerProfile

    user = factory.SubFactory(UserFactory)


class CustomerAddressFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = CustomerAddress

    customer = factory.SubFactory(CustomerProfileFactory)
    label = 'Home'
    street_address = factory.Faker('address')
    # Default coordinates: Lahore city centre
    latitude = factory.LazyFunction(lambda: 31.5204)
    longitude = factory.LazyFunction(lambda: 74.3587)
    is_default = False
