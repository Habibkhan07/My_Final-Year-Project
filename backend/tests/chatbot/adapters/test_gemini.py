"""Tests for chatbot.adapters.gemini.GeminiAgent.

The SDK client is injected via the ``_client`` kwarg so no real network
calls are made. The real ``google.genai.types`` module IS used —
constructing Pydantic models is local and side-effect-free.

Pins:
  - Empty api_key → ImproperlyConfigured at construction (fail-loud).
  - Successful structured-output call returns parsed dict + extracted
    message_to_user as text.
  - Successful free-text call returns raw text + structured=None.
  - SDK exception → fallback AgentOutput (fallback_used=True).
  - JSON parse failure → fallback.
  - response.text raising → fallback.
  - History translation: 'bot' → 'model' role for Gemini.
  - user_message redacted before send (defense in depth).
  - tools parameter accepted but ignored (returns tool_calls=[]).
"""
from __future__ import annotations

import json
from unittest.mock import MagicMock, PropertyMock

import pytest

from chatbot.adapters.gemini import GeminiAgent


# ---- Helpers -------------------------------------------------------------

def _make_mock_client(*, text: str = "OK", raise_on_call: Exception | None = None,
                     text_raises: Exception | None = None) -> MagicMock:
    """Build a mock SDK client with configurable response behavior."""
    client = MagicMock()
    response = MagicMock()
    if text_raises is not None:
        type(response).text = PropertyMock(side_effect=text_raises)
    else:
        response.text = text
    if raise_on_call is not None:
        client.models.generate_content.side_effect = raise_on_call
    else:
        client.models.generate_content.return_value = response
    return client


def _make_agent(client: MagicMock) -> GeminiAgent:
    return GeminiAgent(
        model_name="gemini-2.5-flash",
        api_key="any-test-key",
        _client=client,
    )


# ---- Tests ---------------------------------------------------------------

class TestInit:
    def test_empty_api_key_raises_improperly_configured(self):
        from django.core.exceptions import ImproperlyConfigured

        with pytest.raises(ImproperlyConfigured):
            GeminiAgent(model_name="gemini-2.5-flash", api_key="")

    def test_injected_client_skips_real_init(self):
        # Smoke: should construct without error and store the mock.
        client = MagicMock()
        agent = GeminiAgent(
            model_name="gemini-2.5-flash",
            api_key="",  # ignored when _client is injected
            _client=client,
        )
        assert agent._client is client


class TestGenerateFreeText:
    def test_returns_raw_text_without_schema(self):
        client = _make_mock_client(text="Hello there.")
        agent = _make_agent(client)

        out = agent.generate(
            system_prompt="Be friendly.",
            history=[],
            user_message="Hi",
        )
        assert out["text"] == "Hello there."
        assert out["structured"] is None
        assert out["fallback_used"] is False
        assert out["tool_calls"] == []
        assert out["finish_reason"] == "stop"

    def test_sends_user_message_through_translated_contents(self):
        client = _make_mock_client(text="Got it.")
        agent = _make_agent(client)
        agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="Hello",
        )
        # Inspect what the SDK was called with.
        call = client.models.generate_content.call_args
        contents = call.kwargs["contents"]
        # Last entry should be the user message.
        assert contents[-1].role == "user"
        assert contents[-1].parts[0].text == "Hello"

    def test_history_bot_role_translated_to_model(self):
        client = _make_mock_client(text="OK")
        agent = _make_agent(client)
        agent.generate(
            system_prompt="Sys",
            history=[
                {"role": "user", "text": "first"},
                {"role": "bot", "text": "reply"},
            ],
            user_message="follow-up",
        )
        contents = client.models.generate_content.call_args.kwargs["contents"]
        roles = [c.role for c in contents]
        # user, model (translated from bot), user
        assert roles == ["user", "model", "user"]

    def test_system_prompt_passed_via_config(self):
        client = _make_mock_client(text="OK")
        agent = _make_agent(client)
        agent.generate(
            system_prompt="You are a robot.",
            history=[],
            user_message="hi",
        )
        config = client.models.generate_content.call_args.kwargs["config"]
        assert config.system_instruction == "You are a robot."

    def test_redacts_user_message_defense_in_depth(self):
        client = _make_mock_client(text="OK")
        agent = _make_agent(client)
        agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="My IBAN is PK36HABB0011223344556677",
        )
        contents = client.models.generate_content.call_args.kwargs["contents"]
        last_text = contents[-1].parts[0].text
        assert "PK36HABB0011223344556677" not in last_text
        assert "[REDACTED]" in last_text


