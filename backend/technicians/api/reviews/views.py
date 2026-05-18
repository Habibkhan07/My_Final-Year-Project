"""HTTP layer for customer reviews.

Three operations, two views:

* ``BookingReviewView`` — owns the per-booking surface.
    * GET → returns the existing review (or null) + the predefined
      tag vocabulary. Customer-scoped.
    * POST → submits a review. Customer-scoped.
* ``TechnicianReviewsListView`` — paginated public list of all
  reviews for a given technician (the "All reviews" sheet on the
  tech profile screen).

Both views are thin: parse, validate, delegate, serialize. No
business rules live here.

SECURITY: every booking-scoped endpoint resolves the booking with
``customer=request.user`` baked into the service-layer query. A
non-owner can never read or write a review for someone else's
booking — the service returns ``BookingNotFoundForCustomerError``
(404) and the wire response is indistinguishable from a real
404, preventing IDOR probing.
"""
from __future__ import annotations

from rest_framework import status as drf_status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.selectors.review_selectors import (
    get_review_for_booking,
    list_reviews_for_technician,
)
from technicians.services.review_service import submit_review

from .serializers import (
    BookingReviewResponseSerializer,
    ReviewDetailSerializer,
    ReviewSubmitSerializer,
    TechnicianReviewsPageSerializer,
)


class BookingReviewView(APIView):
    """GET + POST a review for a single booking. Auth required.

    URL kwarg: ``booking_id`` (int). Resolved scoped to ``request.user``
    at the service layer; a non-owner gets a clean 404 envelope.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request: Request, booking_id: int) -> Response:
        # The selector is scoped to ``reviewer=request.user``, so a
        # cross-customer probe (correct booking_id + wrong session)
        # returns null — same as a never-submitted review. Together
        # with the POST path's customer-scoped fetch, this never
        # reveals whether someone ELSE has reviewed a booking the
        # caller doesn't own.
        existing = get_review_for_booking(
            booking_id=booking_id,
            customer_user=request.user,
        )
        body = BookingReviewResponseSerializer({
            "review": existing,
            "predefined_tags": None,  # SerializerMethodField fills it.
        }).data
        return Response(body, status=drf_status.HTTP_200_OK)

    def post(self, request: Request, booking_id: int) -> Response:
        write_ser = ReviewSubmitSerializer(data=request.data)
        write_ser.is_valid(raise_exception=True)
        # Service does the heavy lifting (locking, status check,
        # idempotency check, profile + performance recompute). Any
        # raised exception flows through the project's canonical
        # error envelope handler — no try/except here.
        review = submit_review(
            booking_id=booking_id,
            customer_user=request.user,
            rating=write_ser.validated_data["rating"],
            tags=write_ser.validated_data.get("tags", []),
            text=write_ser.validated_data.get("text", ""),
        )
        return Response(
            ReviewDetailSerializer(review).data,
            status=drf_status.HTTP_201_CREATED,
        )


class TechnicianReviewsListView(APIView):
    """Paginated public list of reviews for a technician.

    Public-readable so the customer can see reviews on the tech
    profile screen pre-booking. No authentication required — there
    is no sensitive data (reviewer names are first + last-initial,
    booking ids are not exposed).

    Query params:
        page_size (int, default 20, hard cap 100)
        cursor    (int, optional — id of the last row of prior page)
    """

    permission_classes = [AllowAny]

    def get(self, request: Request, technician_id: int) -> Response:
        # ``int(...)`` raises ValueError on garbage input → DRF's
        # default exception handler turns that into a 400. Keeping it
        # naive: a malformed cursor is a caller bug, not a security
        # event worth a custom typed exception.
        try:
            page_size = int(request.query_params.get("page_size", 20))
        except (TypeError, ValueError):
            page_size = 20
        cursor_raw = request.query_params.get("cursor")
        try:
            cursor = int(cursor_raw) if cursor_raw is not None else None
        except (TypeError, ValueError):
            cursor = None

        page = list_reviews_for_technician(
            technician_id=technician_id,
            page_size=page_size,
            cursor=cursor,
        )
        body = TechnicianReviewsPageSerializer({
            "reviews": page.reviews,
            "next_cursor": page.next_cursor,
            "has_more": page.has_more,
        }).data
        return Response(body, status=drf_status.HTTP_200_OK)
