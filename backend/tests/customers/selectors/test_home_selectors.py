import pytest
from django.utils import timezone
from datetime import timedelta

from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory

from catalog.selectors.category_selector import get_active_categories
from catalog.selectors.gig_selector import get_featured_fixed_price_gigs
from marketing.selectors.promotion_selector import get_active_promotions
from technicians.selectors.matchmaking_selectors import get_top_nearby_technicians

pytestmark = pytest.mark.django_db

class TestHomeSelectors:

    def test_get_active_categories(self):
        # Setup
        ServiceFactory(is_active=True, display_order=2)
        ServiceFactory(is_active=True, display_order=1)
        ServiceFactory(is_active=False)

        # Action
        categories = get_active_categories(limit=5)

        # Assert
        assert len(categories) == 2
        assert categories[0].display_order == 1
        assert categories[1].display_order == 2

    def test_get_featured_fixed_price_gigs_n_plus_one(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(is_active=True)
        SubServiceFactory(service=service, is_fixed_price=True, is_featured=True)
        SubServiceFactory(service=service, is_fixed_price=True, is_featured=True)
        
        # Action & Assert N+1
        with django_assert_num_queries(1):
            gigs = get_featured_fixed_price_gigs(limit=5)
            for gig in gigs:
                _ = gig.service.name

    def test_get_active_promotions_n_plus_one(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(is_active=True)
        sub_service = SubServiceFactory(service=service)
        
        now = timezone.now()
        PromotionFactory(
            target_service=service,
            is_active=True,
            is_featured_on_home=True,
            valid_from=now - timedelta(days=1),
            valid_until=now + timedelta(days=1)
        )
        PromotionFactory(
            target_service=service,
            is_active=True,
            is_featured_on_home=True,
            valid_from=now - timedelta(days=1),
            valid_until=now + timedelta(days=1)
        )

        # Inactive promo
        PromotionFactory(is_active=False)

        # Action & Assert N+1
        with django_assert_num_queries(1):
            promos = get_active_promotions(limit=5)
            assert len(promos) == 2
            for promo in promos:
                _ = promo.target_service.name

    def test_get_top_nearby_technicians_n_plus_one(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(is_active=True)
        sub_service = SubServiceFactory(service=service)
        
        # 3 Technicians in Lahore with same skills
        for _ in range(3):
            tech = TechnicianProfileFactory(
                base_latitude=31.5204,
                base_longitude=74.3587,
                is_active=True,
                is_onboarding_complete=True
            )
            TechnicianSkillFactory(technician=tech, sub_service=sub_service)

        # Action & Assert N+1
        with django_assert_num_queries(4):
            techs = get_top_nearby_technicians(
                lat=31.5204,
                lng=74.3587,
                radius_km=10.0,
                limit=5
            )
            assert len(techs) == 3
            for tech in techs:
                skills_list = tech.skills.all()
                if skills_list:
                    _ = skills_list[0].service.name
