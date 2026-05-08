"""Quote endpoints — tech submits, customer decides.

All four views follow the canonical Session-2 shape: permission check
inline, orchestrator delegate, response serializer. The orchestrator
owns the state machine + line-item validation + broadcast.
"""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.quotes.serializers import (
    ApproveQuoteResponseSerializer,
    DeclineQuoteRequestSerializer,
    DeclineQuoteResponseSerializer,
    QuoteResponseSerializer,
    RequestRevisionRequestSerializer,
    RequestRevisionResponseSerializer,
    SubmitQuoteRequestSerializer,
)
from bookings.models import JobBooking
from bookings.services import orchestrator


def _not_a_technician_response() -> Response:
    return Response(
        {
            "status": status.HTTP_403_FORBIDDEN,
            "code": "not_a_technician",
            "message": "Tech-only action.",
            "errors": {},
        },
        status=status.HTTP_403_FORBIDDEN,
    )


def _not_a_customer_response() -> Response:
    return Response(
        {
            "status": status.HTTP_403_FORBIDDEN,
            "code": "not_a_customer",
            "message": "Customer-only action.",
            "errors": {},
        },
        status=status.HTTP_403_FORBIDDEN,
    )


def _booking_not_found_response() -> Response:
    return Response(
        {
            "status": status.HTTP_404_NOT_FOUND,
            "code": "booking_not_found",
            "message": "Booking not found.",
            "errors": {},
        },
        status=status.HTTP_404_NOT_FOUND,
    )


def _reject_if_not_customer(request, booking_id: int) -> Response | None:
    """Customer-side IDOR gate.

    Replaces the legacy ``if hasattr(request.user, 'tech_profile')`` early-out
    which incorrectly locked dual-role users (a technician with a tech_profile
    who is also the customer of THIS booking) out of customer-side actions
    on their own bookings. The unified-User model in CLAUDE.md explicitly
    permits a single user to play both roles across different bookings.

    Decision is by booking relationship, not by user-side flags. Returns
    ``None`` when the caller is the booking's customer, or a canonical
    error response (404 or 403 ``not_a_customer``) otherwise. Wire codes
    are preserved for frontend-side switch compatibility.
    """
    try:
        booking = JobBooking.objects.only("id", "customer_id").get(id=booking_id)
    except JobBooking.DoesNotExist:
        return _booking_not_found_response()
    if booking.customer_id != request.user.id:
        return _not_a_customer_response()
    return None


def _quote_payload(quote, booking_id: int) -> dict:
    """Compose the QuoteResponseSerializer payload from an orchestrator
    return value. Done at the view layer because the orchestrator returns
    the ORM instance and the serializer is shape-driven, not Model-driven.
    """
    return {
        "id": quote.id,
        "booking_id": booking_id,
        "revision_number": quote.revision_number,
        "status": quote.status,
        "total_amount": quote.total_amount,
        "is_upsell": quote.is_upsell,
        "line_items": list(quote.line_items.all().select_related("sub_service")),
        "submitted_at": quote.submitted_at,
    }


class SubmitQuoteView(APIView):
    """``POST /api/bookings/<booking_id>/quotes/`` — tech submits a quote."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: tech-only. Quote band + emptiness checks live in
        # the orchestrator; this view only validates ingress shape.
        if not hasattr(request.user, "tech_profile"):
            return _not_a_technician_response()

        req = SubmitQuoteRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        quote = orchestrator.submit_quote(
            booking_id=booking_id,
            technician_user=request.user,
            line_items=req.validated_data["line_items"],
            is_upsell=req.validated_data["is_upsell"],
        )

        payload = _quote_payload(quote, booking_id=booking_id)
        return Response(
            QuoteResponseSerializer(payload).data,
            status=status.HTTP_201_CREATED,
        )


class ApproveQuoteView(APIView):
    """``POST /api/bookings/<booking_id>/quotes/<quote_id>/approve/``."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int, quote_id: int):
        # SECURITY: customer-only by booking relationship (NOT by
        # ``hasattr(tech_profile)`` — that locks out dual-role users on
        # their own customer bookings). Cross-booking quote ids surface
        # as ``quote_not_found`` from the orchestrator's IDOR-safe fetch.
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate

        booking = orchestrator.approve_quote(
            booking_id=booking_id,
            customer_user=request.user,
            quote_id=quote_id,
        )

        return Response(
            ApproveQuoteResponseSerializer({
                "booking_id": booking.id,
                "status": booking.status,
                "final_cash_to_collect": booking.final_cash_to_collect,
            }).data,
            status=status.HTTP_200_OK,
        )


class DeclineQuoteView(APIView):
    """``POST /api/bookings/<booking_id>/quotes/<quote_id>/decline/``."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int, quote_id: int):
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate

        req = DeclineQuoteRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        booking = orchestrator.decline_quote(
            booking_id=booking_id,
            customer_user=request.user,
            quote_id=quote_id,
            reason=req.validated_data.get("reason", ""),
        )

        return Response(
            DeclineQuoteResponseSerializer({
                "booking_id": booking.id,
                "status": booking.status,
                "final_cash_to_collect": booking.final_cash_to_collect,
            }).data,
            status=status.HTTP_200_OK,
        )


class RequestRevisionView(APIView):
    """``POST /api/bookings/<booking_id>/quotes/<quote_id>/request-revision/``."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int, quote_id: int):
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate

        req = RequestRevisionRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        booking = orchestrator.request_revision(
            booking_id=booking_id,
            customer_user=request.user,
            quote_id=quote_id,
            reason=req.validated_data.get("reason", ""),
        )

        return Response(
            RequestRevisionResponseSerializer({
                "booking_id": booking.id,
                "status": booking.status,
                "superseded_quote_id": quote_id,
            }).data,
            status=status.HTTP_200_OK,
        )
