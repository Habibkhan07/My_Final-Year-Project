"""In-process fakes for chatbot tests — no LLM network calls.

Importable as ``from tests.chatbot._fakes import FakeAgent``. The leading
underscore signals "test helper, not a fixture" so pytest doesn't try to
collect it.

``FakeAgent`` satisfies the ``ConversationalAgent`` Protocol structurally.
Tests configure return values per-call or set defaults at construction
time; the ``calls`` log lets tests assert what the flow asked the LLM.
"""
from __future__ import annotations

from typing import Any


class FakeAgent:
    """Pre-programmed LLM stand-in.

    Two modes:
      - Default: return ``self.text`` and ``self.structured`` for every
        ``generate`` call.
      - Scripted: pass ``responses=[...]`` and the agent pops one per
        call. ``StopIteration`` (out of scripted responses) returns the
        default text/structured.
    """

    def __init__(
        self,
        *,
        text: str = "Hello.",
        structured: dict | None = None,
        fallback_used: bool = False,
        responses: list[dict] | None = None,
    ):
        self.text = text
        self.structured = structured
        self.fallback_used = fallback_used
        self._responses = list(responses or [])
        self.calls: list[dict] = []

    def generate(
        self,
        *,
        system_prompt: str,
        history: list[dict],
        user_message: str,
        response_schema: dict | None = None,
        tools: list | None = None,
        extra_validators: list | None = None,
    ) -> dict:
        # ``extra_validators`` accepted for Protocol parity with
        # ``GeminiAgent.generate`` — not exercised by the v1 flow, but
        # callers depending on the Protocol shape must not TypeError here.
        del extra_validators
        self.calls.append(
            {
                "system_prompt": system_prompt,
                "history": history,
                "user_message": user_message,
                "response_schema": response_schema,
                "tools": tools,
            }
        )
        if self._responses:
            r = self._responses.pop(0)
            return {
                "text": r.get("text", self.text),
                "structured": r.get("structured", self.structured),
                "tool_calls": [],
                "finish_reason": r.get("finish_reason", "stop"),
                "fallback_used": r.get("fallback_used", self.fallback_used),
            }
        return {
            "text": self.text,
            "structured": self.structured,
            "tool_calls": [],
            "finish_reason": "stop",
            "fallback_used": self.fallback_used,
        }
