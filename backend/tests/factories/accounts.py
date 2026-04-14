import factory
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from accounts.models import UserProfile, OTPRecord

User = get_user_model()


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    # username doubles as the phone number in this app's auth flow
    username = factory.Sequence(lambda n: f"+9230{n:08d}")
    first_name = factory.Faker('first_name')
    last_name = factory.Faker('last_name')
    email = factory.Sequence(lambda n: f"user_{n}@example.com")


class UserProfileFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = UserProfile

    user = factory.SubFactory(UserFactory)
    phone = factory.LazyAttribute(lambda o: o.user.username)
    is_technician = False


class OTPRecordFactory(factory.django.DjangoModelFactory):
    """
    Creates a valid, unused, non-expired OTPRecord by default.

    For expired records use:
        record = OTPRecordFactory(phone="+923001234567")
        OTPRecord.objects.filter(pk=record.pk).update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )
    """
    class Meta:
        model = OTPRecord

    phone = factory.Sequence(lambda n: f"+9230{n:08d}")
    code = "123456"
    is_used = False
    # expires_at is set by OTPRecord.save() — do not override here
