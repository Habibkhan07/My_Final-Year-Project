"""Tests for chatbot.personas.dispute.flow.DisputeFlow.

The marquee guarantee this file pins:
  THE LLM CANNOT BYPASS THE STATE MACHINE.

Specifically: even if the FakeAgent returns ``phase_complete=True`` with
``fields_captured={}``, the conversation stays in UNDERSTAND because the
flow validates required fields independently of the LLM's self-report.

Other contracts pinned:
  - Cap-exceeded with required captured → forced_advance to EVIDENCE.
  - Cap-exceeded with required missing → conversation aborts (close,
    no ticket — better than filing an empty narrative).
  - EVIDENCE / PAYOUT / CONFIRM phase transitions and rejections.
  - CONFIRM summary validation failure → needs_review_summary=True.
"""
from __future__ import annotations

import pytest

from chatbot.personas.dispute.flow import (
    ConversationAlreadyClosed,
    DisputeFlow,
    UnsupportedMessageKind,
)
from tests.chatbot._fakes import FakeAgent
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.chatbot import ConversationFactory, MessageFactory


@pytest.fixture
def booking(db):
    return JobBookingCompletedFactory()


@pytest.fixture
def conversation(db, booking):
    return ConversationFactory(
        user=booking.customer,
        persona_key="dispute",
        context={"booking_id": booking.id},
        state={
            "phase": "UNDERSTAND",
            "captured_fields": {},
            "bank_draft": {},
            "off_topic_count": 0,
            "forced_advance": False,
        },
        turn_count=0,
    )


@pytest.mark.django_db
class TestOpeningTurn:
    def test_returns_warm_greeting(self, conversation):
        flow = DisputeFlow()
        agent = FakeAgent()
        result = flow.opening_turn(conversation, agent)
        # Templated, so no LLM call expected.
        assert agent.calls == []
        assert result.bot_message
        assert result.ui_input_kind == "text"
        assert result.is_terminal is False


@pytest.mark.django_db
class TestHandleUnderstand:
    def test_advances_when_complete_and_required_captured(self, conversation):
        flow = DisputeFlow()
        agent = FakeAgent(
            text="Got it. Let's collect photos next.",
            structured={
                "message_to_user": "Got it. Let's collect photos next.",
                "phase_complete": True,
                "fields_captured": {"issue_summary": "AC stopped working"},
                "asked_off_topic": False,
            },
        )
        result = flow.handle_user_turn(
            conversation, "text", "AC stopped working after he left.", agent
        )
        assert result.state_patch["phase"] == "EVIDENCE"
        assert result.ui_input_kind == "attachment"
        assert result.state_patch["captured_fields"]["issue_summary"] == "AC stopped working"

    def test_stays_when_llm_says_complete_but_required_missing(self, conversation):
        # MARQUEE TEST: LLM cannot lie its way past the state machine.
        flow = DisputeFlow()
        agent = FakeAgent(
            text="Got it.",
            structured={
                "message_to_user": "Got it.",
                "phase_complete": True,
                "fields_captured": {},  # nothing captured
                "asked_off_topic": False,
            },
        )
        result = flow.handle_user_turn(conversation, "text", "Hi.", agent)
        # phase NOT in state_patch — so it stays at UNDERSTAND.
        assert result.state_patch.get("phase") != "EVIDENCE"
        assert result.ui_input_kind == "text"

    def test_stays_when_required_captured_but_llm_says_not_complete(self, conversation):
        flow = DisputeFlow()
        agent = FakeAgent(
            text="Tell me more about when this happened.",
            structured={
                "message_to_user": "Tell me more about when this happened.",
                "phase_complete": False,
                "fields_captured": {"issue_summary": "AC stopped working"},
                "asked_off_topic": False,
            },
        )
        result = flow.handle_user_turn(
            conversation, "text", "AC stopped working.", agent
        )
        # LLM wants more turns even though required is captured. We respect that.
        assert result.state_patch.get("phase") != "EVIDENCE"
        # The captured field is preserved.
        assert result.state_patch["captured_fields"]["issue_summary"] == "AC stopped working"

    def test_off_topic_counter_increments(self, conversation):
        flow = DisputeFlow()
        agent = FakeAgent(
            text="I can only help with this dispute.",
            structured={
                "message_to_user": "I can only help with this dispute.",
                "phase_complete": False,
                "fields_captured": {},
                "asked_off_topic": True,
            },
        )
        result = flow.handle_user_turn(
            conversation, "text", "What's your refund policy?", agent
        )
        assert result.state_patch["off_topic_count"] == 1

    def test_redacts_user_message_before_llm(self, conversation):
        flow = DisputeFlow()
        agent = FakeAgent(structured={
            "message_to_user": "Ok.",
            "phase_complete": False,
            "fields_captured": {},
            "asked_off_topic": False,
        })
        flow.handle_user_turn(
            conversation,
            "text",
            "Please send refund to PK36HABB0011223344556677",
            agent,
        )
        # The redacted form is what the LLM should have received.
        assert "PK36HABB0011223344556677" not in agent.calls[0]["user_message"]
        assert "[REDACTED]" in agent.calls[0]["user_message"]

    def test_unsupported_message_kind(self, conversation):
        flow = DisputeFlow()
        with pytest.raises(UnsupportedMessageKind):
            flow.handle_user_turn(conversation, "form", {}, FakeAgent())

    def test_captured_fields_dont_blank_out(self, conversation):
        # If the LLM returns empty value for a field we already have,
        # the existing value is preserved.
        conversation.state["captured_fields"] = {"issue_summary": "AC broke"}
        conversation.save()
        flow = DisputeFlow()
        agent = FakeAgent(structured={
            "message_to_user": "More?",
            "phase_complete": False,
            "fields_captured": {"issue_summary": ""},
            "asked_off_topic": False,
        })
        result = flow.handle_user_turn(conversation, "text", "more details", agent)
        assert result.state_patch["captured_fields"]["issue_summary"] == "AC broke"


