"""Tests for ``technicians.services.review_service.submit_review``.

Covers:
    * Happy path: review created, profile + per-service aggregates recomputed.
    * Eligibility gate: only COMPLETED + COMPLETED_INSPECTION_ONLY allowed;
      every other status raises the typed eligibility error.
    * IDOR: a cross-customer booking_id collapses to ``BookingNotFoundForCustomerError``
      (same as a non-existent id — no enumeration leak).
    * Idempotency: a second submit raises ``ReviewAlreadySubmittedError``
      (OneToOne; we short-circuit before the IntegrityError).
    * Input validation: rating out of range, text too long, unknown tag key.
    * Tag dedup + ordering.
    * Multi-review aggregate correctness: 3 ratings → profile and
      per-service rolling averages match ``mean()`` to 2 dp.
    * Sub-service rollup: a booking with a sub_service updates the
      ``TechnicianServicePerformance`` keyed on the parent service.
    * Cross-service isolation: a review for service A does not pollute
      the performance row of service B.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from bookings.models import JobBooking
from technicians.constants.review_tags import POSITIVE_TAGS
from technicians.exceptions import (
    BookingNotEligibleForReviewError,
    BookingNotFoundForCustomerError,
    ReviewAlreadySubmittedError,
)
from technicians.models import (
    Review,
    TechnicianProfile,
    TechnicianServicePerformance,
)
from technicians.services.review_service import submit_review

from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingConfirmedFactory,
    JobBookingFactory,
)
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.customers import CustomerAddressFactory, CustomerProfileFactory
from tests.factories.technicians import TechnicianProfileFactory


def _completed_booking(*, customer=None, technician=None, sub_service=None, service=None):
    """Helper to build a COMPLETED booking with all FKs valid + linked.

    Mirrors the pattern in ``test_job_request_action.py`` — the
    factory chain has enough required fields that inlining the
    construction in every test would obscure intent.
    """
    customer_profile = CustomerProfileFactory(user=customer) if customer else CustomerProfileFactory()
    address = CustomerAddressFactory(customer=customer_profile)
    technician = technician or TechnicianProfileFactory(status="APPROVED")
    kwargs = dict(
        customer=customer_profile.user,
        technician=technician,
        address=address,
        status=JobBooking.STATUS_COMPLETED,
    )
    if service is not None:
        kwargs["service"] = service
    if sub_service is not None:
        kwargs["sub_service"] = sub_service
    return JobBookingCompletedFactory(**kwargs)


@pytest.mark.django_db
class TestSubmitReviewHappyPath:

    def test_creates_review_with_all_fields(self):
        booking = _completed_booking()
        review = submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5,
            tags=["on_time", "professional"],
            text="Great work, would book again.",
        )

        assert review.pk is not None
        assert review.rating == 5
        assert review.tags == ["on_time", "professional"]
        assert review.text == "Great work, would book again."
        assert review.booking_id == booking.id
        assert review.technician_id == booking.technician_id
        assert review.reviewer_id == booking.customer_id

    def test_recomputes_profile_aggregate_to_match_running_average(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=4,
            tags=[],
            text="",
        )
        tech = TechnicianProfile.objects.get(pk=booking.technician_id)
        assert tech.review_count == 1
        assert Decimal(tech.rating_average).quantize(Decimal("0.01")) == Decimal("4.00")

    def test_recomputes_per_service_performance_for_parent_service(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=3,
            tags=[],
            text="",
        )
        perf = TechnicianServicePerformance.objects.get(
            technician_id=booking.technician_id,
            service_id=booking.service_id,
        )
        assert perf.review_count == 1
        assert perf.rating_average == pytest.approx(3.0)

    def test_sub_service_booking_rolls_up_to_parent_service(self):
        parent_service = ServiceFactory()
        sub = SubServiceFactory(service=parent_service)
        booking = _completed_booking(service=parent_service, sub_service=sub)

        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5,
            tags=[],
            text="",
        )

        perf = TechnicianServicePerformance.objects.get(
            technician_id=booking.technician_id,
            service_id=parent_service.id,
        )
        assert perf.review_count == 1
        assert perf.rating_average == pytest.approx(5.0)

    def test_three_reviews_average_correctly(self):
        # Three completed bookings for the same technician + service,
        # ratings 5, 3, 4 → profile + per-service avg == 4.00 exactly.
        tech = TechnicianProfileFactory(status="APPROVED")
        service = ServiceFactory()
        avg_target = 0
        for rating in (5, 3, 4):
            booking = _completed_booking(technician=tech, service=service)
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=rating,
                tags=[],
                text="",
            )
            avg_target += rating

        tech.refresh_from_db()
        assert tech.review_count == 3
        assert Decimal(tech.rating_average).quantize(Decimal("0.01")) == Decimal("4.00")

        perf = TechnicianServicePerformance.objects.get(
            technician_id=tech.id, service_id=service.id
        )
        assert perf.review_count == 3
        assert perf.rating_average == pytest.approx(4.0)

    def test_cross_service_isolation(self):
        # Same tech, two different services. Review on service A must
        # not pollute the performance row for service B.
        tech = TechnicianProfileFactory(status="APPROVED")
        service_a = ServiceFactory()
        service_b = ServiceFactory()

        booking_a = _completed_booking(technician=tech, service=service_a)
        submit_review(
            booking_id=booking_a.id,
            customer_user=booking_a.customer,
            rating=2,
            tags=[],
            text="",
        )

        # Service B has no review → no performance row.
        assert not TechnicianServicePerformance.objects.filter(
            technician=tech, service=service_b
        ).exists()

        # Profile-level (cross-service) average is the single rating.
        tech.refresh_from_db()
        assert tech.review_count == 1
        assert tech.rating_average == pytest.approx(2.0)


@pytest.mark.django_db
class TestSubmitReviewEligibility:

    @pytest.mark.parametrize(
        "status",
        [
            JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_EN_ROUTE,
            JobBooking.STATUS_ARRIVED,
            JobBooking.STATUS_INSPECTING,
            JobBooking.STATUS_QUOTED,
            JobBooking.STATUS_IN_PROGRESS,
            JobBooking.STATUS_TECH_DECLINED,
            JobBooking.STATUS_TECH_NO_RESPONSE,
        ],
    )
    def test_non_terminal_status_rejected(self, status):
        booking = JobBookingConfirmedFactory(status=status)
        with pytest.raises(BookingNotEligibleForReviewError) as exc:
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=5,
                tags=[],
                text="",
            )
        assert exc.value.errors["booking_status"] == [status]

    def test_completed_inspection_only_is_eligible(self):
        booking = _completed_booking()
        booking.status = JobBooking.STATUS_COMPLETED_INSPECTION_ONLY
        booking.save(update_fields=["status"])

        review = submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=4,
            tags=[],
            text="",
        )
        assert review.pk is not None


@pytest.mark.django_db
class TestSubmitReviewIDOR:

    def test_other_customers_booking_collapses_to_not_found(self):
        booking = _completed_booking()
        intruder = UserFactory()
        with pytest.raises(BookingNotFoundForCustomerError):
            submit_review(
                booking_id=booking.id,
                customer_user=intruder,
                rating=5,
                tags=[],
                text="",
            )

    def test_nonexistent_booking_id_same_exception(self):
        intruder = UserFactory()
        with pytest.raises(BookingNotFoundForCustomerError):
            submit_review(
                booking_id=9999999,
                customer_user=intruder,
                rating=5,
                tags=[],
                text="",
            )


@pytest.mark.django_db
class TestSubmitReviewIdempotency:

    def test_second_submit_raises_already_submitted(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5,
            tags=[],
            text="",
        )
        with pytest.raises(ReviewAlreadySubmittedError):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=1,
                tags=[],
                text="",
            )

    def test_second_submit_does_not_create_a_second_row(self):
        booking = _completed_booking()
        submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5, tags=[], text="",
        )
        with pytest.raises(ReviewAlreadySubmittedError):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=1, tags=[], text="",
            )
        assert Review.objects.filter(booking_id=booking.id).count() == 1


@pytest.mark.django_db
class TestSubmitReviewInputValidation:

    def test_rating_below_one_rejected(self):
        booking = _completed_booking()
        with pytest.raises(ValueError, match="rating must be between 1 and 5"):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=0, tags=[], text="",
            )

    def test_rating_above_five_rejected(self):
        booking = _completed_booking()
        with pytest.raises(ValueError, match="rating must be between 1 and 5"):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=6, tags=[], text="",
            )

    def test_rating_non_int_rejected(self):
        booking = _completed_booking()
        with pytest.raises(ValueError, match="rating must be int"):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating="5", tags=[], text="",  # type: ignore[arg-type]
            )

    def test_unknown_tag_key_rejected(self):
        booking = _completed_booking()
        with pytest.raises(ValueError, match="Unknown review tag key"):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=5, tags=["not_a_real_tag"], text="",
            )

    def test_text_over_max_rejected(self):
        booking = _completed_booking()
        with pytest.raises(ValueError, match="text exceeds max length"):
            submit_review(
                booking_id=booking.id,
                customer_user=booking.customer,
                rating=5, tags=[], text="x" * 501,
            )

    def test_duplicate_tags_deduped(self):
        booking = _completed_booking()
        review = submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5,
            tags=["on_time", "on_time", "professional", "on_time"],
            text="",
        )
        # Order preserved, duplicates removed.
        assert review.tags == ["on_time", "professional"]

    def test_all_predefined_positive_tags_accepted(self):
        booking = _completed_booking()
        keys = [t["key"] for t in POSITIVE_TAGS]
        review = submit_review(
            booking_id=booking.id,
            customer_user=booking.customer,
            rating=5,
            tags=keys,
            text="",
        )
        assert review.tags == keys
