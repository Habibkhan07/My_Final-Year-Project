"""Tests for chatbot.services.conversation orchestration.

These pin the framework-level guarantees (persona-agnostic):
  - Start: routes to persona.is_eligible_to_start, raises on rejection.
  - Start: resumes existing open conversation via find_existing_open.
  - Start: creates Conversation + runs opening_turn + persists BOT msg.
  - Message: IDOR-safe (wrong user → ConversationNotFound).
  - Message: quota.consume only fires for text turns.
  - Message: USER message persisted before flow runs.
  - Message: state_patch merged, turn_count incremented.
  - Message: terminal turn auto-closes and runs on_close.
  - Close: idempotent.
  - Close: dispute persona appends templated closing SYSTEM message.
"""
from __future__ import annotations

import pytest

from chatbot.models import Conversation, Message
from chatbot.services.conversation import (
    ConversationClosed,
    ConversationNotFound,
    NotEligibleToStart,
    close_conversation,
    handle_message,
    start_conversation,
)
from chatbot.services.quota import QuotaExceeded
from tests.chatbot._fakes import FakeAgent
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingFactory,
)


# ---- start_conversation -------------------------------------------------

@pytest.mark.django_db
class TestStartConversation:
    def test_creates_conversation_and_opening_message(self):
        booking = JobBookingCompletedFactory()
        agent = FakeAgent()
        conv = start_conversation(
            booking.customer,
            "dispute",
            {"booking_id": booking.id},
            agent=agent,
        )
        assert conv.pk is not None
        assert conv.persona_key == "dispute"
        assert conv.state["phase"] == "UNDERSTAND"
        # Opening turn was templated (no LLM) — bot message persisted.
        assert conv.messages.filter(role="BOT").exists()
        assert agent.calls == []  # template path, no LLM call

    def test_ineligible_booking_raises(self):
        booking = JobBookingFactory()  # default = AWAITING, not COMPLETED
        with pytest.raises(NotEligibleToStart):
            start_conversation(
                booking.customer,
                "dispute",
                {"booking_id": booking.id},
                agent=FakeAgent(),
            )

    def test_idor_other_user_raises(self):
        booking = JobBookingCompletedFactory()
        other = UserFactory()
        with pytest.raises(NotEligibleToStart):
            start_conversation(
                other,
                "dispute",
                {"booking_id": booking.id},
                agent=FakeAgent(),
            )

    def test_resumes_existing_open_conversation(self):
        booking = JobBookingCompletedFactory()
        first = start_conversation(
            booking.customer,
            "dispute",
            {"booking_id": booking.id},
            agent=FakeAgent(),
        )
        # Second call with same (user, booking) returns the SAME conversation.
        second = start_conversation(
            booking.customer,
            "dispute",
            {"booking_id": booking.id},
            agent=FakeAgent(),
        )
        assert second.id == first.id
        assert Conversation.objects.filter(user=booking.customer).count() == 1


# ---- handle_message -----------------------------------------------------

@pytest.fixture
def opened_conversation(db):
    booking = JobBookingCompletedFactory()
    conv = start_conversation(
        booking.customer,
        "dispute",
        {"booking_id": booking.id},
        agent=FakeAgent(),
    )
    return conv


