"""Tests for disputes.services.ticket_creation.create_from_chatbot_session.

Pins:
  - Creates SupportTicket with INTAKE_CHATBOT method.
  - chat_log JSON contains ai_summary, captured_fields, transcript, etc.
  - RefundIntent created when bank_draft has bank_name+iban; skipped when
    bank_draft is empty (e.g. UNDERSTAND-aborted conversation).
  - needs_review=True in chat_log when state.forced_advance=True OR
    state.needs_review_summary=True.
  - raw_narrative falls back to a sentinel when no USER messages exist.
  - Booking audit + realtime side effects fire via the shared helper:
    dispute_opened_at stamped, DISPUTE_OPENED broadcast to both audiences.
"""
from __future__ import annotations

from unittest.mock import patch

import pytest

from bookings.models import SupportTicket
from bookings.services import orchestrator
from realtime.constants.event_types import EventType
from disputes.models import RefundIntent
from disputes.services.ticket_creation import create_from_chatbot_session
from tests.factories.bookings import JobBookingCompletedFactory
from tests.factories.chatbot import (
    AttachmentFactory,
    ConversationFactory,
    MessageFactory,
)


@pytest.fixture
def captured_broadcasts():
    """Capture every ``_broadcast`` emit AND force ``transaction.on_commit``
    callbacks to fire inline (pytest-django wraps tests in a transaction
    that rolls back, so on_commit lambdas don't normally run).

    Mirrors the fixture in ``tests/bookings/services/test_orchestrator.py``;
    duplicated here to avoid cross-app conftest coupling.
    """
    calls = []

    def _capture(*, user, target_role, event_type, payload):
        calls.append({
            'user': user,
            'target_role': target_role,
            'event_type': event_type,
            'payload': payload,
        })

    def _immediate_on_commit(func, using=None):
        func()

    with patch.object(orchestrator, '_broadcast', side_effect=_capture), \
         patch('bookings.services.orchestrator.transaction.on_commit',
               side_effect=_immediate_on_commit):
        yield calls


def _build_closed_conversation(*, with_bank=True, with_messages=True,
                               with_attachments=False, extra_state=None):
    booking = JobBookingCompletedFactory()
    state = {
        "phase": "CLOSED",
        "captured_fields": {
            "issue_summary": "AC stopped working after technician left.",
            "amount_paid": "3500",
        },
        "ai_summary": "Customer reported AC failure after service.",
        "ai_summary_lang": "en",
        "bank_draft": {},
        "forced_advance": False,
        "needs_review_summary": False,
    }
    if with_bank:
        state["bank_draft"] = {
            "bank_name": "HBL",
            "account_title": "Test User",
            "iban": "PK36HABB0011223344556677",
        }
    if extra_state:
        state.update(extra_state)
    conv = ConversationFactory(
        user=booking.customer,
        persona_key="dispute",
        context={"booking_id": booking.id},
        state=state,
        is_closed=True,
    )
    if with_messages:
        MessageFactory(
            conversation=conv,
            role="USER",
            text="AC stopped working after technician left.",
            phase="UNDERSTAND",
        )
        MessageFactory(
            conversation=conv,
            role="BOT",
            text="Sorry to hear that. What was the amount paid?",
            phase="UNDERSTAND",
        )
        MessageFactory(
            conversation=conv,
            role="USER",
            text="I paid Rs 3500 total.",
            phase="UNDERSTAND",
        )
    if with_attachments:
        AttachmentFactory(conversation=conv)
    return conv