@pytest.mark.django_db
class TestCapExceeded:
    def test_cap_with_required_missing_aborts(self, conversation, settings):
        settings.CHATBOT_UNDERSTAND_TURN_CAP = 2
        conversation.turn_count = 2
        conversation.state["captured_fields"] = {}
        conversation.save()
        flow = DisputeFlow()
        result = flow.handle_user_turn(conversation, "text", "hi", FakeAgent())
        assert result.is_terminal is True
        assert result.state_patch["phase"] == "CLOSED"
        assert result.state_patch["aborted_reason"] == "insufficient_info_after_cap"
        assert result.ui_input_kind == "close"

    def test_cap_with_required_captured_force_advances(self, conversation, settings):
        settings.CHATBOT_UNDERSTAND_TURN_CAP = 2
        conversation.turn_count = 2
        conversation.state["captured_fields"] = {"issue_summary": "AC failure"}
        conversation.save()
        flow = DisputeFlow()
        result = flow.handle_user_turn(conversation, "text", "hi", FakeAgent())
        assert result.is_terminal is False
        assert result.state_patch["phase"] == "EVIDENCE"
        assert result.ui_input_kind == "attachment"
        assert result.state_patch["forced_advance"] is True


@pytest.mark.django_db
class TestEvidencePhase:
    def test_attachment_done_advances_to_payout(self, conversation):
        conversation.state["phase"] = "EVIDENCE"
        conversation.save()
        flow = DisputeFlow()
        result = flow.handle_user_turn(
            conversation, "attachment_done", None, FakeAgent()
        )
        assert result.state_patch["phase"] == "PAYOUT"
        assert result.ui_input_kind == "form"
        assert result.ui_form_schema is not None

    def test_zero_photos_allowed(self, conversation):
        # Even with no Attachment rows, attachment_done is honored —
        # some disputes have no visual evidence (e.g. "tech never showed").
        conversation.state["phase"] = "EVIDENCE"
        conversation.save()
        flow = DisputeFlow()
        assert conversation.attachments.count() == 0
        result = flow.handle_user_turn(
            conversation, "attachment_done", None, FakeAgent()
        )
        assert result.state_patch["phase"] == "PAYOUT"

    def test_rejects_text_in_evidence(self, conversation):
        conversation.state["phase"] = "EVIDENCE"
        conversation.save()
        flow = DisputeFlow()
        with pytest.raises(UnsupportedMessageKind):
            flow.handle_user_turn(conversation, "text", "more details", FakeAgent())


@pytest.mark.django_db
class TestPayoutPhase:
    """PAYOUT submit now finalises the ticket inline (the former CONFIRM
    phase was folded into payout submit — see flow.py for the
    rationale). Submit returns ``is_terminal=True`` directly; no separate
    CONFIRM turn is required."""

    def test_form_finalises_ticket_inline(self, conversation):
        conversation.state["phase"] = "PAYOUT"
        conversation.save()
        # Add a USER message so the inline summarisation has something
        # to feed the LLM with.
        MessageFactory(
            conversation=conversation,
            role="USER",
            text="AC stopped working after the technician left.",
        )
        flow = DisputeFlow()
        agent = FakeAgent(
            text="Customer reported the AC stopped working after the technician left."
        )
        form_payload = {
            "bank_name": "HBL",
            "account_title": "Test Account",
            "iban": "PK36HABB0011223344556677",
        }
        result = flow.handle_user_turn(conversation, "form", form_payload, agent)
        # Single turn moves PAYOUT → CLOSED.
        assert result.is_terminal is True
        assert result.state_patch["phase"] == "CLOSED"
        assert result.state_patch["bank_draft"] == form_payload
        assert result.state_patch["needs_review_summary"] is False
        assert "AC stopped working" in result.state_patch["ai_summary"]

    def test_form_with_unsafe_summary_sets_needs_review(self, conversation):
        conversation.state["phase"] = "PAYOUT"
        conversation.save()
        MessageFactory(
            conversation=conversation, role="USER", text="AC broke."
        )
        flow = DisputeFlow()
        # Adversarial LLM: summary contains an IBAN. Output validation
        # rejects it, fallback substituted, needs_review_summary=True.
        agent = FakeAgent(
            text="Send refund to PK36HABB0011223344556677."
        )
        form_payload = {
            "bank_name": "HBL",
            "account_title": "Test Account",
            "iban": "PK36HABB0011223344556677",
        }
        result = flow.handle_user_turn(conversation, "form", form_payload, agent)
        assert result.is_terminal is True
        assert result.state_patch["needs_review_summary"] is True
        assert "PK36HABB0011223344556677" not in result.state_patch["ai_summary"]

    def test_rejects_text_in_payout(self, conversation):
        conversation.state["phase"] = "PAYOUT"
        conversation.save()
        flow = DisputeFlow()
        with pytest.raises(UnsupportedMessageKind):
            flow.handle_user_turn(conversation, "text", "hi", FakeAgent())


@pytest.mark.django_db
class TestClosedPhase:
    def test_raises_when_closed(self, conversation):
        conversation.state["phase"] = "CLOSED"
        conversation.save()
        flow = DisputeFlow()
        with pytest.raises(ConversationAlreadyClosed):
            flow.handle_user_turn(conversation, "text", "hi", FakeAgent())

    def test_is_terminal_reflects_state(self, conversation):
        flow = DisputeFlow()
        assert flow.is_terminal(conversation) is False
        conversation.state["phase"] = "CLOSED"
        conversation.save()
        assert flow.is_terminal(conversation) is True