@pytest.mark.django_db
class TestHandleMessage:
    def test_text_turn_persists_user_and_bot_messages(self, opened_conversation):
        agent = FakeAgent(structured={
            "message_to_user": "Got it. Photos next.",
            "phase_complete": True,
            "fields_captured": {"issue_summary": "AC failed"},
            "asked_off_topic": False,
        }, text="Got it. Photos next.")

        before_user = opened_conversation.messages.filter(role="USER").count()
        before_bot = opened_conversation.messages.filter(role="BOT").count()

        handle_message(
            opened_conversation.id,
            opened_conversation.user,
            "text",
            "AC stopped working.",
            agent=agent,
        )

        opened_conversation.refresh_from_db()
        assert opened_conversation.messages.filter(role="USER").count() == before_user + 1
        assert opened_conversation.messages.filter(role="BOT").count() == before_bot + 1

    def test_state_patch_merged_and_turn_count_incremented(self, opened_conversation):
        agent = FakeAgent(structured={
            "message_to_user": "Ok.",
            "phase_complete": True,
            "fields_captured": {"issue_summary": "AC failed"},
            "asked_off_topic": False,
        }, text="Ok.")

        handle_message(
            opened_conversation.id,
            opened_conversation.user,
            "text",
            "AC stopped working.",
            agent=agent,
        )

        opened_conversation.refresh_from_db()
        assert opened_conversation.state["phase"] == "EVIDENCE"
        assert opened_conversation.state["captured_fields"]["issue_summary"] == "AC failed"
        assert opened_conversation.turn_count == 1

    def test_idor_wrong_user_raises_not_found(self, opened_conversation):
        other = UserFactory()
        with pytest.raises(ConversationNotFound):
            handle_message(
                opened_conversation.id,
                other,
                "text",
                "trying to peek",
                agent=FakeAgent(),
            )

    def test_closed_conversation_raises(self, opened_conversation):
        opened_conversation.is_closed = True
        opened_conversation.save()
        with pytest.raises(ConversationClosed):
            handle_message(
                opened_conversation.id,
                opened_conversation.user,
                "text",
                "hi",
                agent=FakeAgent(),
            )

    def test_quota_only_consumed_for_text(self, opened_conversation):
        from chatbot.models import DailyLlmCallQuota
        from django.utils import timezone

        # attachment_done in EVIDENCE phase → no LLM, no quota.
        opened_conversation.state["phase"] = "EVIDENCE"
        opened_conversation.save()
        handle_message(
            opened_conversation.id,
            opened_conversation.user,
            "attachment_done",
            None,
            agent=FakeAgent(),
        )
        assert not DailyLlmCallQuota.objects.filter(
            user=opened_conversation.user,
            date=timezone.localdate(),
        ).exists()

    def test_quota_exceeded_propagates(self, opened_conversation, settings):
        settings.CHATBOT_DAILY_CALL_LIMIT = 0
        with pytest.raises(QuotaExceeded):
            handle_message(
                opened_conversation.id,
                opened_conversation.user,
                "text",
                "hi",
                agent=FakeAgent(),
            )

    def test_terminal_turn_closes_conversation(self, opened_conversation):
        # Drive through to CONFIRM and let it close.
        agent_understand = FakeAgent(structured={
            "message_to_user": "Got it.",
            "phase_complete": True,
            "fields_captured": {"issue_summary": "AC failed"},
            "asked_off_topic": False,
        }, text="Got it.")
        handle_message(
            opened_conversation.id, opened_conversation.user,
            "text", "AC failed", agent=agent_understand,
        )
        opened_conversation.refresh_from_db()
        assert opened_conversation.state["phase"] == "EVIDENCE"

        handle_message(
            opened_conversation.id, opened_conversation.user,
            "attachment_done", None, agent=FakeAgent(),
        )
        opened_conversation.refresh_from_db()
        assert opened_conversation.state["phase"] == "PAYOUT"

        # Add a USER message so the inline summarisation in the PAYOUT
        # submit has narrative content to summarise.
        from tests.factories.chatbot import MessageFactory
        MessageFactory(
            conversation=opened_conversation,
            role="USER",
            text="AC failure after the technician left.",
        )

        # PAYOUT submit now finalises the ticket in one turn — CONFIRM
        # phase no longer exists as a discrete step.
        agent_summary = FakeAgent(text="Customer reported AC failure.")
        handle_message(
            opened_conversation.id, opened_conversation.user,
            "form",
            {
                "bank_name": "HBL",
                "account_title": "Test",
                "iban": "PK36HABB0011223344556677",
            },
            agent=agent_summary,
        )
        opened_conversation.refresh_from_db()
        assert opened_conversation.is_closed is True
        assert "support_ticket_id" in opened_conversation.output_refs


# ---- close_conversation -------------------------------------------------

@pytest.mark.django_db
class TestCloseConversation:
    def test_idempotent_when_already_closed(self, opened_conversation):
        opened_conversation.is_closed = True
        opened_conversation.output_refs = {"support_ticket_id": 99}
        opened_conversation.save()
        result = close_conversation(opened_conversation.id, opened_conversation.user)
        assert result == {"support_ticket_id": 99}

    def test_appends_dispute_closing_system_message(self, opened_conversation):
        # Set up a CONFIRM-state conversation with all required fields,
        # so on_close can file the ticket and the closing message appends.
        from tests.factories.chatbot import MessageFactory
        MessageFactory(
            conversation=opened_conversation,
            role="USER",
            text="AC stopped working.",
        )
        opened_conversation.state = {
            **opened_conversation.state,
            "phase": "CLOSED",
            "captured_fields": {"issue_summary": "AC failed"},
            "ai_summary": "Customer reported AC failure.",
            "bank_draft": {
                "bank_name": "HBL",
                "account_title": "Test",
                "iban": "PK36HABB0011223344556677",
            },
        }
        opened_conversation.save()

        close_conversation(opened_conversation.id, opened_conversation.user)

        opened_conversation.refresh_from_db()
        system_msgs = opened_conversation.messages.filter(role="SYSTEM")
        assert system_msgs.count() == 1
        last = system_msgs.last()
        assert "ticket #" in last.text
        assert "within 3 working days" in last.text

    def test_idor_wrong_user_raises_not_found(self, opened_conversation):
        other = UserFactory()
        with pytest.raises(ConversationNotFound):
            close_conversation(opened_conversation.id, other)
