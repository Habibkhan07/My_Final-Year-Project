"""Read-only queries for ``technicians.Review``.

Two surfaces:

* ``get_review_for_booking`` — single-row lookup, customer-scoped.
  Powers the GET half of ``/api/bookings/<id>/review/`` so the
  customer's UI can render the post-submit thank-you body on cold
  reload without trying to re-submit.
* ``list_reviews_for_technician`` — paginated public read for the
  technician profile screen ("All reviews" sheet). Cursor-based to
  stay stable as new reviews land between page loads.

Both functions return data only — no exceptions for "not found"
cases. The view layer chooses what to do with a ``None`` /
empty-list result.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from django.db.models import QuerySet

from technicians.models import Review


def get_review_for_booking(
    *,
    booking_id: int,
    customer_user,
) -> Optional[Review]:
    """Return the customer's existing review for ``booking_id``, or
    ``None`` if no review has been submitted yet.

    Scoped to ``reviewer=customer_user`` AND ``booking_id`` — a second
    customer cannot probe whether a booking they don't own has been
    reviewed. (The booking ownership is also enforced by the view's
    ``submit_review`` path; this selector adds the same gate to the
    read path for symmetry.)

    select_related on ``reviewer`` so the response serializer can
    render the reviewer's first name without an extra query.
    """
    return (
        Review.objects
        .select_related("reviewer", "booking", "technician__user")
        .filter(booking_id=booking_id, reviewer=customer_user)
        .first()
    )


@dataclass(frozen=True)
class TechnicianReviewsPage:
    """Wire-friendly page object for ``list_reviews_for_technician``.

    A dataclass (not a NamedTuple) so the view can extend the response
    with derived fields later without churning the call sites.
    """
    reviews: list[Review]
    next_cursor: Optional[int]
    has_more: bool


def list_reviews_for_technician(
    *,
    technician_id: int,
    page_size: int = 20,
    cursor: Optional[int] = None,
) -> TechnicianReviewsPage:
    """Paginated review list for the tech profile screen.

    Cursor is the ``id`` of the last row in the previous page;
    pagination is over ``(-created_at, -id)`` so a stable secondary
    sort breaks created_at ties (which happen in test fixtures and
    in burst-create flows). The cursor filter is ``id < cursor`` —
    one row per cursor, no duplicates across pages even if rows
    arrive in the gap.

    select_related on ``reviewer`` for the avatar / name render.
    """
    page_size = max(1, min(page_size, 100))  # hard cap for defence
    qs: QuerySet[Review] = (
        Review.objects
        .select_related("reviewer")
        .filter(technician_id=technician_id)
        .order_by("-created_at", "-id")
    )
    if cursor is not None:
        qs = qs.filter(id__lt=cursor)

    # Fetch one extra to detect "has more" without a second COUNT query.
    rows = list(qs[: page_size + 1])
    has_more = len(rows) > page_size
    visible = rows[:page_size]
    next_cursor = visible[-1].id if (has_more and visible) else None

    return TechnicianReviewsPage(
        reviews=visible,
        next_cursor=next_cursor,
        has_more=has_more,
    )
