"""Read-side accessors for ``Quote`` / ``QuoteLineItem`` / ``BookingItem``.

Every accessor enforces the no-N+1 rule (CLAUDE.md): nested data is fetched
via ``select_related`` / ``prefetch_related`` so callers can iterate
``line_items`` and read ``sub_service.name`` without firing extra queries.
Callers are session-2 views (orchestrator screen, admin) and session-3
frontend hydration paths.
"""

from __future__ import annotations

from typing import List

from bookings.models import BookingItem, JobBooking, Quote


def get_active_quote(booking: JobBooking) -> Quote | None:
    """Return the most recent SUBMITTED quote, or — if none is currently
    submitted — the most recent quote of any state.

    The "most recent submitted" preference matters during a revision dance:
    after the customer requests a revision, the prior quote is SUPERSEDED
    and a fresh one becomes SUBMITTED. The orchestrator screen always wants
    the SUBMITTED one if it exists (that's the actionable card). The
    fallback handles freshly-resolved bookings whose newest quote may be
    APPROVED / DECLINED / SUPERSEDED — the screen still wants to render
    the most recent decision.

    Returns ``None`` when the booking has no quotes (pre-INSPECTING).
    """
    submitted = (
        booking.quotes
        .filter(status=Quote.STATUS_SUBMITTED)
        .order_by('-revision_number')
        .prefetch_related('line_items__sub_service')
        .first()
    )
    if submitted is not None:
        return submitted
    return (
        booking.quotes
        .order_by('-revision_number')
        .prefetch_related('line_items__sub_service')
        .first()
    )


def list_quote_history(booking: JobBooking) -> List[Quote]:
    """All quotes for the booking, oldest revision first.

    Used by admin and debugging tools to walk the full negotiation chain.
    The orchestrator screen calls ``get_active_quote`` instead.
    """
    return list(
        booking.quotes
        .order_by('revision_number')
        .prefetch_related('line_items__sub_service')
    )


def list_booking_items(booking: JobBooking) -> List[BookingItem]:
    """The accepted-and-performed line items for the booking.

    Source of truth for the finance sprint's reconciliation queries —
    BookingItem rows are append-only on quote approval, never deleted by
    revision, so the sum of ``line_total`` is always the work performed
    (modulo cancellation paths that the booking row's terminal status
    captures separately).
    """
    return list(
        booking.items
        .order_by('id')
        .select_related('sub_service', 'sourced_quote')
    )
