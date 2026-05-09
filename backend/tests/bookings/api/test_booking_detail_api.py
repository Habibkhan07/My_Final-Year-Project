"""HTTP tests for ``GET /api/bookings/<id>/``.

Coverage:
  * 401 anonymous, 403 non-participant, 404 missing
  * 200 happy path — payload shape, customer + tech mini blocks, ui block,
    available_transitions
  * No HTTP cache header (audit P1-04)
  * UserProfile-less customer falls back to empty phone string
  * Cycle 2 regression guards (#A1, #B1, #A-10, #A-17)
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient

from accounts.models import UserProfile
from bookings.models import JobBooking
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    BookingItemFactory,
    JobBookingArrivedFactory,
    JobBookingCompletedFactory,
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

    def test_booking_items_payload_uses_price_charged_field(self):
        """Audit cycle 2 #A1 regression guard.

        The booking-detail serializer previously serialized BookingItem
        rows through QuoteLineItemResponseSerializer, which expects
        ``priced_at``. BookingItem has ``price_charged`` — the access
        raised ``AttributeError`` at runtime on every booking with an
        accepted item (i.e. anything past quote-approval). The bug
        survived because no fixture in this file ever created a
        BookingItem. This test exercises the path explicitly.
        """
        booking = JobBookingCompletedFactory()
        sub = LaborSubServiceFactory(service=booking.service)
        item = BookingItemFactory(
            booking=booking,
            sub_service=sub,
            quantity=2,
            price_charged=Decimal('750.00'),
            line_total=Decimal('1500.00'),
        )
        self.client.force_authenticate(user=booking.customer)

        response = self.client.get(_url(booking.id))
        assert response.status_code == 200, response.content
        body = response.json()

        items = body["booking_items"]
        assert len(items) == 1
        wire = items[0]
        # Wire field name is ``price_charged`` (not ``priced_at``) — the
        # frontend's BookingItemModel parses by this exact JSON key.
        assert wire["id"] == item.id
        assert wire["sub_service_id"] == sub.id
        assert wire["sub_service_name"] == sub.name
        assert wire["quantity"] == 2
        assert "price_charged" in wire
        assert "priced_at" not in wire
        assert Decimal(wire["price_charged"]) == Decimal("750.00")
        assert Decimal(wire["line_total"]) == Decimal("1500.00")
        # ``sourced_quote_id`` is always present on the wire (nullable);
        # the frontend's optional field decodes it.
        assert "sourced_quote_id" in wire

    def test_child_booking_id_surfaces_when_present(self):
        """Audit cycle 2 #B1 regression guard.

        When this booking is the CANCELLED parent of a reschedule chain,
        the response carries ``child_booking_id`` so the orchestrator
        screen can render a "Continued on #N" link instead of stranding
        the user on a defunct original.
        """
        parent = JobBookingConfirmedFactory(status=JobBooking.STATUS_CANCELLED)
        child = JobBookingConfirmedFactory(
            customer=parent.customer,
            technician=parent.technician,
            parent_booking=parent,
        )
        self.client.force_authenticate(user=parent.customer)

        response = self.client.get(_url(parent.id))
        assert response.status_code == 200
        assert response.json()["child_booking_id"] == child.id

    def test_child_booking_id_is_null_when_no_child(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        assert response.json()["child_booking_id"] is None

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

    def test_profile_picture_url_is_absolute_when_present(self):
        """Audit P1-02 + cycle 2 #A-10 regression guard.

        Frontend's `Image.network` requires an absolute URL — a relative
        media path would silently fail on every device. The serializer
        composes the URL via ``request.build_absolute_uri(image.url)``.
        This test pins the contract: when a tech has a profile picture,
        the wire field is an absolute http(s) URI containing the request
        host. Stripping the build_absolute_uri call would break this.
        """
        booking = JobBookingConfirmedFactory()
        booking.technician.profile_picture = SimpleUploadedFile(
            'tech.jpg', b'\x89PNG\r\n\x1a\n', content_type='image/jpeg',
        )
        booking.technician.save(update_fields=['profile_picture'])
        self.client.force_authenticate(user=booking.customer)

        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        url = response.json()["technician"]["profile_picture_url"]
        assert url is not None
        # Absolute scheme + host. APIClient defaults to http://testserver.
        assert url.startswith("http://") or url.startswith("https://")
        assert "testserver" in url

    def test_profile_picture_url_is_null_when_absent(self):
        """Sibling guard to the absolute-URI test.

        When the tech has no profile picture, the field is null on the
        wire (frontend renders an avatar placeholder). It is never an
        empty string and never a bare relative path.
        """
        booking = JobBookingConfirmedFactory()
        # Factory default leaves profile_picture unset.
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        assert response.json()["technician"]["profile_picture_url"] is None

    @pytest.mark.parametrize(
        "status,expected",
        [
            (JobBooking.STATUS_AWAITING_TECH_ACCEPT, False),
            (JobBooking.STATUS_CONFIRMED, False),
            (JobBooking.STATUS_EN_ROUTE, False),
            (JobBooking.STATUS_ARRIVED, False),
            (JobBooking.STATUS_INSPECTING, False),
            (JobBooking.STATUS_QUOTED, False),
            (JobBooking.STATUS_IN_PROGRESS, True),
            (JobBooking.STATUS_COMPLETED, True),
            (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, True),
            (JobBooking.STATUS_CANCELLED, False),
            (JobBooking.STATUS_REJECTED, False),
            (JobBooking.STATUS_NO_SHOW, True),
            # DISPUTED already has an open dispute — the button would be
            # a no-op. Only IN_PROGRESS / COMPLETED /
            # COMPLETED_INSPECTION_ONLY / NO_SHOW are dispute-eligible.
            (JobBooking.STATUS_DISPUTED, False),
        ],
    )
    def test_show_dispute_button_matrix(self, status, expected):
        """Cycle 2 #A-17 regression guard.

        ``show_dispute_button`` is the load-bearing flag the
        secondary-actions slot reads to surface the "Open dispute"
        button. The product rule: only after work has actually started
        or visibly failed (IN_PROGRESS / COMPLETED /
        COMPLETED_INSPECTION_ONLY / NO_SHOW) is dispute a valid
        affordance. Quoting/inspecting/cancelled/already-disputed
        must NOT show it.

        This test pins the entire 13-row matrix so a per-handler edit
        in ``orchestrator_ui.py`` can't silently flip any cell. Quote
        factories are seeded for QUOTED to keep the handler happy
        (see test_orchestrator_ui_selector.py for the same pattern).
        """
        booking = JobBookingConfirmedFactory(status=status)
        if status == JobBooking.STATUS_QUOTED:
            QuoteFactory(booking=booking)
        self.client.force_authenticate(user=booking.customer)
        response = self.client.get(_url(booking.id))
        assert response.status_code == 200
        assert response.json()["ui"]["show_dispute_button"] is expected
