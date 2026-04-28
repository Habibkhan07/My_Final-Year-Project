"""
Tests for bookings/services/instant_book_service.py
create_instant_booking()

Coverage:
  - Happy path: booking created, fields persisted correctly, status=CONFIRMED
  - Address not owned by user → InvalidAddressError
  - Address belonging to another user → same InvalidAddressError (IDOR safe)
  - Technician does not exist → TechnicianProfile.DoesNotExist
  - PENDING technician → TechnicianProfile.DoesNotExist
  - REJECTED technician → TechnicianProfile.DoesNotExist
  - Technician has no base location → OutOfServiceAreaError
  - Address within max_travel_radius_km → booking succeeds
  - Address beyond max_travel_radius_km → OutOfServiceAreaError (correct distance/radius)
  - Overlapping CONFIRMED booking → SlotUnavailableError
  - Overlapping PENDING booking → SlotUnavailableError
  - Overlapping CANCELLED booking → does NOT block (booking succeeds)
  - Non-overlapping: existing booking ends exactly at our start → succeeds
  - Non-overlapping: existing booking starts exactly at our end → succeeds
"""
import datetime
import decimal
import zoneinfo
import pytest

from technicians.models import TechnicianProfile
from bookings.models import JobBooking
from bookings.exceptions import (
    InconsistentBookingIntentError,
    InvalidAddressError,
    OutOfServiceAreaError,
    PriceMismatchError,
    PromoFirewallError,
    SlotUnavailableError,
)
from bookings.services.instant_book_service import create_instant_booking
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")


def _pkt(h: int, m: int = 0) -> datetime.datetime:
    return datetime.datetime(2026, 4, 7, h, m, tzinfo=PKT)


def _make_booking_kwargs(tech, address, service=None):
    """
    Minimal valid kwargs for ``create_instant_booking``. Defaults to a
    Scenario-C inspection booking; ``price_amount`` matches the supplied
    service's ``base_inspection_fee`` so the price check passes.
    """
    if service is None:
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
    return dict(
        technician_id=tech.id,
        address_id=address.id,
        service_id=service.id,
        scheduled_start=_pkt(10),
        scheduled_end=_pkt(11),
        price_amount=decimal.Decimal(service.base_inspection_fee),
    )


