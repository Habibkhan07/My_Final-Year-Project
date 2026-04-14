import factory
from customers.models import CustomerProfile, SavedAddress
from tests.factories.accounts import UserFactory


class CustomerProfileFactory(factory.django.DjangoModelFactory):
    """
    Creates a customers.models.CustomerProfile (distinct from accounts.models.CustomerProfile).
    Owns SavedAddress records via the 'addresses' related name.
    """
    class Meta:
        model = CustomerProfile

    user = factory.SubFactory(UserFactory)


class SavedAddressFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = SavedAddress

    customer = factory.SubFactory(CustomerProfileFactory)
    label = 'Home'
    # Default coordinates: Lahore city centre — within any reasonable travel radius
    latitude = factory.LazyFunction(lambda: 31.5204)
    longitude = factory.LazyFunction(lambda: 74.3587)
    address_text = factory.Faker('address')
