"""HTTP-layer tests for the customer review endpoints.

Covers:
    * GET /api/bookings/<id>/review/
        - Unauthenticated → 401.
        - Authenticated, no review yet → ``review: null`` + predefined_tags.
        - Authenticated, review submitted → review echoed.
        - Cross-customer probe → ``review: null`` (no leak).
        - Response shape includes both positive and constructive tag sets.
    * POST /api/bookings/<id>/review/
        - Unauthenticated → 401.
        - Happy path → 201 + serialized review.
        - Non-COMPLETED booking → 400 with ``review_not_eligible``.
        - Already submitted → 409 with ``review_already_submitted``.
        - Wrong owner (IDOR) → 404 with ``booking_not_found``.
        - Invalid rating → 400 (standard DRF validation envelope).
        - Unknown tag → 400 with field error on ``tags``.
        - Profile + per-service performance updated.
    * GET /api/technicians/<id>/reviews/
        - Empty for fresh tech.
        - Newest-first list rendered.
        - Cursor pagination.
"""
from __future__ import annotations

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from bookings.models import JobBooking
from technicians.models import Review, TechnicianProfile, TechnicianServicePerformance
from technicians.services.review_service import submit_review

from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingCompletedFactory, JobBookingConfirmedFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory
from tests.factories.technicians import TechnicianProfileFactory


pytestmark = pytest.mark.django_db


def _completed_booking(customer_user=None, technician=None):
    customer_profile = (
        CustomerProfileFactory(user=customer_user)
        if customer_user
        else CustomerProfileFactory()
    )
    address = CustomerAddressFactory(customer=customer_profile)
    technician = technician or TechnicianProfileFactory(status="APPROVED")
    return JobBookingCompletedFactory(
        customer=customer_profile.user,
        technician=technician,
        address=address,
        status=JobBooking.STATUS_COMPLETED,
    )


# =====================================================================
# GET /api/bookings/<id>/review/
# =====================================================================

