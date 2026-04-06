import factory
from technicians.models import TechnicianProfile, TechnicianSkill, TechnicianServicePerformance
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
    base_rate = 1000.00
    max_rate = 1400.00


class TechnicianServicePerformanceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TechnicianServicePerformance

    technician = factory.SubFactory(TechnicianProfileFactory)
    service = factory.SubFactory(ServiceFactory)
    review_count = 0
    rating_average = 0.0
