"""
Tests for the technician-side accept / decline API endpoints.

POST /api/bookings/<id>/accept/
POST /api/bookings/<id>/decline/

Covers:
    - 200 happy path: response shape, persisted status, idempotent retry.
    - 401 anonymous.
    - 404 missing OR wrong-owner (IDOR collapse — same response shape).
    - 409 booking_no_longer_available with current_status echoed.
    - Customer-event side-effect: dispatched once on success, zero times
      on every failure path. Uses ``django_db(transaction=True)`` so
      on_commit hooks fire for real.
"""
from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from bookings.models import JobBooking
from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.customers import CustomerProfileFactory
from tests.factories.technicians import TechnicianProfileFactory


def _accept_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/accept/"


def _decline_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/decline/"


# =====================================================================
# accept — happy path + persisted state
# =====================================================================

@pytest.mark.django_db
class TestAcceptHappyPath:

    def setup_method(self):
        self.client = APIClient()

    def test_200_transitions_to_confirmed(self, mocker):
        # Mock at the service module's import path so the patch survives
        # both direct imports and on_commit re-entries inside the request.
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 200

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CONFIRMED

    def test_200_response_body_shape(self, mocker):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        data = response.json()
        assert data == {
            "booking_id": booking.id,
            "status": JobBooking.STATUS_CONFIRMED,
        }

    def test_200_idempotent_when_same_tech_retries(self, mocker):
        # Network blip / double-tap: two POSTs, both succeed, end state
        # CONFIRMED. The second call returns 200 with the same body.
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        first = self.client.post(_accept_url(booking.id), {}, format="json")
        second = self.client.post(_accept_url(booking.id), {}, format="json")
        assert first.status_code == 200
        assert second.status_code == 200
        assert first.json() == second.json()


# =====================================================================
# accept — 4xx error envelopes
# =====================================================================

