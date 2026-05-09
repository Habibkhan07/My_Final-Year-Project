"""``GET /api/bookings/<booking_id>/`` — orchestrator-screen detail."""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.booking_detail.serializers import (
    BookingDetailResponseSerializer,
)
from bookings.models import JobBooking
from bookings.selectors.dispute_selector import list_open_tickets
from bookings.selectors.orchestrator_ui import resolve_orchestrator_ui
from bookings.selectors.quote_selector import (
    get_active_quote,
    list_booking_items,
)
from bookings.selectors.transition_validator import available_transitions


class BookingDetailView(APIView):
    """Read-only single-booking view for the orchestrator screen.

    Audit P1-04 — NO HTTP cache. Realtime events drive frontend re-fetches;
    a 5-second ``Cache-Control`` would silently return stale data exactly
    when fresh state matters most.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id: int):
        try:
            booking = (
                JobBooking.objects
                # Audit P1-01: customer__userprofile prefetched for the
                # phone field; AttributeError fallback handles users
                # without a UserProfile (legacy/system).
                # Audit P1-02: technician.profile_picture URL is built
                # via request.build_absolute_uri.
                .select_related(
                    "customer", "customer__userprofile",
                    "technician__user",
                    "address",
                    "service", "sub_service", "parent_booking",
                )
                .get(id=booking_id)
            )
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

        # SECURITY: scope to participants only. Non-participants get 403,
        # not 404, so the IDOR boundary is explicit. Audit P0-02:
        # TechnicianProfile.user uses related_name='tech_profile'.
        is_customer = booking.customer_id == request.user.id
        is_technician = (
            hasattr(request.user, "tech_profile")
            and booking.technician_id == request.user.tech_profile.id
        )
        if not (is_customer or is_technician):
            return Response(
                {
                    "status": status.HTTP_403_FORBIDDEN,
                    "code": "not_a_participant",
                    "message": "You are not a participant on this booking.",
                    "errors": {},
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        viewer_role = "customer" if is_customer else "technician"

        # Reschedule-chain forward pointer (audit cycle 2 #B1). When this
        # booking is the CANCELLED original, surface the child's id so the
        # orchestrator UI can offer a "Continued on #N" link — otherwise a
        # user who returns to the original (e.g. via a stale FCM tap) is
        # stranded. Most-recent child wins to tolerate chains > 1.
        child = (
            booking.child_bookings.order_by('-id').only('id').first()
        )
        child_booking_id = child.id if child is not None else None

        payload = {
            "booking": booking,
            "active_quote": get_active_quote(booking),
            "booking_items": list_booking_items(booking),
            "open_tickets_count": len(list_open_tickets(booking)),
            "ui": resolve_orchestrator_ui(
                booking, viewer=request.user, role=viewer_role,
            ),
            "available_transitions": available_transitions(
                booking, viewer=request.user, role=viewer_role,
            ),
            "child_booking_id": child_booking_id,
        }

        response = Response(
            BookingDetailResponseSerializer(payload, context={"request": request}).data,
            status=status.HTTP_200_OK,
        )
        # Audit P1-04: realtime events drive frontend re-fetches; any
        # browser/CDN cache (heuristic or otherwise) would silently serve
        # the previous status payload exactly when fresh state matters.
        # ``no-store`` forbids both shared and private caches; ``private``
        # is belt-and-braces for proxies that ignore ``no-store``.
        response['Cache-Control'] = 'no-store, no-cache, must-revalidate, private'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'
        return response
