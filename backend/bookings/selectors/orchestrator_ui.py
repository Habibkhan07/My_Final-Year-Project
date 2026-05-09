"""Resolve UI hints for the booking-detail response per (status, role).

The frontend's ``BookingOrchestratorScreen`` (session 3) reads
``ui.*`` fields verbatim and never branches on raw ``status``. All copy +
button labels + slot visibility flow from this selector. Mirrors the
existing ``customer_bookings_selector._resolve_ui_block`` pattern but
returns a richer block (primary/secondary actions, tracking + quote +
dispute slot toggles) appropriate for the full-screen orchestrator vs.
the list-card preview.

One handler function per ``(status, role)`` tuple. A neutral fallback
handler covers any future status that lands without a registered
handler — the frontend renders the booking with no actions rather than
a hard error.

Endpoint convention (sprint §24): action ``endpoint`` strings are
relative paths starting at ``/bookings/...``. The frontend prepends
``AppConstants.baseUrl`` (already includes the ``/api`` prefix) before
dispatching, so embedding ``/api/`` here would produce ``/api/api/...``.
"""
from __future__ import annotations

from typing import Callable, Literal, Optional

from bookings.models import JobBooking
from bookings.selectors.quote_selector import get_active_quote

# Public type alias documenting what the view treats as opaque copy.
UiAction = dict[str, str]
UiBlock = dict[str, object]
ViewerRole = Literal["customer", "technician"]


# ----------------------------------------------------------------------
# Action helpers — kept small + named so the per-status handlers read
# top-down. Endpoint paths are wire strings the frontend dumps into a
# request URL; they're built off the booking id so routing changes only
# need an update here.
# ----------------------------------------------------------------------


def _customer_cancel_action(booking: JobBooking, label: str) -> UiAction:
    return {
        "label": label,
        "endpoint": f"/bookings/{booking.id}/cancel/",
        "method": "POST",
        "style": "destructive",
    }


def _tech_cancel_action(booking: JobBooking) -> UiAction:
    return {
        "label": "Cancel job",
        "endpoint": f"/bookings/{booking.id}/tech-cancel/",
        "method": "POST",
        "style": "destructive",
    }


def _no_show_action(booking: JobBooking, label: str) -> UiAction:
    return {
        "label": label,
        "endpoint": f"/bookings/{booking.id}/no-show/",
        "method": "POST",
        "style": "neutral",
    }


def _reschedule_action(booking: JobBooking) -> UiAction:
    return {
        "label": "Reschedule",
        "endpoint": f"/bookings/{booking.id}/reschedule/",
        "method": "POST",
        "style": "neutral",
    }


def _en_route_action(booking: JobBooking) -> UiAction:
    return {
        "label": "I'm on the way",
        "endpoint": f"/bookings/{booking.id}/en-route/",
        "method": "POST",
        "style": "primary",
    }


def _arrived_action(booking: JobBooking) -> UiAction:
    return {
        "label": "I've arrived",
        "endpoint": f"/bookings/{booking.id}/arrived/",
        "method": "POST",
        "style": "primary",
    }


def _start_inspection_action(booking: JobBooking) -> UiAction:
    return {
        "label": "Start inspection",
        "endpoint": f"/bookings/{booking.id}/start-inspection/",
        "method": "POST",
        "style": "primary",
    }


def _submit_quote_action(booking: JobBooking, label: str = "Submit quote") -> UiAction:
    return {
        "label": label,
        "endpoint": f"/bookings/{booking.id}/quotes/",
        "method": "POST",
        "style": "primary",
    }


def _confirm_cash_action(booking: JobBooking) -> UiAction:
    amount = booking.final_cash_to_collect
    label = (
        f"Cash collected: Rs. {int(amount):,}"
        if amount is not None
        else "Mark complete"
    )
    return {
        "label": label,
        "endpoint": f"/bookings/{booking.id}/confirm-cash-received/",
        "method": "POST",
        "style": "primary",
    }


def _technician_display_name(booking: JobBooking) -> str:
    user = booking.technician.user
    return user.get_full_name() or user.username


def _customer_display_name(booking: JobBooking) -> str:
    user = booking.customer
    return user.get_full_name() or user.username


# ----------------------------------------------------------------------
# Per-(status, role) handlers
# ----------------------------------------------------------------------


