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

from bookings.models import JobBooking, Quote
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


def _customer_arriving_action(booking: JobBooking) -> UiAction:
    """InDrive-style ACK on the customer's ARRIVED screen.

    Surfaces only while ``customer_acknowledged_arrival_at`` is null;
    once stamped, ``_customer_arrived`` swaps the primary slot to None
    and the UI shows the "✓ Notified" confirmation state instead.
    """
    return {
        "label": "I'm coming out",
        "endpoint": f"/bookings/{booking.id}/customer-arriving/",
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
        # Customer's self-serve cancel disappears at EN_ROUTE — the tech
        # has burned fuel and committed time, so one-tap cancel becomes
        # unfair. Customer's only exit from here is Contact Support
        # (`feedback_customer_cancel_window.md`). Tech keeps their
        # self-serve cancel — they need an emergency exit.
        "secondary_actions": [],
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
    """Customer ARRIVED view.

    InDrive-style meeting flow: the tech does NOT knock the door in
    Pakistani urban context — they stop at the address pin and the
    customer walks out to find them. We surface a primary "I'm coming
    out" CTA until the customer ACKs, then collapse the slot so the
    body copy alone communicates the post-ACK state.
    """
    has_acked = booking.customer_acknowledged_arrival_at is not None
    tech_name = _technician_display_name(booking)
    if has_acked:
        body_text = f'You let {tech_name} know you are on your way out.'
        primary_action = None
    else:
        body_text = (
            f'{tech_name} is parked at your address. '
            f'Please walk out to meet them.'
        )
        primary_action = _customer_arriving_action(booking)
    return {
        "status_label": "Technician at the address",
        "body_text": body_text,
        "primary_action": primary_action,
        # No customer cancel from EN_ROUTE onward
        # (`feedback_customer_cancel_window.md`).
        "secondary_actions": [],
        "show_tracking": True,
        "show_quote_card": False,
        "show_dispute_button": False,
        "tone": "positive",
    }


def _tech_arrived(booking, viewer):
    """Tech ARRIVED view.

    The body copy reflects whether the customer has acknowledged via the
    "I'm coming out" CTA. Before ACK: amber-waiting framing. After ACK:
    green "customer is coming" framing. The tech keeps "Start inspection"
    as the primary slot regardless — they shouldn't be blocked from
    starting if the customer is slow.
    """
    has_acked = booking.customer_acknowledged_arrival_at is not None
    customer_name = _customer_display_name(booking)
    if has_acked:
        body_text = f'{customer_name} is coming out to meet you.'
    else:
        body_text = (
            f'You are at the address. Waiting for {customer_name} '
            f'to walk out and meet you.'
        )
    return {
        "status_label": "On site",
        "body_text": body_text,
        "primary_action": _start_inspection_action(booking),
        # Tech-cancel + customer-no-show both moved under Help on the
        # frontend; the latter is now a reason in the cancel-reason
        # picker (`feedback_cancel_vs_no_show.md`).
        "secondary_actions": [
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
        "body_text": f"{_technician_display_name(booking)} is inspecting the issue.",
        "primary_action": None,
        # No customer cancel from EN_ROUTE onward
        # (`feedback_customer_cancel_window.md`).
        "secondary_actions": [],
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
        # Cancel-only secondary; customer-no-show moved into the
        # cancel-reason picker (`feedback_cancel_vs_no_show.md`).
        "secondary_actions": [
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
            # No customer cancel from EN_ROUTE onward
            # (`feedback_customer_cancel_window.md`).
            "secondary_actions": [],
            "show_tracking": False,
            "show_quote_card": True,
            "show_dispute_button": False,
            "tone": "warning",
        }
    # `request-revision` only makes sense when the quote contains
    # labor-priced line items — those are the items the technician
    # set within `[base, max]` and can lower in person. If every
    # line item references a fixed-price (catalog) sub-service, there
    # is literally no negotiable surface, so we omit the action.
    #
    # Post-arrival the customer + technician are face-to-face; the
    # action is the signal that flips the quote back so the tech can
    # rebuild it on their own device while the customer watches. The
    # button itself is the wire trigger — the verbal bargain happens
    # around it. Surfacing it on a catalog-only quote would be a UX
    # lie (nothing to lower).
    #
    # `get_active_quote` prefetches `line_items__sub_service` so this
    # iteration adds no queries.
    has_labor_charges = any(
        not item.sub_service.is_fixed_price
        for item in active_quote.line_items.all()
    )

    secondary_actions = [
        {
            "label": "Decline (Rs. 500 inspection fee)",
            "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/decline/",
            "method": "POST",
            "style": "destructive",
        },
    ]
    if has_labor_charges:
        secondary_actions.append({
            "label": "Ask for a revision",
            "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/request-revision/",
            "method": "POST",
            "style": "neutral",
        })
    # No customer cancel from EN_ROUTE onward — decline-quote
    # exists for "I don't want this work" (Rs. 500 inspection
    # fee only); request-revision exists for "fix the quote".
    # No need for a third escape (`feedback_customer_cancel_window.md`).

    return {
        "status_label": "Quote ready",
        "body_text": "Review the quote and approve, decline, or ask for a revision.",
        "primary_action": {
            "label": "Approve quote",
            "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/approve/",
            "method": "POST",
            "style": "primary",
        },
        "secondary_actions": secondary_actions,
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
        # Cancel-only secondary; customer-no-show moved into the
        # cancel-reason picker (`feedback_cancel_vs_no_show.md`).
        "secondary_actions": [
            _tech_cancel_action(booking),
        ],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "info",
    }


def _customer_in_progress(booking, viewer):
    # When the tech submits an upsell mid-job, an `is_upsell=True`,
    # SUBMITTED quote appears on the booking while the booking itself
    # stays IN_PROGRESS. The customer needs UI affordances to act on it
    # (approve / decline / ask for a revision) — without these the
    # backend supports the action but the customer has no way to fire
    # it. `get_active_quote` returns the most recent SUBMITTED quote
    # (preferring SUBMITTED over older terminal-status ones).
    active_quote = get_active_quote(booking)
    has_pending_upsell = (
        active_quote is not None
        and active_quote.is_upsell
        and active_quote.status == Quote.STATUS_SUBMITTED
    )

    if has_pending_upsell:
        # Mirror the regular-quote action set from `_customer_quoted`
        # but scoped to the upsell. Same labels — the customer reads
        # them in the same place as the initial quote review and the
        # cognitive model carries.
        has_labor_charges = any(
            not item.sub_service.is_fixed_price
            for item in active_quote.line_items.all()
        )
        secondary_actions = [
            {
                "label": "Decline upsell",
                "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/decline/",
                "method": "POST",
                "style": "destructive",
            },
        ]
        if has_labor_charges:
            secondary_actions.append({
                "label": "Ask for a revision",
                "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/request-revision/",
                "method": "POST",
                "style": "neutral",
            })
        return {
            "status_label": "Extra work proposed",
            "body_text": (
                f"{_technician_display_name(booking)} added extra work. "
                "Approve to include it in the final bill."
            ),
            "primary_action": {
                "label": "Approve upsell",
                "endpoint": f"/bookings/{booking.id}/quotes/{active_quote.id}/approve/",
                "method": "POST",
                "style": "primary",
            },
            "secondary_actions": secondary_actions,
            "show_tracking": False,
            "show_quote_card": True,
            "show_dispute_button": False,
            "tone": "info",
        }

    return {
        "status_label": "Work in progress",
        "body_text": f"{_technician_display_name(booking)} is performing the agreed work.",
        "primary_action": None,
        "secondary_actions": [],
        "show_tracking": False,
        "show_quote_card": True,
        # Dispute is a post-transaction surface — disputes are about a
        # *completed exchange* the customer is unhappy with. Hiding it
        # pre-cash prevents premature escalations while the tech is
        # mid-job (see feedback_dispute_visibility memory).
        "show_dispute_button": False,
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
        # Dispute is a post-transaction surface — disputes are about a
        # *completed exchange* the customer is unhappy with. Hiding it
        # pre-cash prevents premature escalations while the tech is
        # mid-job (see feedback_dispute_visibility memory).
        "show_dispute_button": False,
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
