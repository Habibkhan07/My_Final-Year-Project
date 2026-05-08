"""HTTP tests for the termination endpoints (cancel × 2, no-show, dispute, reschedule)."""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal
from io import BytesIO

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from PIL import Image
from rest_framework.test import APIClient

from bookings.models import JobBooking, SupportTicket, TechReliabilityIncident
from realtime.constants.event_types import EventType
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingConfirmedFactory,
    JobBookingFactory,
    JobBookingInProgressFactory,
)
from tests.factories.technicians import TechnicianProfileFactory


pytestmark = pytest.mark.django_db


def _customer_cancel_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/cancel/"


def _tech_cancel_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/tech-cancel/"


def _no_show_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/no-show/"


def _disputes_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/disputes/"


def _reschedule_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/reschedule/"


def _png_bytes(size_kb: int = 10) -> bytes:
    """Generate an in-memory PNG of approximately ``size_kb`` kilobytes."""
    buf = BytesIO()
    img = Image.new("RGB", (10, 10), color=(255, 0, 0))
    img.save(buf, format="PNG")
    return buf.getvalue()


# ---------------------------------------------------------------------
# customer cancel
# ---------------------------------------------------------------------


class TestCustomerCancelEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_403_when_tech(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_customer_cancel_url(booking.id))
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_customer"

    def test_200_happy_path(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_customer_cancel_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_CANCELLED
        assert body["cancel_reason"] == "customer_cancelled_post_accept"

    def test_400_when_in_progress(self, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_customer_cancel_url(booking.id))
        assert response.status_code == 400
        assert response.json()["code"] == "cancellation_not_allowed"


# ---------------------------------------------------------------------
# tech cancel
# ---------------------------------------------------------------------


class TestTechCancelEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_200_writes_reliability_incident(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _tech_cancel_url(booking.id),
            {"reason": "Vehicle broke down."},
            format="json",
        )
        assert response.status_code == 200
        assert response.json()["cancel_reason"] == "technician_cancelled"

        incidents = TechReliabilityIncident.objects.filter(
            booking=booking,
            incident_type=TechReliabilityIncident.INCIDENT_TECH_CANCEL,
        )
        assert incidents.count() == 1


# ---------------------------------------------------------------------
# no-show
# ---------------------------------------------------------------------


class TestMarkNoShowEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_403_when_neither_party(self):
        booking = JobBookingArrivedFactory()
        rando = UserFactory()
        self.client.force_authenticate(user=rando)
        response = self.client.post(_no_show_url(booking.id))
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_participant"

    def test_404_when_booking_missing(self):
        rando = UserFactory()
        self.client.force_authenticate(user=rando)
        response = self.client.post(_no_show_url(999_999))
        assert response.status_code == 404
        assert response.json()["code"] == "booking_not_found"

    def test_200_tech_path_after_15_min(self, fake_finance, captured_broadcasts):
        # ARRIVED 16 minutes ago.
        past = timezone.now() - timedelta(minutes=16)
        booking = JobBookingArrivedFactory(arrived_at=past)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_no_show_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_NO_SHOW
        assert body["no_show_actor"] == "tech"

    def test_400_no_show_too_early(self, captured_broadcasts):
        booking = JobBookingArrivedFactory(arrived_at=timezone.now())
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_no_show_url(booking.id))
        assert response.status_code == 400
        assert response.json()["code"] == "no_show_too_early"

    def test_200_customer_path_after_window(self, fake_finance, captured_broadcasts):
        scheduled = timezone.now() - timedelta(minutes=20)
        booking = JobBookingConfirmedFactory(
            scheduled_start=scheduled,
            scheduled_end=scheduled + timedelta(hours=1),
        )
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_no_show_url(booking.id))
        assert response.status_code == 200
        assert response.json()["no_show_actor"] == "customer"


# ---------------------------------------------------------------------
# open dispute (multipart)
# ---------------------------------------------------------------------


class TestOpenDisputeEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_201_with_photo(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.customer)
        photo = SimpleUploadedFile(
            "evidence.png",
            _png_bytes(),
            content_type="image/png",
        )
        response = self.client.post(
            _disputes_url(booking.id),
            {
                "initial_reason": "Tech broke a fitting and refused to fix it.",
                "photo": photo,
            },
            format="multipart",
        )
        assert response.status_code == 201, response.content
        body = response.json()
        assert body["booking_id"] == booking.id
        assert body["booking_status"] == JobBooking.STATUS_DISPUTED
        assert body["dispute_intake_method"] == SupportTicket.INTAKE_FORM

        ticket = SupportTicket.objects.get(id=body["ticket_id"])
        assert ticket.evidence.count() == 1

    def test_400_missing_initial_reason(self, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_disputes_url(booking.id), {}, format="multipart")
        assert response.status_code == 400

    def test_201_no_photo(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _disputes_url(booking.id),
            {"initial_reason": "Customer is refusing to pay."},
            format="multipart",
        )
        assert response.status_code == 201


# ---------------------------------------------------------------------
# reschedule
# ---------------------------------------------------------------------


class TestRescheduleEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_201_creates_child_and_cancels_original(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        new_start = timezone.now() + timedelta(days=2)
        new_end = new_start + timedelta(hours=2)

        response = self.client.post(
            _reschedule_url(booking.id),
            {
                "new_scheduled_start": new_start.isoformat(),
                "new_scheduled_end": new_end.isoformat(),
            },
            format="json",
        )
        assert response.status_code == 201
        body = response.json()
        assert body["original_booking_id"] == booking.id
        assert body["original_status"] == JobBooking.STATUS_CANCELLED
        assert body["child_status"] == JobBooking.STATUS_AWAITING_TECH_ACCEPT

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        child = JobBooking.objects.get(id=body["child_booking_id"])
        assert child.parent_booking_id == booking.id

    def test_400_when_end_before_start(self, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        new_start = timezone.now() + timedelta(days=2)
        response = self.client.post(
            _reschedule_url(booking.id),
            {
                "new_scheduled_start": new_start.isoformat(),
                "new_scheduled_end": (new_start - timedelta(minutes=1)).isoformat(),
            },
            format="json",
        )
        assert response.status_code == 400

    def test_403_when_tech(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        new_start = timezone.now() + timedelta(days=2)
        response = self.client.post(
            _reschedule_url(booking.id),
            {
                "new_scheduled_start": new_start.isoformat(),
                "new_scheduled_end": (new_start + timedelta(hours=1)).isoformat(),
            },
            format="json",
        )
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_customer"

    def test_400_when_new_start_in_the_past(self):
        """Regression for the C4-new audit finding (Pass 2).

        A customer must not be able to reschedule into the past. The
        orchestrator's overlap check is purely against other bookings,
        not against ``now``; without this serializer guard the child
        booking would be born in the past and corrupt matchmaking +
        SLA timers.
        """
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        past_start = timezone.now() - timedelta(days=1)
        past_end = past_start + timedelta(hours=1)
        response = self.client.post(
            _reschedule_url(booking.id),
            {
                "new_scheduled_start": past_start.isoformat(),
                "new_scheduled_end": past_end.isoformat(),
            },
            format="json",
        )
        assert response.status_code == 400, response.json()
        # Validation surfaces from the serializer; canonical envelope.
        assert "new_scheduled_start" in response.json().get("errors", {})

    def test_400_when_new_start_beyond_max_future_window(self):
        """C4-new — reject reschedules into the far future to prevent
        capacity-pollution attacks (year-2099 slot reservation).
        """
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        far_start = timezone.now() + timedelta(days=365)
        far_end = far_start + timedelta(hours=1)
        response = self.client.post(
            _reschedule_url(booking.id),
            {
                "new_scheduled_start": far_start.isoformat(),
                "new_scheduled_end": far_end.isoformat(),
            },
            format="json",
        )
        assert response.status_code == 400
        assert "new_scheduled_start" in response.json().get("errors", {})
