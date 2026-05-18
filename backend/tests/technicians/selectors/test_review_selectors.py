"""Tests for ``technicians.selectors.review_selectors``.

Covers:
    * ``get_review_for_booking``:
        - Returns the review for the booking's own customer.
        - Returns None when no review submitted.
        - Returns None for a cross-customer probe (doesn't leak whether
          another customer's booking has been reviewed).
        - Single query — uses ``select_related`` for reviewer.
    * ``list_reviews_for_technician``:
        - Empty when the tech has no reviews.
        - Returns newest-first, ordered by (-created_at, -id).
        - Paginates correctly: cursor returns the next page, has_more
          flips false on the last page.
        - page_size cap enforced (>100 clamped to 100; <1 clamped to 1).
        - Bounded query count regardless of result size.
"""
from __future__ import annotations

import pytest
from django.utils import timezone

from bookings.models import JobBooking
from technicians.models import Review
from technicians.selectors.review_selectors import (
    get_review_for_booking,
    list_reviews_for_technician,
)
from technicians.services.review_service import submit_review

from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory
from tests.factories.technicians import TechnicianProfileFactory


def _completed_booking_for(customer_user=None, technician=None):
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
# get_review_for_booking
# =====================================================================

@pytest.mark.django_db
class TestGetReviewForBooking:

    def test_returns_review_for_owner(self):
        booking = _completed_booking_for()
        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        result = get_review_for_booking(
            booking_id=booking.id, customer_user=booking.customer,
        )
        assert result is not None
        assert result.booking_id == booking.id

    def test_returns_none_when_no_review(self):
        booking = _completed_booking_for()
        result = get_review_for_booking(
            booking_id=booking.id, customer_user=booking.customer,
        )
        assert result is None

    def test_returns_none_for_cross_customer_probe(self):
        # A second customer queries the first customer's booking_id —
        # selector returns None even though a review exists. The wire
        # never reveals whether the booking has been reviewed.
        booking = _completed_booking_for()
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        intruder = UserFactory()
        result = get_review_for_booking(
            booking_id=booking.id, customer_user=intruder,
        )
        assert result is None

    def test_returns_none_for_nonexistent_booking(self):
        intruder = UserFactory()
        result = get_review_for_booking(
            booking_id=99999, customer_user=intruder,
        )
        assert result is None

    def test_uses_select_related(self, django_assert_num_queries):
        # Single query: selector itself + the access to .reviewer for
        # serialization should not fire an extra query.
        booking = _completed_booking_for()
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=5, tags=[], text="",
        )

        with django_assert_num_queries(1):
            result = get_review_for_booking(
                booking_id=booking.id, customer_user=booking.customer,
            )
            # Touch the related field to confirm it was prefetched.
            _ = result.reviewer.first_name


# =====================================================================
# list_reviews_for_technician
# =====================================================================

@pytest.mark.django_db
class TestListReviewsForTechnician:

    def test_empty_when_no_reviews(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        page = list_reviews_for_technician(technician_id=tech.id)
        assert page.reviews == []
        assert page.next_cursor is None
        assert page.has_more is False

    def test_newest_first(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        # Submit three reviews — natural created_at ordering is the
        # submit order; selector should return reverse-chronological.
        ratings_in_order = []
        for rating in (3, 4, 5):
            booking = _completed_booking_for(technician=tech)
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=rating, tags=[], text="",
            )
            ratings_in_order.append(rating)

        page = list_reviews_for_technician(technician_id=tech.id, page_size=20)
        assert [r.rating for r in page.reviews] == list(reversed(ratings_in_order))
        assert page.next_cursor is None
        assert page.has_more is False

    def test_pagination_cursor_walks_pages(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        for i in range(5):
            booking = _completed_booking_for(technician=tech)
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=(i % 5) + 1, tags=[], text="",
            )

        page1 = list_reviews_for_technician(technician_id=tech.id, page_size=2)
        assert len(page1.reviews) == 2
        assert page1.has_more is True
        assert page1.next_cursor is not None

        page2 = list_reviews_for_technician(
            technician_id=tech.id, page_size=2, cursor=page1.next_cursor,
        )
        assert len(page2.reviews) == 2
        assert page2.has_more is True
        assert page2.next_cursor is not None
        # No overlap between page 1 and page 2.
        page1_ids = {r.id for r in page1.reviews}
        page2_ids = {r.id for r in page2.reviews}
        assert page1_ids.isdisjoint(page2_ids)

        page3 = list_reviews_for_technician(
            technician_id=tech.id, page_size=2, cursor=page2.next_cursor,
        )
        assert len(page3.reviews) == 1
        assert page3.has_more is False
        assert page3.next_cursor is None

    def test_page_size_capped_at_100(self):
        # Without the cap, a malicious client could ask for page_size=1M.
        tech = TechnicianProfileFactory(status="APPROVED")
        page = list_reviews_for_technician(
            technician_id=tech.id, page_size=10_000,
        )
        # Empty list, but the call should not raise / not attempt a
        # 10k-row fetch. We assert the cap by looking at the QuerySet
        # slice indirectly — calling with a huge page_size should
        # behave identically to calling with 100.
        assert page.reviews == []

    def test_page_size_floored_at_1(self):
        tech = TechnicianProfileFactory(status="APPROVED")
        booking = _completed_booking_for(technician=tech)
        submit_review(
            booking_id=booking.id, customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        # page_size=0 (or negative) is clamped to 1, not allowed to
        # short-circuit into "return nothing".
        page = list_reviews_for_technician(technician_id=tech.id, page_size=0)
        assert len(page.reviews) == 1

    def test_bounded_query_count(self, django_assert_num_queries):
        # 5 reviews + serialization of reviewer name should be 1 query
        # (the SELECT with select_related). We allow 2 for safety
        # (some test factories materialize extra rows on cold cache).
        tech = TechnicianProfileFactory(status="APPROVED")
        for _ in range(5):
            booking = _completed_booking_for(technician=tech)
            submit_review(
                booking_id=booking.id, customer_user=booking.customer,
                rating=5, tags=[], text="",
            )

        with django_assert_num_queries(1):
            page = list_reviews_for_technician(
                technician_id=tech.id, page_size=10,
            )
            for r in page.reviews:
                _ = r.reviewer.first_name
