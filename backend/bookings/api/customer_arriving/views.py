"""Customer-side ARRIVED acknowledgement — "I'm coming out".

InDrive-style meeting flow. When the tech reaches the address pin they
don't knock the door (Pakistani urban reality — gated compounds, joint
families); they wait at the pin while the customer walks out. This
endpoint records that the customer noticed and is heading out so the
tech's UI flips from amber "waiting for customer" to green "customer
is coming".

Idempotent on re-tap (a stale UI push could fire this twice).
Status-gated to ARRIVED — re-ACK on a moved-on booking is rejected so
a stray tap can't resurrect or pollute later phases.
"""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.customer_arriving.serializers import (
    CustomerArrivingResponseSerializer,
)
from bookings.services import orchestrator


class CustomerArrivingView(APIView):
    """``POST /api/bookings/<booking_id>/customer-arriving/``

    Customer-only. Stamps ``customer_acknowledged_arrival_at`` and
    broadcasts ``CUSTOMER_ARRIVING`` to the assigned tech. Returns the
    updated booking snapshot so the customer's UI can flip to the
    "✓ Notified" state without a follow-up GET.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: customer-only — the orchestrator's ``_require_customer``
        # is the authoritative IDOR guard. No status check needed here;
        # the service rejects out-of-state acks via the canonical envelope.
        booking = orchestrator.customer_arriving(
            booking_id=booking_id,
            customer_user=request.user,
        )
        return Response(
            CustomerArrivingResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )
