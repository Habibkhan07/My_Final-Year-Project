"""Tech-location GPS ingress.

Two side effects on every accepted call:
  1. Publish a ``tech_gps`` stream frame to ``tracking_job_<booking_id>``
     so any subscribed customer + admin watcher receives the update.
  2. Call ``auto_transition.evaluate_on_location`` which may flip the
     booking's status (CONFIRMED → EN_ROUTE, EN_ROUTE → ARRIVED) via
     the orchestrator.

Throttling: a process-local TTL dict rejects ≥2 calls per 4 seconds
per (tech_user, booking) pair. This absorbs the 5-second tick clock
drift from the Android foreground location service. Multi-worker
Daphne deployments allow N×4s effective rate (one slot per worker);
this is acceptable for v1 — see ``flag.md::tech-location-rate-limit-not-distributed``
for the proper redis-backed token-bucket fix.

The view is a thin pass-through: NO ``select_for_update`` (high-frequency
read path), NO direct status mutation (orchestrator owns that). The
orchestrator's atomic block is the lock window for any actual transition.
"""
from __future__ import annotations

import logging
import time

from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.api.tech_location.serializers import (
    TechLocationRequestSerializer,
    TechLocationResponseSerializer,
)
from bookings.models import JobBooking
from bookings.services import auto_transition
from realtime.constants.groups import TRACKING_JOB_GROUP_TEMPLATE
from realtime.streams import publish_stream

logger = logging.getLogger(__name__)


# 4 second throttle absorbs the 5-second client tick + clock drift.
_THROTTLE_SECONDS = 4.0

# Process-local LRU-ish bucket keyed by (tech_user_id, booking_id) -> last_ts.
# Acceptable per CLAUDE.md "no Redis dependency for ratelimiting in v1";
# see flag.md tech-location-rate-limit-not-distributed for the proper fix.
_LAST_PUBLISH_TS: dict[tuple[int, int], float] = {}
# Hard cap so a long-running process can't grow the dict unboundedly.
_THROTTLE_CACHE_MAX = 5_000


def _throttle_hit(key: tuple[int, int], now: float) -> bool:
    last = _LAST_PUBLISH_TS.get(key)
    if last is not None and (now - last) < _THROTTLE_SECONDS:
        return True
    _LAST_PUBLISH_TS[key] = now
    if len(_LAST_PUBLISH_TS) > _THROTTLE_CACHE_MAX:
        # Drop oldest 10% — cheap stampede control.
        cutoff = now - (_THROTTLE_SECONDS * 4)
        for stale_key in [k for k, ts in _LAST_PUBLISH_TS.items() if ts < cutoff]:
            _LAST_PUBLISH_TS.pop(stale_key, None)
    return False


class TechLocationIngressView(APIView):
    """``POST /api/bookings/<booking_id>/tech-location/``"""
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: Tech-only. The auto-transition layer has its own
        # IDOR-safe early return (returns None for non-owning callers),
        # but rejecting non-techs here avoids the DB hit.
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

        req = TechLocationRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        # IDOR-FIRST ORDERING (audit H5): the booking lookup + assigned-tech
        # check run BEFORE the throttle. Pre-fix the throttle ran first,
        # which let an authenticated tech who is NOT assigned to a given
        # booking populate ``_LAST_PUBLISH_TS`` with throwaway
        # (tech_user_id, random_booking_id) keys until the cap-eviction
        # sweep evicted legitimate entries. Throttle keys must only ever
        # exist for the legitimate (assigned tech, booking) pair.
        try:
            booking = (
                JobBooking.objects
                .only("id", "status", "technician_id")
                .select_related("technician")
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

        # IDOR check: assigned tech only.
        if booking.technician.user_id != request.user.id:
            return Response(
                {
                    "status": status.HTTP_403_FORBIDDEN,
                    "code": "not_assigned_to_you",
                    "message": "You are not the technician on this booking.",
                    "errors": {},
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # Throttle AFTER the IDOR check so non-assigned tech traffic
        # cannot pollute the throttle bucket.
        if _throttle_hit((request.user.id, booking_id), time.monotonic()):
            return Response(
                {
                    "status": status.HTTP_429_TOO_MANY_REQUESTS,
                    "code": "too_many_requests",
                    "message": "GPS frames are limited to 1 per 4 seconds.",
                    "errors": {},
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        lat = req.validated_data["lat"]
        lng = req.validated_data["lng"]

        # Audit P2 (Pass 2 / H4): the terminal-status guard + publish_stream
        # MUST live under a row lock on the booking. With the previous
        # unlocked status read, the booking could transition to
        # COMPLETED / CANCELLED / DISPUTED between the check and the
        # ``publish_stream`` call, leaking the technician's GPS to
        # subscribers AFTER the job ended. By re-fetching the status
        # under ``select_for_update`` and emitting the stream while the
        # lock is held, any concurrent terminal transition either:
        #   (a) lost the race and runs after we publish — fine, the
        #       customer was a legitimate participant a moment ago.
        #   (b) won the race and ran before we acquired the lock —
        #       our locked re-read sees the terminal status and we
        #       silent-no-op, preventing the leak.
        #
        # The ``auto_transition.evaluate_on_location`` call runs OUTSIDE
        # this atomic block: it has its own transactional boundary in
        # the orchestrator and would re-lock the same row, which is
        # safe but pointless under the same outer transaction. Releasing
        # the lock before the auto-transition also keeps Redis fan-out
        # latency off the lock-hold window.
        with transaction.atomic():
            locked_booking = (
                JobBooking.objects
                .select_for_update()
                .only("id", "status")
                .get(id=booking_id)
            )
            if locked_booking.status in JobBooking.TERMINAL_STATUSES:
                return Response(
                    TechLocationResponseSerializer({
                        "published": False,
                        "transition_fired": None,
                    }).data,
                    status=status.HTTP_200_OK,
                )

            # Side-effect 1: stream frame fan-out. The customer's WS
            # connection may have joined ``tracking_job_<id>`` via the
            # consumer's ``subscribe_tracking`` upstream message.
            publish_stream(
                group=TRACKING_JOB_GROUP_TEMPLATE.format(booking_id=booking_id),
                stream_type="tech_gps",
                payload={
                    "lat": lat,
                    "lng": lng,
                    "accuracy_meters": req.validated_data.get("accuracy_meters"),
                    "heading": req.validated_data.get("heading"),
                    "booking_id": booking_id,
                },
            )

        # Side-effect 2: geofence-driven auto-transition. Returns the
        # new status string when a transition fired, or None. Runs
        # outside the lock above — see comment block.
        new_status = auto_transition.evaluate_on_location(
            booking_id=booking_id,
            lat=lat,
            lng=lng,
            technician_user=request.user,
        )

        return Response(
            TechLocationResponseSerializer({
                "published": True,
                "transition_fired": new_status,
            }).data,
            status=status.HTTP_200_OK,
        )
