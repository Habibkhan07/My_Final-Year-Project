"""Read-side accessors for ``SupportTicket`` / ``TicketEvidence``.

Same no-N+1 contract as ``quote_selector``: every accessor prefetches
evidence and selects the opener so the admin/customer view can iterate
without extra queries.
"""

from __future__ import annotations

from typing import List

from bookings.models import JobBooking, SupportTicket


def list_open_tickets(booking: JobBooking) -> List[SupportTicket]:
    """All OPEN tickets on the booking, newest first.

    Multiple OPEN tickets per booking are allowed (a customer and a tech
    can both file independently). The booking's ``status`` flip to
    DISPUTED is one-shot regardless.
    """
    return list(
        booking.tickets
        .filter(status=SupportTicket.STATUS_OPEN)
        .order_by('-opened_at')
        .select_related('opened_by')
        .prefetch_related('evidence')
    )


def list_all_tickets(booking: JobBooking) -> List[SupportTicket]:
    """All tickets (OPEN + RESOLVED), newest first. Admin view."""
    return list(
        booking.tickets
        .order_by('-opened_at')
        .select_related('opened_by')
        .prefetch_related('evidence')
    )
