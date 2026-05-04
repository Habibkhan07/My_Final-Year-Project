"""
Tests for the customer-side bookings list + counts API.

GET /api/bookings/
GET /api/bookings/counts/

Covers exhaustively:

  * 200 happy path with full payload-shape assertion (every documented
    field per CUSTOMER_BOOKINGS_API.md §1.4 / §2.2 is present).
  * Segment routing (upcoming / past).
  * Explicit ``status`` csv filter overriding segment.
  * Cursor round-trip pagination.
  * Page-size clamping + invalid values.
  * Authentication (401 on anonymous).
  * IDOR — user A cannot see user B's bookings.
  * Validation envelopes — invalid_status_filter, invalid_cursor,
    validation_error (page_size out of range, malformed since).
  * REJECTED reason discrimination via EventLog.
  * Counts endpoint matches the same predicates as the list segments.
"""
from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from bookings.models import JobBooking
from realtime.constants.event_types import EventType
from realtime.models.events import EventLog
from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory


pytestmark = pytest.mark.django_db


LIST_URL = "/api/bookings/"
COUNTS_URL = "/api/bookings/counts/"


def _booking_in_future(*, customer, **kwargs) -> JobBooking:
    start = timezone.now() + datetime.timedelta(days=1)
    end = start + datetime.timedelta(hours=1)
    return JobBookingFactory(
        customer=customer,
        scheduled_start=start,
        scheduled_end=end,
        **kwargs,
    )


def _booking_in_past(*, customer, **kwargs) -> JobBooking:
    end = timezone.now() - datetime.timedelta(hours=1)
    start = end - datetime.timedelta(hours=1)
    return JobBookingFactory(
        customer=customer,
        scheduled_start=start,
        scheduled_end=end,
        **kwargs,
    )


def _make_rejection_log(*, user, job_id: int, reason: str) -> EventLog:
    return EventLog.objects.create(
        user=user,
        event_type=EventType.BOOKING_REJECTED.value,
        target_role=EventLog.TARGET_CUSTOMER,
        payload={"job_id": job_id, "reason": reason},
        is_critical=False,
    )


# =====================================================================
# Authentication
# =====================================================================


class TestAuthentication:

    def setup_method(self):
        self.client = APIClient()

    def test_list_401_anonymous(self):
        response = self.client.get(LIST_URL)
        assert response.status_code == 401
        assert response.json()["code"] == "unauthorized"

    def test_counts_401_anonymous(self):
        response = self.client.get(COUNTS_URL)
        assert response.status_code == 401


# =====================================================================
# 200 happy path — list
# =====================================================================


class TestListHappyPath:

    def setup_method(self):
        self.client = APIClient()

    def test_returns_envelope_with_documented_top_level_keys(self):
        user = UserFactory()
        _booking_in_future(customer=user)
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL)
        assert response.status_code == 200
        body = response.json()
        assert set(body.keys()) == {
            "items",
            "next_cursor",
            "has_more",
            "server_time",
        }

    def test_item_shape_matches_api_doc(self):
        user = UserFactory()
        profile = CustomerProfileFactory(user=user)
        address = CustomerAddressFactory(
            customer=profile, label="Home", locality_label="Gulberg, Lahore",
        )
        booking = _booking_in_future(
            customer=user,
            address=address,
            status=JobBooking.STATUS_CONFIRMED,
            price_amount=Decimal("2500.00"),
            price_context="Fixed Price",
        )
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL)
        item = response.json()["items"][0]

        # Every documented top-level key.
        assert set(item.keys()) == {
            "id",
            "status",
            "service",
            "technician",
            "address_label",
            "scheduled_start",
            "scheduled_end",
            "created_at",
            "price",
            "ui",
        }
        assert item["id"] == booking.id
        assert item["status"] == JobBooking.STATUS_CONFIRMED
        assert set(item["service"].keys()) == {"name", "icon_name"}
        assert set(item["technician"].keys()) == {
            "id",
            "display_name",
            "profile_picture_url",
        }
        assert set(item["price"].keys()) == {"amount", "context", "ui_label"}
        assert set(item["ui"].keys()) == {"badge_text", "badge_tone", "headline"}
        assert item["price"]["ui_label"] == "Rs. 2,500"
        assert item["address_label"] == "Home — Gulberg, Lahore"

    def test_default_segment_is_upcoming(self):
        # No explicit ?segment= → upcoming. Past rows excluded.
        user = UserFactory()
        upcoming = _booking_in_future(
            customer=user, status=JobBooking.STATUS_CONFIRMED,
        )
        _booking_in_past(customer=user, status=JobBooking.STATUS_COMPLETED)
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL)
        ids = [it["id"] for it in response.json()["items"]]
        assert ids == [upcoming.id]

    def test_explicit_segment_past(self):
        user = UserFactory()
        _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)
        completed = _booking_in_past(
            customer=user, status=JobBooking.STATUS_COMPLETED,
        )
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL, {"segment": "past"})
        ids = [it["id"] for it in response.json()["items"]]
        assert ids == [completed.id]

    def test_server_time_is_iso8601(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL)
        # Round-trip to confirm ISO-8601-parseable.
        from datetime import datetime as _dt

        parsed = _dt.fromisoformat(response.json()["server_time"])
        assert parsed is not None

    def test_empty_user_returns_empty_envelope(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL)
        body = response.json()
        assert body["items"] == []
        assert body["next_cursor"] is None
        assert body["has_more"] is False


