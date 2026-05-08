"""Geofence-trigger tests for ``bookings.services.auto_transition``.

Coverage:
    - Threshold semantics: CONFIRMED + far → EN_ROUTE; near → no-op.
    - EN_ROUTE + close → ARRIVED; still far → no-op.
    - INSPECTING / IN_PROGRESS / terminal: never auto-flip.
    - Booking-not-found returns None silently.
    - Address-deleted (FK SET_NULL) returns None.
    - Haversine math against known Lahore coordinates.

The orchestrator owns atomicity; this module just classifies. Tests use
the real orchestrator under the hood (no mock) — they're light enough that
faking the call would obscure the intent.
"""

from decimal import Decimal
from unittest.mock import patch

import pytest

from bookings.models import JobBooking
from bookings.services import auto_transition
from bookings.services.auto_transition import (
    ARRIVED_THRESHOLD_METERS,
    EN_ROUTE_THRESHOLD_METERS,
    _haversine_meters,
)
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingConfirmedFactory,
    JobBookingEnRouteFactory,
    JobBookingInspectingFactory,
)
from tests.factories.customers import CustomerAddressFactory


pytestmark = pytest.mark.django_db


# Lahore landmarks for math sanity tests.
LIBERTY_LAT, LIBERTY_LNG = 31.5167, 74.3460
GULBERG_LAT, GULBERG_LNG = 31.5204, 74.3587  # ~1.3km from Liberty


@pytest.fixture
def patched_orchestrator():
    """Patch the orchestrator entry points so auto_transition tests stay
    focused on the trigger classification — the orchestrator itself has
    its own dedicated test file.
    """
    with patch.object(auto_transition.orchestrator, 'en_route') as en_route, \
         patch.object(auto_transition.orchestrator, 'arrived') as arrived:
        yield {'en_route': en_route, 'arrived': arrived}


class TestHaversine:
    def test_zero_distance(self):
        assert _haversine_meters(31.5, 74.3, 31.5, 74.3) < 1

    def test_lahore_landmarks_distance_in_band(self):
        # Liberty Market <-> Gulberg is roughly 1.3km. Allow ±200m for
        # rounding noise in the curated coordinates.
        d = _haversine_meters(LIBERTY_LAT, LIBERTY_LNG, GULBERG_LAT, GULBERG_LNG)
        assert 1100 < d < 1500

    def test_one_thousandth_degree_latitude_about_111m(self):
        d = _haversine_meters(31.5, 74.3, 31.501, 74.3)
        assert 100 < d < 120

    def test_symmetry(self):
        d1 = _haversine_meters(31.5, 74.3, 31.6, 74.4)
        d2 = _haversine_meters(31.6, 74.4, 31.5, 74.3)
        assert abs(d1 - d2) < 0.001


class TestEvaluateOnLocation:
    def _confirmed_at(self, lat, lng):
        addr = CustomerAddressFactory(latitude=Decimal(str(lat)), longitude=Decimal(str(lng)))
        return JobBookingConfirmedFactory(address=addr)

    def test_confirmed_far_from_address_flips_en_route(self, patched_orchestrator):
        booking = self._confirmed_at(LIBERTY_LAT, LIBERTY_LNG)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=GULBERG_LAT, lng=GULBERG_LNG,  # ~1.3km away >> 200m
            technician_user=booking.technician.user,
        )
        assert result == JobBooking.STATUS_EN_ROUTE
        patched_orchestrator['en_route'].assert_called_once()
        kwargs = patched_orchestrator['en_route'].call_args.kwargs
        assert kwargs['source'] == 'auto'

    def test_confirmed_near_address_no_flip(self, patched_orchestrator):
        booking = self._confirmed_at(LIBERTY_LAT, LIBERTY_LNG)
        # ~50m offset (well below 200m threshold)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=LIBERTY_LAT + 0.0004,  # ~44m
            lng=LIBERTY_LNG,
            technician_user=booking.technician.user,
        )
        assert result is None
        patched_orchestrator['en_route'].assert_not_called()

    def test_en_route_close_to_address_flips_arrived(self, patched_orchestrator):
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingEnRouteFactory(address=addr)
        # ~30m offset (well below 100m threshold)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=LIBERTY_LAT + 0.0003,
            lng=LIBERTY_LNG,
            technician_user=booking.technician.user,
        )
        assert result == JobBooking.STATUS_ARRIVED
        patched_orchestrator['arrived'].assert_called_once()

    def test_en_route_still_far_no_flip(self, patched_orchestrator):
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingEnRouteFactory(address=addr)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=GULBERG_LAT, lng=GULBERG_LNG,  # ~1.3km away
            technician_user=booking.technician.user,
        )
        assert result is None
        patched_orchestrator['arrived'].assert_not_called()

    def test_inspecting_never_flips(self, patched_orchestrator):
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingInspectingFactory(address=addr)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=LIBERTY_LAT, lng=LIBERTY_LNG,
            technician_user=booking.technician.user,
        )
        assert result is None
        patched_orchestrator['en_route'].assert_not_called()
        patched_orchestrator['arrived'].assert_not_called()

    def test_arrived_never_re_flips(self, patched_orchestrator):
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingArrivedFactory(address=addr)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=LIBERTY_LAT, lng=LIBERTY_LNG,
            technician_user=booking.technician.user,
        )
        assert result is None

    def test_booking_not_found_silent(self, patched_orchestrator):
        result = auto_transition.evaluate_on_location(
            booking_id=999_999_999,
            lat=31.5, lng=74.3,
            technician_user=None,
        )
        assert result is None

    def test_address_null_silent(self, patched_orchestrator):
        # FK is SET_NULL — a deleted address shouldn't crash the geofence.
        booking = JobBookingConfirmedFactory(address=None)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=31.5, lng=74.3,
            technician_user=booking.technician.user,
        )
        assert result is None

    def test_unauthorized_tech_returns_none_silently(self, patched_orchestrator):
        # Defense-in-depth: a tech who doesn't own the booking gets the
        # same response as a "no trigger" frame, regardless of whether
        # the lat/lng would have flipped the status. Without this guard
        # the orchestrator's ERROR_NOT_ASSIGNED_TO_YOU rejection would
        # leak booking-state information across techs.
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingConfirmedFactory(address=addr)
        attacker = UserFactory()
        # Send a lat/lng that WOULD trigger en_route for the real tech.
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=GULBERG_LAT, lng=GULBERG_LNG,
            technician_user=attacker,
        )
        assert result is None
        patched_orchestrator['en_route'].assert_not_called()
        patched_orchestrator['arrived'].assert_not_called()

    def test_none_technician_user_returns_none_silently(self, patched_orchestrator):
        # Defensive: a caller passing technician_user=None (e.g. an
        # unauthenticated request that slipped past the view layer) must
        # never reach the orchestrator.
        addr = CustomerAddressFactory(
            latitude=Decimal(str(LIBERTY_LAT)),
            longitude=Decimal(str(LIBERTY_LNG)),
        )
        booking = JobBookingConfirmedFactory(address=addr)
        result = auto_transition.evaluate_on_location(
            booking_id=booking.id,
            lat=GULBERG_LAT, lng=GULBERG_LNG,
            technician_user=None,
        )
        assert result is None
        patched_orchestrator['en_route'].assert_not_called()
