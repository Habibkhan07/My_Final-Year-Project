"""Termination endpoints — customer/tech cancel, no-show, dispute, reschedule."""
from __future__ import annotations

from rest_framework import status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.terminations.serializers import (
    CustomerCancelResponseSerializer,
    MarkNoShowResponseSerializer,
    OpenDisputeRequestSerializer,
    OpenDisputeResponseSerializer,
    RescheduleRequestSerializer,
    RescheduleResponseSerializer,
    TechCancelRequestSerializer,
    TechCancelResponseSerializer,
)
from bookings.models import JobBooking, SupportTicket
from bookings.services import orchestrator


def _403(code: str, message: str) -> Response:
    return Response(
        {
            "status": status.HTTP_403_FORBIDDEN,
            "code": code,
            "message": message,
            "errors": {},
        },
        status=status.HTTP_403_FORBIDDEN,
    )


def _booking_not_found() -> Response:
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
    """Customer-side IDOR gate by booking relationship.

    Replaces the legacy ``if hasattr(request.user, 'tech_profile')`` early-out
    which locked dual-role users (technician + customer on different
    bookings) out of customer-side actions on their own bookings. The
    unified-User model permits one user to play both roles across the
    platform; the only thing that matters here is THIS booking's
    customer_id matching the caller. Returns ``None`` to continue, or a
    canonical 404/403 ``not_a_customer`` envelope otherwise.
    """
    try:
        booking = JobBooking.objects.only("id", "customer_id").get(id=booking_id)
    except JobBooking.DoesNotExist:
        return _booking_not_found()
    if booking.customer_id != request.user.id:
        return _403("not_a_customer", "Customer-only action.")
    return None


class CustomerCancelView(APIView):
    """``POST /api/bookings/<booking_id>/cancel/`` — customer-only."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: customer-only by booking relationship. Orchestrator's
        # _require_customer is the authoritative IDOR check; this
        # pre-gate keeps the canonical 403 ``not_a_customer`` wire code
        # for non-customers and emits 404 for missing bookings before
        # the orchestrator's atomic block opens.
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate

        booking = orchestrator.cancel_by_customer(
            booking_id=booking_id,
            customer_user=request.user,
        )
        return Response(
            CustomerCancelResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class TechCancelView(APIView):
    """``POST /api/bookings/<booking_id>/tech-cancel/`` — tech-only."""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        if not hasattr(request.user, "tech_profile"):
            return _403("not_a_technician", "Tech-only action.")

        # ``reason`` is parsed for future use but the current
        # orchestrator function does not accept a reason argument —
        # it writes a fixed ``technician_cancelled`` cancel_reason.
        req = TechCancelRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        booking = orchestrator.cancel_by_tech(
            booking_id=booking_id,
            technician_user=request.user,
        )
        return Response(
            TechCancelResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class MarkNoShowView(APIView):
    """``POST /api/bookings/<booking_id>/no-show/`` — either party.

    The actor role is derived from the authenticated user's relationship
    to the booking, NEVER from a body field. A tech sending
    ``actor_role='customer'`` must not flip a customer-side no-show.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # We need to check whether the user is the customer or the tech
        # of THIS booking before calling the orchestrator (which expects
        # an explicit actor_role kwarg). A user who is neither falls
        # through to 403; the orchestrator's ``_require_*`` guards are
        # the authoritative IDOR check, but reaching them with the
        # wrong actor_role would surface ``not_assigned_to_you``
        # which is the wrong code for "you are neither party."
        try:
            booking = JobBooking.objects.only(
                "id", "status", "customer_id", "technician_id",
            ).select_related("technician").get(id=booking_id)
        except JobBooking.DoesNotExist:
            return Response(
                {
                    "status": status.HTTP_404_NOT_FOUND,
                    "code": "booking_not_found",
                    "message": "Booking not found.",
                    "errors": {},
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        if booking.customer_id == request.user.id:
            actor_role = "customer"
        elif (
            hasattr(request.user, "tech_profile")
            and booking.technician.user_id == request.user.id
        ):
            actor_role = "tech"
        else:
            return _403(
                "not_a_participant",
                "You are not a participant on this booking.",
            )

        booking = orchestrator.mark_no_show(
            booking_id=booking_id,
            actor_user=request.user,
            actor_role=actor_role,
        )
        return Response(
            MarkNoShowResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class OpenDisputeView(APIView):
    """``POST /api/bookings/<booking_id>/disputes/`` — multipart.

    Either party can open. Optional photo evidence (≤5 MB).
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, booking_id: int):
        # Either-party — defer the actual authorization to the
        # orchestrator (it raises ``not_assigned_to_you`` if neither).
        req = OpenDisputeRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        ticket = orchestrator.open_dispute(
            booking_id=booking_id,
            opener_user=request.user,
            initial_reason=req.validated_data["initial_reason"],
            photo_file=req.validated_data.get("photo"),
        )

        return Response(
            OpenDisputeResponseSerializer({
                "ticket_id": ticket.id,
                "booking_id": ticket.booking_id,
                "booking_status": ticket.booking.status,
                "dispute_intake_method": SupportTicket.INTAKE_FORM,
            }).data,
            status=status.HTTP_201_CREATED,
        )


class RescheduleView(APIView):
    """``POST /api/bookings/<booking_id>/reschedule/`` — customer-only.

    Cancels the original booking and creates a child in
    ``AWAITING_TECH_ACCEPT`` for the new time window. The orchestrator
    locks the technician profile and re-checks slot availability inside
    the atomic block.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate

        req = RescheduleRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        child = orchestrator.reschedule(
            original_booking_id=booking_id,
            customer_user=request.user,
            new_scheduled_start=req.validated_data["new_scheduled_start"],
            new_scheduled_end=req.validated_data["new_scheduled_end"],
        )

        # Orchestrator returns the child booking; the original is
        # CANCELLED (orchestrator stamped status + cancelled_at). The
        # original's status wire string is fixed.
        return Response(
            RescheduleResponseSerializer({
                "original_booking_id": child.parent_booking_id,
                "original_status": JobBooking.STATUS_CANCELLED,
                "child_booking_id": child.id,
                "child_status": child.status,
            }).data,
            status=status.HTTP_201_CREATED,
        )
