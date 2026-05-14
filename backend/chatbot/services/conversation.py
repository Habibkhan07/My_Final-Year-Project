"""Conversation orchestration — the single entry point for the chat framework.

Three public functions:

  start_conversation(user, persona_key, context, agent=None)
      → Conversation
      Authorizes via persona.is_eligible_to_start (which holds the
      relevant row lock), resumes any open conversation via
      ``find_existing_open``, otherwise creates a fresh row and runs the
      flow's ``opening_turn`` for the initial bot message.

  handle_message(conversation_id, user, message_kind, payload, agent=None)
      → TurnResult
      Locks the Conversation row (IDOR-safe — scoped to user), consumes
      LLM quota for text turns, persists USER message, delegates to
      ``flow.handle_user_turn``, applies state patch + persists bot
      message, closes if terminal.

  close_conversation(conversation_id, user)
      → dict (output_refs)
      Locks the row, idempotent (no-op when already closed), runs
      ``persona.on_close`` to produce side effects (SupportTicket etc),
      stores output_refs back onto the conversation. The dispute persona
      also gets a templated closing system message appended here so the
      user sees their ticket ID.

All mutating ops run inside ``transaction.atomic`` with
``select_for_update`` on the Conversation row — concurrent calls for the
same conversation serialize cleanly.
"""
from __future__ import annotations

from typing import Any

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from chatbot import personas
from chatbot.adapters import get_default_agent
from chatbot.models import Conversation, Message
from chatbot.services import quota
from chatbot.services.ports import ConversationalAgent, TurnResult


# ---- Exceptions translated to API error envelopes -----------------------

class NotEligibleToStart(Exception):
    """Persona rejected the start request (wrong booking status, IDOR,
    etc.). Translated to ``400 not_eligible_to_start``."""


class ConversationNotFound(Exception):
    """Translated to ``404 conversation_not_found``. Used for both real
    misses and IDOR (different user)."""


class ConversationClosed(Exception):
    """User tried to message a closed conversation.
    Translated to ``409 conversation_closed``."""


# ---- Public API ---------------------------------------------------------

def start_conversation(
    user,
    persona_key: str,
    context: dict,
    agent: ConversationalAgent | None = None,
) -> Conversation:
    """Open (or resume) a conversation with the named persona.

    Raises ``NotEligibleToStart`` if the persona rejects (missing
    context, wrong booking status, IDOR — never leaks why).
    """
    persona = personas.get(persona_key)
    agent = agent or get_default_agent()

    with transaction.atomic():
        # is_eligible_to_start takes the relevant row lock (dispute
        # locks the Booking row) so the find_existing_open + create
        # path below is race-safe against parallel POSTs.
        if not persona.is_eligible_to_start(user, context):
            raise NotEligibleToStart(persona_key)

        existing = None
        if hasattr(persona, "find_existing_open"):
            existing = persona.find_existing_open(user, context)
        if existing is not None:
            return existing

        conv = Conversation.objects.create(
            user=user,
            persona_key=persona_key,
            context=context,
            state=persona.initial_state(context),
            turn_count=0,
            is_closed=False,
            output_refs={},
        )

        # Opening turn (templated for dispute — no LLM call). Result is
        # persisted as the first BOT message and any state patch applied.
        result = persona.flow_engine.opening_turn(conv, agent)
        _persist_bot_message(conv, result)
        _apply_state_patch(conv, result.state_patch)
        # turn_count is NOT incremented for the opening turn — it counts
        # user-driven turns only (used by the UNDERSTAND turn cap).
        conv.save(update_fields=["state"])

        return conv


