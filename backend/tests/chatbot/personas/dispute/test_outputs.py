"""Tests for chatbot.personas.dispute.outputs.finalize_dispute.

Pins:
  - finalize_dispute returns {"support_ticket_id": N}
  - Idempotent: replaying with output_refs already set returns the same
    dict WITHOUT creating a new ticket.
"""
from __future__ import annotations

import pytest

from bookings.models import SupportTicket
from chatbot.personas.dispute.outputs import finalize_dispute
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.chatbot import ConversationFactory, MessageFactory


def _make_closed_conv():
    booking = JobBookingCompletedFactory()
    conv = ConversationFactory(
        user=booking.customer,
        persona_key="dispute",
        context={"booking_id": booking.id},
        state={
            "phase": "CLOSED",
            "captured_fields": {"issue_summary": "AC failure"},
            "ai_summary": "AC failure reported.",
            "bank_draft": {
                "bank_name": "HBL",
                "account_title": "Test",
                "iban": "PK36HABB0011223344556677",
            },
        },
        is_closed=True,
    )
    MessageFactory(conversation=conv, role="USER", text="AC failed.")
    return conv


@pytest.mark.django_db
class TestFinalizeDispute:
    def test_returns_output_refs_with_ticket_id(self):
        conv = _make_closed_conv()
        refs = finalize_dispute(conv)
        assert "support_ticket_id" in refs
        assert SupportTicket.objects.filter(id=refs["support_ticket_id"]).exists()

    def test_idempotent_returns_existing_without_creating(self):
        conv = _make_closed_conv()
        refs1 = finalize_dispute(conv)
        # Simulate the conversation service writing output_refs back to the row.
        conv.output_refs = refs1
        conv.save()

        before = SupportTicket.objects.count()
        refs2 = finalize_dispute(conv)
        after = SupportTicket.objects.count()

        assert refs2["support_ticket_id"] == refs1["support_ticket_id"]
        assert before == after  # no duplicate ticket