@pytest.mark.django_db
class TestAcceptErrors:

    def setup_method(self):
        self.client = APIClient()

    def test_401_when_unauthenticated(self):
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 401

    def test_404_when_booking_does_not_exist(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        self.client.force_authenticate(user=tech.user)
        response = self.client.post(_accept_url(999_999), {}, format="json")
        assert response.status_code == 404
        assert response.json()["code"] == "not_found"

    def test_404_when_booking_belongs_to_other_technician(self):
        # IDOR-safe collapse: same response as missing.
        tech_a = TechnicianProfileFactory(status="APPROVED")
        tech_b = TechnicianProfileFactory(status="APPROVED")
        booking = JobBookingFactory(
            technician=tech_b,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        self.client.force_authenticate(user=tech_a.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 404
        assert response.json()["code"] == "not_found"
        # Booking unchanged.
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT

    def test_404_for_a_logged_in_customer(self):
        # Logged-in customer (not a technician) can't accept anything.
        profile = CustomerProfileFactory()
        booking = JobBookingFactory(
            customer=profile.user,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        self.client.force_authenticate(user=profile.user)
        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 404

    @pytest.mark.parametrize(
        "blocking_status",
        [
            JobBooking.STATUS_REJECTED,    # SLA fired first
            JobBooking.STATUS_CANCELLED,   # Customer cancelled first
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_PENDING,
        ],
    )
    def test_409_when_status_is_not_actionable(self, mocker, blocking_status):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=blocking_status)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 409
        data = response.json()
        assert data["code"] == "booking_no_longer_available"
        assert data["status"] == 409
        # Echo the live status so the client can debug if the offer disappears.
        assert data["errors"]["current_status"] == [blocking_status]

    def test_409_envelope_matches_contract(self, mocker):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_REJECTED)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        data = response.json()
        assert set(data.keys()) == {"status", "code", "message", "errors"}


# =====================================================================
# decline — happy path + idempotency
# =====================================================================

@pytest.mark.django_db
class TestDeclineHappyPath:

    def setup_method(self):
        self.client = APIClient()

    def test_200_transitions_to_rejected(self, mocker):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 200
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_REJECTED

    def test_200_response_body_shape(self, mocker):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.json() == {
            "booking_id": booking.id,
            "status": JobBooking.STATUS_REJECTED,
        }

    def test_200_idempotent_when_same_tech_retries(self, mocker):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        first = self.client.post(_decline_url(booking.id), {}, format="json")
        second = self.client.post(_decline_url(booking.id), {}, format="json")
        assert first.status_code == 200
        assert second.status_code == 200
        assert first.json() == second.json()

    def test_200_when_sla_already_fired_first(self, mocker):
        # Technician taps Decline at the same instant the SLA fires.
        # End state matches intent → idempotent success, no second emit.
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_REJECTED)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 200


# =====================================================================
# decline — 4xx error envelopes
# =====================================================================

@pytest.mark.django_db
class TestDeclineErrors:

    def setup_method(self):
        self.client = APIClient()

    def test_401_when_unauthenticated(self):
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 401

    def test_404_when_booking_does_not_exist(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        self.client.force_authenticate(user=tech.user)
        response = self.client.post(_decline_url(999_999), {}, format="json")
        assert response.status_code == 404

    def test_404_when_booking_belongs_to_other_technician(self):
        tech_a = TechnicianProfileFactory(status="APPROVED")
        tech_b = TechnicianProfileFactory(status="APPROVED")
        booking = JobBookingFactory(
            technician=tech_b,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        )
        self.client.force_authenticate(user=tech_a.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 404
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT

    @pytest.mark.parametrize(
        "blocking_status",
        [
            JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_PENDING,
        ],
    )
    def test_409_when_status_is_not_actionable(self, mocker, blocking_status):
        mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=blocking_status)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 409
        data = response.json()
        assert data["code"] == "booking_no_longer_available"
        assert data["errors"]["current_status"] == [blocking_status]


# =====================================================================
# Customer-event side-effect at the API boundary
#
# Service-layer tests already prove on_commit semantics. These tests
# prove the same contract holds when the request flows through the DRF
# view: a 200 fans the broadcast exactly once, a 4xx fans it zero times.
# Use transaction=True so on_commit fires.
# =====================================================================

@pytest.mark.django_db(transaction=True)
class TestAcceptApiBroadcastSideEffect:

    def setup_method(self):
        self.client = APIClient()

    def test_200_dispatches_once(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 200
        assert broadcast.call_count == 1
        assert broadcast.call_args.kwargs["event_type"] == "job_accepted"

    def test_409_does_not_dispatch(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_REJECTED)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_accept_url(booking.id), {}, format="json")
        assert response.status_code == 409
        assert broadcast.call_count == 0

    def test_404_does_not_dispatch(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        tech = TechnicianProfileFactory(status="APPROVED")
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(_accept_url(999_999), {}, format="json")
        assert response.status_code == 404
        assert broadcast.call_count == 0

    def test_idempotent_retry_dispatches_once_total(self, mocker):
        # Two POSTs, one event. Doubly important: a duplicated
        # job_accepted on the customer's side would be confusing.
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        self.client.post(_accept_url(booking.id), {}, format="json")
        self.client.post(_accept_url(booking.id), {}, format="json")
        assert broadcast.call_count == 1


@pytest.mark.django_db(transaction=True)
class TestDeclineApiBroadcastSideEffect:

    def setup_method(self):
        self.client = APIClient()

    def test_200_dispatches_once(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 200
        assert broadcast.call_count == 1
        assert broadcast.call_args.kwargs["event_type"] == "booking_rejected"

    def test_409_does_not_dispatch(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_CONFIRMED)
        self.client.force_authenticate(user=booking.technician.user)

        response = self.client.post(_decline_url(booking.id), {}, format="json")
        assert response.status_code == 409
        assert broadcast.call_count == 0

    def test_idempotent_retry_dispatches_once_total(self, mocker):
        broadcast = mocker.patch(
            "bookings.services.job_request_action.EventDispatchService.broadcast_event"
        )
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        self.client.force_authenticate(user=booking.technician.user)

        self.client.post(_decline_url(booking.id), {}, format="json")
        self.client.post(_decline_url(booking.id), {}, format="json")
        assert broadcast.call_count == 1
