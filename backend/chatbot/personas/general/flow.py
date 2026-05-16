"""GeneralChatFlow — single-phase free-form Q&A.

The dispute persona is a state machine with five phases. This persona
is the opposite shape: one phase, no fields to capture, no forms, no
attachments, no terminal condition driven by content. Every text turn
calls the LLM with a system prompt that holds the live service list +
static policy facts; non-text message kinds are rejected.

The conversation closes only when the user (or the close endpoint)
explicitly closes it. The bot never decides to terminate on its own.
"""
from __future__ import annotations

from typing import Any

from chatbot.personas.general import prompts
from chatbot.services.content_safety import (
    fallback_message,
    redact_input,
    validate_output,
)
from chatbot.services.ports import ConversationalAgent, TurnResult


# Reuse the dispute persona's exception types so the views' translation
# table (`UnsupportedMessageKind` → 400, `ConversationAlreadyClosed` →
# 409) covers this persona too without view edits.
from chatbot.personas.dispute.flow import (  # noqa: E402
    ConversationAlreadyClosed,
    UnsupportedMessageKind,
)


# Single placeholder phase. The flow has no internal state machine but
# the framework expects ``state['phase']`` to be a non-empty string for
# serialization (it's returned to the FE as ``current_phase``).
PHASE_CHAT = "CHAT"


# Canned fallback message reused for both adapter-side failures and
# output-validation rejections. Registered in content_safety under the
# "general" persona key — see ``content_safety._FALLBACKS``.
_FALLBACK_KIND = "turn_message"


# History window cap fed to the LLM on each turn.
#
# The flow has no per-conversation turn cap (unlike dispute's
# ``CHATBOT_UNDERSTAND_TURN_CAP``), so without a window the entire
# transcript would be re-sent to Gemini on every message. At 30 we keep
# the last ~15 exchanges — comfortably enough context for follow-ups
# that reference earlier turns ("what about the case I asked about
# above?") while still capping the prompt size well below any
# cost-relevant threshold. Older turns remain in the DB for audit;
# they are simply not fed back to the LLM.
_HISTORY_MAX_MESSAGES = 30


