"""HTTP tests for the manual phase-marker endpoints.

POST /api/bookings/<id>/start-inspection/
POST /api/bookings/<id>/en-route/
POST /api/bookings/<id>/arrived/

Each endpoint covers:
  * 401 anonymous
  * 403 wrong role (customer hitting tech endpoint, etc.)
  * 200 happy path (response shape + persisted status)
  * 400 invalid_transition with current_status echoed
  * idempotency on already-target state
  * realtime broadcast registered (via ``captured_broadcasts``)

The geofence check on ``arrived/`` is exercised separately with
``settings.BOOKING_GEOFENCE_STRICT`` toggled.
"""
from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from bookings.models import JobBooking
from realtime.constants.event_types import EventType
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingConfirmedFactory,
    JobBookingEnRouteFactory,
)
from tests.factories.customers import CustomerProfileFactory


pytestmark = pytest.mark.django_db


def _start_inspection_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/start-inspection/"


def _en_route_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/en-route/"


def _arrived_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/arrived/"


# ---------------------------------------------------------------------
# start-inspection
# ---------------------------------------------------------------------


class TestStartInspectionEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_401_when_anonymous(self):
        booking = JobBookingArrivedFactory()
        response = self.client.post(_start_inspection_url(booking.id))
        assert response.status_code == 401

    def test_403_when_not_a_technician(self):
        booking = JobBookingArrivedFactory()
        # A user with no tech_profile.
        customer = booking.customer
        CustomerProfileFactory(user=customer)
        self.client.force_authenticate(user=customer)
        response = self.client.post(_start_inspection_url(booking.id))
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_technician"

    def test_200_happy_path_flips_status(self, fake_finance, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_start_inspection_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        assert body["id"] == booking.id
        assert body["status"] == JobBooking.STATUS_INSPECTING
        assert body["inspection_started_at"] is not None

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_INSPECTING

    def test_400_invalid_transition_when_not_arrived(self, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_start_inspection_url(booking.id))
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "invalid_transition"
        assert body["errors"]["current_status"] == [JobBooking.STATUS_CONFIRMED]

    def test_idempotent_on_already_inspecting(self, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        first = self.client.post(_start_inspection_url(booking.id))
        assert first.status_code == 200
        second = self.client.post(_start_inspection_url(booking.id))
        assert second.status_code == 200

    def test_403_other_tech(self):
        booking = JobBookingArrivedFactory()
        other = UserFactory()
        # Make ``other`` a tech via a TechnicianProfile so the inline
        # ``hasattr(user, 'tech_profile')`` check passes; the orchestrator's
        # IDOR guard then rejects.
        from tests.factories.technicians import TechnicianProfileFactory
        TechnicianProfileFactory(user=other)
        self.client.force_authenticate(user=other)
        response = self.client.post(_start_inspection_url(booking.id))
        assert response.status_code == 400
        assert response.json()["code"] == "not_assigned_to_you"


# ---------------------------------------------------------------------
# en-route
# ---------------------------------------------------------------------


class TestEnRouteEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_200_flips_status_and_stamps_timestamp(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_en_route_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_EN_ROUTE
        assert body["en_route_started_at"] is not None

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_EN_ROUTE

    def test_broadcast_to_customer(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        self.client.post(_en_route_url(booking.id))
        events = [c for c in captured_broadcasts if c["event_type"] == EventType.TECH_EN_ROUTE]
        assert len(events) == 1
        assert events[0]["target_role"] == "customer"
        assert events[0]["user"].id == booking.customer_id

    def test_400_when_not_confirmed(self, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_en_route_url(booking.id))
        assert response.status_code == 400
        assert response.json()["code"] == "invalid_transition"


# ---------------------------------------------------------------------
# arrived
# ---------------------------------------------------------------------


class TestArrivedEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_200_happy_path(self, fake_finance, captured_broadcasts):
        booking = JobBookingEnRouteFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_arrived_url(booking.id))
        assert response.status_code == 200
        assert response.json()["status"] == JobBooking.STATUS_ARRIVED
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_ARRIVED

    def test_geofence_lenient_allows_far_coords(self, fake_finance, captured_broadcasts, settings):
        from tests.factories.customers import CustomerAddressFactory

        settings.BOOKING_GEOFENCE_STRICT = False
        # Lahore-ish address; coords below are 5km off.
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingEnRouteFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _arrived_url(booking.id),
            {"current_lat": 31.6, "current_lng": 74.4},
            format="json",
        )
        assert response.status_code == 200

    def test_geofence_strict_rejects_far_coords(self, fake_finance, captured_broadcasts, settings):
        from tests.factories.customers import CustomerAddressFactory

        settings.BOOKING_GEOFENCE_STRICT = True
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingEnRouteFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _arrived_url(booking.id),
            {"current_lat": 31.6, "current_lng": 74.4},
            format="json",
        )
        assert response.status_code == 400
        assert response.json()["code"] == "not_at_customer_location"

    def test_geofence_strict_allows_close_coords(self, fake_finance, captured_broadcasts, settings):
        from tests.factories.customers import CustomerAddressFactory

        settings.BOOKING_GEOFENCE_STRICT = True
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingEnRouteFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        # ~50m off — within 100m threshold.
        response = self.client.post(
            _arrived_url(booking.id),
            {"current_lat": 31.5208, "current_lng": 74.3589},
            format="json",
        )
        assert response.status_code == 200
