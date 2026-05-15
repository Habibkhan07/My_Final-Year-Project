"""HTTP-level tests for the tech-side scheduled-jobs views.

Covers auth gates, query-param validation, wire-shape contract, and the
error envelope. The selector-level correctness lives in
``tests/technicians/selectors/test_scheduled_jobs.py``; these tests
exercise the view's parse + delegate behavior.
"""
from __future__ import annotations

import base64

import pytest
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from bookings.models import JobBooking
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingConfirmedFactory,
)
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


LIST_URL_NAME = "tech-scheduled-jobs-list"
COUNTS_URL_NAME = "tech-scheduled-jobs-counts"


# ─────────────────────────────────────────────────────────────────────────
# List view — auth, happy paths, query param errors.
# ─────────────────────────────────────────────────────────────────────────


class TestScheduledJobsListViewAuth:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse(LIST_URL_NAME)

    def test_anonymous_returns_401(self):
        response = self.client.get(self.url)
        assert response.status_code == 401

    def test_non_technician_returns_403_envelope(self):
        """A customer-only user (no ``tech_profile``) must hit the
        permission_denied envelope — same shape the dashboard view uses."""
        user = UserFactory()  # no TechnicianProfile attached
        self.client.force_authenticate(user=user)

        response = self.client.get(self.url)

        assert response.status_code == 403
        body = response.json()
        assert body["code"] == "permission_denied"
        assert body["status"] == 403
        assert "user" in body["errors"]


class TestScheduledJobsListViewHappy:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse(LIST_URL_NAME)

    def _authed(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)
        return tech

    def test_default_segment_is_upcoming(self):
        tech = self._authed()
        future = timezone.now() + timezone.timedelta(hours=2)
        JobBookingConfirmedFactory(
            technician=tech,
            scheduled_start=future - timezone.timedelta(hours=1),
            scheduled_end=future,
        )
        JobBookingCompletedFactory(technician=tech)

        response = self.client.get(self.url)

        assert response.status_code == 200
        body = response.json()
        # Default is upcoming; the completed row should not appear.
        assert len(body["items"]) == 1
        assert body["items"][0]["status"] == JobBooking.STATUS_CONFIRMED

    def test_segment_past_returns_terminal_rows(self):
        tech = self._authed()
        JobBookingCompletedFactory(technician=tech)

        response = self.client.get(self.url, {"segment": "past"})

        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 1
        assert body["items"][0]["status"] == JobBooking.STATUS_COMPLETED

    def test_cursor_pagination_round_trip(self):
        """Two-page split via cursor; pages MUST NOT overlap and MUST
        together cover the full set."""
        tech = self._authed()
        for _ in range(5):
            JobBookingCompletedFactory(technician=tech)

        page1 = self.client.get(self.url, {"segment": "past", "page_size": 2}).json()
        assert page1["has_more"] is True
        page2 = self.client.get(
            self.url,
            {"segment": "past", "page_size": 2, "cursor": page1["next_cursor"]},
        ).json()

        page1_ids = {item["id"] for item in page1["items"]}
        page2_ids = {item["id"] for item in page2["items"]}
        assert not (page1_ids & page2_ids)
        assert len(page1_ids) == 2
        assert len(page2_ids) == 2

    def test_response_shape(self):
        """Every documented top-level + per-item field is present. This
        is the wire contract the Flutter mapper depends on."""
        tech = self._authed()
        JobBookingCompletedFactory(technician=tech)

        response = self.client.get(self.url, {"segment": "past"})

        body = response.json()
        assert set(body.keys()) == {"items", "next_cursor", "has_more", "server_time"}
        item = body["items"][0]
        assert set(item.keys()) == {
            "id",
            "status",
            "service",
            "customer",
            "address_label",
            "scheduled_start",
            "scheduled_end",
            "created_at",
            "payout",
            "ui",
        }
        assert set(item["service"].keys()) == {"name", "icon_name"}
        assert set(item["customer"].keys()) == {
            "id",
            "display_name",
            "profile_picture_url",
        }
        assert set(item["payout"].keys()) == {"amount", "context", "ui_label"}
        assert set(item["ui"].keys()) == {"badge_text", "badge_tone", "headline"}
        # CustomerProfile has no profile_picture field in v1.
        assert item["customer"]["profile_picture_url"] is None


class TestScheduledJobsListViewErrors:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse(LIST_URL_NAME)
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

    def test_invalid_segment(self):
        response = self.client.get(self.url, {"segment": "garbage"})
        body = response.json()
        assert response.status_code == 400
        assert body["code"] == "validation_error"
        assert "segment" in body["errors"]

    def test_invalid_status_filter_uses_dedicated_code(self):
        response = self.client.get(self.url, {"status": "WAITING"})
        body = response.json()
        assert response.status_code == 400
        assert body["code"] == "invalid_status_filter"
        assert "WAITING" in body["errors"]["status"][0]

    @pytest.mark.parametrize(
        "bad_cursor",
        [
            "not-base64-at-all!!!",
            # Valid base64, garbage JSON inside.
            base64.urlsafe_b64encode(b"{not json").rstrip(b"=").decode("ascii"),
            # Valid base64 + valid JSON, but missing the required ``id`` key.
            base64.urlsafe_b64encode(b'{"ss":"2026-01-01T00:00:00+00:00"}')
            .rstrip(b"=")
            .decode("ascii"),
        ],
    )
    def test_invalid_cursor(self, bad_cursor):
        response = self.client.get(self.url, {"cursor": bad_cursor})
        body = response.json()
        assert response.status_code == 400
        assert body["code"] == "invalid_cursor"

    @pytest.mark.parametrize("bad_page_size", ["0", "-5", "abc", "99"])
    def test_invalid_page_size(self, bad_page_size):
        response = self.client.get(self.url, {"page_size": bad_page_size})
        body = response.json()
        assert response.status_code == 400
        assert body["code"] == "validation_error"
        assert "page_size" in body["errors"]

    @pytest.mark.parametrize(
        "bad_since",
        [
            "not-a-date",
            # Naive datetime — rejected because comparing it against
            # tz-aware created_at triggers Django's RuntimeWarning.
            "2026-01-01T00:00:00",
        ],
    )
    def test_invalid_since(self, bad_since):
        response = self.client.get(self.url, {"since": bad_since})
        body = response.json()
        assert response.status_code == 400
        assert body["code"] == "validation_error"
        assert "since" in body["errors"]


# ─────────────────────────────────────────────────────────────────────────
# Counts view — auth + shape.
# ─────────────────────────────────────────────────────────────────────────


class TestScheduledJobsCountsView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse(COUNTS_URL_NAME)

    def test_anonymous_returns_401(self):
        response = self.client.get(self.url)
        assert response.status_code == 401

    def test_non_technician_returns_403(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(self.url)
        assert response.status_code == 403
        assert response.json()["code"] == "permission_denied"

    def test_response_shape(self):
        tech = TechnicianProfileFactory()
        JobBookingCompletedFactory(technician=tech)
        JobBookingCompletedFactory(technician=tech)
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        body = response.json()
        assert set(body.keys()) == {"upcoming", "past", "server_time"}
        assert body["past"] == 2
        assert body["upcoming"] == 0