class TestCreateInstantBooking:

    # ------------------------------------------------------------------
    # HAPPY PATH
    # ------------------------------------------------------------------

    def test_returns_job_booking_instance(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

        assert isinstance(booking, JobBooking)

    def test_booking_persisted_with_correct_fields(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id,
            address_id=address.id,
            service_id=service.id,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('500.00'),
        )

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CONFIRMED
        assert booking.technician == tech
        assert booking.customer == profile.user
        assert booking.address == address
        assert booking.service == service
        assert booking.sub_service is None
        assert booking.promotion is None
        assert booking.price_amount == decimal.Decimal('500.00')
        # Server-derived from the resolver — Scenario C → "Inspection Fee".
        assert booking.price_context == 'Inspection Fee'

    def test_booking_exists_in_db(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

        assert JobBooking.objects.filter(pk=booking.id).exists()

    # ------------------------------------------------------------------
    # ADDRESS OWNERSHIP (IDOR GUARD)
    # ------------------------------------------------------------------

    def test_nonexistent_address_raises_invalid_address(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        profile = CustomerProfileFactory()

        with pytest.raises(InvalidAddressError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id,
                address_id=999999,
                service_id=ServiceFactory().id,
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )

    def test_address_owned_by_other_user_raises_invalid_address(self):
        """
        address_id exists but belongs to a different CustomerProfile.
        Must raise the same InvalidAddressError — caller cannot tell the difference.
        """
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587)
        other_profile = CustomerProfileFactory()
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()

        with pytest.raises(InvalidAddressError):
            create_instant_booking(
                customer_user=attacker_profile.user,
                technician_id=tech.id,
                address_id=other_address.id,
                service_id=ServiceFactory().id,
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )

    # ------------------------------------------------------------------
    # TECHNICIAN STATUS GUARD
    # ------------------------------------------------------------------

    def test_nonexistent_technician_raises_does_not_exist(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        with pytest.raises(TechnicianProfile.DoesNotExist):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=999999,
                address_id=address.id,
                service_id=ServiceFactory().id,
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )

    def test_pending_technician_raises_does_not_exist(self):
        tech = TechnicianProfileFactory(status='PENDING')
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        with pytest.raises(TechnicianProfile.DoesNotExist):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

    def test_rejected_technician_raises_does_not_exist(self):
        tech = TechnicianProfileFactory(status='REJECTED')
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        with pytest.raises(TechnicianProfile.DoesNotExist):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

    # ------------------------------------------------------------------
    # GEOFENCE
    # ------------------------------------------------------------------

    def test_no_base_location_raises_out_of_service_area(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=None, base_longitude=None)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        with pytest.raises(OutOfServiceAreaError):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

    def test_address_within_radius_succeeds(self):
        """Same coordinates → 0 km distance → always within any radius."""
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=5,
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))
        assert booking.pk is not None

    def test_address_beyond_radius_raises_out_of_service_area(self):
        """Lahore → Karachi is ~1,200 km, well beyond any radius."""
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,   # Lahore
            max_travel_radius_km=10,
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(
            customer=profile,
            latitude=24.8607, longitude=67.0011,             # Karachi
        )

        with pytest.raises(OutOfServiceAreaError) as exc_info:
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

        assert exc_info.value.radius_km == 10
        assert exc_info.value.distance_km > 100  # sanity: definitely far

    def test_out_of_service_area_error_carries_correct_radius(self):
        """OutOfServiceAreaError.radius_km must match the technician's setting."""
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=7,
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=24.8607, longitude=67.0011)

        with pytest.raises(OutOfServiceAreaError) as exc_info:
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

        assert exc_info.value.radius_km == 7

    # ------------------------------------------------------------------
    # SLOT CONFLICT
    # ------------------------------------------------------------------

    def test_confirmed_booking_blocks_overlapping_slot(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        # Pre-existing CONFIRMED booking at the same window
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            status=JobBooking.STATUS_CONFIRMED,
        )

        with pytest.raises(SlotUnavailableError):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

    def test_pending_booking_blocks_overlapping_slot(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            status=JobBooking.STATUS_PENDING,
        )

        with pytest.raises(SlotUnavailableError):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))

    def test_cancelled_booking_does_not_block_slot(self):
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            status=JobBooking.STATUS_CANCELLED,
        )

        # Should succeed — CANCELLED bookings are ignored
        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))
        assert booking.pk is not None

    def test_booking_ending_at_our_start_does_not_block(self):
        """
        Half-open semantics: existing booking ends at 10:00 (our start).
        scheduled_end (10:00) > our start (10:00) → False → not a conflict.
        """
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(9),
            scheduled_end=_pkt(10),   # ends exactly when ours starts
            status=JobBooking.STATUS_CONFIRMED,
        )

        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))
        assert booking.pk is not None

    def test_booking_starting_at_our_end_does_not_block(self):
        """
        Half-open semantics: existing booking starts at 11:00 (our end).
        existing.start (11:00) < our end (11:00) → False → not a conflict.
        """
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(11),  # starts exactly when ours ends
            scheduled_end=_pkt(12),
            status=JobBooking.STATUS_CONFIRMED,
        )

        booking = create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))
        assert booking.pk is not None

    def test_partial_overlap_at_start_blocks_slot(self):
        """Existing booking [9:30–10:30] overlaps our [10:00–11:00]."""
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(9, 30),
            scheduled_end=_pkt(10, 30),
            status=JobBooking.STATUS_CONFIRMED,
        )

        with pytest.raises(SlotUnavailableError):
            create_instant_booking(customer_user=profile.user, **_make_booking_kwargs(tech, address))


# ======================================================================
# Catalog scenario coverage — A / B / D persist the right FKs and
# server-derived ``price_context`` label. Scenario C is already covered
# by ``test_booking_persisted_with_correct_fields`` above.
# ======================================================================

@pytest.fixture
def lahore_tech_and_address():
    tech = TechnicianProfileFactory(
        status='APPROVED',
        base_latitude=31.5204, base_longitude=74.3587,
        max_travel_radius_km=10,
    )
    profile = CustomerProfileFactory()
    address = CustomerAddressFactory(
        customer=profile, latitude=31.5204, longitude=74.3587,
    )
    return tech, profile, address


class TestCatalogScenarioCoverage:

    def test_scenario_a_fixed_gig_persists_sub_service_and_label(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True, base_price=decimal.Decimal('1500.00'),
        )

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('1500.00'),
        )

        booking.refresh_from_db()
        assert booking.service == service
        assert booking.sub_service == sub
        assert booking.promotion is None
        assert booking.price_context == 'Fixed Price'

    def test_scenario_b_labor_gig_accepts_floor_of_range(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'),
            max_rate=decimal.Decimal('1400.00'),
        )

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('1000.00'),  # floor of range
        )

        booking.refresh_from_db()
        assert booking.sub_service == sub
        assert booking.price_context == 'Labor Fee'

    def test_scenario_b_labor_gig_accepts_ceiling_of_range(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'),
            max_rate=decimal.Decimal('1400.00'),
        )

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('1400.00'),  # ceiling of range
        )

        assert booking.price_amount == decimal.Decimal('1400.00')

    def test_scenario_d_promo_on_parent_persists_promotion_fk(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        promo = PromotionFactory(target_service=service)

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, promotion_id=promo.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('500.00'),
        )

        booking.refresh_from_db()
        assert booking.promotion == promo
        assert booking.price_context == 'Inspection Fee'


