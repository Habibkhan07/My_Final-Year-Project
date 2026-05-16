"""Tests for chatbot.personas.general — the help Q&A persona.

Covers:
  - Persona shape + registration in the framework registry.
  - Eligibility (always True for authenticated users).
  - Flow opening turn (templated, no LLM call).
  - Flow text turns (live service list, PII redaction, output validation
    fallback paths, message-kind rejection).
  - API smoke through /api/chat/general/start/ and /message/ with the
    Gemini adapter patched out via FakeAgent.

The FakeAgent records every call so we can assert what the flow sent
to the LLM (system prompt content, redacted user message, etc.).
"""
from __future__ import annotations

from unittest.mock import patch

import pytest
from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from chatbot import personas
from chatbot.models import Conversation, Message
from chatbot.personas.dispute.flow import (
    ConversationAlreadyClosed,
    UnsupportedMessageKind,
)
from chatbot.personas.general.flow import (
    GeneralChatFlow,
    _HISTORY_MAX_MESSAGES,
)
from chatbot.personas.general.persona import GeneralHelpPersona
from chatbot.services import conversation as conv_service
from tests.chatbot._fakes import FakeAgent
from tests.factories.accounts import UserFactory
from tests.factories.catalog import ServiceFactory
from tests.factories.chatbot import ConversationFactory, MessageFactory


# ---- Persona shape & registration ---------------------------------------


class TestPersonaShape:
    def test_key_and_display_name(self):
        p = GeneralHelpPersona()
        assert p.key == "general"
        assert p.display_name == "Help"

    def test_protocol_surface_present(self):
        p = GeneralHelpPersona()
        # Required attributes
        assert isinstance(p.flow_engine, GeneralChatFlow)
        assert p.tools == []
        assert p.response_schema is None
        # Required methods (callables, not properties)
        assert callable(p.is_eligible_to_start)
        assert callable(p.initial_state)
        assert callable(p.on_close)
        # Resume opt-out: find_existing_open deliberately absent so the
        # orchestration service treats every start as a fresh session.
        assert not hasattr(p, "find_existing_open")


class TestRegistration:
    def test_persona_registered_in_framework(self):
        # ChatbotConfig.ready registered both shipped personas at app load.
        # Looking up "general" should not raise PersonaNotFound.
        p = personas.get("general")
        assert isinstance(p, GeneralHelpPersona)


# ---- Eligibility & state ------------------------------------------------


@pytest.mark.django_db
class TestEligibility:
    def test_any_authenticated_user_is_eligible(self):
        user = UserFactory()
        p = GeneralHelpPersona()
        assert p.is_eligible_to_start(user, {}) is True

    def test_eligibility_ignores_context_contents(self):
        # General help has no context-driven gate — any dict is fine.
        user = UserFactory()
        p = GeneralHelpPersona()
        assert p.is_eligible_to_start(user, {"booking_id": 9999}) is True


class TestInitialState:
    def test_returns_phase_chat(self):
        state = GeneralHelpPersona().initial_state({})
        assert state == {"phase": "CHAT"}


@pytest.mark.django_db
class TestOnClose:
    def test_returns_empty_dict(self):
        conv = ConversationFactory(persona_key="general", context={})
        assert GeneralHelpPersona().on_close(conv) == {}

    def test_is_idempotent(self):
        # Calling on_close twice must not raise or produce different
        # output — general help creates no rows, so this is trivially
        # idempotent, but the test pins the contract.
        conv = ConversationFactory(persona_key="general", context={})
        p = GeneralHelpPersona()
        assert p.on_close(conv) == p.on_close(conv) == {}


# ---- Flow: opening turn -------------------------------------------------


@pytest.mark.django_db
class TestOpeningTurn:
    def test_returns_greeting_text_directive_without_calling_agent(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        agent = FakeAgent()
        flow = GeneralChatFlow()

        result = flow.opening_turn(conv, agent)

        assert "Karigar" in result.bot_message
        assert result.ui_input_kind == "text"
        assert result.ui_form_schema is None
        assert result.is_terminal is False
        # Critical: opening turn is templated — no quota spend.
        assert agent.calls == []


# ---- Flow: text turns ---------------------------------------------------


@pytest.mark.django_db
class TestHandleUserTurnText:
    def test_calls_agent_with_live_service_list_in_prompt(self):
        # Three active services with icons + one stub (no icon) + one
        # inactive. Only the three real ones should appear in the prompt.
        ServiceFactory(name="AC Repair", icon_name="ac_repair", display_order=1)
        ServiceFactory(name="Plumbing", icon_name="plumbing", display_order=2)
        ServiceFactory(name="Electrician", icon_name="electrician", display_order=3)
        ServiceFactory(name="Stub Category", icon_name="", display_order=99)
        ServiceFactory(
            name="Old Category", icon_name="old", is_active=False, display_order=4
        )

        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        agent = FakeAgent(text="Sure, AC Repair is one of our services.")
        flow = GeneralChatFlow()

        flow.handle_user_turn(conv, "text", "what services do you offer?", agent)

        assert len(agent.calls) == 1
        prompt = agent.calls[0]["system_prompt"]
        assert "AC Repair" in prompt
        assert "Plumbing" in prompt
        assert "Electrician" in prompt
        # Excluded because of empty icon_name (FE-side stub).
        assert "Stub Category" not in prompt
        # Excluded because is_active=False.
        assert "Old Category" not in prompt
        # Anchored policy facts present.
        assert "Rs. 500" in prompt
        assert "within 3 working days" in prompt

    def test_redacts_pii_before_agent_call(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        agent = FakeAgent(text="Got it.")
        flow = GeneralChatFlow()

        # Pakistani-shaped IBAN + phone in user input — both must be
        # substituted with [REDACTED] before reaching the LLM.
        msg = "My iban is PK36SCBL0000001123456702 and phone +923001234567."
        flow.handle_user_turn(conv, "text", msg, agent)

        sent = agent.calls[0]["user_message"]
        assert "PK36SCBL0000001123456702" not in sent
        assert "+923001234567" not in sent
        assert "[REDACTED]" in sent

    def test_returns_text_directive_not_terminal(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        agent = FakeAgent(text="Booking works like this...")
        flow = GeneralChatFlow()

        result = flow.handle_user_turn(conv, "text", "how does booking work?", agent)

        assert result.bot_message == "Booking works like this..."
        assert result.ui_input_kind == "text"
        assert result.ui_form_schema is None
        assert result.is_terminal is False
        assert result.state_patch == {}

    def test_falls_back_when_adapter_signals_fallback(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        # Even though text is present, fallback_used=True forces the
        # canned safe message — that's the adapter's "something went
        # wrong but here's a safe string" signal.
        agent = FakeAgent(text="actual llm output", fallback_used=True)
        flow = GeneralChatFlow()

        result = flow.handle_user_turn(conv, "text", "anything", agent)

        assert result.bot_message != "actual llm output"
        # The canned turn_message fallback from content_safety.
        assert "Sorry" in result.bot_message or "rephrase" in result.bot_message

    def test_falls_back_when_output_contains_url(self):
        # The framework's output validator rejects responses containing
        # URLs (a hallucination smell). On rejection the flow swaps in
        # the canned safe string — proves persona-side validate_output
        # is actually wired.
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        agent = FakeAgent(text="Check https://example.com for details.")
        flow = GeneralChatFlow()

        result = flow.handle_user_turn(conv, "text", "where can i find info?", agent)

        assert "https://" not in result.bot_message
        assert "Sorry" in result.bot_message or "rephrase" in result.bot_message

    def test_history_capped_to_last_30_messages(self):
        # 50 prior BOT messages + the latest USER message that we'll send.
        # _build_history drops the trailing USER and slices to last 30,
        # so the LLM only sees 30 of the 50 older BOT lines (the most
        # recent ones — index 20..49 in chronological order).
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        for i in range(50):
            MessageFactory(
                conversation=conv,
                role=Message.ROLE_BOT,
                text=f"bot-{i}",
                phase="CHAT",
            )
        # Trailing USER message (the one being processed) — dropped, not
        # counted toward the cap.
        MessageFactory(
            conversation=conv,
            role=Message.ROLE_USER,
            text="latest user",
            phase="CHAT",
        )

        agent = FakeAgent(text="ok")
        GeneralChatFlow().handle_user_turn(conv, "text", "latest user", agent)

        history = agent.calls[0]["history"]
        assert len(history) == 30
        # Oldest kept = bot-20 (50 BOT msgs, drop first 20, keep last 30).
        assert history[0]["text"] == "bot-20"
        # Newest kept = bot-49 (the trailing USER was dropped before slicing).
        assert history[-1]["text"] == "bot-49"

    def test_builds_history_from_prior_messages_excluding_latest_user(self):
        # The orchestration service writes the just-arrived USER message
        # to DB before calling handle_user_turn. _build_history must drop
        # it so the LLM doesn't see it twice (we pass it as user_message
        # to agent.generate separately).
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        MessageFactory(conversation=conv, role=Message.ROLE_BOT, text="Hi!", phase="CHAT")
        MessageFactory(
            conversation=conv, role=Message.ROLE_USER, text="What's the fee?", phase="CHAT"
        )
        MessageFactory(
            conversation=conv, role=Message.ROLE_BOT, text="Rs. 500.", phase="CHAT"
        )
        # The latest user message — must be dropped from history.
        MessageFactory(
            conversation=conv, role=Message.ROLE_USER, text="Latest question", phase="CHAT"
        )
        agent = FakeAgent(text="ok")
        flow = GeneralChatFlow()

        flow.handle_user_turn(conv, "text", "Latest question", agent)

        history = agent.calls[0]["history"]
        texts = [h["text"] for h in history]
        assert "Hi!" in texts
        assert "What's the fee?" in texts
        assert "Rs. 500." in texts
        assert "Latest question" not in texts  # dropped — sent as user_message


# ---- Flow: message-kind rejection ---------------------------------------


@pytest.mark.django_db
class TestHandleUserTurnRejectsNonText:
    def test_form_kind_raises_unsupported(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        flow = GeneralChatFlow()
        with pytest.raises(UnsupportedMessageKind):
            flow.handle_user_turn(conv, "form", {"foo": "bar"}, FakeAgent())

    def test_attachment_done_kind_raises_unsupported(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        flow = GeneralChatFlow()
        with pytest.raises(UnsupportedMessageKind):
            flow.handle_user_turn(conv, "attachment_done", None, FakeAgent())

    def test_closed_conversation_raises(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CLOSED"}
        )
        flow = GeneralChatFlow()
        with pytest.raises(ConversationAlreadyClosed):
            flow.handle_user_turn(conv, "text", "anything", FakeAgent())


# ---- API smoke ----------------------------------------------------------


@pytest.fixture
def api():
    return APIClient()


@pytest.fixture
def authed(api):
    user = UserFactory()
    api.force_authenticate(user=user)
    api.user = user  # stash for assertions
    return api


def _patch_agent(*, text="Booking is simple — search, request, pay cash."):
    fake = FakeAgent(text=text)
    return (
        patch(
            "chatbot.services.conversation.get_default_agent",
            return_value=fake,
        ),
        fake,
    )


@pytest.mark.django_db
class TestAPISmoke:
    def test_start_creates_conversation_with_greeting(self, authed):
        # Seed at least one service so the prompt builder has data later.
        ServiceFactory(name="AC Repair", icon_name="ac_repair")

        patcher, fake = _patch_agent()
        with patcher:
            resp = authed.post(
                "/api/chat/general/start/", {"context": {}}, format="json"
            )

        assert resp.status_code == 201, resp.content
        body = resp.json()
        assert body["persona_key"] == "general"
        assert body["current_phase"] == "CHAT"
        assert "Karigar" in body["bot_message"]
        assert body["ui_input_kind"] == "text"

        # Conversation row exists for the authed user.
        conv = Conversation.objects.get(id=body["conversation_id"])
        assert conv.user_id == authed.user.id
        assert conv.persona_key == "general"
        assert conv.is_closed is False

        # Opening turn must NOT spend LLM quota — templated greeting.
        assert fake.calls == []

    def test_message_endpoint_returns_bot_reply_and_persists(self, authed):
        ServiceFactory(name="AC Repair", icon_name="ac_repair")

        # Start a conversation first.
        with _patch_agent()[0]:
            start_resp = authed.post(
                "/api/chat/general/start/", {"context": {}}, format="json"
            )
        conv_id = start_resp.json()["conversation_id"]

        # Send a text turn — agent reply mocked.
        patcher, fake = _patch_agent(
            text="Every visit has a flat Rs. 500 inspection fee."
        )
        with patcher:
            resp = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {"kind": "text", "payload": "what's the inspection fee?"},
                format="json",
            )

        assert resp.status_code == 200, resp.content
        body = resp.json()
        assert "Rs. 500" in body["bot_message"]
        assert body["ui_input_kind"] == "text"
        assert body["is_closed"] is False

        # Persistence: greeting (BOT) + user turn (USER) + bot reply (BOT).
        msgs = list(
            Message.objects.filter(conversation_id=conv_id).order_by("created_at")
        )
        roles = [m.role for m in msgs]
        assert roles == [Message.ROLE_BOT, Message.ROLE_USER, Message.ROLE_BOT]
        assert msgs[-1].text == "Every visit has a flat Rs. 500 inspection fee."

        # LLM was called once with the live service list in the prompt.
        assert len(fake.calls) == 1
        assert "AC Repair" in fake.calls[0]["system_prompt"]

    def test_message_form_kind_returns_400_unsupported(self, authed):
        ServiceFactory(name="AC Repair", icon_name="ac_repair")

        with _patch_agent()[0]:
            start_resp = authed.post(
                "/api/chat/general/start/", {"context": {}}, format="json"
            )
        conv_id = start_resp.json()["conversation_id"]

        # General persona rejects form — view translates UnsupportedMessageKind
        # to 400 unsupported_message_kind.
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {"kind": "form", "payload": {"bank_name": "X", "account_title": "Y",
                                          "iban": "PK36SCBL0000001123456702"}},
            format="json",
        )
        assert resp.status_code == 400
        body = resp.json()
        assert body["code"] == "unsupported_message_kind"


# ---- History window: edge cases + DB-layer cap --------------------------


@pytest.mark.django_db
class TestHistoryWindow:
    """Pins the LLM-history slicing contract.

    The cap exists to keep per-turn LLM cost bounded as a Help session
    grows (the persona has no auto-close — see flag.md #56). The DB
    fetch is also bounded at the ORM layer so a long conversation
    doesn't materialise thousands of rows in memory.
    """

    def _flow_and_conv(self):
        conv = ConversationFactory(
            persona_key="general", context={}, state={"phase": "CHAT"}
        )
        return GeneralChatFlow(), conv

    def test_history_below_cap_returns_all_messages(self):
        # 5 BOT messages + the just-arrived trailing USER. After dropping
        # the trailing USER, 5 entries remain — well below the 30 cap.
        flow, conv = self._flow_and_conv()
        for i in range(5):
            MessageFactory(
                conversation=conv,
                role=Message.ROLE_BOT,
                text=f"bot-{i}",
                phase="CHAT",
            )
        MessageFactory(
            conversation=conv,
            role=Message.ROLE_USER,
            text="latest",
            phase="CHAT",
        )

        agent = FakeAgent(text="ok")
        flow.handle_user_turn(conv, "text", "latest", agent)

        history = agent.calls[0]["history"]
        assert len(history) == 5
        assert [h["text"] for h in history] == [f"bot-{i}" for i in range(5)]

    def test_history_at_exact_cap_returns_all_30(self):
        # Exactly 30 BOT messages + trailing USER. Cap should retain all
        # 30 (boundary condition on the ``> cap`` guard).
        flow, conv = self._flow_and_conv()
        for i in range(_HISTORY_MAX_MESSAGES):
            MessageFactory(
                conversation=conv,
                role=Message.ROLE_BOT,
                text=f"bot-{i}",
                phase="CHAT",
            )
        MessageFactory(
            conversation=conv,
            role=Message.ROLE_USER,
            text="latest",
            phase="CHAT",
        )

        agent = FakeAgent(text="ok")
        flow.handle_user_turn(conv, "text", "latest", agent)

        history = agent.calls[0]["history"]
        assert len(history) == _HISTORY_MAX_MESSAGES
        assert history[0]["text"] == "bot-0"
        assert history[-1]["text"] == f"bot-{_HISTORY_MAX_MESSAGES - 1}"

    def test_history_mixed_roles_order_preserved_after_cap(self):
        # 20 alternating BOT/USER pairs = 40 messages, plus trailing USER.
        # After dropping trailing, 40 entries; cap retains last 30 in
        # chronological order. The slice should preserve role alternation
        # exactly as inserted.
        flow, conv = self._flow_and_conv()
        for i in range(20):
            MessageFactory(
                conversation=conv,
                role=Message.ROLE_BOT,
                text=f"bot-{i}",
                phase="CHAT",
            )
            MessageFactory(
                conversation=conv,
                role=Message.ROLE_USER,
                text=f"user-{i}",
                phase="CHAT",
            )
        MessageFactory(
            conversation=conv,
            role=Message.ROLE_USER,
            text="trailing",
            phase="CHAT",
        )

        agent = FakeAgent(text="ok")
        flow.handle_user_turn(conv, "text", "trailing", agent)

        history = agent.calls[0]["history"]
        assert len(history) == _HISTORY_MAX_MESSAGES
        # 40 paired messages minus trailing dropped → cap keeps last 30 =
        # bot-5, user-5, bot-6, user-6, ..., bot-19, user-19.
        # First kept is bot-5; verify role + text alternation.
        for idx, h in enumerate(history):
            pair_index = 5 + (idx // 2)
            if idx % 2 == 0:
                assert h["role"] == "bot"
                assert h["text"] == f"bot-{pair_index}"
            else:
                assert h["role"] == "user"
                assert h["text"] == f"user-{pair_index}"

    def test_history_query_limits_at_db_layer_not_in_python(self):
        # The optimization: even with thousands of messages in the DB,
        # we should only ever fetch cap+1 = 31 rows. Without the LIMIT
        # at the ORM layer, this would materialise the full list and
        # slice in Python (slow at scale).
        flow, conv = self._flow_and_conv()
        # 1000 prior BOT messages — would be a 1000-row fetch without
        # the LIMIT in _build_history.
        Message.objects.bulk_create(
            [
                Message(
                    conversation=conv,
                    role=Message.ROLE_BOT,
                    text=f"bot-{i}",
                    phase="CHAT",
                    lang="",
                )
                for i in range(1000)
            ]
        )
        MessageFactory(
            conversation=conv,
            role=Message.ROLE_USER,
            text="trailing",
            phase="CHAT",
        )

        agent = FakeAgent(text="ok")
        with CaptureQueriesContext(connection) as ctx:
            flow.handle_user_turn(conv, "text", "trailing", agent)

        # Locate the messages-table SELECT issued by _build_history. The
        # turn also persists messages (orchestration layer would, but we
        # called the flow directly so the only message-side traffic is
        # the history fetch). Filter loosely on the table name.
        msg_selects = [
            q["sql"]
            for q in ctx.captured_queries
            if "chatbot_message" in q["sql"].lower()
            and q["sql"].lstrip().upper().startswith("SELECT")
        ]
        assert len(msg_selects) == 1, (
            "expected exactly one message SELECT from _build_history, "
            f"got {len(msg_selects)}: {msg_selects}"
        )
        # The LIMIT count is the cap + 1 (extra slot for a possible
        # trailing USER we'll drop). Lock to the constant so a future
        # cap bump updates here automatically.
        assert f"LIMIT {_HISTORY_MAX_MESSAGES + 1}" in msg_selects[0]

        # And the LLM history actually retains the 30 newest BOT
        # messages (oldest=bot-970, newest=bot-999), proving the slice
        # was correct end-to-end.
        history = agent.calls[0]["history"]
        assert len(history) == _HISTORY_MAX_MESSAGES
        assert history[0]["text"] == "bot-970"
        assert history[-1]["text"] == "bot-999"
