"""Tech-side scheduled-jobs API views — thin parse + delegate.

Powers the technician "Schedule" tab: paginated list (Upcoming / Past)
plus aggregate counts for the segmented-control badges. Mirrors the
customer-side ``/api/bookings/`` contract with audience-flipped wire
shape (see ``technicians.selectors.scheduled_jobs`` for the rationale).

No business logic lives here — these are parse + delegate views per the
project's thin-views, fat-services rule. All DB reads run in the selector
under a ``technician=request.user.tech_profile`` IDOR scope.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from technicians.selectors.scheduled_jobs import (
    ALLOWED_SEGMENTS,
    ALLOWED_STATUSES,
    CursorDecodeError,
    DEFAULT_PAGE_SIZE,
    MAX_PAGE_SIZE,
    SEGMENT_UPCOMING,
    count_scheduled_jobs,
    list_scheduled_jobs,
)


def _forbidden_non_tech() -> Response:
    """Standard 403 envelope reused by both views."""
    return Response(
        {
            "status": 403,
            "code": "permission_denied",
            "message": "User is not a registered technician.",
            "errors": {"user": ["Technician profile not found."]},
        },
        status=403,
    )


def _validation_error(field: str, detail: str, code: str = "validation_error") -> Response:
    return Response(
        {
            "status": 400,
            "code": code,
            "message": "Invalid query parameters.",
            "errors": {field: [detail]},
        },
        status=400,
    )


class TechnicianScheduledJobsListView(APIView):
    """``GET /api/technicians/me/scheduled-jobs/``

    Query params (all optional):
      * ``segment``    — ``upcoming`` (default) or ``past``.
      * ``status``     — comma-separated status csv override; bypasses
                         segment's time-window predicate. Reserved for
                         future filter-chip UIs.
      * ``cursor``     — opaque token from previous response.
      * ``page_size``  — int, 1..50, default 20.
      * ``since``      — ISO-8601 ``created_at__gte`` filter. v1 list
                         notifier does not use this; accepted for
                         symmetry with the customer-side contract.

    SECURITY: ``request.user.tech_profile`` is the only IDOR gate. The
    selector's ``technician=tech_profile`` scope guarantees no other
    tech's bookings ever enter the queryset.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            tech_profile = request.user.tech_profile
        except TechnicianProfile.DoesNotExist:
            return _forbidden_non_tech()

        segment = request.query_params.get("segment", SEGMENT_UPCOMING)
        if segment not in ALLOWED_SEGMENTS:
            return _validation_error(
                "segment",
                f"Must be one of: {', '.join(sorted(ALLOWED_SEGMENTS))}.",
            )

        status_filter: Optional[list[str]] = None
        raw_status = request.query_params.get("status")
        if raw_status:
            requested = [s.strip().upper() for s in raw_status.split(",") if s.strip()]
            unknown = [s for s in requested if s not in ALLOWED_STATUSES]
            if unknown:
                return _validation_error(
                    "status",
                    f"Unknown status value(s): {','.join(unknown)}.",
                    code="invalid_status_filter",
                )
            status_filter = requested

        page_size_raw = request.query_params.get("page_size")
        if page_size_raw is None:
            page_size = DEFAULT_PAGE_SIZE
        else:
            try:
                page_size = int(page_size_raw)
            except (TypeError, ValueError):
                return _validation_error(
                    "page_size",
                    "page_size must be an integer.",
                )
            if page_size < 1 or page_size > MAX_PAGE_SIZE:
                return _validation_error(
                    "page_size",
                    f"Ensure this value is between 1 and {MAX_PAGE_SIZE}.",
                )

        since: Optional[datetime] = None
        raw_since = request.query_params.get("since")
        if raw_since:
            try:
                since = datetime.fromisoformat(raw_since)
            except (TypeError, ValueError):
                return _validation_error(
                    "since",
                    "since must be ISO-8601 (e.g. 2026-05-15T00:00:00+00:00).",
                )
            # Reject naive datetimes — comparing them against tz-aware
            # ``created_at`` triggers Django's RuntimeWarning and is
            # ambiguous about wall-clock interpretation.
            if since.tzinfo is None:
                return _validation_error(
                    "since",
                    "since must include a timezone offset (e.g. +00:00).",
                )

        cursor = request.query_params.get("cursor") or None

        try:
            result = list_scheduled_jobs(
                tech_profile=tech_profile,
                segment=segment,
                status_filter=status_filter,
                cursor=cursor,
                page_size=page_size,
                since=since,
            )
        except CursorDecodeError:
            return Response(
                {
                    "status": 400,
                    "code": "invalid_cursor",
                    "message": "Cursor is malformed.",
                    "errors": {"cursor": ["Cursor is malformed."]},
                },
                status=400,
            )

        return Response(
            {
                "items": result.items,
                "next_cursor": result.next_cursor,
                "has_more": result.has_more,
                "server_time": result.server_time.isoformat(),
            }
        )


class TechnicianScheduledJobsCountsView(APIView):
    """``GET /api/technicians/me/scheduled-jobs/counts/``

    Returns two ``COUNT(*)`` queries — used by the segmented-control
    badges. No params. Earnings aggregates are deliberately not surfaced
    here (Metrics tab owns "how much have I earned").

    SECURITY: same IDOR gate as the list view.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            tech_profile = request.user.tech_profile
        except TechnicianProfile.DoesNotExist:
            return _forbidden_non_tech()

        result = count_scheduled_jobs(tech_profile=tech_profile)
        return Response(
            {
                "upcoming": result.upcoming,
                "past": result.past,
                "server_time": result.server_time.isoformat(),
            }
        )
