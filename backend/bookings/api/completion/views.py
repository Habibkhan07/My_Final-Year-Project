"""Combined complete + cash collection endpoint."""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.completion.serializers import (
    ConfirmCashReceivedRequestSerializer,
    ConfirmCashReceivedResponseSerializer,
)
from bookings.services import orchestrator


class ConfirmCashReceivedView(APIView):
    """``POST /api/bookings/<booking_id>/confirm-cash-received/``

    Tech-only. Combined ``IN_PROGRESS → COMPLETED`` + cash stamp.
    Idempotent on already-COMPLETED (orchestrator short-circuits).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: Tech-only — ``hasattr(user, 'tech_profile')`` is the
        # cheap pre-check; the orchestrator's ``_require_assigned_tech``
        # is the IDOR-safe authoritative check.
        if not hasattr(request.user, "tech_profile"):
            return Response(
                {
                    "status": status.HTTP_403_FORBIDDEN,
                    "code": "not_a_technician",
                    "message": "Tech-only action.",
                    "errors": {},
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        req = ConfirmCashReceivedRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        booking = orchestrator.mark_complete_with_cash(
            booking_id=booking_id,
            technician_user=request.user,
            cash_amount=req.validated_data["amount"],
            method=req.validated_data["method"],
        )
        return Response(
            ConfirmCashReceivedResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )
