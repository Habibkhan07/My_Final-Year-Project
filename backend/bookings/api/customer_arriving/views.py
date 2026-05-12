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
from bookings.api.quotes.views import _reject_if_not_customer
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
        # SECURITY: customer-only IDOR pre-gate. Without this, a non-
        # participant authenticated user probing this endpoint would
        # reach `_require_customer` inside the orchestrator and get
        # back a 400 `not_assigned_to_you` for an EXISTING booking but
        # a 404 `booking_not_found` for a missing one — leaking
        # existence by status-code differential. Other customer-side
        # endpoints (cancel, approve_quote, decline_quote,
        # request-revision, reschedule) all collapse both into 404 via
        # `_reject_if_not_customer`; this view is the last hold-out.
        gate = _reject_if_not_customer(request, booking_id)
        if gate is not None:
            return gate
        # The orchestrator's `_require_customer` remains the
        # authoritative guard (defence-in-depth); the pre-gate above
        # only changes which envelope the leaked-existence probe sees.
        booking = orchestrator.customer_arriving(
            booking_id=booking_id,
            customer_user=request.user,
        )
        return Response(
            CustomerArrivingResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )
