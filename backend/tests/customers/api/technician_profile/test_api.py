"""
Tests for GET /api/customers/technician-profile/{id}/
customers/api/technician_profile/views.py

Coverage:
  - 200 happy path (no context)
  - 404 for non-existent tech
  - 404 for PENDING / REJECTED tech
  - Full response contract (all required fields present)
  - ui_rating_text has ⭐ prefix
  - distance_km is null when no coordinates; float when provided
  - Scenario A (fixed-price gig): correct price, "Fixed Price" context, promo_tag always null
  - Promo firewall: promotion_id passed with fixed-price gig must not leak into promo_tag
  - Scenario B (labor gig): single-price and range-price variants, "Labor Fee" context
  - Scenario B labor gig + active promo: promo_tag populated
  - Scenario C (category): inspection fee + "Inspection Fee" context
  - skills list serialized with name and icon_name
  - recent_reviews serialized (reviewer_name, rating, text)
  - recent_reviews is empty array when none exist
  - Invalid / garbage query params handled gracefully (no 500)
  - 404 error envelope matches standard contract
"""
import pytest
from rest_framework.test import APIClient
from django.urls import reverse

from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianSkillFactory,
    ReviewFactory,
)
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory
from tests.factories.accounts import UserFactory

pytestmark = pytest.mark.django_db


class TestTechnicianProfileDetailView:

    def setup_method(self):
        self.client = APIClient()

    def _url(self, pk):
        return reverse('technician-profile-detail', kwargs={'pk': pk})

    # ------------------------------------------------------------------
    # 404 / ACCESS CONTROL
    # ------------------------------------------------------------------

    def test_404_for_nonexistent_id(self):
        response = self.client.get(self._url(999999))
        assert response.status_code == 404
        data = response.json()
        assert data['code'] == 'not_found'
        assert data['status'] == 404
        assert data['errors'] == {}

    def test_404_for_pending_technician(self):
        tech = TechnicianProfileFactory(status='PENDING')
        response = self.client.get(self._url(tech.id))
        assert response.status_code == 404

    def test_404_for_rejected_technician(self):
        tech = TechnicianProfileFactory(status='REJECTED')
        response = self.client.get(self._url(tech.id))
        assert response.status_code == 404

    # ------------------------------------------------------------------
    # HAPPY PATH — RESPONSE CONTRACT
    # ------------------------------------------------------------------

    def test_200_and_full_contract(self):
        """Asserts every required field is present in the response."""
        tech = TechnicianProfileFactory(status='APPROVED', rating_average=4.5, review_count=30)
        response = self.client.get(self._url(tech.id))

        assert response.status_code == 200
        data = response.json()

        required_fields = [
            'id', 'full_name', 'city', 'profile_picture',
            'rating_average', 'review_count',
            'distance_km', 'bayesian_score', 'is_active',
            'ui_rating_text', 'primary_price', 'price_context', 'promo_tag',
            'skills', 'recent_reviews',
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"

    def test_ui_rating_text_has_star_prefix(self):
        tech = TechnicianProfileFactory(status='APPROVED', rating_average=4.97, review_count=120)
        data = self.client.get(self._url(tech.id)).json()
        assert data['ui_rating_text'].startswith('⭐')
        assert '4.97' in data['ui_rating_text']
        assert '120' in data['ui_rating_text']

    def test_distance_km_is_null_without_coordinates(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        data = self.client.get(self._url(tech.id)).json()
        assert data['distance_km'] is None

    def test_distance_km_is_float_when_coordinates_provided(self):
        tech = TechnicianProfileFactory(
            status='APPROVED', base_latitude=31.5204, base_longitude=74.3587
        )
        data = self.client.get(
            self._url(tech.id), {'lat': '31.5294', 'lng': '74.3587'}
        ).json()
        assert data['distance_km'] is not None
        assert isinstance(data['distance_km'], float)

    def test_default_fallback_pricing_with_no_context(self):
        """No context params → Rs. 500 / Inspection Fee / promo_tag null."""
        tech = TechnicianProfileFactory(status='APPROVED')
        data = self.client.get(self._url(tech.id)).json()
        assert data['primary_price'] == 'Rs. 500'
        assert data['price_context'] == 'Inspection Fee'
        assert data['promo_tag'] is None

    # ------------------------------------------------------------------
    # SCENARIO A — FIXED-PRICE GIG
    # ------------------------------------------------------------------

    def test_scenario_a_fixed_price_gig(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=True, base_price=1500.00)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id), {'sub_service_id': sub.id}).json()

        assert data['primary_price'] == 'Rs. 1,500'
        assert data['price_context'] == 'Fixed Price'
        assert data['promo_tag'] is None

    def test_scenario_a_promo_firewall_never_leaks_onto_fixed_gig(self):
        """
        CRITICAL: Passing a valid promotion_id alongside a fixed-price gig
        must NEVER populate promo_tag. Discount stacking is forbidden.
        """
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=True, base_price=2000.00)
        promo = PromotionFactory(target_service=service, discount_value=20)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(
            self._url(tech.id),
            {'sub_service_id': sub.id, 'promotion_id': promo.id},
        ).json()

        assert data['price_context'] == 'Fixed Price'
        assert data['promo_tag'] is None, (
            "promo_tag MUST be null for fixed-price gigs — discount stacking is forbidden"
        )

    def test_scenario_a_service_level_promo_also_blocked_on_fixed_gig(self):
        """Even an auto-resolved service-level promo must not apply to fixed-price gigs."""
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=True, base_price=1200.00)
        PromotionFactory(target_service=service)  # active, no explicit promotion_id passed
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id), {'sub_service_id': sub.id}).json()

        assert data['price_context'] == 'Fixed Price'
        assert data['promo_tag'] is None

    # ------------------------------------------------------------------
    # SCENARIO B — LABOR GIG
    # ------------------------------------------------------------------

    def test_scenario_b_labor_gig_shows_single_base_price_when_no_max(self):
        """After migration 0014 the tech no longer sets a labor rate; the
        platform's ``SubService.base_price`` is the single labor figure
        when ``max_price`` is null."""
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=1200.00, max_price=None,
        )
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id), {'sub_service_id': sub.id}).json()

        assert data['primary_price'] == 'Rs. 1,200'
        assert data['price_context'] == 'Labor Fee'
        assert data['promo_tag'] is None

    def test_scenario_b_labor_gig_shows_range_when_max_set(self):
        """When the catalog declares an upper bound the customer sees a
        Rs. base – max band — honest about the platform-set spread."""
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=800.00, max_price=2000.00,
        )
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id), {'sub_service_id': sub.id}).json()

        assert data['primary_price'] == 'Rs. 800 – 2,000'
        assert data['price_context'] == 'Labor Fee'

    def test_scenario_b_labor_gig_with_active_promo(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        promo = PromotionFactory(
            target_service=service,
            discount_type='PERCENTAGE',
            discount_value=20,
            description="20% Off Final Bill",
        )
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(
            self._url(tech.id),
            {'sub_service_id': sub.id, 'promotion_id': promo.id},
        ).json()

        assert data['price_context'] == 'Labor Fee'
        # Short chip label; long marketing copy lives on ui_description.
        assert data['promo_tag'] == '20% OFF'

    # ------------------------------------------------------------------
    # SCENARIO C — CATEGORY DISCOVERY
    # ------------------------------------------------------------------

    def test_scenario_c_inspection_fee(self):
        service = ServiceFactory(base_inspection_fee=600.00)
        tech = TechnicianProfileFactory(status='APPROVED')

        data = self.client.get(self._url(tech.id), {'service_id': service.id}).json()

        assert data['primary_price'] == 'Rs. 600'
        assert data['price_context'] == 'Inspection Fee'
        assert data['promo_tag'] is None

    def test_scenario_c_with_active_promo(self):
        service = ServiceFactory(base_inspection_fee=500.00, name="AC Repair")
        promo = PromotionFactory(
            target_service=service,
            discount_value=20,
            discount_type='PERCENTAGE',
            description="20% OFF AC Service!",
        )
        tech = TechnicianProfileFactory(status='APPROVED')

        data = self.client.get(
            self._url(tech.id),
            {'service_id': service.id, 'promotion_id': promo.id},
        ).json()

        assert data['price_context'] == 'Inspection Fee'
        # Chip label derived from discount mechanics, not description.
        assert data['promo_tag'] == '20% OFF'

    # ------------------------------------------------------------------
    # EXPANDABLE DATA — SKILLS & REVIEWS
    # ------------------------------------------------------------------

    def test_skills_list_contains_name_and_icon_name(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, name="Gas Refill", icon_name="ac_repair")
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id)).json()

        assert len(data['skills']) == 1
        assert data['skills'][0]['name'] == 'Gas Refill'
        assert data['skills'][0]['icon_name'] == 'ac_repair'

    def test_skill_carries_service_id_and_sub_service_id(self):
        """
        The customer-side service picker on the technician profile screen
        needs `service_id` to POST to /api/bookings/instant-book/, and
        `sub_service_id` when the skill is sub-service-scoped.

        Regression guard: an earlier rev shipped `sub_service_id` with a
        redundant `source='sub_service_id'` kwarg, which DRF rejects at
        endpoint-hit time with an AssertionError 500. The wire-shape
        assertions here would have caught that during test, not in
        production.
        """
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, name="AC Repair", icon_name="ac_repair")
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        data = self.client.get(self._url(tech.id)).json()

        skill = data['skills'][0]
        assert skill['service_id'] == service.id
        assert skill['sub_service_id'] == sub.id

    def test_recent_reviews_serialized_correctly(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        reviewer = UserFactory(first_name="Sara", last_name="Khan")
        ReviewFactory(technician=tech, reviewer=reviewer, rating=5, text="Excellent work!")

        data = self.client.get(self._url(tech.id)).json()

        assert len(data['recent_reviews']) == 1
        review = data['recent_reviews'][0]
        assert review['reviewer_name'] == 'Sara Khan'
        assert review['rating'] == 5
        assert review['text'] == 'Excellent work!'

    def test_recent_reviews_capped_at_two(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        for _ in range(5):
            ReviewFactory(technician=tech)

        data = self.client.get(self._url(tech.id)).json()
        assert len(data['recent_reviews']) == 2

    def test_recent_reviews_empty_when_none_exist(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        data = self.client.get(self._url(tech.id)).json()
        assert data['recent_reviews'] == []

    def test_deleted_reviewer_shows_anonymous(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        ReviewFactory(technician=tech, reviewer=None, rating=4, text="Good work.")

        data = self.client.get(self._url(tech.id)).json()
        assert data['recent_reviews'][0]['reviewer_name'] == 'Anonymous'

    # ------------------------------------------------------------------
    # ROBUSTNESS — GARBAGE INPUT
    # ------------------------------------------------------------------

    def test_garbage_lat_lng_does_not_crash(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(
            self._url(tech.id), {'lat': 'DROP_TABLE', 'lng': 'NULL'}
        )
        assert response.status_code == 200
        assert response.json()['distance_km'] is None

    def test_garbage_service_id_is_ignored_gracefully(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id), {'service_id': 'abc'})
        assert response.status_code == 200

    def test_nonexistent_service_id_is_ignored_gracefully(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id), {'service_id': 999999})
        assert response.status_code == 200
        data = response.json()
        # Falls back to default pricing
        assert data['primary_price'] == 'Rs. 500'
        assert data['price_context'] == 'Inspection Fee'

    def test_nonexistent_sub_service_id_falls_back_to_default(self):
        tech = TechnicianProfileFactory(status='APPROVED')
        response = self.client.get(self._url(tech.id), {'sub_service_id': 999999})
        assert response.status_code == 200
        data = response.json()
        assert data['primary_price'] == 'Rs. 500'
