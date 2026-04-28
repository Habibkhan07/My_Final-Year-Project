"""
Tests for ``bookings.selectors.pricing_selector.resolve_booking_intent``.

Covers the four pricing scenarios documented in DISCOVERY_API.md and
BOOKINGS_API.md:

  * Scenario A — Fixed-Price Gig (sub_service.is_fixed_price=True).
  * Scenario B — Labor Gig (sub_service.is_fixed_price=False).
  * Scenario C — Category / Promo on parent service (only service set).
  * Fallback — no discovery context.

Plus the absolute promo firewall rule on Scenario A (no discount stacking
on fixed gigs) and the labor-gig rate-range / fallback variations.
"""
import decimal
import pytest

from bookings.selectors import (
    BOOKING_TYPE_FIXED_GIG,
    BOOKING_TYPE_INSPECTION,
    BOOKING_TYPE_LABOR_GIG,
    BOOKING_TYPE_UNKNOWN,
    resolve_booking_intent,
)
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Scenario C — Category / inspection
# ---------------------------------------------------------------------------

class TestInspectionScenario:

    def test_returns_inspection_booking_type(self):
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        tech = TechnicianProfileFactory(status='APPROVED')

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=None, promotion=None,
        )

        assert intent.booking_type == BOOKING_TYPE_INSPECTION
        assert intent.primary_amount == decimal.Decimal('500.00')
        assert intent.primary_amount_max is None
        assert intent.price_context_label == 'Inspection Fee'
        assert intent.promo_tag_firewalled is None

    def test_promo_on_parent_service_surfaces_tag(self):
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('600.00'))
        promo = PromotionFactory(target_service=service, description='20% Off Total')
        tech = TechnicianProfileFactory(status='APPROVED')

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=None, promotion=promo,
        )

        assert intent.booking_type == BOOKING_TYPE_INSPECTION
        assert intent.promotion == promo
        assert intent.promo_tag_firewalled == '20% Off Total'


# ---------------------------------------------------------------------------
# Scenario A — Fixed-price gig (firewall enforced)
# ---------------------------------------------------------------------------

class TestFixedGigScenario:

    def test_returns_fixed_gig_with_subservice_base_price(self):
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True, base_price=decimal.Decimal('1500.00'),
        )
        tech = TechnicianProfileFactory(status='APPROVED')

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=None,
        )

        assert intent.booking_type == BOOKING_TYPE_FIXED_GIG
        assert intent.primary_amount == decimal.Decimal('1500.00')
        assert intent.primary_amount_max is None
        assert intent.price_context_label == 'Fixed Price'

    def test_promo_firewall_strips_promotion_and_tag(self):
        """ABSOLUTE rule: discount stacking on fixed gigs is forbidden."""
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True, base_price=decimal.Decimal('2000.00'),
        )
        promo = PromotionFactory(target_service=service)
        tech = TechnicianProfileFactory(status='APPROVED')

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=promo,
        )

        # The Promotion model is dropped entirely so a write-path consumer
        # cannot accidentally persist a phantom FK.
        assert intent.promotion is None
        assert intent.promo_tag_firewalled is None


# ---------------------------------------------------------------------------
# Scenario B — Labor gig (range / single / fallback)
# ---------------------------------------------------------------------------

class TestLaborGigScenario:

    def test_asymmetric_skill_rate_yields_range(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'),
            max_rate=decimal.Decimal('1400.00'),
        )

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=None,
        )

        assert intent.booking_type == BOOKING_TYPE_LABOR_GIG
        assert intent.primary_amount == decimal.Decimal('1000.00')
        assert intent.primary_amount_max == decimal.Decimal('1400.00')
        assert intent.primary_price == 'Rs. 1,000 - 1,400'
        assert intent.price_context_label == 'Labor Fee'

    def test_symmetric_skill_rate_yields_single_value(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1200.00'),
            max_rate=decimal.Decimal('1200.00'),
        )

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=None,
        )

        assert intent.primary_amount == decimal.Decimal('1200.00')
        assert intent.primary_amount_max is None
        assert intent.primary_price == 'Rs. 1,200'

    def test_no_skill_rate_falls_back_to_subservice_base_price(self):
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False, base_price=decimal.Decimal('800.00'),
        )
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(technician=tech, sub_service=sub, base_rate=None, max_rate=None)

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=None,
        )

        assert intent.primary_amount == decimal.Decimal('800.00')
        assert intent.primary_amount_max is None

    def test_promo_on_labor_gig_surfaces_tag(self):
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        promo = PromotionFactory(target_service=service, description='Promo on labor')
        tech = TechnicianProfileFactory(status='APPROVED')
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'), max_rate=decimal.Decimal('1000.00'),
        )

        intent = resolve_booking_intent(
            technician=tech, service=service, sub_service=sub, promotion=promo,
        )

        assert intent.promotion == promo
        assert intent.promo_tag_firewalled == 'Promo on labor'


# ---------------------------------------------------------------------------
# Fallback — no discovery context
# ---------------------------------------------------------------------------

class TestNoContextFallback:

    def test_returns_unknown_with_default_inspection_fee(self):
        tech = TechnicianProfileFactory(status='APPROVED')

        intent = resolve_booking_intent(
            technician=tech, service=None, sub_service=None, promotion=None,
        )

        assert intent.booking_type == BOOKING_TYPE_UNKNOWN
        assert intent.primary_amount == decimal.Decimal('500.00')
        assert intent.primary_price == 'Rs. 500'
        assert intent.price_context_label == 'Inspection Fee'
        assert intent.promo_tag_firewalled is None