@pytest.mark.django_db
class TestCreateFromChatbotSession:
    def test_creates_supportticket_with_chatbot_intake(self):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)
        assert ticket.pk is not None
        assert ticket.dispute_intake_method == SupportTicket.INTAKE_CHATBOT
        assert ticket.booking_id == conv.context["booking_id"]
        assert ticket.opened_by_id == conv.user_id

    def test_raw_narrative_concatenates_user_messages(self):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)
        assert "AC stopped working" in ticket.initial_reason
        assert "Rs 3500" in ticket.initial_reason
        # BOT messages NOT in narrative.
        assert "Sorry to hear" not in ticket.initial_reason

    def test_chat_log_contains_ai_summary_and_fields(self):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)
        log = ticket.chat_log
        assert log["ai_summary"] == "Customer reported AC failure after service."
        assert log["ai_summary_lang"] == "en"
        assert log["captured_fields"]["issue_summary"] == "AC stopped working after technician left."
        assert log["captured_fields"]["amount_paid"] == "3500"
        assert log["conversation_id"] == conv.id

    def test_chat_log_contains_messages_snapshot(self):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)
        log = ticket.chat_log
        assert len(log["messages"]) == 3
        roles = [m["role"] for m in log["messages"]]
        assert roles == ["USER", "BOT", "USER"]

    def test_chat_log_contains_attachment_paths(self):
        conv = _build_closed_conversation(with_attachments=True)
        ticket = create_from_chatbot_session(conversation=conv)
        log = ticket.chat_log
        assert len(log["attachments"]) == 1
        assert log["attachments"][0]["mime_type"] == "image/jpeg"

    def test_creates_refund_intent_when_bank_draft_present(self):
        conv = _build_closed_conversation(with_bank=True)
        ticket = create_from_chatbot_session(conversation=conv)
        intent = RefundIntent.objects.get(ticket=ticket)
        assert intent.bank_name == "HBL"
        assert intent.account_title == "Test User"
        assert intent.iban == "PK36HABB0011223344556677"

    def test_skips_refund_intent_when_bank_draft_empty(self):
        # Conversation aborted at UNDERSTAND — bank form never submitted.
        conv = _build_closed_conversation(with_bank=False)
        ticket = create_from_chatbot_session(conversation=conv)
        assert not RefundIntent.objects.filter(ticket=ticket).exists()

    def test_needs_review_when_forced_advance(self):
        conv = _build_closed_conversation(
            extra_state={"forced_advance": True}
        )
        ticket = create_from_chatbot_session(conversation=conv)
        assert ticket.chat_log["needs_review"] is True
        assert ticket.chat_log["needs_review_reason"] == "forced_advance"

    def test_needs_review_when_summary_validation_failed(self):
        conv = _build_closed_conversation(
            extra_state={
                "needs_review_summary": True,
                "needs_review_reason": "output_contains_iban",
            }
        )
        ticket = create_from_chatbot_session(conversation=conv)
        assert ticket.chat_log["needs_review"] is True
        assert ticket.chat_log["needs_review_reason"] == "output_contains_iban"

    def test_needs_review_false_on_clean_conversation(self):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)
        assert ticket.chat_log["needs_review"] is False

    def test_missing_booking_id_raises(self):
        booking = JobBookingCompletedFactory()
        conv = ConversationFactory(
            user=booking.customer,
            persona_key="dispute",
            context={},  # no booking_id
            is_closed=True,
        )
        with pytest.raises(ValueError):
            create_from_chatbot_session(conversation=conv)

    def test_empty_narrative_uses_sentinel(self):
        conv = _build_closed_conversation(with_messages=False)
        ticket = create_from_chatbot_session(conversation=conv)
        assert "see chat_log" in ticket.initial_reason


@pytest.mark.django_db
class TestDisputeOpenedSideEffects:
    """The chatbot intake path MUST produce the same booking-side audit +
    realtime footprint as the form intake path. Pinned via the shared
    ``apply_dispute_opened_side_effects`` helper.
    """

    def test_dispute_opened_at_stamped_on_first_chatbot_ticket(
        self, captured_broadcasts,
    ):
        conv = _build_closed_conversation()
        assert conv.context["booking_id"]

        from bookings.models import JobBooking
        before = JobBooking.objects.get(id=conv.context["booking_id"])
        assert before.dispute_opened_at is None

        create_from_chatbot_session(conversation=conv)

        after = JobBooking.objects.get(id=conv.context["booking_id"])
        assert after.dispute_opened_at is not None

    def test_broadcasts_dispute_opened_to_both_audiences(
        self, captured_broadcasts,
    ):
        conv = _build_closed_conversation()
        ticket = create_from_chatbot_session(conversation=conv)

        events = [
            c for c in captured_broadcasts
            if c["event_type"] == EventType.DISPUTE_OPENED
        ]
        assert len(events) == 2, (
            "Chatbot intake must broadcast to both customer and technician "
            f"(got {len(events)} broadcasts: {events!r})"
        )
        assert {e["target_role"] for e in events} == {"customer", "technician"}
        # Payload carries the ticket id and customer-opener role.
        payload = events[0]["payload"]
        assert payload["ticket_id"] == ticket.id
        assert payload["opened_by_role"] == "customer"
        assert payload["job_id"] == conv.context["booking_id"]

    def test_completed_booking_status_preserved_not_flipped_to_disputed(
        self, captured_broadcasts,
    ):
        # Chatbot dispute path only runs on COMPLETED / COMPLETED_INSPECTION_ONLY
        # — both terminal. Status must NOT flip to DISPUTED (that would erase
        # the completion record). dispute_opened_at carries the audit instead.
        conv = _build_closed_conversation()

        from bookings.models import JobBooking
        before_status = JobBooking.objects.get(
            id=conv.context["booking_id"]
        ).status
        assert before_status == JobBooking.STATUS_COMPLETED

        create_from_chatbot_session(conversation=conv)

        after_status = JobBooking.objects.get(
            id=conv.context["booking_id"]
        ).status
        assert after_status == JobBooking.STATUS_COMPLETED  # preserved
