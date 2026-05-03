"""
Technician-side accept / decline endpoints.

Both views are HTTP-only: parse → delegate → respond. The transactional
state machine, IDOR-safe queryset scoping, and customer-facing event
broadcast all live in ``bookings/services/job_request_action.py``.

Error mapping (uniform for both endpoints):
    BookingNotFoundForTechnicianError  →  404 not_found
    BookingNotActionableError          →  409 booking_no_longer_available
                                          (errors.current_status echoes
                                           the live row state for client
                                           debugging)

SECURITY: ``IsAuthenticated`` blocks anonymous callers at the permission
layer; the service-layer queryset filter on ``technician__user=request.user``
prevents a logged-in non-owner technician (or a logged-in customer) from
mutating another technician's booking — both surface as 404 here.
"""
from __future__ import annotations

from typing import Callable

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.job_actions.serializers import JobBookingActionResponseSerializer
from bookings.exceptions import (
    BookingNotActionableError,
    BookingNotFoundForTechnicianError,
)
from bookings.services.job_request_action import (
    accept_job_booking,
    decline_job_booking,
)


class _BaseJobBookingActionView(APIView):
    """
    Shared HTTP shell for accept / decline. Subclasses set ``_action``
    to the corresponding service entrypoint. Keeping the two views in a
    single shared shell guarantees identical error envelopes — the
    client's ``_mapFailure`` switch keys on the response shape, not the
    URL, so a divergence here would silently break one path.
    """
    permission_classes = [IsAuthenticated]
    _action: Callable

    def post(self, request: Request, booking_id: int) -> Response:
        try:
            booking = self._action(
                booking_id=booking_id,
                technician_user=request.user,
            )
        except BookingNotFoundForTechnicianError:
            return Response(
                {
                    "status": status.HTTP_404_NOT_FOUND,
                    "code": "not_found",
                    "message": "Booking not found.",
                    "errors": {},
                },
                status=status.HTTP_404_NOT_FOUND,
            )
        except BookingNotActionableError as exc:
            return Response(
                {
                    "status": status.HTTP_409_CONFLICT,
                    "code": "booking_no_longer_available",
                    "message": "This job is no longer available.",
                    "errors": {"current_status": [exc.current_status]},
                },
                status=status.HTTP_409_CONFLICT,
            )

        return Response(
            JobBookingActionResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )


class AcceptJobBookingView(_BaseJobBookingActionView):
    """POST /api/bookings/<booking_id>/accept/"""
    _action = staticmethod(accept_job_booking)


class DeclineJobBookingView(_BaseJobBookingActionView):
    """POST /api/bookings/<booking_id>/decline/"""
    _action = staticmethod(decline_job_booking)