class TestGenerateStructured:
    def test_returns_parsed_structured_and_extracted_text(self):
        payload = {
            "message_to_user": "Got it. Tell me when this happened.",
            "phase_complete": False,
            "fields_captured": {"issue_summary": "AC failure"},
            "asked_off_topic": False,
        }
        client = _make_mock_client(text=json.dumps(payload))
        agent = _make_agent(client)

        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="AC stopped working",
            response_schema={"type": "object"},
        )
        # message_to_user is what the user sees, not the raw JSON.
        assert out["text"] == "Got it. Tell me when this happened."
        assert out["structured"] == payload
        assert out["fallback_used"] is False

    def test_sets_mime_type_and_schema_in_config(self):
        client = _make_mock_client(text='{"message_to_user": "ok", "phase_complete": false, "fields_captured": {}, "asked_off_topic": false}')
        agent = _make_agent(client)
        schema = {"type": "object", "properties": {}}
        agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
            response_schema=schema,
        )
        config = client.models.generate_content.call_args.kwargs["config"]
        assert config.response_mime_type == "application/json"
        assert config.response_schema == schema

    def test_malformed_json_returns_fallback(self):
        client = _make_mock_client(text="not valid json {{{")
        agent = _make_agent(client)

        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
            response_schema={"type": "object"},
        )
        assert out["fallback_used"] is True
        assert out["structured"] is None
        assert out["finish_reason"] == "fallback"
        # The fallback text is the canned safe message — not the malformed JSON.
        assert "{{{" not in out["text"]

    def test_structured_without_message_to_user_falls_back(self):
        # If the LLM returns valid JSON but omits ``message_to_user``,
        # we fall back to a canned safe string — leaking the raw JSON
        # to the user as a chat bubble would be a worse failure mode.
        # Gemini's response_schema is best-effort, not strict, so this
        # case is reachable in production.
        payload = {"phase_complete": False, "fields_captured": {}, "asked_off_topic": False}
        client = _make_mock_client(text=json.dumps(payload))
        agent = _make_agent(client)
        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
            response_schema={"type": "object"},
        )
        assert out["fallback_used"] is True
        assert out["finish_reason"] == "fallback"
        # Raw JSON must NOT bleed into the user-facing text.
        assert "phase_complete" not in out["text"]


class TestGenerateFailures:
    def test_sdk_exception_returns_fallback(self):
        client = _make_mock_client(raise_on_call=RuntimeError("network died"))
        agent = _make_agent(client)
        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
        )
        assert out["fallback_used"] is True
        assert out["finish_reason"] == "fallback"
        # User-facing fallback message is a non-empty string.
        assert out["text"]

    def test_response_text_property_raises_returns_fallback(self):
        # Simulates a safety-blocked response where .text raises.
        client = _make_mock_client(text_raises=RuntimeError("blocked"))
        agent = _make_agent(client)
        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
        )
        assert out["fallback_used"] is True


class TestToolsBranchNotImplemented:
    def test_tools_parameter_accepted_but_ignored(self):
        # Tools branch is deferred to v1.1. Adapter must accept the
        # parameter (Protocol stability) but always return tool_calls=[].
        client = _make_mock_client(text="OK")
        agent = _make_agent(client)
        out = agent.generate(
            system_prompt="Sys",
            history=[],
            user_message="hi",
            tools=[{"name": "fake_tool"}],
        )
        assert out["tool_calls"] == []
