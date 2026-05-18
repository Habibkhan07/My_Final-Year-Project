"""Customer-side review submission — write path for ``technicians.Review``.

Contract (invariants the caller can rely on):

* Exactly one review per booking, enforced at the DB layer by the
  ``Review.booking`` ``OneToOneField``. The service short-circuits
  before insert when ``booking.review`` already exists, returning a
  typed 409 instead of letting MySQL raise an ``IntegrityError``.
* Eligible bookings only: ``COMPLETED`` and ``COMPLETED_INSPECTION_ONLY``
  (per ``feedback_dispute_visibility`` memory). Any other status
  raises ``BookingNotEligibleForReviewError`` with the current status
  in the error envelope so the Flutter mapper can pick the right copy.
* IDOR-safe: the booking is fetched scoped to ``customer=customer_user``.
  A wrong-owner read returns ``BookingNotFoundForCustomerError`` — the
  same 404 a non-existent id returns, indistinguishable to the caller.
* Matchmaking-coherent: the ``TechnicianProfile.rating_average`` /
  ``review_count`` columns AND the per-service ``TechnicianService
  Performance`` row are recomputed **inside the same transaction** as
  the ``Review`` insert. The next dispatch picks up the new score
  with no extra wiring — matchmaking reads these columns directly
  (see ``technicians.selectors.matchmaking_selectors``).
* Drift-proof aggregates: both rolling averages are recomputed via
  ``Avg()`` over the full review set for the (tech) / (tech,service)
  partition, never incremented. At this scale (low review count per
  tech) the indexed SELECT is cheap and immune to off-by-one bugs
  that incremental math is prone to.
* Concurrent-write-safe: ``select_for_update`` on the booking AND on
  the ``TechnicianProfile`` row serialises against any other review
  for the same tech firing concurrently. Without the profile lock,
  two simultaneous reviews could each compute ``avg`` against a
  pre-write set and produce non-deterministic final values.

# SECURITY: select_for_update on booking with customer-scoped fetch
  prevents IDOR. The OneToOne on Review.booking makes double-submit a
  database-level integrity error (the typed exception is a friendly
  translation, not the only line of defence).
"""
from __future__ import annotations

import logging
from typing import Iterable

from django.db import transaction
from django.db.models import Avg, Count

from bookings.models import JobBooking
from technicians.constants.review_tags import ALL_TAG_KEYS
from technicians.exceptions import (
    BookingNotEligibleForReviewError,
    BookingNotFoundForCustomerError,
    ReviewAlreadySubmittedError,
)
from technicians.models import (
    Review,
    TechnicianProfile,
    TechnicianServicePerformance,
)

logger = logging.getLogger(__name__)

#: Statuses that allow a review to be submitted. Lifted to a module-level
#: frozenset so the test suite can import-and-compare without re-stating
#: the literal strings, and so any future eligibility expansion is a
#: single-line edit instead of a grep-and-replace.
_ELIGIBLE_STATUSES: frozenset[str] = frozenset({
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
})

#: Hard cap on the optional free-text field. Mirrors the serializer's
#: ``max_length`` so a malformed direct service call (no serializer in
#: front of it — e.g. management command, test) cannot create a row
#: that fails wire-validation on read-back.
_MAX_TEXT_LENGTH: int = 500


def _normalise_tags(tags: Iterable[str] | None) -> list[str]:
    """Drop dupes, preserve order, reject unknown keys.

    Defence-in-depth — the serializer is the primary validation gate,
    but the service stays callable from management commands / tests
    / future internal flows, none of which see the serializer. A
    defensive normaliser here means the JSON column never accepts a
    typo'd key from a non-API caller. Unknown keys raise
    ``ValueError`` synchronously — surfaces as a 500 if it ever
    escapes to the API path (which it won't, because the serializer
    catches it first), keeping the misuse loud.
    """
    if not tags:
        return []
    seen: set[str] = set()
    result: list[str] = []
    for key in tags:
        if not isinstance(key, str):
            raise ValueError(f"Review tag must be a string, got {type(key).__name__}")
        if key in seen:
            continue
        if key not in ALL_TAG_KEYS:
            raise ValueError(f"Unknown review tag key: {key!r}")
        seen.add(key)
        result.append(key)
    return result