def _customer_awaiting(booking, viewer):
    return {
        "status_label": "Awaiting tech",
        "body_text": f"Waiting for {_technician_display_name(booking)} to confirm…",
        "primary_action": None,
        "secondary_actions": [
            _customer_cancel_action(booking, "Cancel booking"),
            _reschedule_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "warning",
    }


def _tech_awaiting(booking, viewer):
    return {
        "status_label": "Awaiting your reply",
        "body_text": "A new job is waiting on your accept/decline.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "warning",
    }


def _customer_confirmed(booking, viewer):
    return {
        "status_label": "Confirmed",
        "body_text": f"{_technician_display_name(booking)} confirmed your booking.",
        "primary_action": None,
        "secondary_actions": [
            _customer_cancel_action(booking, "Cancel"),
            _reschedule_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "positive",
    }


def _tech_confirmed(booking, viewer):
    return {
        "status_label": "Confirmed",
        "body_text": f"You're booked with {_customer_display_name(booking)}.",
        "primary_action": _en_route_action(booking),
        "secondary_actions": [_tech_cancel_action(booking)],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "positive",
    }


def _customer_en_route(booking, viewer):
    return {
        "status_label": "On the way",
        "body_text": f"{_technician_display_name(booking)} is heading to your address.",
        "primary_action": None,
        "secondary_actions": [
            _customer_cancel_action(booking, "Cancel"),
            _no_show_action(booking, "Tech didn't show"),
        ],
        "show_tracking": True,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "info",
    }


def _tech_en_route(booking, viewer):
    return {
        "status_label": "En route",
        "body_text": "Drive safe — tap arrived when you reach the customer.",
        "primary_action": _arrived_action(booking),
        "secondary_actions": [_tech_cancel_action(booking)],
        "show_tracking": True,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "info",
    }


def _customer_arrived(booking, viewer):
    return {
        "status_label": "Technician at door",
        "body_text": f"{_technician_display_name(booking)} has arrived.",
        "primary_action": None,
        "secondary_actions": [
            _customer_cancel_action(booking, "Cancel"),
            _no_show_action(booking, "Tech didn't show"),
        ],
        "show_tracking": True,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "positive",
    }


def _tech_arrived(booking, viewer):
    return {
        "status_label": "On site",
        "body_text": "Open the quote builder when you've assessed the job.",
        "primary_action": _start_inspection_action(booking),
        "secondary_actions": [
            _no_show_action(booking, "Customer no-show"),
            _tech_cancel_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "positive",
    }


def _customer_inspecting(booking, viewer):
    return {
        "status_label": "Inspection in progress",
        "body_text": f"{_technician_display_name(booking)} is preparing your quote.",
        "primary_action": None,
        "secondary_actions": [
            _customer_cancel_action(booking, "Cancel"),
        ],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "info",
    }


def _tech_inspecting(booking, viewer):
    return {
        "status_label": "Build the quote",
        "body_text": "Add line items for the parts and labor you'll perform.",
        "primary_action": _submit_quote_action(booking),
        "secondary_actions": [
            _no_show_action(booking, "Customer no-show"),
            _tech_cancel_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "info",
    }


def _customer_quoted(booking, viewer):
    # The orchestrator only enters QUOTED via ``submit_quote``, which always
    # leaves at least one SUBMITTED row in ``booking.quotes``. ``get_active_quote``
    # never returns None here — but we guard defensively so a stale row with
    # corrupt data degrades to "no actions" rather than a 500.
    active_quote = get_active_quote(booking)
    if active_quote is None:
        return {
            "status_label": "Quote ready",
            "body_text": "Quote details are unavailable. Refresh in a moment.",
            "primary_action": None,
            "secondary_actions": [_customer_cancel_action(booking, "Cancel")],
            "show_tracking": False,
            "show_quote_card": True,
            "show_dispute_button": False,
            "tone": "warning",
        }
    return {
        "status_label": "Quote ready",
        "body_text": "Review the quote and approve, decline, or ask for a revision.",
        "primary_action": {
            "label": "Approve quote",
            "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/approve/",
            "method": "POST",
            "style": "primary",
        },
        "secondary_actions": [
            {
                "label": "Decline (Rs. 500 inspection fee)",
                "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/decline/",
                "method": "POST",
                "style": "destructive",
            },
            {
                "label": "Ask for a revision",
                "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/request-revision/",
                "method": "POST",
                "style": "neutral",
            },
            _customer_cancel_action(booking, "Cancel"),
        ],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "info",
    }


def _tech_quoted(booking, viewer):
    return {
        "status_label": "Awaiting customer decision",
        "body_text": "The customer is reviewing your quote.",
        "primary_action": None,
        "secondary_actions": [
            _no_show_action(booking, "Customer no-show"),
            _tech_cancel_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "info",
    }


def _customer_in_progress(booking, viewer):
    return {
        "status_label": "Work in progress",
        "body_text": f"{_technician_display_name(booking)} is performing the agreed work.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "info",
    }


def _tech_in_progress(booking, viewer):
    return {
        "status_label": "Doing the work",
        "body_text": "Tap below once you've collected cash and finished the job.",
        "primary_action": _confirm_cash_action(booking),
        "secondary_actions": [
            _submit_quote_action(booking, "Add upsell"),
        ],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "info",
    }


def _customer_completed(booking, viewer):
    return {
        "status_label": "Completed",
        "body_text": f"{_technician_display_name(booking)} finished the job.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "positive",
    }


def _tech_completed(booking, viewer):
    return {
        "status_label": "Completed",
        "body_text": "Cash collected, job closed.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "positive",
    }


def _customer_completed_inspection_only(booking, viewer):
    return {
        "status_label": "Inspection only",
        "body_text": "You declined the quote — Rs. 500 inspection fee was due.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "neutral",
    }


def _tech_completed_inspection_only(booking, viewer):
    return {
        "status_label": "Inspection-only",
        "body_text": "Customer declined the quote. Inspection fee due.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": True,
        "tone": "neutral",
    }


def _customer_cancelled(booking, viewer):
    return {
        "status_label": "Cancelled",
        "body_text": "This booking was cancelled.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "neutral",
    }


def _tech_cancelled(booking, viewer):
    return {
        "status_label": "Cancelled",
        "body_text": "This booking was cancelled.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "neutral",
    }


def _customer_rejected(booking, viewer):
    return {
        "status_label": "Unavailable",
        "body_text": f"{_technician_display_name(booking)} couldn't take this job.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "negative",
    }


def _tech_rejected(booking, viewer):
    return {
        "status_label": "Declined",
        "body_text": "You declined this job.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "negative",
    }


def _customer_no_show(booking, viewer):
    return {
        "status_label": "No-show",
        "body_text": "This booking ended in a no-show.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": True,
        "tone": "negative",
    }


def _tech_no_show(booking, viewer):
    return {
        "status_label": "No-show",
        "body_text": "This booking ended in a no-show.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": True,
        "tone": "negative",
    }


def _customer_disputed(booking, viewer):
    return {
        "status_label": "In dispute",
        "body_text": "An admin is reviewing this booking.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "warning",
    }


def _tech_disputed(booking, viewer):
    return {
        "status_label": "In dispute",
        "body_text": "An admin is reviewing this booking.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "warning",
    }


# Legacy PENDING — bookings in this state predate migration 0007 and should
# not surface in the orchestrator screen, but a defensive handler keeps the
# UI honest for any stale rows.
def _customer_pending(booking, viewer):
    return _customer_awaiting(booking, viewer)


def _tech_pending(booking, viewer):
    return _tech_awaiting(booking, viewer)


_HANDLERS: dict[tuple[str, str], Callable] = {
    (JobBooking.STATUS_AWAITING_TECH_ACCEPT, "customer"): _customer_awaiting,
    (JobBooking.STATUS_AWAITING_TECH_ACCEPT, "technician"): _tech_awaiting,
    (JobBooking.STATUS_CONFIRMED, "customer"): _customer_confirmed,
    (JobBooking.STATUS_CONFIRMED, "technician"): _tech_confirmed,
    (JobBooking.STATUS_EN_ROUTE, "customer"): _customer_en_route,
    (JobBooking.STATUS_EN_ROUTE, "technician"): _tech_en_route,
    (JobBooking.STATUS_ARRIVED, "customer"): _customer_arrived,
    (JobBooking.STATUS_ARRIVED, "technician"): _tech_arrived,
    (JobBooking.STATUS_INSPECTING, "customer"): _customer_inspecting,
    (JobBooking.STATUS_INSPECTING, "technician"): _tech_inspecting,
    (JobBooking.STATUS_QUOTED, "customer"): _customer_quoted,
    (JobBooking.STATUS_QUOTED, "technician"): _tech_quoted,
    (JobBooking.STATUS_IN_PROGRESS, "customer"): _customer_in_progress,
    (JobBooking.STATUS_IN_PROGRESS, "technician"): _tech_in_progress,
    (JobBooking.STATUS_COMPLETED, "customer"): _customer_completed,
    (JobBooking.STATUS_COMPLETED, "technician"): _tech_completed,
    (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, "customer"): _customer_completed_inspection_only,
    (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, "technician"): _tech_completed_inspection_only,
    (JobBooking.STATUS_CANCELLED, "customer"): _customer_cancelled,
    (JobBooking.STATUS_CANCELLED, "technician"): _tech_cancelled,
    (JobBooking.STATUS_REJECTED, "customer"): _customer_rejected,
    (JobBooking.STATUS_REJECTED, "technician"): _tech_rejected,
    (JobBooking.STATUS_NO_SHOW, "customer"): _customer_no_show,
    (JobBooking.STATUS_NO_SHOW, "technician"): _tech_no_show,
    (JobBooking.STATUS_DISPUTED, "customer"): _customer_disputed,
    (JobBooking.STATUS_DISPUTED, "technician"): _tech_disputed,
    (JobBooking.STATUS_PENDING, "customer"): _customer_pending,
    (JobBooking.STATUS_PENDING, "technician"): _tech_pending,
}


def _fallback(booking: JobBooking, viewer) -> UiBlock:
    return {
        "status_label": booking.get_status_display(),
        "body_text": "",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": False,
        "show_dispute_button": True,
        "tone": "neutral",
    }


def resolve_orchestrator_ui(
    booking: JobBooking,
    *,
    viewer,
    role: ViewerRole,
) -> UiBlock:
    """Return the dict that becomes the ``ui`` block in the booking-detail
    response.

    ``viewer`` is currently unused but reserved — future personalization
    (e.g. surfacing first-job copy when ``viewer.is_first_booking`` is
    True) plugs in without changing the call sites.
    """
    handler: Optional[Callable] = _HANDLERS.get((booking.status, role))
    if handler is None:
        return _fallback(booking, viewer)
    return handler(booking, viewer)