# =====================================================================
# Pagination
# =====================================================================


class TestPagination:

    def setup_method(self):
        self.client = APIClient()

    def test_cursor_round_trip(self):
        user = UserFactory()
        bookings = []
        for i in range(5):
            b = _booking_in_future(customer=user)
            b.scheduled_start = timezone.now() + datetime.timedelta(days=i + 1)
            b.scheduled_end = b.scheduled_start + datetime.timedelta(hours=1)
            b.save()
            bookings.append(b)
        self.client.force_authenticate(user=user)

        page1 = self.client.get(LIST_URL, {"page_size": 2}).json()
        assert page1["has_more"] is True
        assert page1["next_cursor"] is not None
        assert len(page1["items"]) == 2

        page2 = self.client.get(
            LIST_URL,
            {"page_size": 2, "cursor": page1["next_cursor"]},
        ).json()
        assert page2["has_more"] is True
        assert len(page2["items"]) == 2

        page3 = self.client.get(
            LIST_URL,
            {"page_size": 2, "cursor": page2["next_cursor"]},
        ).json()
        assert page3["has_more"] is False
        assert page3["next_cursor"] is None
        assert len(page3["items"]) == 1

        # Concatenated pages reconstruct the full ordered list.
        all_ids = (
            [it["id"] for it in page1["items"]]
            + [it["id"] for it in page2["items"]]
            + [it["id"] for it in page3["items"]]
        )
        assert all_ids == [b.id for b in bookings]

    def test_page_size_clamped_at_max(self):
        user = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=user)
        self.client.force_authenticate(user=user)

        # 51 (just over max=50). Should be 400 — DRF IntegerField with
        # max_value enforces.
        response = self.client.get(LIST_URL, {"page_size": 51})
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "validation_error"

    def test_page_size_below_one_400(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"page_size": 0})
        assert response.status_code == 400
        assert response.json()["code"] == "validation_error"


# =====================================================================
# Error envelopes
# =====================================================================


class TestErrorEnvelopes:

    def setup_method(self):
        self.client = APIClient()

    def test_invalid_cursor_400(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"cursor": "@@@garbage@@@"})
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "invalid_cursor"
        assert "cursor" in body["errors"]

    def test_invalid_status_filter_400(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"status": "WAITING,GHOSTED"})
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "invalid_status_filter"
        assert "status" in body["errors"]

    def test_invalid_segment_value_400(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"segment": "tomorrow"})
        assert response.status_code == 400
        body = response.json()
        # ChoiceField validation surfaces as the generic envelope code.
        assert body["code"] == "validation_error"
        assert "segment" in body["errors"]

    def test_malformed_since_400(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"since": "not-an-iso-date"})
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "validation_error"
        assert "since" in body["errors"]


# =====================================================================
# IDOR — user A's bookings invisible to user B
# =====================================================================


