"""Tests for ``bookings.selectors.orchestrator_ui.resolve_orchestrator_ui``.

Verifies that:
  * Every (status, role) tuple in the model's STATUS_CHOICES has a
    handler registered (no fallback for known statuses).
  * The fallback handler kicks in for unknown statuses (defensive only).
  * Each handler returns the expected dict shape (all required keys
    present, ``tone`` is one of the allowed enum values).
  * Endpoint wire format matches the §24 convention: paths begin with
    ``/bookings/...`` (no ``/api/`` prefix), and quote-action endpoints
    interpolate the live ``active_quote.id`` (no literal ``<id>``).
"""
from __future__ import annotations

import pytest

from bookings.models import JobBooking, Quote
from bookings.selectors.orchestrator_ui import (
    _HANDLERS,
    resolve_orchestrator_ui,
)
from tests.factories.bookings import (
    JobBookingConfirmedFactory,
    QuoteFactory,
    QuoteLineItemFactory,
)
from tests.factories.catalog import (
    FixedPriceSubServiceFactory,
    LaborSubServiceFactory,
)


pytestmark = pytest.mark.django_db


_REQUIRED_KEYS = {
    "status_label",
    "body_text",
    "primary_action",
    "secondary_actions",
    "show_tracking",
    "show_quote_card",
    "show_dispute_button",
    "tone",
}
_ALLOWED_TONES = {"positive", "warning", "negative", "neutral", "info"}


def _iter_action_endpoints(block):
    """Yield every ``endpoint`` string in a UI block (primary + secondary)."""
    primary = block.get("primary_action")
    if primary is not None:
        yield primary["endpoint"]
    for action in block.get("secondary_actions", []):
        yield action["endpoint"]


def test_every_status_has_both_role_handlers():
    """STATUS_CHOICES × {customer, technician} should all be registered."""
    statuses = {value for value, _label in JobBooking.STATUS_CHOICES}
    for status in statuses:
        for role in ("customer", "technician"):
            assert (status, role) in _HANDLERS, (
                f"Missing handler for ({status!r}, {role!r})"
            )


@pytest.mark.parametrize("role", ["customer", "technician"])
@pytest.mark.parametrize(
    "status",
    [value for value, _ in JobBooking.STATUS_CHOICES],
)
def test_every_handler_returns_expected_shape(status, role):
    booking = JobBookingConfirmedFactory(status=status)
    if status == JobBooking.STATUS_QUOTED:
        # Quoted handlers read get_active_quote(); seed a SUBMITTED row so
        # the customer-side handler renders the action set rather than the
        # defensive "no actions" fallback.
        QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role=role)
    assert _REQUIRED_KEYS.issubset(block.keys())
    assert block["tone"] in _ALLOWED_TONES
    assert isinstance(block["secondary_actions"], list)
    assert isinstance(block["show_tracking"], bool)
    assert isinstance(block["show_quote_card"], bool)
    assert isinstance(block["show_dispute_button"], bool)


@pytest.mark.parametrize("role", ["customer", "technician"])
@pytest.mark.parametrize(
    "status",
    [value for value, _ in JobBooking.STATUS_CHOICES],
)
def test_endpoint_wire_format_invariants(status, role):
    """No ``/api/`` prefix and no literal ``<id>`` placeholders.

    Sprint §24: ``AppConstants.baseUrl`` already includes ``/api``, so
    handler endpoints concatenate to ``/api/bookings/...`` only when this
    selector emits ``/bookings/...``. Quote actions must interpolate the
    real ``active_quote.id`` — frontend never templates URLs.
    """
    booking = JobBookingConfirmedFactory(status=status)
    if status == JobBooking.STATUS_QUOTED:
        QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role=role)
    for endpoint in _iter_action_endpoints(block):
        assert not endpoint.startswith("/api/"), (
            f"Handler ({status!r}, {role!r}) emitted {endpoint!r} with /api/ prefix"
        )
        assert endpoint.startswith("/bookings/"), (
            f"Handler ({status!r}, {role!r}) emitted {endpoint!r} not under /bookings/"
        )
        assert "<id>" not in endpoint, (
            f"Handler ({status!r}, {role!r}) emitted unfilled <id> placeholder in {endpoint!r}"
        )


