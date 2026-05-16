import datetime
import factory
from technicians.models import (
    Review,
    TechnicianProfile,
    TechnicianSchedule,
    TechnicianServiceLicense,
    TechnicianServicePerformance,
    TechnicianSkill,
)
from tests.factories.accounts import UserFactory
from tests.factories.catalog import SubServiceFactory, ServiceFactory

class TechnicianProfileFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianProfile
        skip_postgeneration_save = True

    user = factory.SubFactory(UserFactory)
    city = 'LHR'
    cnic_number = factory.Sequence(lambda n: f"35202-0000000-{n}")
    status = 'APPROVED'
    is_onboarding_complete = True
    is_active = True
    # Happy-path default: tech is online and bookable. Matches the other
    # bookability gates above (status / is_active / is_onboarding_complete)
    # so discovery + instant-book tests don't have to repeat themselves.
    # Tests that exercise offline / locked-out paths set this to False
    # explicitly.
    is_online = True
    base_latitude = 31.5204
    base_longitude = 74.3587
    max_travel_radius_km = 10
    rating_average = 4.5
    review_count = 10

    @factory.post_generation
    def skills(self, create, extracted, **kwargs):
        if not create:
            return
        if extracted:
            for skill in extracted:
                TechnicianSkillFactory(technician=self, sub_service=skill)


class TechnicianSkillFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianSkill

    technician = factory.SubFactory(TechnicianProfileFactory)
    sub_service = factory.SubFactory(SubServiceFactory)
    years_of_experience = 2
    labor_rate = 1000.00


class TechnicianServiceLicenseFactory(factory.django.DjangoModelFactory):
    """Bridge row gating which parent services a tech can take work
    under. The skills CRUD endpoint (`add_skill`) requires a matching
    row before allowing an add; the picker endpoint
    (`/me/service-categories/`) returns only services with one.

    ``license_picture`` defaults to None — the column is nullable and
    the gate cares only about row existence. Tests that need an image
    (e.g. admin-view rendering tests) can pass an explicit file.
    """

    class Meta:
        model = TechnicianServiceLicense

    technician = factory.SubFactory(TechnicianProfileFactory)
    service = factory.SubFactory(ServiceFactory)
    license_picture = None


class TechnicianServicePerformanceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianServicePerformance

    technician = factory.SubFactory(TechnicianProfileFactory)
    service = factory.SubFactory(ServiceFactory)
    review_count = 0
    rating_average = 0.0


class TechnicianScheduleFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianSchedule

    technician = factory.SubFactory(TechnicianProfileFactory)
    day_of_week = 0  # Monday
    start_time = datetime.time(9, 0)   # 9:00 AM
    end_time = datetime.time(17, 0)    # 5:00 PM
    is_working = True


class ReviewFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Review

    technician = factory.SubFactory(TechnicianProfileFactory)
    reviewer = factory.SubFactory(UserFactory)
    rating = 5
    text = factory.Faker('sentence')