class TestWritePathRejections:

    def test_sub_service_belongs_to_different_service_rejects(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service_a = ServiceFactory()
        service_b = ServiceFactory()
        # SubService's parent is service_b; we'll send service_a with this sub.
        sub = SubServiceFactory(service=service_b, is_fixed_price=False)

        with pytest.raises(InconsistentBookingIntentError) as exc:
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service_a.id, sub_service_id=sub.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )
        assert exc.value.field == 'sub_service_id'

    def test_promotion_targets_different_service_rejects(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service_a = ServiceFactory()
        service_b = ServiceFactory()
        promo = PromotionFactory(target_service=service_b)

        with pytest.raises(InconsistentBookingIntentError) as exc:
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service_a.id, promotion_id=promo.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal(service_a.base_inspection_fee),
            )
        assert exc.value.field == 'promotion_id'

    def test_promo_on_fixed_gig_triggers_firewall(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True, base_price=decimal.Decimal('1500.00'),
        )
        promo = PromotionFactory(target_service=service)

        with pytest.raises(PromoFirewallError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service.id, sub_service_id=sub.id, promotion_id=promo.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1500.00'),
            )

    def test_price_below_inspection_fee_rejects(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))

        with pytest.raises(PriceMismatchError) as exc:
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id, service_id=service.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1.00'),
            )
        assert exc.value.expected_min == decimal.Decimal('500.00')

    def test_price_below_labor_floor_rejects(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'),
            max_rate=decimal.Decimal('1400.00'),
        )

        with pytest.raises(PriceMismatchError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service.id, sub_service_id=sub.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('999.00'),
            )

    def test_price_above_labor_ceiling_rejects(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(service=service, is_fixed_price=False)
        TechnicianSkillFactory(
            technician=tech, sub_service=sub,
            base_rate=decimal.Decimal('1000.00'),
            max_rate=decimal.Decimal('1400.00'),
        )

        with pytest.raises(PriceMismatchError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service.id, sub_service_id=sub.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1401.00'),
            )

    def test_nonexistent_service_id_rejects_as_inconsistent(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        with pytest.raises(InconsistentBookingIntentError) as exc:
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=999_999,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )
        assert exc.value.field == 'service_id'

    def test_decimal_normalisation_accepts_500_vs_500_00(self, lahore_tech_and_address):
        """``"500"`` and ``"500.00"`` must compare equal — normalize both sides."""
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500'))

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id, service_id=service.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('500.00'),
        )
        assert booking.pk is not None


# ======================================================================
# on_commit dispatch — verifies the realtime side-effect contract:
#   * dispatcher fires exactly once on the success path
#   * dispatcher does NOT fire on any error path (rollback hygiene)
#
# We need transaction=True so transaction.on_commit callbacks actually run;
# the default django_db wraps the test in a savepoint that never commits,
# which would mask both the positive and negative cases.
# ======================================================================

@pytest.mark.django_db(transaction=True)
class TestInstantBookOnCommitDispatch:

    def _setup_valid(self):
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(
            customer=profile, latitude=31.5204, longitude=74.3587,
        )
        return tech, profile, address

    def test_success_path_dispatches_exactly_once(self, mocker):
        # Patch where the service looks the symbol up — the import is local
        # to create_instant_booking, so we patch on the dispatch module.
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        tech, profile, address = self._setup_valid()

        booking = create_instant_booking(
            customer_user=profile.user,
            **_make_booking_kwargs(tech, address),
        )

        assert dispatch.call_count == 1
        # The on_commit callback receives the freshly-created booking.
        called_with = dispatch.call_args.args[0]
        assert called_with.id == booking.id

    def test_invalid_address_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        tech, profile, _ = self._setup_valid()

        with pytest.raises(InvalidAddressError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id,
                address_id=999_999,
                service_id=ServiceFactory().id,
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )
        assert dispatch.call_count == 0

    def test_out_of_service_area_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        # Lahore tech, Karachi address → ~1200 km, way out of radius.
        tech = TechnicianProfileFactory(
            status='APPROVED',
            base_latitude=31.5204, base_longitude=74.3587,
            max_travel_radius_km=10,
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(
            customer=profile, latitude=24.8607, longitude=67.0011,
        )

        with pytest.raises(OutOfServiceAreaError):
            create_instant_booking(
                customer_user=profile.user, **_make_booking_kwargs(tech, address),
            )
        assert dispatch.call_count == 0

    def test_slot_unavailable_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        tech, profile, address = self._setup_valid()
        # Pre-existing CONFIRMED booking that exactly conflicts.
        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            status=JobBooking.STATUS_CONFIRMED,
        )

        with pytest.raises(SlotUnavailableError):
            create_instant_booking(
                customer_user=profile.user, **_make_booking_kwargs(tech, address),
            )
        assert dispatch.call_count == 0

    def test_technician_not_found_does_not_dispatch(self, mocker):
        dispatch = mocker.patch(
            'bookings.services.job_request_dispatch.dispatch_job_new_request_event'
        )
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        with pytest.raises(TechnicianProfile.DoesNotExist):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=999_999,
                address_id=address.id,
                service_id=ServiceFactory().id,
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('500.00'),
            )
        assert dispatch.call_count == 0
