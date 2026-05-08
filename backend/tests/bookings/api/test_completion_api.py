"""HTTP tests for ``POST /api/bookings/<id>/confirm-cash-received/``."""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.test import APIClient

from bookings.models import JobBooking
from realtime.constants.event_types import EventType
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingInProgressFactory,
)


pytestmark = pytest.mark.django_db


def _url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/confirm-cash-received/"


class TestConfirmCashReceivedEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_401_anonymous(self):
        booking = JobBookingInProgressFactory()
        response = self.client.post(_url(booking.id), {"amount": "1000.00"}, format="json")
        assert response.status_code == 401

    def test_403_when_customer(self):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_url(booking.id), {"amount": "1000.00"}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_technician"

    def test_200_happy_path(self, fake_finance, captured_broadcasts):
        # final_cash_to_collect must be pinned on the booking — the
        # orchestrator validates the submitted amount against this
        # server-derived figure (audit P2 / C2). In production this
        # is set on quote-decision; the factory leaves it null.
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal("1500.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "1500.00", "method": "cash"},
            format="json",
        )
        assert response.status_code == 200, response.json()
        body = response.json()
        assert body["status"] == JobBooking.STATUS_COMPLETED
        assert Decimal(body["cash_collected_amount"]) == Decimal("1500.00")
        assert body["cash_collection_method"] == "cash"
        assert body["completed_at"] is not None
        assert body["cash_collected_at"] is not None

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_COMPLETED

    def test_400_invalid_input_when_amount_zero(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "0.00", "method": "cash"},
            format="json",
        )
        # DRF's DecimalField min_value rejects 0 first → 400 validation_error.
        assert response.status_code == 400

    def test_400_invalid_method(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "1000.00", "method": "mobile_money"},
            format="json",
        )
        assert response.status_code == 400

    def test_400_invalid_transition_when_not_in_progress(self, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "1000.00", "method": "cash"},
            format="json",
        )
        assert response.status_code == 400
        assert response.json()["code"] == "invalid_transition"

    def test_idempotent_on_already_completed(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal("1000.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        first = self.client.post(_url(booking.id), {"amount": "1000.00"}, format="json")
        assert first.status_code == 200, first.json()
        second = self.client.post(_url(booking.id), {"amount": "1000.00"}, format="json")
        assert second.status_code == 200

    def test_broadcasts_payment_received_then_job_completed(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal("1500.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        self.client.post(_url(booking.id), {"amount": "1500.00"}, format="json")
        types = [c["event_type"] for c in captured_broadcasts]
        assert EventType.PAYMENT_RECEIVED in types
        assert EventType.JOB_COMPLETED in types

    def test_400_when_cash_amount_below_final_cash_to_collect(
        self, fake_finance, captured_broadcasts,
    ):
        """Regression for the C2 audit finding (Pass 2).

        A technician must NOT be able to mark a Rs. 1500 job paid with
        Rs. 1. The orchestrator validates the submitted ``cash_amount``
        against the server-derived ``final_cash_to_collect``. Mismatch
        surfaces a clean 400 ``invalid_input`` envelope; no booking
        mutation occurs.
        """
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal("1500.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "1.00", "method": "cash"},
            format="json",
        )
        assert response.status_code == 400, response.json()
        body = response.json()
        assert body["code"] == "invalid_input"
        assert "cash_amount" in body["errors"]
        # Booking must remain unmutated.
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_IN_PROGRESS
        assert booking.cash_collected_amount is None

    def test_400_when_cash_amount_above_final_cash_to_collect(
        self, fake_finance, captured_broadcasts,
    ):
        """C2 — over-payment is also rejected. The cash button is
        single-shot with the server-derived figure; any drift means
        either client tampering or a stale UI."""
        booking = JobBookingInProgressFactory(
            final_cash_to_collect=Decimal("1500.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "5000.00", "method": "cash"},
            format="json",
        )
        assert response.status_code == 400
        assert response.json()["code"] == "invalid_input"

    def test_400_when_final_cash_to_collect_unset(self, fake_finance, captured_broadcasts):
        """C2 — IN_PROGRESS booking with no final_cash_to_collect is a
        server-side invariant break. Surface invalid_transition rather
        than fall through to a 500 on the comparison."""
        booking = JobBookingInProgressFactory(final_cash_to_collect=None)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"amount": "1500.00", "method": "cash"},
            format="json",
        )
        assert response.status_code == 400
        assert response.json()["code"] == "invalid_transition"
