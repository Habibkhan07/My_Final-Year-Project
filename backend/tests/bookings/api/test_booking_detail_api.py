"""HTTP tests for ``GET /api/bookings/<id>/``.

Coverage:
  * 401 anonymous, 403 non-participant, 404 missing
  * 200 happy path — payload shape, customer + tech mini blocks, ui block,
    available_transitions
  * No HTTP cache header (audit P1-04)
  * UserProfile-less customer falls back to empty phone string
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.test import APIClient

from accounts.models import UserProfile
from bookings.models import JobBooking
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingConfirmedFactory,
    JobBookingQuotedFactory,
    QuoteFactory,
    QuoteLineItemFactory,
)
from tests.factories.catalog import LaborSubServiceFactory
from tests.factories.customers import CustomerAddressFactory


pytestmark = pytest.mark.django_db


def _url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/"


class TestBookingDetailEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_401_anonymous(self):
        booking = JobBookingConfirmedFactory()
        response = self.client.get(_url(booking.id))
        assert response.status_code == 401

    def test_403_non_participant(self):
        booking = JobBookingConfirmedFactory()
        rando = UserFactory()
        self.client.force_authenticate(user=rando)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_participant"

    def test_404_missing(self):
        rando = UserFactory()
        self.client.force_authenticate(user=rando)
        response = self.client.get(_url(999_999))
        assert response.status_code == 404
        assert response.json()["code"] == "booking_not_found"

    def test_200_happy_path_for_customer(self):
        addr = CustomerAddressFactory(label="Home")
        booking = JobBookingConfirmedFactory(address=addr)
        UserProfile.objects.create(user=booking.customer, phone="+923001234567")
        self.client.force_authenticate(user=booking.customer)

        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        # Audit P1-04 — no HTTP cache. Realtime events drive re-fetches;
        # any cached payload would render stale state exactly when
        # freshness matters. We assert the full no-cache stack so the
        # contract cannot regress to "absent header" (the previous test
        # passed for an empty Cache-Control header, which browsers
        # heuristically cache anyway).
        cache_control = response.get("Cache-Control", "")
        assert "no-store" in cache_control
        assert "no-cache" in cache_control
        assert "max-age" not in cache_control
        assert response.get("Pragma") == "no-cache"
        assert response.get("Expires") == "0"

        body = response.json()
        assert body["id"] == booking.id
        assert body["status"] == JobBooking.STATUS_CONFIRMED
        assert body["customer"]["phone_no"] == "+923001234567"
        assert body["customer"]["id"] == booking.customer.id
        assert body["technician"]["id"] == booking.technician.id
        assert body["address"]["label"] == "Home"
        assert body["ui"]["status_label"] == "Confirmed"
        assert body["ui"]["tone"] == "positive"
        assert "cancel_by_customer" in body["available_transitions"]

    def test_200_happy_path_for_tech(self):
        booking = JobBookingArrivedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        # Tech sees a primary action (start_inspection) on ARRIVED.
        assert body["ui"]["primary_action"] is not None
        assert "start_inspection" in body["available_transitions"]

    def test_phone_falls_back_to_empty_when_no_userprofile(self):
        # No UserProfile on the customer.
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        assert response.json()["customer"]["phone_no"] == ""

    def test_active_quote_payload_when_quote_exists(self):
        booking = JobBookingQuotedFactory()
        sub = LaborSubServiceFactory(service=booking.service)
        quote = QuoteFactory(booking=booking, total_amount=Decimal("1500.00"))
        QuoteLineItemFactory(quote=quote, sub_service=sub)
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        body = response.json()
        assert body["active_quote"] is not None
        assert body["active_quote"]["id"] == quote.id
        assert body["active_quote"]["status"] == "SUBMITTED"
        assert len(body["active_quote"]["line_items"]) == 1

    def test_pricing_block(self):
        booking = JobBookingConfirmedFactory(
            inspection_fee=Decimal("500.00"),
        )
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        pricing = response.json()["pricing"]
        assert Decimal(pricing["inspection_fee"]) == Decimal("500.00")
        assert pricing["base_services_total"] is None
