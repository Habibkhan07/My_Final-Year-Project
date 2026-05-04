"""
Customer-side bookings list + counts views.

Both views are HTTP-only: parse query → delegate to the selector →
render envelope. No business logic. The selector
(``bookings/selectors/customer_bookings_selector.py``) owns:

- IDOR-safe queryset scoping (``customer=request.user``)
- Cursor encoding / decoding
- The status → ``ui`` block resolver (mirrored on the Flutter side)
- The batched ``EventLog`` lookup for ``REJECTED`` reason discriminator
- Pagination semantics (slice ``page_size + 1`` for ``has_more``)

SECURITY: ``IsAuthenticated`` blocks anonymous callers; the queryset
filter on ``customer=request.user`` inside the selector prevents a
logged-in user from enumerating other users' bookings — IDOR-proof by
construction (no per-row permission check is needed at this layer
because non-owned rows never enter the queryset).
"""
from __future__ import annotations

from rest_framework import status as http_status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.customer_list.serializers import (
    BookingsCountsResponseSerializer,
    BookingsListResponseSerializer,
    CustomerBookingsListQuerySerializer,
)
from bookings.selectors.customer_bookings_selector import (
    CursorDecodeError,
    count_customer_bookings,
    list_customer_bookings,
)


class CustomerBookingsListView(APIView):
    """
    GET /api/bookings/

    Paginated list of the authenticated customer's bookings. Filterable
    by ``segment`` (``upcoming`` / ``past``) or by an explicit ``status``
    csv. See ``CUSTOMER_BOOKINGS_API.md`` for the full contract.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        query = CustomerBookingsListQuerySerializer(data=request.query_params)
        if not query.is_valid():
            return Response(
                {
                    "status": http_status.HTTP_400_BAD_REQUEST,
                    "code": _query_error_code(query.errors),
                    "message": "Invalid query parameters.",
                    "errors": query.errors,
                },
                status=http_status.HTTP_400_BAD_REQUEST,
            )

        validated = query.validated_data
        try:
            result = list_customer_bookings(
                user=request.user,
                segment=validated["segment"],
                status_filter=validated.get("status"),
                cursor=validated.get("cursor") or None,
                page_size=validated["page_size"],
                since=validated.get("since"),
            )
        except CursorDecodeError:
            return Response(
                {
                    "status": http_status.HTTP_400_BAD_REQUEST,
                    "code": "invalid_cursor",
                    "message": "Cursor is malformed.",
                    "errors": {"cursor": ["Cursor is malformed."]},
                },
                status=http_status.HTTP_400_BAD_REQUEST,
            )

        body = {
            "items": result.items,
            "next_cursor": result.next_cursor,
            "has_more": result.has_more,
            "server_time": result.server_time.isoformat(),
        }
        return Response(
            BookingsListResponseSerializer(body).data,
            status=http_status.HTTP_200_OK,
        )


class CustomerBookingsCountsView(APIView):
    """
    GET /api/bookings/counts/

    Cheap COUNT(*) aggregates for the segmented-control badges. Two
    queries, no joins. Mirrors the same segment definitions as the list
    endpoint — kept in lockstep via the shared selector module.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        result = count_customer_bookings(user=request.user)
        body = {
            "upcoming": result.upcoming,
            "past": result.past,
            "server_time": result.server_time.isoformat(),
        }
        return Response(
            BookingsCountsResponseSerializer(body).data,
            status=http_status.HTTP_200_OK,
        )


def _query_error_code(errors: dict) -> str:
    """
    Map field-level query errors to a stable ``code`` string the Flutter
    repository switches on. Falls back to the generic ``validation_error``
    used by the rest of the API for unrecognized field combinations.
    """
    if "status" in errors:
        return "invalid_status_filter"
    if "cursor" in errors:
        return "invalid_cursor"
    return "validation_error"
