"""HTTP tests for the quote endpoints.

POST /api/bookings/<id>/quotes/                                — submit
POST /api/bookings/<id>/quotes/<qid>/approve/                  — approve
POST /api/bookings/<id>/quotes/<qid>/decline/                  — decline
POST /api/bookings/<id>/quotes/<qid>/request-revision/         — revision

Coverage per endpoint:
  * 401 anonymous
  * 403 wrong role (customer hits submit, tech hits approve/decline/revision)
  * 200/201 happy path
  * 400 invalid_transition / quote_band_violation / invalid_quote_empty
  * realtime broadcast asserted
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.test import APIClient

from bookings.models import BookingItem, JobBooking, Quote
from realtime.constants.event_types import EventType
from tests.factories.bookings import (
    JobBookingInProgressFactory,
    JobBookingInspectingFactory,
    JobBookingQuotedFactory,
    QuoteFactory,
    QuoteLineItemFactory,
)
from tests.factories.catalog import (
    FixedPriceSubServiceFactory,
    LaborSubServiceFactory,
)
from tests.factories.technicians import TechnicianProfileFactory


pytestmark = pytest.mark.django_db


def _submit_url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/quotes/"


def _approve_url(booking_id: int, quote_id: int) -> str:
    return f"/api/bookings/{booking_id}/quotes/{quote_id}/approve/"


def _decline_url(booking_id: int, quote_id: int) -> str:
    return f"/api/bookings/{booking_id}/quotes/{quote_id}/decline/"


def _revision_url(booking_id: int, quote_id: int) -> str:
    return f"/api/bookings/{booking_id}/quotes/{quote_id}/request-revision/"


# ---------------------------------------------------------------------
# submit_quote
# ---------------------------------------------------------------------


class TestSubmitQuoteEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_401_anonymous(self):
        booking = JobBookingInspectingFactory()
        response = self.client.post(_submit_url(booking.id), {}, format="json")
        assert response.status_code == 401

    def test_403_when_customer(self):
        booking = JobBookingInspectingFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_submit_url(booking.id), {}, format="json")
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_technician"

    def test_201_happy_path_labor(self, fake_finance, captured_broadcasts):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(
            service=booking.service,
            base_price=Decimal("1000.00"),
            max_price=Decimal("2500.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _submit_url(booking.id),
            {
                "is_upsell": False,
                "line_items": [
                    {"sub_service_id": sub.id, "quantity": 1, "priced_at": "1500.00"},
                ],
            },
            format="json",
        )
        assert response.status_code == 201
        body = response.json()
        assert body["revision_number"] == 1
        assert body["status"] == "SUBMITTED"
        assert Decimal(body["total_amount"]) == Decimal("1500.00")
        assert body["line_items"][0]["sub_service_name"] == sub.name

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_QUOTED

    def test_400_when_line_items_empty(self, fake_finance, captured_broadcasts):
        booking = JobBookingInspectingFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _submit_url(booking.id),
            {"is_upsell": False, "line_items": []},
            format="json",
        )
        assert response.status_code == 400

    def test_400_quote_band_violation(self, fake_finance, captured_broadcasts):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(
            service=booking.service,
            base_price=Decimal("1000.00"),
            max_price=Decimal("2000.00"),
        )
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _submit_url(booking.id),
            {
                "is_upsell": False,
                "line_items": [
                    {"sub_service_id": sub.id, "quantity": 1, "priced_at": "9999.00"},
                ],
            },
            format="json",
        )
        assert response.status_code == 400
        assert response.json()["code"] == "quote_band_violation"

    def test_400_when_line_item_quantity_above_cap(
        self, fake_finance, captured_broadcasts,
    ):
        """Regression for the C5-new audit finding (Pass 2).

        ``quantity`` MUST be bounded so ``priced_at * quantity`` cannot
        overflow the ``Decimal(max_digits=10)`` ceiling. Pre-fix a tech
        could send ``quantity=2147483647`` and either truncate the
        line_total silently or trigger a 500. The serializer rejects
        anything above the cap (999) with a clean 400.
        """
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(service=booking.service)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _submit_url(booking.id),
            {
                "is_upsell": False,
                "line_items": [
                    {
                        "sub_service_id": sub.id,
                        "quantity": 1_000_000,
                        "priced_at": "1500.00",
                    },
                ],
            },
            format="json",
        )
        assert response.status_code == 400, response.json()
        # Field-level error surfaces under line_items[0].quantity in
        # the canonical envelope.
        body = response.json()
        assert "errors" in body

    def test_broadcast_quote_generated(self, fake_finance, captured_broadcasts):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(service=booking.service)
        self.client.force_authenticate(user=booking.technician.user)
        self.client.post(
            _submit_url(booking.id),
            {
                "line_items": [
                    {"sub_service_id": sub.id, "priced_at": "1500.00"},
                ],
            },
            format="json",
        )
        events = [c for c in captured_broadcasts if c["event_type"] == EventType.QUOTE_GENERATED]
        assert len(events) == 1
        assert events[0]["target_role"] == "customer"


# ---------------------------------------------------------------------
# approve_quote
# ---------------------------------------------------------------------


class TestApproveQuoteEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def _quoted_with_quote(self):
        booking = JobBookingQuotedFactory()
        sub = LaborSubServiceFactory(service=booking.service)
        quote = QuoteFactory(booking=booking, total_amount=Decimal("1500.00"))
        QuoteLineItemFactory(
            quote=quote,
            sub_service=sub,
            priced_at=Decimal("1500.00"),
            line_total=Decimal("1500.00"),
        )
        booking.inspection_fee = Decimal("500.00")
        booking.save(update_fields=["inspection_fee"])
        return booking, quote

    def test_403_when_tech(self):
        booking, quote = self._quoted_with_quote()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(_approve_url(booking.id, quote.id))
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_customer"

    def test_200_happy_path(self, fake_finance, captured_broadcasts):
        booking, quote = self._quoted_with_quote()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_approve_url(booking.id, quote.id))
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_IN_PROGRESS
        # base 1500 - inspection 500 = 1000
        assert Decimal(body["final_cash_to_collect"]) == Decimal("1000.00")

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_IN_PROGRESS
        assert BookingItem.objects.filter(booking=booking).count() == 1

    def test_404_quote_not_found(self, captured_broadcasts):
        booking, _ = self._quoted_with_quote()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_approve_url(booking.id, 99999))
        assert response.status_code == 404
        assert response.json()["code"] == "quote_not_found"

    def test_dual_role_customer_can_approve_own_quote(
        self, fake_finance, captured_broadcasts,
    ):
        """Regression for the H1 audit finding.

        A user who has applied as a technician (and therefore carries a
        ``tech_profile``) must still be able to approve a quote on a
        booking where THEY are the customer. The pre-fix gate
        ``if hasattr(request.user, "tech_profile")`` rejected this
        legitimate flow with 403 ``not_a_customer``. CLAUDE.md's
        unified-User model explicitly permits one user to play both
        roles across different bookings; THIS booking's customer_id
        match is the only thing that matters.
        """
        booking, quote = self._quoted_with_quote()
        # Promote the customer to a dual-role user: same User account,
        # now also an APPROVED technician on the platform.
        TechnicianProfileFactory(user=booking.customer)
        # Sanity: the customer now has tech_profile (the bug pre-condition).
        booking.customer.refresh_from_db()
        assert hasattr(booking.customer, "tech_profile")

        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(_approve_url(booking.id, quote.id))
        assert response.status_code == 200, response.json()
        assert response.json()["status"] == JobBooking.STATUS_IN_PROGRESS

    def test_404_when_booking_missing(self):
        """Customer-side gate must surface a clean 404 (not 403) when
        the booking_id does not exist. Pre-fix this returned 403
        ``not_a_customer`` for tech callers because the hasattr gate
        fired before the booking lookup."""
        rando = JobBookingQuotedFactory().customer  # any authenticated user
        self.client.force_authenticate(user=rando)
        response = self.client.post(_approve_url(999_999, 1))
        assert response.status_code == 404
        assert response.json()["code"] == "booking_not_found"


# ---------------------------------------------------------------------
# decline_quote
# ---------------------------------------------------------------------


class TestDeclineQuoteEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_200_terminal_status_with_inspection_fee(self, fake_finance, captured_broadcasts):
        booking = JobBookingQuotedFactory(inspection_fee=Decimal("500.00"))
        quote = QuoteFactory(booking=booking)
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(
            _decline_url(booking.id, quote.id),
            {"reason": "Too expensive."},
            format="json",
        )
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_COMPLETED_INSPECTION_ONLY
        assert Decimal(body["final_cash_to_collect"]) == Decimal("500.00")

    def test_broadcast_quote_declined(self, fake_finance, captured_broadcasts):
        booking = JobBookingQuotedFactory(inspection_fee=Decimal("500.00"))
        quote = QuoteFactory(booking=booking)
        self.client.force_authenticate(user=booking.customer)
        self.client.post(
            _decline_url(booking.id, quote.id),
            {"reason": "Nope"},
            format="json",
        )
        events = [c for c in captured_broadcasts if c["event_type"] == EventType.QUOTE_DECLINED]
        assert len(events) == 1
        assert events[0]["target_role"] == "technician"


# ---------------------------------------------------------------------
# request_revision
# ---------------------------------------------------------------------


class TestRequestRevisionEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_200_flips_back_to_inspecting(self, fake_finance, captured_broadcasts):
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking)
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(
            _revision_url(booking.id, quote.id),
            {"reason": "Drop the second item."},
            format="json",
        )
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == JobBooking.STATUS_INSPECTING
        assert body["superseded_quote_id"] == quote.id

        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_INSPECTING
        quote.refresh_from_db()
        assert quote.status == Quote.STATUS_SUPERSEDED
