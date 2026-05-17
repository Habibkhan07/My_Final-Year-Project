"""
Tests for technicians/selectors/profile_selector.py
get_technician_profile_detail()

Coverage:
  - Happy path: approved tech returned with dynamic attributes attached
  - Status guard: PENDING and REJECTED profiles raise DoesNotExist
  - Non-existent ID raises DoesNotExist
  - Distance attached when valid lat/lng provided; None otherwise
  - Bayesian score attached in all cases
  - Scenario A context: sub_service + is_fixed_price=True resolved
  - Scenario B context: sub_service + is_fixed_price=False resolved, prefetched_skill attached
  - Scenario C context: service_id resolved
  - Promo resolved from explicit promotion_id
  - Promo resolved from active promo on service (no promotion_id passed)
  - Expired promo not resolved
  - all_skills and recent_reviews_list prefetched (N+1 guard)
"""
import pytest
from datetime import timedelta
from django.utils import timezone

from technicians.models import TechnicianProfile
from technicians.selectors.profile_selector import get_technician_profile_detail
from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianSkillFactory,
    ReviewFactory,
)
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory

pytestmark = pytest.mark.django_db


class TestGetTechnicianProfileDetail:

    # ------------------------------------------------------------------
    # HAPPY PATH
    # ------------------------------------------------------------------

    def test_returns_approved_technician(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert result.id == tech.id

    def test_attaches_bayesian_score(self):
        tech = TechnicianProfileFactory(status='APPROVED', rating_average=4.5, review_count=20)
        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert hasattr(result, 'bayesian_score')
        assert isinstance(result.bayesian_score, float)

    def test_attaches_distance_km_when_coordinates_provided(self):
        # Tech is at Lahore city centre
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204,
            base_longitude=74.3587,
        )
        # Customer ~1 km north
        result, _, _, _ = get_technician_profile_detail(
            tech_id=tech.id, lat=31.5294, lng=74.3587
        )
        assert result.distance_km is not None
        assert isinstance(result.distance_km, float)
        assert result.distance_km < 5.0  # Must be a plausible small distance

    def test_distance_km_is_none_when_no_coordinates(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert result.distance_km is None

    def test_distance_km_is_none_when_tech_has_no_gps(self):
        tech = TechnicianProfileFactory(
            status='APPROVED', base_latitude=None, base_longitude=None
        )
        result, _, _, _ = get_technician_profile_detail(
            tech_id=tech.id, lat=31.5204, lng=74.3587
        )
        assert result.distance_km is None

    # ------------------------------------------------------------------
    # STATUS GUARD
    # ------------------------------------------------------------------

    def test_raises_for_pending_technician(self):
        tech = TechnicianProfileFactory(status='PENDING')
        with pytest.raises(TechnicianProfile.DoesNotExist):
            get_technician_profile_detail(tech_id=tech.id)

    def test_raises_for_rejected_technician(self):
        # ``rejection_reason`` is required for REJECTED rows by the model's
        # CheckConstraint (technicianprofile_rejected_requires_reason). The
        # selector's behaviour under test is purely status-based, so a
        # placeholder reason is fine.
        tech = TechnicianProfileFactory(
            status='REJECTED', rejection_reason='Documents incomplete.'
        )
        with pytest.raises(TechnicianProfile.DoesNotExist):
            get_technician_profile_detail(tech_id=tech.id)

    def test_raises_for_nonexistent_id(self):
        with pytest.raises(TechnicianProfile.DoesNotExist):
            get_technician_profile_detail(tech_id=999999)

    # ------------------------------------------------------------------
    # CONTEXT RESOLUTION
    # ------------------------------------------------------------------

    def test_scenario_a_resolves_fixed_price_subservice(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=True, base_price=1500.00)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        _, resolved_service, resolved_subservice, _ = get_technician_profile_detail(
            tech_id=tech.id, sub_service_id=sub.id
        )
        assert resolved_subservice is not None
        assert resolved_subservice.id == sub.id
        assert resolved_subservice.is_fixed_price is True
        assert resolved_service.id == service.id

    def test_scenario_b_resolves_variable_subservice_and_prefetches_skill(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        result, _, resolved_subservice, _ = get_technician_profile_detail(
            tech_id=tech.id, sub_service_id=sub.id
        )
        assert resolved_subservice.is_fixed_price is False
        # prefetched_skill must be attached and non-empty — the membership
        # row exists, which is all the pricing resolver needs now.
        assert hasattr(result, 'prefetched_skill')
        assert len(result.prefetched_skill) == 1
        assert result.prefetched_skill[0].sub_service_id == sub.id

    def test_scenario_c_resolves_service_from_service_id(self):
        service = ServiceFactory(base_inspection_fee=600.00)
        tech = TechnicianProfileFactory(status='APPROVED')

        _, resolved_service, resolved_subservice, _ = get_technician_profile_detail(
            tech_id=tech.id, service_id=service.id
        )
        assert resolved_service.id == service.id
        assert resolved_subservice is None

    def test_subservice_takes_precedence_over_service_id(self):
        """sub_service_id must win — resolved_service is inferred from the subservice's parent."""
        service_a = ServiceFactory(name="AC Repair")
        service_b = ServiceFactory(name="Plumbing")
        sub = SubServiceFactory(service=service_a, is_fixed_price=False)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        _, resolved_service, resolved_subservice, _ = get_technician_profile_detail(
            tech_id=tech.id, sub_service_id=sub.id, service_id=service_b.id
        )
        assert resolved_subservice.id == sub.id
        assert resolved_service.id == service_a.id  # inferred from subservice, not service_b

    # ------------------------------------------------------------------
    # PROMO RESOLUTION
    # ------------------------------------------------------------------

    def test_resolves_promo_from_explicit_promotion_id(self):
        service = ServiceFactory()
        promo = PromotionFactory(target_service=service, discount_value=20, discount_type='PERCENTAGE')
        tech = TechnicianProfileFactory(status='APPROVED')

        _, _, _, resolved_promo = get_technician_profile_detail(
            tech_id=tech.id, service_id=service.id, promotion_id=promo.id
        )
        assert resolved_promo is not None
        assert resolved_promo.id == promo.id

    def test_resolves_promo_automatically_from_service_if_no_promotion_id(self):
        """Active promo on the service must be surfaced even without an explicit promotion_id."""
        service = ServiceFactory()
        promo = PromotionFactory(target_service=service)
        tech = TechnicianProfileFactory(status='APPROVED')

        _, _, _, resolved_promo = get_technician_profile_detail(
            tech_id=tech.id, service_id=service.id
        )
        assert resolved_promo is not None
        assert resolved_promo.id == promo.id

    def test_expired_promo_not_resolved(self):
        service = ServiceFactory()
        PromotionFactory(
            target_service=service,
            valid_from=timezone.now() - timedelta(days=10),
            valid_until=timezone.now() - timedelta(days=1),  # expired
        )
        tech = TechnicianProfileFactory(status='APPROVED')

        _, _, _, resolved_promo = get_technician_profile_detail(
            tech_id=tech.id, service_id=service.id
        )
        assert resolved_promo is None

    def test_inactive_promo_not_resolved(self):
        service = ServiceFactory()
        PromotionFactory(target_service=service, is_active=False)
        tech = TechnicianProfileFactory(status='APPROVED')

        _, _, _, resolved_promo = get_technician_profile_detail(
            tech_id=tech.id, service_id=service.id
        )
        assert resolved_promo is None

    def test_invalid_promotion_id_resolves_to_none(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        _, _, _, resolved_promo = get_technician_profile_detail(
            tech_id=tech.id, promotion_id=999999
        )
        assert resolved_promo is None

    # ------------------------------------------------------------------
    # PREFETCH CORRECTNESS
    # ------------------------------------------------------------------

    def test_recent_reviews_list_prefetched_capped_at_two(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        for _ in range(5):
            ReviewFactory(technician=tech)

        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert hasattr(result, 'recent_reviews_list')
        assert len(result.recent_reviews_list) == 2

    def test_recent_reviews_empty_when_no_reviews(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert result.recent_reviews_list == []

    def test_all_skills_prefetched(self):
        service = ServiceFactory()
        sub1 = SubServiceFactory(service=service)
        sub2 = SubServiceFactory(service=service)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub1)
        TechnicianSkillFactory(technician=tech, sub_service=sub2)

        result, _, _, _ = get_technician_profile_detail(tech_id=tech.id)
        assert hasattr(result, 'all_skills')
        assert len(result.all_skills) == 2

    # ------------------------------------------------------------------
    # N+1 GUARD
    # ------------------------------------------------------------------

    def test_num_queries_for_full_profile_with_context(self, django_assert_num_queries):
        """
        Verifies no N+1 queries regardless of how many skills or reviews the tech has.
        Expected queries (sub_service_id context):
          1. SubService lookup (context resolution — resolves subservice + infers parent service)
          2. Service lookup (inferred parent service of the SubService)
          3. Platform avg via TechnicianServicePerformance (Bayesian C constant)
          4. TechnicianServicePerformance for this specific tech + service (context-aware R/v)
          5. Main TechnicianProfile fetch (select_related user)
          6. Prefetch: all_skills (technicianskill_set with select_related sub_service__service)
          7. Prefetch: recent_reviews (reviews[:2] with select_related reviewer)
          8. Prefetch: prefetched_skill (technicianskill_set filtered by sub_service)
        """
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        tech = TechnicianProfileFactory(status='APPROVED')
        for _ in range(5):
            TechnicianSkillFactory(technician=tech, sub_service=SubServiceFactory(service=service))
        TechnicianSkillFactory(technician=tech, sub_service=sub)
        for _ in range(5):
            ReviewFactory(technician=tech)

        with django_assert_num_queries(8):
            get_technician_profile_detail(tech_id=tech.id, sub_service_id=sub.id)