class GeneralChatFlow:
    """Stateless turn handler for the general help persona."""

    # ---- FlowEngine Protocol surface -------------------------------------

    def opening_turn(
        self,
        conversation,
        agent: ConversationalAgent,
    ) -> TurnResult:
        """Templated greeting — no LLM call. Saves quota for real turns.

        ``state_patch`` is empty: ``Persona.initial_state`` already
        wrote ``phase=CHAT`` to the conversation row at create time.
        Re-patching it here would be redundant noise.
        """
        return TurnResult(
            bot_message=prompts.OPENING_GREETING,
            ui_input_kind="text",
            ui_form_schema=None,
            ui_hint="Ask a question",
            state_patch={},
            is_terminal=False,
        )

    def handle_user_turn(
        self,
        conversation,
        message_kind: str,
        payload: Any,
        agent: ConversationalAgent,
    ) -> TurnResult:
        if conversation.state.get("phase") == "CLOSED":
            raise ConversationAlreadyClosed()

        if message_kind != "text":
            raise UnsupportedMessageKind(
                f"general persona expects 'text', got {message_kind!r}"
            )

        # Build a fresh system prompt with a live service list. The
        # query is cheap (~10 rows, indexed) and rebuilding per turn
        # means admin-side catalog changes show up without restarts —
        # and the LLM can't invent a category we don't actually offer.
        system_prompt = prompts.render_system_prompt(self._service_names())
        history = self._build_history(conversation)
        redacted = redact_input(payload or "")

        out = agent.generate(
            system_prompt=system_prompt,
            history=history,
            user_message=redacted,
            response_schema=None,
            tools=None,
        )

        raw_text = out.get("text") or ""

        if out.get("fallback_used"):
            bot_message = fallback_message("general", _FALLBACK_KIND)
        else:
            is_safe, _reason = validate_output(
                raw_text,
                persona_key="general",
                kind=_FALLBACK_KIND,
                extra_validators=None,
            )
            bot_message = (
                raw_text if is_safe
                else fallback_message("general", _FALLBACK_KIND)
            )

        return TurnResult(
            bot_message=bot_message,
            ui_input_kind="text",
            ui_form_schema=None,
            ui_hint="Ask another question",
            state_patch={},
            is_terminal=False,
        )

    def is_terminal(self, conversation) -> bool:
        # General help conversations only end when the user (or the
        # close endpoint) closes them. No content-driven termination.
        return conversation.state.get("phase") == "CLOSED"

    def directive_from_state(self, conversation) -> dict:
        """Resume directive — always 'text in' for an open conversation.

        Called when the start endpoint returns an existing open
        conversation (rare for general help since we don't enable
        ``find_existing_open``, but kept for parity with the dispute
        persona and forward-compat with a future resume opt-in).
        """
        phase = conversation.state.get("phase") or PHASE_CHAT
        if phase == "CLOSED":
            return {
                "ui_input_kind": "close",
                "ui_form_schema": None,
                "ui_hint": "",
            }
        return {
            "ui_input_kind": "text",
            "ui_form_schema": None,
            "ui_hint": "Ask another question",
        }

    # ---- Helpers ---------------------------------------------------------

    def _service_names(self) -> list[str]:
        """Live customer-visible service categories from the catalog.

        Filters to active rows with a real ``icon_name`` — matches what
        the customer sees on the Home screen (rows without an icon are
        treated as stubs / placeholders on the FE). Ordered by
        ``display_order`` then name for deterministic prompt output.
        """
        # Local import keeps this module importable without the catalog
        # app — mirrors the pattern in the dispute flow.
        from catalog.models import Service

        return list(
            Service.objects.filter(is_active=True)
            .exclude(icon_name__isnull=True)
            .exclude(icon_name="")
            .order_by("display_order", "name")
            .values_list("name", flat=True)
        )

    def _build_history(self, conversation) -> list[dict]:
        """Format prior messages as LLM history.

        Two trims applied:
          1. Drops the trailing USER message — the orchestration service
             persists it before calling us, but we pass it to the adapter
             separately as ``user_message`` so it would otherwise appear
             twice.
          2. Caps the window at ``_HISTORY_MAX_MESSAGES`` most-recent
             entries. Older turns stay in the DB for audit but are not
             re-fed to the LLM. This keeps per-turn cost bounded even on
             very long help sessions (the daily quota is the only other
             bound, and at 100 turns/day that's a quadratic cost growth
             without this cap).

        **DB shape.** We fetch DESC and slice to ``cap+1`` at the
        ORM layer (one SQL row count = constant regardless of total
        conversation length), then reverse in Python to restore
        chronological order. The ``+1`` keeps a slot for a possible
        trailing USER that we'll drop. Without auto-close of stale
        general-persona conversations (see flag #56), naively fetching
        all messages would scale linearly with session age — this query
        stays flat.
        """
        # DESC + LIMIT cap+1 at the DB layer — never materialise more
        # than we need. The `[..._HISTORY_MAX_MESSAGES + 1]` slice
        # becomes a SQL LIMIT, evaluated by the ORM.
        msgs = list(
            conversation.messages.order_by("-created_at")[
                : _HISTORY_MAX_MESSAGES + 1
            ]
        )
        # Restore chronological order for the LLM.
        msgs.reverse()
        if msgs and msgs[-1].role == "USER":
            msgs = msgs[:-1]
        # Tail-trim in case the trailing USER was NOT present and we
        # over-fetched by one (we requested cap+1 to cover the drop).
        if len(msgs) > _HISTORY_MAX_MESSAGES:
            msgs = msgs[-_HISTORY_MAX_MESSAGES:]
        return [
            {
                "role": "user" if m.role == "USER" else "bot",
                "text": m.text,
            }
            for m in msgs
            if m.text
        ]