class TestBookingReviewGet:

    def setup_method(self):
        self.client = APIClient()

    def test_unauthenticated_returns_401(self):
        booking = _completed_booking()
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.get(url)
        assert response.status_code == 401

    def test_no_review_returns_null_review_with_tags(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.get(url)
        assert response.status_code == 200
        body = response.json()
        assert body["review"] is None
        # Both tag buckets must be present so the FE can swap chips
        # client-side as the user picks a rating.
        assert "positive" in body["predefined_tags"]
        assert "constructive" in body["predefined_tags"]
        positive_keys = {t["key"] for t in body["predefined_tags"]["positive"]}
        assert {"on_time", "professional"}.issubset(positive_keys)

    def test_submitted_review_echoed(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=4, tags=["on_time"], text="Solid work.",
        )
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.get(url)
        assert response.status_code == 200
        body = response.json()
        assert body["review"] is not None
        assert body["review"]["rating"] == 4
        assert body["review"]["tags"] == ["on_time"]
        assert body["review"]["text"] == "Solid work."

    def test_cross_customer_probe_returns_null(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        intruder = UserFactory()
        self.client.force_authenticate(user=intruder)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.get(url)
        assert response.status_code == 200
        # No leak: intruder sees null, NOT "review already exists".
        assert response.json()["review"] is None


# =====================================================================
# POST /api/bookings/<id>/review/
# =====================================================================

class TestBookingReviewPost:

    def setup_method(self):
        self.client = APIClient()

    def test_unauthenticated_returns_401(self):
        booking = _completed_booking()
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(url, {"rating": 5}, format="json")
        assert response.status_code == 401

    def test_happy_path_returns_201_with_review(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(
            url,
            {"rating": 5, "tags": ["on_time", "professional"], "text": "Great"},
            format="json",
        )
        assert response.status_code == 201
        body = response.json()
        assert body["rating"] == 5
        assert body["tags"] == ["on_time", "professional"]
        assert body["text"] == "Great"
        assert "reviewer_name" in body
        # Persisted.
        assert Review.objects.filter(booking_id=booking.id).count() == 1

    def test_non_completed_booking_returns_400(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(
            url, {"rating": 5, "tags": [], "text": ""}, format="json",
        )
        assert response.status_code == 400
        body = response.json()
        assert body["code"] == "review_not_eligible"
        assert body["errors"]["booking_status"] == [JobBooking.STATUS_CONFIRMED]

    def test_double_submit_returns_409(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        first = self.client.post(url, {"rating": 5}, format="json")
        assert first.status_code == 201

        second = self.client.post(url, {"rating": 1}, format="json")
        assert second.status_code == 409
        assert second.json()["code"] == "review_already_submitted"
        # No second row.
        assert Review.objects.filter(booking_id=booking.id).count() == 1
        # First-write rating preserved.
        assert Review.objects.get(booking_id=booking.id).rating == 5

    def test_other_customers_booking_returns_404(self):
        booking = _completed_booking()
        intruder = UserFactory()
        self.client.force_authenticate(user=intruder)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(url, {"rating": 5}, format="json")
        assert response.status_code == 404
        assert response.json()["code"] == "booking_not_found"

    def test_rating_out_of_range_returns_400(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(url, {"rating": 6}, format="json")
        assert response.status_code == 400
        # DRF's default validation envelope keys field errors under
        # the field name. Just assert the field is flagged.
        body = response.json()
        assert "rating" in body.get("errors", {})

    def test_unknown_tag_returns_400_with_field_error(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        response = self.client.post(
            url, {"rating": 5, "tags": ["definitely_not_a_tag"]}, format="json",
        )
        assert response.status_code == 400
        body = response.json()
        assert "tags" in body.get("errors", {})

    def test_profile_and_performance_updated_after_post(self):
        booking = _completed_booking()
        self.client.force_authenticate(user=booking.customer)
        url = reverse("booking-review", kwargs={"booking_id": booking.id})
        self.client.post(url, {"rating": 4}, format="json")

        tech = TechnicianProfile.objects.get(pk=booking.technician_id)
        assert tech.review_count == 1
        assert float(tech.rating_average) == pytest.approx(4.0)

        perf = TechnicianServicePerformance.objects.get(
            technician_id=tech.id, service_id=booking.service_id,
        )
        assert perf.review_count == 1
        assert perf.rating_average == pytest.approx(4.0)


# =====================================================================
# GET /api/technicians/<id>/reviews/
# =====================================================================

class TestTechnicianReviewsList:

    def setup_method(self):
        self.client = APIClient()

    def test_empty_list_for_fresh_tech(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        url = reverse("technician-reviews-list", kwargs={"technician_id": tech.id})
        response = self.client.get(url)
        assert response.status_code == 200
        body = response.json()
        assert body["reviews"] == []
        assert body["next_cursor"] is None
        assert body["has_more"] is False

    def test_newest_first_ordering(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        ratings = []
        for r in (3, 4, 5):
            booking = _completed_booking(technician=tech)
            submit_review(
                booking_id=booking.id, customer_user=booking.customer,
                rating=r, tags=[], text="",
            )
            ratings.append(r)

        url = reverse("technician-reviews-list", kwargs={"technician_id": tech.id})
        response = self.client.get(url)
        body = response.json()
        assert [r["rating"] for r in body["reviews"]] == list(reversed(ratings))

    def test_pagination(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        for r in range(5):
            booking = _completed_booking(technician=tech)
            submit_review(
                booking_id=booking.id, customer_user=booking.customer,
                rating=(r % 5) + 1, tags=[], text="",
            )

        url = reverse("technician-reviews-list", kwargs={"technician_id": tech.id})
        r1 = self.client.get(url + "?page_size=2").json()
        assert len(r1["reviews"]) == 2
        assert r1["has_more"] is True
        assert r1["next_cursor"] is not None

        r2 = self.client.get(url + f"?page_size=2&cursor={r1['next_cursor']}").json()
        assert len(r2["reviews"]) == 2

        # No overlap.
        page1_ids = {r["id"] for r in r1["reviews"]}
        page2_ids = {r["id"] for r in r2["reviews"]}
        assert page1_ids.isdisjoint(page2_ids)

    def test_garbage_cursor_returns_first_page(self):
        # Malformed cursor is a caller error — we degrade gracefully
        # to "no cursor" rather than 500.
        tech = TechnicianProfileFactory(status="APPROVED")
        booking = _completed_booking(technician=tech)
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        url = reverse("technician-reviews-list", kwargs={"technician_id": tech.id})
        response = self.client.get(url + "?cursor=notanint")
        assert response.status_code == 200
        assert len(response.json()["reviews"]) == 1

    def test_no_auth_required(self):
        # Public read so customers can see reviews before booking.
        tech = TechnicianProfileFactory(status="APPROVED")
        url = reverse("technician-reviews-list", kwargs={"technician_id": tech.id})
        response = self.client.get(url)
        assert response.status_code == 200
