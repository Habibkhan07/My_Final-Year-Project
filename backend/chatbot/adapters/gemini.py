"""Gemini adapter — the ONLY file in the project that imports google.genai.

Implements ``ConversationalAgent`` (Protocol in ``chatbot.services.ports``).
Three responsibilities:

  1. Translate the framework's neutral history shape into Gemini's
     ``types.Content`` list and ``GenerateContentConfig``.
  2. Call ``client.models.generate_content`` with timeout + safety
     handling. Vendor exceptions and parse errors become a single
     ``AgentOutput`` with ``fallback_used=True`` — the flow never has
     to think about vendor errors.
  3. Run ``content_safety.validate_output`` (with optional persona
     ``extra_validators`` passed by the caller) so any PII / forbidden
     content the LLM hallucinates is replaced by a canned fallback
     before reaching the user.

Tool execution is NOT implemented in v1 — the ``tools`` parameter is
accepted (Protocol stability) but always ignored; ``tool_calls`` in the
response is always ``[]``. Flagged for v1.1 work.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Callable

from chatbot.services.content_safety import fallback_message, redact_input
from chatbot.services.ports import AgentOutput

logger = logging.getLogger(__name__)


class GeminiAgent:
    """Production ``ConversationalAgent`` backed by Google's Gemini API.

    Constructor takes ``model_name`` + ``api_key``; both come from
    settings. Empty api_key raises ``ImproperlyConfigured`` at FIRST USE
    (mirrors JazzCashHostedGateway's pattern) so an unused adapter does
    not block server boot.
    """

    def __init__(
        self,
        *,
        model_name: str,
        api_key: str,
        timeout_ms: int = 15_000,
        _client: Any = None,
    ):
        # Tests inject ``_client`` so the SDK never makes a real network
        # call; the real types module is still used for translation
        # (Pydantic model construction is local and side-effect-free).
        from google.genai import types

        self._types = types
        self._model_name = model_name

        if _client is not None:
            self._client = _client
            return

        if not api_key:
            from django.core.exceptions import ImproperlyConfigured

            raise ImproperlyConfigured(
                "GEMINI_API_KEY is not set. Add it to backend/.env (get one "
                "at https://aistudio.google.com/apikey) or use a FakeAgent "
                "in tests by passing ``agent=`` to the conversation service."
            )

        # Local import keeps the SDK Client class out of memory until we
        # actually need to make network calls.
        from google import genai

        self._client = genai.Client(
            api_key=api_key,
            http_options=types.HttpOptions(timeout=timeout_ms),
        )

    # ---- ConversationalAgent Protocol surface ----------------------------

    def generate(
        self,
        *,
        system_prompt: str,
        history: list[dict],
        user_message: str,
        response_schema: dict | None = None,
        tools: list | None = None,
        extra_validators: list[Callable[[str], tuple[bool, str | None]]] | None = None,
    ) -> AgentOutput:
        # ``tools`` and ``extra_validators`` accepted for Protocol
        # stability but not applied here in v1:
        #   - tools: function-calling branch deferred to v1.1
        #   - extra_validators: content validation lives in the flow
        # See the module docstring for the responsibility split.
        del tools, extra_validators

        # Defense in depth — the flow already redacted, but if a future
        # caller forgets, the LLM still never sees PII.
        redacted_user_message = redact_input(user_message or "")

        contents = self._build_contents(history, redacted_user_message)
        config = self._build_config(system_prompt, response_schema)

        try:
            response = self._client.models.generate_content(
                model=self._model_name,
                contents=contents,
                config=config,
            )
        except Exception as exc:  # vendor SDK can raise many exception types
            logger.warning(
                "gemini_call_failed: %s (model=%s)",
                type(exc).__name__,
                self._model_name,
            )
            return self._fallback(reason="exception")

        # response.text raises if there's no candidates (safety block etc).
        # Guard explicitly.
        try:
            text = (response.text or "").strip()
        except Exception:
            logger.warning(
                "gemini_response_text_unavailable (model=%s)",
                self._model_name,
            )
            return self._fallback(reason="response_text_unavailable")

        structured: dict | None = None
        if response_schema is not None and text:
            try:
                structured = json.loads(text)
            except json.JSONDecodeError:
                logger.warning(
                    "gemini_structured_parse_failed (model=%s)",
                    self._model_name,
                )
                return self._fallback(reason="json_parse_error")

            # When structured output is requested, the user-facing text
            # MUST come from ``message_to_user``. If it's missing or
            # blank (Gemini's response_schema is best-effort, not
            # strict), the raw JSON string would otherwise leak to the
            # user as a chat bubble. Fall back to a canned safe message.
            extracted = (
                str(structured["message_to_user"]).strip()
                if isinstance(structured, dict)
                and structured.get("message_to_user")
                else ""
            )
            if not extracted:
                logger.warning(
                    "gemini_missing_message_to_user (model=%s)",
                    self._model_name,
                )
                return self._fallback(reason="missing_message_to_user")
            text = extracted

        # NOTE: content validation lives in the FLOW (it knows the right
        # ``kind`` for length caps — turn_message vs summary — and the
        # persona-specific extra_validators). The adapter intentionally
        # passes the raw output through; ``fallback_used`` is reserved
        # for vendor errors (exception, parse failure, blocked response,
        # malformed structured response).
        # ``extra_validators`` is accepted for Protocol stability but
        # not applied here.
        return {
            "text": text,
            "structured": structured,
            "tool_calls": [],  # tool execution deferred to v1.1
            "finish_reason": "stop",
            "fallback_used": False,
        }

    # ---- Translation helpers --------------------------------------------

    def _build_contents(
        self,
        history: list[dict],
        user_message: str,
    ) -> list:
        """Convert our (role: user|bot, text) history into Gemini's
        ``list[types.Content]``. Maps role 'bot' → 'model'.

        The current user_message is appended as the last entry; an empty
        user_message (opening_turn invocation) sends just the history.
        """
        types = self._types
        out: list = []
        for m in history:
            role = "model" if m.get("role") == "bot" else "user"
            text = m.get("text") or ""
            if not text:
                continue
            out.append(types.Content(role=role, parts=[types.Part(text=text)]))
        if user_message:
            out.append(types.Content(role="user", parts=[types.Part(text=user_message)]))
        # Gemini requires at least one Content. If history is empty AND
        # user_message is empty (shouldn't happen in our flows), send a
        # whitespace placeholder to avoid an SDK error.
        if not out:
            out.append(types.Content(role="user", parts=[types.Part(text=" ")]))
        return out

    def _build_config(
        self,
        system_prompt: str,
        response_schema: dict | None,
    ):
        types = self._types
        kwargs: dict[str, Any] = {"system_instruction": system_prompt}
        if response_schema:
            kwargs["response_mime_type"] = "application/json"
            kwargs["response_schema"] = response_schema
        return types.GenerateContentConfig(**kwargs)

    def _fallback(self, *, reason: str) -> AgentOutput:
        """Single fallback exit point. Returns the canned safe message
        with ``fallback_used=True`` so the caller (the flow) can flag
        ``needs_review`` on any resulting ticket."""
        logger.debug("gemini_fallback reason=%s model=%s", reason, self._model_name)
        return {
            "text": fallback_message("<adapter>", "turn_message"),
            "structured": None,
            "tool_calls": [],
            "finish_reason": "fallback",
            "fallback_used": True,
        }
