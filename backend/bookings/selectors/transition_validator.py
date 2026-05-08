"""Project the orchestrator's transition validity rules into a list of
function names that the frontend can use as button gates.

Must stay in lockstep with ``bookings.services.orchestrator``'s actual
from-state guards. The test suite enumerates every (status, role) tuple
and verifies parity by attempting each absent transition against the
orchestrator and asserting it raises ``BookingValidationError``.

This selector is a *projection*, not a reimplementation: the
orchestrator remains the only authority on whether a transition can
actually run. The validator exists so the booking-detail response can
include hints without the frontend having to mirror the state machine.
"""
from __future__ import annotations

from typing import Literal

from bookings.models import JobBooking, SupportTicket

ViewerRole = Literal["customer", "technician"]


# Status sets — kept here (not imported from orchestrator) so this
# selector has no module-load dependency on the service layer. Drift
# is prevented by the test that calls the orchestrator and compares.
_TECH_CANCELLABLE = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
})

_CUSTOMER_CANCELLABLE = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
})

_TECH_REPORT_NO_SHOW = frozenset({
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
})

_CUSTOMER_REPORT_NO_SHOW = frozenset({
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
})

_RESCHEDULE_FROM = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
})

# open_dispute is allowed from every state EXCEPT pre-confirmed
# (orchestrator's _DISPUTE_DISALLOWED). We don't include DISPUTED here
# because filing a second dispute on a disputed booking is a no-op
# status-wise — but the orchestrator does allow it. Keep parity.
_DISPUTE_DISALLOWED = frozenset({
    JobBooking.STATUS_PENDING,
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_REJECTED,
})


def available_transitions(
    booking: JobBooking,
    *,
    viewer,
    role: ViewerRole,
) -> list[str]:
    """Return orchestrator function names valid from the current state for
    the current viewer role.

    Each name corresponds to a public function in
    ``bookings.services.orchestrator``. The frontend uses the list to
    enable/disable action buttons — the booking-detail ``ui`` block is
    the *primary* hint surface; this list is the machine-readable view
    of the same information.
    """
    out: list[str] = []
    s = booking.status

    if role == "technician":
        if s == JobBooking.STATUS_CONFIRMED:
            out.append("en_route")
        elif s == JobBooking.STATUS_EN_ROUTE:
            out.append("arrived")
        elif s == JobBooking.STATUS_ARRIVED:
            out.append("start_inspection")

        # Quotes — tech submits at INSPECTING (regular) and IN_PROGRESS
        # (upsell). Customer decides; tech does not approve their own
        # quote.
        if s in (JobBooking.STATUS_INSPECTING, JobBooking.STATUS_IN_PROGRESS):
            out.append("submit_quote")

        # Combined complete + cash collection (sprint meta §14 rule 2).
        if s == JobBooking.STATUS_IN_PROGRESS:
            out.append("mark_complete_with_cash")

        if s in _TECH_CANCELLABLE:
            out.append("cancel_by_tech")

        if s in _TECH_REPORT_NO_SHOW:
            # Time guard (15 min) is enforced in the orchestrator —
            # surfaced here as the action being available; the
            # actual call may still raise ERROR_NO_SHOW_TOO_EARLY.
            out.append("mark_no_show")

    elif role == "customer":
        if s == JobBooking.STATUS_QUOTED:
            out.extend(["approve_quote", "decline_quote", "request_revision"])

        if s in _CUSTOMER_CANCELLABLE:
            out.append("cancel_by_customer")

        if s in _RESCHEDULE_FROM:
            out.append("reschedule")

        if s in _CUSTOMER_REPORT_NO_SHOW:
            out.append("mark_no_show")

    # Dispute is available to either party from any non-pre-CONFIRMED
    # state, with the orchestrator's "preserve terminal status" rule
    # making it idempotent for already-resolved bookings. We surface
    # ``open_dispute`` only when no OPEN ticket already exists — the
    # booking-detail screen renders a "View dispute" link instead in
    # that case, fed by ``open_tickets_count`` in the response.
    if s not in _DISPUTE_DISALLOWED and not booking.tickets.filter(
        status=SupportTicket.STATUS_OPEN,
    ).exists():
        out.append("open_dispute")

    return out