class TestIdor:

    def setup_method(self):
        self.client = APIClient()

    def test_list_does_not_leak_other_users_bookings(self):
        a = UserFactory()
        b = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=b)

        self.client.force_authenticate(user=a)
        response = self.client.get(LIST_URL)
        assert response.status_code == 200
        assert response.json()["items"] == []

    def test_counts_are_per_user(self):
        a = UserFactory()
        b = UserFactory()
        for _ in range(3):
            _booking_in_future(customer=b)
        for _ in range(1):
            _booking_in_future(customer=a)

        self.client.force_authenticate(user=a)
        a_counts = self.client.get(COUNTS_URL).json()
        self.client.force_authenticate(user=b)
        b_counts = self.client.get(COUNTS_URL).json()

        assert a_counts["upcoming"] == 1
        assert b_counts["upcoming"] == 3


# =====================================================================
# Status filter override
# =====================================================================


class TestStatusFilter:

    def setup_method(self):
        self.client = APIClient()

    def test_explicit_csv_overrides_segment(self):
        user = UserFactory()
        confirmed_aged = _booking_in_past(
            customer=user, status=JobBooking.STATUS_CONFIRMED,
        )
        # Active confirmed (segment=upcoming default would catch this).
        _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)

        self.client.force_authenticate(user=user)
        # status=CONFIRMED with no segment should drop the time-window
        # predicate and surface BOTH confirmed rows. We just assert the
        # aged-out one shows up — that's the segment-only path's blind spot.
        response = self.client.get(LIST_URL, {"status": "CONFIRMED"})
        assert response.status_code == 200
        ids = {it["id"] for it in response.json()["items"]}
        assert confirmed_aged.id in ids

    def test_csv_is_case_insensitive(self):
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)
        self.client.force_authenticate(user=user)
        response = self.client.get(LIST_URL, {"status": "confirmed"})
        assert response.status_code == 200
        ids = [it["id"] for it in response.json()["items"]]
        assert ids == [b.id]


# =====================================================================
# REJECTED reason resolution via EventLog
# =====================================================================


class TestRejectedReasonOnApi:

    def setup_method(self):
        self.client = APIClient()

    def test_technician_declined_surfaces_unavailable_copy(self):
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _make_rejection_log(
            user=user, job_id=b.id, reason="technician_declined",
        )
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL, {"segment": "past"})
        item = response.json()["items"][0]
        assert item["ui"]["badge_text"] == "Unavailable"
        assert item["ui"]["badge_tone"] == "negative"

    def test_sla_timeout_surfaces_timed_out_copy(self):
        user = UserFactory()
        b = _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _make_rejection_log(user=user, job_id=b.id, reason="sla_timeout")
        self.client.force_authenticate(user=user)

        response = self.client.get(LIST_URL, {"segment": "past"})
        item = response.json()["items"][0]
        assert item["ui"]["badge_text"] == "Timed out"
        assert "didn't respond in time" in item["ui"]["headline"]


# =====================================================================
# Counts endpoint
# =====================================================================


class TestCountsApi:

    def setup_method(self):
        self.client = APIClient()

    def test_returns_documented_envelope(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(COUNTS_URL)
        assert response.status_code == 200
        body = response.json()
        assert set(body.keys()) == {"upcoming", "past", "server_time"}

    def test_counts_match_list_segments(self):
        user = UserFactory()
        # 2 upcoming, 3 past (terminal + aged-out).
        _booking_in_future(customer=user, status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        _booking_in_future(customer=user, status=JobBooking.STATUS_CONFIRMED)
        _booking_in_future(customer=user, status=JobBooking.STATUS_REJECTED)
        _booking_in_past(customer=user, status=JobBooking.STATUS_COMPLETED)
        _booking_in_past(customer=user, status=JobBooking.STATUS_CONFIRMED)

        self.client.force_authenticate(user=user)
        body = self.client.get(COUNTS_URL).json()
        assert body["upcoming"] == 2
        assert body["past"] == 3

    def test_zero_when_no_bookings(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        body = self.client.get(COUNTS_URL).json()
        assert body == {
            "upcoming": 0,
            "past": 0,
            "server_time": body["server_time"],
        }


# =====================================================================
# Method routing — only GET is allowed
# =====================================================================


class TestMethodRouting:

    def setup_method(self):
        self.client = APIClient()

    def test_post_to_list_405(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.post(LIST_URL, {}, format="json")
        # DRF's default 405 still flows through the standard envelope.
        assert response.status_code == 405

    def test_post_to_counts_405(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.post(COUNTS_URL, {}, format="json")
        assert response.status_code == 405