def test_customer_quoted_endpoints_interpolate_active_quote_id():
    """Approve/decline/revision URLs must contain the actual quote id."""
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    # request-revision is now gated on "any labor line item present".
    # Seed a labor item so this test continues to verify the endpoint
    # interpolation it always cared about.
    QuoteLineItemFactory(quote=quote, sub_service=LaborSubServiceFactory())
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    primary = block["primary_action"]
    assert primary is not None
    assert primary["endpoint"] == f"/bookings/{booking.id}/quotes/{quote.id}/approve/"
    secondary_endpoints = {a["endpoint"] for a in block["secondary_actions"]}
    assert f"/bookings/{booking.id}/quotes/{quote.id}/decline/" in secondary_endpoints
    assert (
        f"/bookings/{booking.id}/quotes/{quote.id}/request-revision/"
        in secondary_endpoints
    )


def test_customer_quoted_omits_request_revision_when_all_line_items_fixed_price():
    """Catalog-priced quotes have no negotiable surface → omit revision.

    Post-arrival the customer + technician are face-to-face. A
    "negotiate" action only makes sense when something on the bill is
    a labor charge the tech can lower within `[base, max]`. If every
    line item is a fixed-price sub-service (catalog), the tech has no
    band to negotiate within and the action would be a UX lie.
    """
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    QuoteLineItemFactory(quote=quote, sub_service=FixedPriceSubServiceFactory())
    QuoteLineItemFactory(quote=quote, sub_service=FixedPriceSubServiceFactory())
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    secondary_endpoints = {a["endpoint"] for a in block["secondary_actions"]}
    revision_endpoint = (
        f"/bookings/{booking.id}/quotes/{quote.id}/request-revision/"
    )
    assert revision_endpoint not in secondary_endpoints, (
        "request-revision should NOT appear on an all-fixed-price quote — "
        "nothing for the tech to lower in person"
    )
    # Decline still emitted (the "I don't want this work" exit is
    # universal; only the revision verb depends on labor).
    assert (
        f"/bookings/{booking.id}/quotes/{quote.id}/decline/"
        in secondary_endpoints
    )


def test_customer_quoted_keeps_request_revision_when_mixed_line_items():
    """At least one labor line item is enough to keep the revision verb.

    Real-world quotes often mix fixed-price parts (e.g. a specific
    capacitor with a catalog price) with labor charges (the tech's
    install time). The latter is negotiable; the former is not. So as
    long as ONE labor item exists, the action is meaningful.
    """
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    QuoteLineItemFactory(quote=quote, sub_service=FixedPriceSubServiceFactory())
    QuoteLineItemFactory(quote=quote, sub_service=LaborSubServiceFactory())
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    secondary_endpoints = {a["endpoint"] for a in block["secondary_actions"]}
    assert (
        f"/bookings/{booking.id}/quotes/{quote.id}/request-revision/"
        in secondary_endpoints
    )


def test_customer_quoted_omits_request_revision_when_empty_line_items():
    """Defensive — a quote with no line items has nothing to negotiate.

    `submit_quote` rejects empty quotes, so this is unreachable through
    the wire; but `any()` over an empty iterable is False, so the
    selector naturally degrades to "no revision verb" for the edge.
    Pin the behavior to flag a regression if someone changes the
    selector to default-include instead of default-omit.
    """
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    secondary_endpoints = {a["endpoint"] for a in block["secondary_actions"]}
    assert (
        f"/bookings/{booking.id}/quotes/{quote.id}/request-revision/"
        not in secondary_endpoints
    )


def test_customer_quoted_without_active_quote_falls_back_safely():
    """Defensive: if no quote exists, render no-actions block (not a 500)."""
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    # Intentionally do NOT seed a quote.
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert block["tone"] == "warning"
    assert block["primary_action"] is None
    # Customer cancel is hidden from EN_ROUTE onward
    # (`feedback_customer_cancel_window.md`), so the defensive fallback
    # block has zero secondary actions — the customer's exit is via
    # Contact Support, not a self-serve button mid-job.
    assert block["secondary_actions"] == []


def test_customer_view_on_quoted_shows_approve_action():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert block["primary_action"] is not None
    assert block["primary_action"]["label"].startswith("Approve")
    assert block["show_quote_card"] is True


def test_tech_view_on_in_progress_shows_cash_action():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_IN_PROGRESS)
    block = resolve_orchestrator_ui(booking, viewer=booking.technician.user, role="technician")
    assert block["primary_action"] is not None
    assert "Mark complete" in block["primary_action"]["label"] or "Cash collected" in block["primary_action"]["label"]


def test_customer_view_on_en_route_shows_tracking():
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_EN_ROUTE)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert block["show_tracking"] is True


def test_completed_booking_renders_dispute_slot():
    """Customer should be able to file a dispute on a completed booking."""
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_COMPLETED)
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert block["show_dispute_button"] is True


@pytest.mark.parametrize(
    "status,customer_sees_cancel,tech_sees_cancel",
    [
        # Pre-EN_ROUTE: customer can cancel (free / pre-commitment).
        (JobBooking.STATUS_AWAITING_TECH_ACCEPT, True, False),
        (JobBooking.STATUS_CONFIRMED, True, True),
        # EN_ROUTE onward: customer cancel disappears (tech is moving /
        # committed). Tech keeps theirs as an emergency exit.
        (JobBooking.STATUS_EN_ROUTE, False, True),
        (JobBooking.STATUS_ARRIVED, False, True),
        (JobBooking.STATUS_INSPECTING, False, True),
        (JobBooking.STATUS_QUOTED, False, True),
        # Post-cash / terminal: no cancel for either side.
        (JobBooking.STATUS_IN_PROGRESS, False, False),
        (JobBooking.STATUS_COMPLETED, False, False),
        (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, False, False),
        (JobBooking.STATUS_CANCELLED, False, False),
        (JobBooking.STATUS_REJECTED, False, False),
        (JobBooking.STATUS_NO_SHOW, False, False),
        (JobBooking.STATUS_DISPUTED, False, False),
    ],
)
def test_cancel_visibility_matrix(status, customer_sees_cancel, tech_sees_cancel):
    """Locks the cancel-visibility rule per `feedback_customer_cancel_window.md`.

    Customer's self-serve cancel only exists pre-EN_ROUTE; tech's
    self-serve cancel exists through QUOTED (their emergency exit ramp
    while they're committed to the job).
    """
    booking = JobBookingConfirmedFactory(status=status)
    # QUOTED needs an active quote to take the main code path. If we
    # don't seed one, the fallback runs — which also asserts no cancel
    # for customer, so this path stays valid either way.
    if status == JobBooking.STATUS_QUOTED:
        QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)

    customer_block = resolve_orchestrator_ui(
        booking, viewer=booking.customer, role="customer"
    )
    customer_endpoints = {a["endpoint"] for a in customer_block["secondary_actions"]}
    assert (
        f"/bookings/{booking.id}/cancel/" in customer_endpoints
    ) is customer_sees_cancel, (
        f"customer view on {status!r}: expected cancel visibility "
        f"{customer_sees_cancel}, got {customer_endpoints}"
    )

    tech_block = resolve_orchestrator_ui(
        booking, viewer=booking.technician.user, role="technician"
    )
    tech_endpoints = {a["endpoint"] for a in tech_block["secondary_actions"]}
    assert (
        f"/bookings/{booking.id}/tech-cancel/" in tech_endpoints
    ) is tech_sees_cancel, (
        f"tech view on {status!r}: expected cancel visibility "
        f"{tech_sees_cancel}, got {tech_endpoints}"
    )


def test_fallback_for_unknown_status():
    """A row with a status not in _HANDLERS still produces a sensible block."""
    booking = JobBookingConfirmedFactory()
    booking.status = "TOTALLY_UNKNOWN_STATUS"
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert _REQUIRED_KEYS.issubset(block.keys())
    assert block["tone"] == "neutral"
    assert block["primary_action"] is None
    assert block["secondary_actions"] == []