@transaction.atomic
def submit_review(
    *,
    booking_id: int,
    customer_user,
    rating: int,
    tags: Iterable[str] | None = None,
    text: str | None = None,
) -> Review:
    """Create a ``Review`` row for ``booking_id`` and recompute aggregate
    rating columns for matchmaking.

    Returns the freshly-created ``Review`` instance with all relations
    already loaded (caller's serializer needs ``reviewer`` and
    ``booking`` to render the response without an extra query).

    Raises
    ------
    BookingNotFoundForCustomerError
        Booking does not exist OR is not owned by ``customer_user``.
        Indistinguishable — IDOR-safe.
    BookingNotEligibleForReviewError
        Booking exists and is owned by ``customer_user`` but is not in
        a terminal-success status.
    ReviewAlreadySubmittedError
        A review already exists for this booking (OneToOne).
    ValueError
        ``rating`` is outside 1-5, ``tags`` contains an unknown key,
        or ``text`` exceeds ``_MAX_TEXT_LENGTH``. These are caller-
        misuse signals — the serializer enforces them before the API
        path ever hits this function, so an escape here indicates a
        non-API caller bug (management command, test, internal flow).
    """
    # ── Input validation ────────────────────────────────────────────
    # Done BEFORE acquiring any row locks so a caller error doesn't
    # hold the booking + technician rows under SELECT FOR UPDATE.
    if not isinstance(rating, int):
        raise ValueError(f"rating must be int, got {type(rating).__name__}")
    if not 1 <= rating <= 5:
        raise ValueError(f"rating must be between 1 and 5 inclusive, got {rating}")
    if text is not None and len(text) > _MAX_TEXT_LENGTH:
        raise ValueError(
            f"text exceeds max length {_MAX_TEXT_LENGTH} (got {len(text)} chars)"
        )
    normalised_tags = _normalise_tags(tags)
    normalised_text = (text or "").strip()

    # ── Lock booking + verify ownership + eligibility ──────────────
    # select_related on technician__user / service / sub_service so the
    # response serializer can render the booking summary without firing
    # additional queries under the open transaction.
    try:
        booking = (
            JobBooking.objects
            .select_for_update()
            .select_related("technician__user", "service", "sub_service")
            .get(pk=booking_id, customer=customer_user)
        )
    except JobBooking.DoesNotExist as exc:
        raise BookingNotFoundForCustomerError() from exc

    if booking.status not in _ELIGIBLE_STATUSES:
        raise BookingNotEligibleForReviewError(current_status=booking.status)

    # Cheap pre-check that mirrors the OneToOne constraint. Avoids the
    # round-trip-then-IntegrityError pattern; the typed exception above
    # is the user-facing translation. Using ``hasattr`` because the
    # reverse OneToOne raises ``DoesNotExist`` rather than returning
    # ``None`` when unset — wrapping that with hasattr is the
    # idiomatic Django check.
    if hasattr(booking, "review"):
        raise ReviewAlreadySubmittedError()

    # ── Lock technician profile (serialises concurrent inserts) ────
    # Why: two concurrent reviews for the same tech, each computing
    # AVG() against the pre-insert set, would each see a stale count.
    # The SELECT FOR UPDATE on the profile row serialises them so the
    # second one waits for the first to commit, then recomputes
    # against the post-first-insert set. Same lock posture as the
    # wallet-mutation flow (per ``feedback_critical_financial_code``).
    tech = (
        TechnicianProfile.objects
        .select_for_update()
        .get(pk=booking.technician_id)
    )

    # ── Insert the Review row ──────────────────────────────────────
    review = Review.objects.create(
        technician=tech,
        reviewer=customer_user,
        booking=booking,
        rating=rating,
        tags=normalised_tags,
        text=normalised_text,
    )

    # ── Recompute profile-level rolling average ────────────────────
    # The ``or 0`` guards aren't reachable in production (we just
    # inserted a row, so the aggregate has at least one value), but
    # they make the code resilient to mutation patterns where the
    # filter set could be empty (e.g. a future hard-delete path).
    profile_agg = Review.objects.filter(technician=tech).aggregate(
        avg=Avg("rating"),
        count=Count("id"),
    )
    tech.rating_average = profile_agg["avg"] or 0
    tech.review_count = profile_agg["count"] or 0
    tech.save(update_fields=["rating_average", "review_count"])

    # ── Recompute per-service performance ──────────────────────────
    # TechnicianServicePerformance is keyed on the parent ``Service``,
    # not on ``SubService``. ``booking.service_id`` is always populated
    # (the parent service is mandatory on every JobBooking, while
    # sub_service is nullable — verified at bookings/models.py:98-109).
    # So no sub_service→service resolution is needed; ``service_id``
    # is the authoritative key.
    perf, _created = (
        TechnicianServicePerformance.objects
        .select_for_update()
        .get_or_create(
            technician=tech,
            service_id=booking.service_id,
            defaults={"review_count": 0, "rating_average": 0.0},
        )
    )
    perf_agg = Review.objects.filter(
        technician=tech,
        booking__service_id=booking.service_id,
    ).aggregate(avg=Avg("rating"), count=Count("id"))
    perf.rating_average = perf_agg["avg"] or 0
    perf.review_count = perf_agg["count"] or 0
    perf.save(update_fields=["rating_average", "review_count"])

    logger.info(
        "review.submit booking=%s technician=%s rating=%s "
        "profile_avg=%.2f profile_count=%s perf_avg=%.2f perf_count=%s",
        booking.pk, tech.pk, rating,
        float(tech.rating_average), tech.review_count,
        float(perf.rating_average), perf.review_count,
    )

    return review
