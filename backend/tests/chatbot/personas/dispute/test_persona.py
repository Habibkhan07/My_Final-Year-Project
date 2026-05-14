"""Tests for chatbot.personas.dispute.persona.DisputePersona.

Pins:
  - Eligibility: only the booking's customer + COMPLETED / COMPLETED_
    INSPECTION_ONLY booking can open a dispute.
  - IDOR: another user's booking → not eligible (DoesNotExist swallowed
    so the customer can't probe for booking ids).
  - find_existing_open returns an existing open conversation for the same
    booking, ignoring closed ones and other personas.
  - initial_state shape matches the flow's expectations.
"""
from __future__ import annotations

import pytest

from chatbot.personas.dispute.persona import DisputePersona
from tests.factories.accounts import UserFactory
from tests.factories.bookings import JobBookingCompletedFactory, JobBookingFactory
from tests.factories.chatbot import ConversationFactory


@pytest.mark.django_db
class TestIsEligibleToStart:
    def test_completed_booking_owned_by_user_is_eligible(self):
        b = JobBookingCompletedFactory()
        persona = DisputePersona()
        assert persona.is_eligible_to_start(b.customer, {"booking_id": b.id}) is True

    def test_other_users_booking_not_eligible(self):
        b = JobBookingCompletedFactory()
        other = UserFactory()
        persona = DisputePersona()
        # IDOR guard: wrong customer → DoesNotExist → False.
        assert persona.is_eligible_to_start(other, {"booking_id": b.id}) is False

    def test_non_completed_booking_not_eligible(self):
        b = JobBookingFactory()  # default status = AWAITING
        persona = DisputePersona()
        assert persona.is_eligible_to_start(b.customer, {"booking_id": b.id}) is False

    def test_missing_booking_id_not_eligible(self):
        user = UserFactory()
        persona = DisputePersona()
        assert persona.is_eligible_to_start(user, {}) is False

    def test_nonexistent_booking_id_not_eligible(self):
        user = UserFactory()
        persona = DisputePersona()
        assert persona.is_eligible_to_start(user, {"booking_id": 999999}) is False


@pytest.mark.django_db
class TestFindExistingOpen:
    def test_returns_open_conversation_for_booking(self):
        b = JobBookingCompletedFactory()
        conv = ConversationFactory(
            user=b.customer,
            persona_key="dispute",
            context={"booking_id": b.id},
            is_closed=False,
        )
        persona = DisputePersona()
        result = persona.find_existing_open(b.customer, {"booking_id": b.id})
        assert result is not None
        assert result.id == conv.id

    def test_ignores_closed_conversations(self):
        b = JobBookingCompletedFactory()
        ConversationFactory(
            user=b.customer,
            persona_key="dispute",
            context={"booking_id": b.id},
            is_closed=True,
        )
        persona = DisputePersona()
        assert persona.find_existing_open(b.customer, {"booking_id": b.id}) is None

    def test_ignores_other_persona_conversations(self):
        b = JobBookingCompletedFactory()
        ConversationFactory(
            user=b.customer,
            persona_key="general",  # different persona
            context={"booking_id": b.id},
            is_closed=False,
        )
        persona = DisputePersona()
        assert persona.find_existing_open(b.customer, {"booking_id": b.id}) is None

    def test_ignores_other_booking(self):
        b1 = JobBookingCompletedFactory()
        b2 = JobBookingCompletedFactory(customer=b1.customer)
        ConversationFactory(
            user=b1.customer,
            persona_key="dispute",
            context={"booking_id": b1.id},
            is_closed=False,
        )
        persona = DisputePersona()
        assert persona.find_existing_open(b1.customer, {"booking_id": b2.id}) is None

    def test_no_booking_id_returns_none(self):
        user = UserFactory()
        persona = DisputePersona()
        assert persona.find_existing_open(user, {}) is None


class TestInitialState:
    def test_shape_matches_flow_expectations(self):
        persona = DisputePersona()
        state = persona.initial_state({"booking_id": 1})
        assert state["phase"] == "UNDERSTAND"
        assert state["captured_fields"] == {}
        assert state["bank_draft"] == {}
        assert state["off_topic_count"] == 0
        assert state["forced_advance"] is False
