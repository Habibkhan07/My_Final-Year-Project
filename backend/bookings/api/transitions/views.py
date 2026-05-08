"""Manual phase-marker endpoints — tech-only.

Each view follows the canonical Session-2 shape (sprint meta §4.0):
permission check inline, orchestrator delegate, response serializer.
``BookingValidationError`` propagates to the standard DRF handler in
``core.common.failures.exception``.

The auto path lives at ``POST /api/bookings/<id>/tech-location/`` and
calls ``auto_transition.evaluate_on_location``; these manual endpoints
exist for fallback (no-GPS techs, frontend retry after auto failure).
"""
from __future__ import annotations

import logging
from math import asin, cos, radians, sin, sqrt

from django.conf import settings
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.transitions.serializers import (
    ArrivedRequestSerializer,
    ArrivedResponseSerializer,
    EnRouteResponseSerializer,
    StartInspectionResponseSerializer,
)
from bookings.services import orchestrator

logger = logging.getLogger(__name__)

# Mirrors auto_transition.ARRIVED_THRESHOLD_METERS so the strict-mode
# geofence here uses the same distance the auto-flip path uses.
_ARRIVED_THRESHOLD_METERS = 100


def _not_a_technician_response() -> Response:
    """403 envelope used by every tech-only view in this module."""
    return Response(
        {
            "status": status.HTTP_403_FORBIDDEN,
            "code": "not_a_technician",
            "message": "Tech-only action.",
            "errors": {},
        },
        status=status.HTTP_403_FORBIDDEN,
    )


def _haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    earth_radius_m = 6_371_000
    phi1, phi2 = radians(lat1), radians(lat2)
    dphi = radians(lat2 - lat1)
    dlambda = radians(lng2 - lng1)
    a = sin(dphi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(dlambda / 2) ** 2
    c = 2 * asin(sqrt(a))
    return earth_radius_m * c


class StartInspectionView(APIView):
    """``POST /api/bookings/<booking_id>/start-inspection/``

    Tech-only. ``ARRIVED → INSPECTING``. Idempotent on already-INSPECTING
    (orchestrator short-circuits the no-op case).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: Tech-only. The orchestrator does an IDOR-safe
        # ``_require_assigned_tech`` check internally, but we early-out
        # for users with no tech_profile so non-techs never reach the
        # service layer (and don't learn whether the booking exists).
        if not hasattr(request.user, "tech_profile"):
            return _not_a_technician_response()

        booking = orchestrator.start_inspection(
            booking_id=booking_id,
            technician_user=request.user,
        )
        return Response(
            StartInspectionResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class EnRouteView(APIView):
    """``POST /api/bookings/<booking_id>/en-route/``

    Tech-only manual override. ``CONFIRMED → EN_ROUTE``. Same orchestrator
    function the auto path calls; ``source='manual'`` is informational.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        if not hasattr(request.user, "tech_profile"):
            return _not_a_technician_response()

        booking = orchestrator.en_route(
            booking_id=booking_id,
            technician_user=request.user,
            source="manual",
        )
        return Response(
            EnRouteResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class ArrivedView(APIView):
    """``POST /api/bookings/<booking_id>/arrived/``

    Tech-only manual override. ``EN_ROUTE → ARRIVED``. Optional body:
    ``current_lat`` / ``current_lng`` for the strict-mode geofence check.

    Strict mode (``BOOKING_GEOFENCE_STRICT=True``): when both coords are
    supplied AND the Haversine distance to the customer address exceeds
    100m, the view rejects with ``400 not_at_customer_location``.
    Lenient mode (default): same mismatch logs a warning but allows the
    transition. The auto path is unaffected — it never auto-flips on a
    mismatch regardless of this flag.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        if not hasattr(request.user, "tech_profile"):
            return _not_a_technician_response()

        req = ArrivedRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)
        current_lat = req.validated_data.get("current_lat")
        current_lng = req.validated_data.get("current_lng")

        if current_lat is not None and current_lng is not None:
            self._maybe_geofence_check(booking_id, current_lat, current_lng)

        booking = orchestrator.arrived(
            booking_id=booking_id,
            technician_user=request.user,
            source="manual",
        )
        return Response(
            ArrivedResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )

    @staticmethod
    def _maybe_geofence_check(booking_id: int, current_lat: float, current_lng: float) -> None:
        """Lookup the booking's address and (in strict mode) reject on mismatch.

        Reads the env flag at request-time via ``django.conf.settings`` so
        per-request env changes (or test ``settings.BOOKING_GEOFENCE_STRICT``
        overrides) take effect without an import-time cache.
        """
        # Lazy ORM: stay out of the orchestrator's lock. We only need
        # the address coords; not under a select_for_update.
        from bookings.models import JobBooking

        try:
            booking = (
                JobBooking.objects
                .select_related("address")
                .only("id", "address__latitude", "address__longitude")
                .get(id=booking_id)
            )
        except JobBooking.DoesNotExist:
            # Let the orchestrator surface the canonical 404 envelope.
            return
        if booking.address is None:
            return

        distance_m = _haversine_meters(
            current_lat,
            current_lng,
            float(booking.address.latitude),
            float(booking.address.longitude),
        )
        if distance_m <= _ARRIVED_THRESHOLD_METERS:
            return

        if getattr(settings, "BOOKING_GEOFENCE_STRICT", False):
            # Use BookingValidationError so the canonical envelope handler
            # in ``core.common.failures.exception`` formats the response —
            # avoids a parallel envelope shape just for this rare case.
            from bookings.exceptions import BookingValidationError

            raise BookingValidationError(
                code="not_at_customer_location",
                message="Tech location is more than 100m from the customer address.",
                errors={"current_lat": [f"distance {int(distance_m)}m exceeds 100m"]},
            )

        logger.warning(
            "arrived geofence mismatch booking=%s distance=%dm (lenient mode allows)",
            booking_id,
            int(distance_m),
        )
