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
from tests.factories.bookings import JobBookingConfirmedFactory, QuoteFactory


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


def test_customer_quoted_without_active_quote_falls_back_safely():
    """Defensive: if no quote exists, render no-actions block (not a 500)."""
    booking = JobBookingConfirmedFactory(status=JobBooking.STATUS_QUOTED)
    # Intentionally do NOT seed a quote.
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert block["tone"] == "warning"
    assert block["primary_action"] is None
    # The single secondary action is "Cancel" — also confirms wire format.
    assert len(block["secondary_actions"]) == 1
    assert block["secondary_actions"][0]["endpoint"] == f"/bookings/{booking.id}/cancel/"


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


def test_fallback_for_unknown_status():
    """A row with a status not in _HANDLERS still produces a sensible block."""
    booking = JobBookingConfirmedFactory()
    booking.status = "TOTALLY_UNKNOWN_STATUS"
    block = resolve_orchestrator_ui(booking, viewer=booking.customer, role="customer")
    assert _REQUIRED_KEYS.issubset(block.keys())
    assert block["tone"] == "neutral"
    assert block["primary_action"] is None
    assert block["secondary_actions"] == []
