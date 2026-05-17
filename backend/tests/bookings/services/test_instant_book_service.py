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
    Scenario-C inspection booking. The persisted ``price_amount`` is
    derived from the resolved catalog references — there is no client
    price field on the service signature.
    """
    if service is None:
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
    return dict(
        technician_id=tech.id,
        address_id=address.id,
        service_id=service.id,
        scheduled_start=_pkt(10),
        scheduled_end=_pkt(11),
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
        )

        booking.refresh_from_db()
        # Newly created bookings sit in AWAITING until the dispatched
        # technician accepts (separate sprint). Flag #1 closure.
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT
        assert booking.technician == tech
        assert booking.customer == profile.user
        assert booking.address == address
        assert booking.service == service
        assert booking.sub_service is None
        assert booking.promotion is None
        # Server-derived from the resolver — Scenario C → service.base_inspection_fee.
        assert booking.price_amount == decimal.Decimal('500.00')
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

    def test_offline_technician_raises_does_not_exist(self):
        """Offline tech (manually toggled OR auto-offlined via wallet lockout)
        cannot be booked. The customer's discovery list already filters by
        ``is_online=True``; this is the defense-in-depth check at the booking
        write that catches stale tech_ids from prior discovery snapshots.

        Collapses to ``TechnicianProfile.DoesNotExist`` to match the
        IDOR-safe opaque response used for PENDING / REJECTED techs."""
        tech = TechnicianProfileFactory(status='APPROVED', is_online=False)
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

    def test_awaiting_booking_blocks_overlapping_slot(self):
        # An AWAITING booking is dispatched but not yet accepted by the tech.
        # It still reserves the slot — otherwise two parallel bookings could
        # both be dispatched against the same window.
        tech = TechnicianProfileFactory(status='APPROVED', base_latitude=31.5204, base_longitude=74.3587, max_travel_radius_km=10)
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, latitude=31.5204, longitude=74.3587)

        JobBookingFactory(
            technician=tech,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
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
        )

        booking.refresh_from_db()
        assert booking.service == service
        assert booking.sub_service == sub
        assert booking.promotion is None
        assert booking.price_amount == decimal.Decimal('1500.00')
        assert booking.price_context == 'Fixed Price'

    def test_scenario_b_labor_gig_persists_subservice_base_price(self, lahore_tech_and_address):
        """Replaces the legacy "persist skill rate" test — labor_rate
        was dropped in migration 0014. ``price_amount`` now lands on
        ``sub_service.base_price``."""
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=decimal.Decimal('1200.00'),
        )
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )

        booking.refresh_from_db()
        assert booking.sub_service == sub
        assert booking.price_context == 'Labor Fee'
        assert booking.price_amount == decimal.Decimal('1200.00')

    def test_scenario_d_promo_on_parent_persists_promotion_fk(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        promo = PromotionFactory(target_service=service)

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, promotion_id=promo.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )

        booking.refresh_from_db()
        assert booking.promotion == promo
        assert booking.price_amount == decimal.Decimal('500.00')
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
            )

    def test_nonexistent_service_id_rejects_as_inconsistent(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        with pytest.raises(InconsistentBookingIntentError) as exc:
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=999_999,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            )
        assert exc.value.field == 'service_id'


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
            )
        assert dispatch.call_count == 0


# ======================================================================
# Promo snapshot at booking creation (audit P1-03)
#
# Promotion FK can become NULL via on_delete=SET_NULL when a promo is
# deleted. The denormalized snapshots on JobBooking survive that deletion
# and preserve the audit trail. The contract:
#   - With promotion → promo_code_snapshot equals promotion.name
#                      promo_discount_snapshot equals promotion.discount_value
#   - Without promotion → both snapshots null
#   - Fixed-price gig with promo → snapshots null (firewall stripped the FK
#                                  inside the resolver; we snapshot post-firewall)
# ======================================================================


class TestPromoSnapshotAtCreation:

    def test_snapshot_written_when_promotion_present(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        promo = PromotionFactory(
            target_service=service,
            name='SUMMER25',
            discount_value=decimal.Decimal('250.00'),
        )

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, promotion_id=promo.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )

        booking.refresh_from_db()
        assert booking.promo_code_snapshot == 'SUMMER25'
        assert booking.promo_discount_snapshot == decimal.Decimal('250.00')

    def test_snapshot_null_without_promotion(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        booking = create_instant_booking(
            customer_user=profile.user,
            **_make_booking_kwargs(tech, address),
        )
        booking.refresh_from_db()
        assert booking.promo_code_snapshot is None
        assert booking.promo_discount_snapshot is None

    def test_snapshot_null_on_fixed_gig_promo_firewalled_in_resolver(self, lahore_tech_and_address):
        # Fixed-gig + promo on the wire → resolver firewall strips the
        # promotion. We snapshot from intent.promotion (post-firewall), so
        # the booking carries null snapshots and the firewall stays the
        # single point of truth.
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True,
            base_price=decimal.Decimal('1500.00'),
        )
        promo = PromotionFactory(target_service=service)

        # Promo on a fixed gig actually triggers the firewall and raises;
        # the snapshot test for the firewall path is implicit (the booking
        # is never created). Confirm here that the firewall still raises so
        # the audit P1-03 fix didn't accidentally bypass it.
        with pytest.raises(PromoFirewallError):
            create_instant_booking(
                customer_user=profile.user,
                technician_id=tech.id, address_id=address.id,
                service_id=service.id, sub_service_id=sub.id,
                promotion_id=promo.id,
                scheduled_start=_pkt(10), scheduled_end=_pkt(11),
            )


# ---------------------------------------------------------------------------
# Inspection-fee + final-cash + address-snapshot columns at booking creation.
#
# These columns are populated at booking time by ``create_instant_booking``
# so the orchestrator's quote-decision transitions (approve / decline) and
# the customer-side receipt UI have the data they need without a follow-up
# write. Pre-fix audit found all three columns silently NULL — that bug
# made INSPECTION-flow declines owe Rs.0 instead of Rs.500, and broke the
# tech's "Cash Collected: Rs.X" button on FIXED_GIG / LABOR_GIG paths.
# ---------------------------------------------------------------------------


class TestInspectionFeeColumn:
    """``inspection_fee`` is set only for INSPECTION-flow bookings.

    Inspection bookings have ``sub_service=None``; the resolver returns
    ``booking_type=INSPECTION`` and ``primary_amount=service.base_inspection_fee``.
    The fee column mirrors that figure so the orchestrator's decline path
    has it without re-resolving from the catalog.
    """

    def test_inspection_flow_persists_base_inspection_fee(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.inspection_fee == decimal.Decimal('500.00')

    def test_fixed_gig_leaves_inspection_fee_null(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True,
            base_price=decimal.Decimal('1500.00'),
        )
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.inspection_fee is None

    def test_labor_gig_leaves_inspection_fee_null(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=decimal.Decimal('1200.00'),
        )
        TechnicianSkillFactory(technician=tech, sub_service=sub)
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.inspection_fee is None


class TestFinalCashToCollectColumn:
    """``final_cash_to_collect`` is set at creation only for paths whose
    cash figure is final at booking time (FIXED_GIG / LABOR_GIG).

    INSPECTION-flow bookings leave the column NULL because the cash
    button number is unknown until the customer accepts or declines the
    quote — the orchestrator's ``approve_quote`` / ``decline_quote`` write
    it then.
    """

    def test_inspection_flow_leaves_final_cash_null(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory(base_inspection_fee=decimal.Decimal('500.00'))
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.final_cash_to_collect is None

    def test_fixed_gig_persists_full_price(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=True,
            base_price=decimal.Decimal('1500.00'),
        )
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.final_cash_to_collect == decimal.Decimal('1500.00')

    def test_labor_gig_persists_resolved_labor_rate(self, lahore_tech_and_address):
        tech, profile, address = lahore_tech_and_address
        service = ServiceFactory()
        sub = SubServiceFactory(
            service=service, is_fixed_price=False,
            base_price=decimal.Decimal('1200.00'),
        )
        TechnicianSkillFactory(technician=tech, sub_service=sub)
        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id, address_id=address.id,
            service_id=service.id, sub_service_id=sub.id,
            scheduled_start=_pkt(10), scheduled_end=_pkt(11),
        )
        booking.refresh_from_db()
        assert booking.final_cash_to_collect == decimal.Decimal('1200.00')


class TestActualAddressSnapshotColumn:
    """``actual_address_snapshot`` is composed from the address's
    ``street_address`` + best-available locality field. The column
    survives ``customer.address.SET_NULL`` if the customer later deletes
    the address, so receipts and admin still render where the visit was.
    """

    def test_snapshot_uses_locality_label_when_present(self, lahore_tech_and_address):
        tech, profile, _ = lahore_tech_and_address
        address = CustomerAddressFactory(
            customer=profile,
            latitude=decimal.Decimal('31.5204'),
            longitude=decimal.Decimal('74.3587'),
            street_address='123 Main Boulevard',
            locality_label='Gulberg III, Lahore',
            city='Lahore',
        )
        booking = create_instant_booking(
            customer_user=profile.user,
            **_make_booking_kwargs(tech, address),
        )
        booking.refresh_from_db()
        # locality_label preferred over city when both present.
        assert booking.actual_address_snapshot == '123 Main Boulevard, Gulberg III, Lahore'

    def test_snapshot_falls_back_to_city_without_locality_label(self, lahore_tech_and_address):
        tech, profile, _ = lahore_tech_and_address
        address = CustomerAddressFactory(
            customer=profile,
            latitude=decimal.Decimal('31.5204'),
            longitude=decimal.Decimal('74.3587'),
            street_address='456 Side Street',
            locality_label=None,
            city='Karachi',
        )
        booking = create_instant_booking(
            customer_user=profile.user,
            **_make_booking_kwargs(tech, address),
        )
        booking.refresh_from_db()
        assert booking.actual_address_snapshot == '456 Side Street, Karachi'

    def test_snapshot_is_street_only_when_no_locality_or_city(self, lahore_tech_and_address):
        tech, profile, _ = lahore_tech_and_address
        address = CustomerAddressFactory(
            customer=profile,
            latitude=decimal.Decimal('31.5204'),
            longitude=decimal.Decimal('74.3587'),
            street_address='789 Lonely Lane',
            locality_label=None,
            city=None,
        )
        booking = create_instant_booking(
            customer_user=profile.user,
            **_make_booking_kwargs(tech, address),
        )
        booking.refresh_from_db()
        assert booking.actual_address_snapshot == '789 Lonely Lane'
