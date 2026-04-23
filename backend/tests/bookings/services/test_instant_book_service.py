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
from bookings.exceptions import InvalidAddressError, OutOfServiceAreaError, SlotUnavailableError
from bookings.services.instant_book_service import create_instant_booking
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db

PKT = zoneinfo.ZoneInfo("Asia/Karachi")


def _pkt(h: int, m: int = 0) -> datetime.datetime:
    return datetime.datetime(2026, 4, 7, h, m, tzinfo=PKT)


def _make_booking_kwargs(tech, address):
    """Minimal valid kwargs for create_instant_booking."""
    return dict(
        technician_id=tech.id,
        address_id=address.id,
        scheduled_start=_pkt(10),
        scheduled_end=_pkt(11),
        price_amount=decimal.Decimal('1500.00'),
        price_context='AC Repair',
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

        booking = create_instant_booking(
            customer_user=profile.user,
            technician_id=tech.id,
            address_id=address.id,
            scheduled_start=_pkt(10),
            scheduled_end=_pkt(11),
            price_amount=decimal.Decimal('1500.00'),
            price_context='AC Repair',
        )

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CONFIRMED
        assert booking.technician == tech
        assert booking.customer == profile.user
        assert booking.address == address
        assert booking.price_amount == decimal.Decimal('1500.00')
        assert booking.price_context == 'AC Repair'

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
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1000.00'),
                price_context='',
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
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1000.00'),
                price_context='',
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
                scheduled_start=_pkt(10),
                scheduled_end=_pkt(11),
                price_amount=decimal.Decimal('1000.00'),
                price_context='',
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