def handle_message(
    conversation_id: int,
    user,
    message_kind: str,
    payload: Any,
    agent: ConversationalAgent | None = None,
) -> TurnResult:
    """Process one user turn. Returns the TurnResult so the view can
    serialize the bot response + UI hints to the frontend."""
    agent = agent or get_default_agent()

    with transaction.atomic():
        try:
            conv = (
                Conversation.objects.select_for_update()
                .get(id=conversation_id, user=user)
                # SECURITY: scoped to user — IDOR-safe. Wrong user → 404,
                # not 403, so existence of another user's conversation
                # isn't probable.
            )
        except Conversation.DoesNotExist as exc:
            raise ConversationNotFound(conversation_id) from exc

        if conv.is_closed:
            raise ConversationClosed(conversation_id)

        persona = personas.get(conv.persona_key)
        flow = persona.flow_engine

        # Quota gate: only consume for turns that will actually call the
        # LLM. Text turns in UNDERSTAND do. Form submits and "done"
        # signals do not. This is a coarse pre-check; the flow may still
        # short-circuit without calling the agent (e.g. cap exceeded).
        #
        # Race / leak safety: this fires BEFORE phase-validation, so a
        # text-message during EVIDENCE would still consume. That is NOT
        # a leak today — ``quota.consume`` opens a nested savepoint
        # inside this outer atomic, and the ``UnsupportedMessageKind``
        # raised by the flow rolls the whole atomic back (savepoint
        # included). If this method ever stops being wrapped in an
        # outer atomic, reorder the quota call to AFTER ``handle_user_turn``.
        if message_kind == "text":
            quota.consume(user)

        # Persist USER message (audit trail) BEFORE the flow runs — so
        # the flow's history-building helper sees the just-arrived
        # message in DB if it queries.
        if message_kind == "text" and payload:
            Message.objects.create(
                conversation=conv,
                role=Message.ROLE_USER,
                text=str(payload),
                phase=conv.state.get("phase", ""),
                lang="",  # detection deferred — flag for v1.1
            )

        result = flow.handle_user_turn(conv, message_kind, payload, agent)

        # Persist bot response (if any) and apply state patch.
        _persist_bot_message(conv, result)
        _apply_state_patch(conv, result.state_patch)
        conv.turn_count += 1
        conv.save(update_fields=["state", "turn_count"])

        # Auto-close on terminal turn. close_conversation is idempotent
        # so callers don't have to special-case this path.
        if result.is_terminal:
            close_conversation(conv.id, user)

        return result


def close_conversation(conversation_id: int, user) -> dict:
    """Run persona.on_close and mark the conversation closed.

    Idempotent: re-calling on an already-closed conversation returns the
    existing output_refs without re-running on_close.
    """
    with transaction.atomic():
        try:
            conv = (
                Conversation.objects.select_for_update()
                .get(id=conversation_id, user=user)
            )
        except Conversation.DoesNotExist as exc:
            raise ConversationNotFound(conversation_id) from exc

        if conv.is_closed:
            return dict(conv.output_refs or {})

        persona = personas.get(conv.persona_key)
        output_refs = persona.on_close(conv) or {}

        # Persona-specific: append a templated closing system message so
        # the user sees the ticket ID. Keeps the LLM out of the closing
        # path — guarantees the SLA string and ticket ref are correct.
        if conv.persona_key == "dispute":
            ticket_id = output_refs.get("support_ticket_id")
            if ticket_id is not None:
                from chatbot.personas.dispute.prompts import closing_template

                Message.objects.create(
                    conversation=conv,
                    role=Message.ROLE_SYSTEM,
                    text=closing_template(
                        ticket_id=ticket_id,
                        sla=settings.DISPUTE_SLA_STRING,
                    ),
                    phase="CLOSED",
                    lang="en",
                )

        conv.output_refs = output_refs
        conv.is_closed = True
        conv.closed_at = timezone.now()
        conv.save(
            update_fields=["output_refs", "is_closed", "closed_at"]
        )

        return output_refs


# ---- Helpers (private) ---------------------------------------------------

def _persist_bot_message(conv: Conversation, result: TurnResult) -> None:
    """Insert a BOT row if the result carried a non-empty bot_message."""
    if not result.bot_message:
        return
    Message.objects.create(
        conversation=conv,
        role=Message.ROLE_BOT,
        text=result.bot_message,
        phase=conv.state.get("phase", ""),
        lang="",
    )


def _apply_state_patch(conv: Conversation, patch: dict) -> None:
    """Merge a flow's state_patch into Conversation.state in-place.
    Shallow merge — keys at the top level overwrite; nested dicts are
    not deep-merged (the flow is responsible for producing the full
    nested state it wants when keys overlap)."""
    if not patch:
        return
    merged = dict(conv.state or {})
    merged.update(patch)
    conv.state = merged
