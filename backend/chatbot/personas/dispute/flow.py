"""DisputeFlow — state machine for the dispute resolution chatbot.

Five phases:

  UNDERSTAND  →  multi-turn LLM-driven conversation that captures
                 issue_summary (required), amount_paid, date_of_failure,
                 contacted_technician (all optional). The LLM advises
                 phase_complete; the flow validates required fields
                 independently before advancing — the LLM cannot lie its
                 way past the gate.

  EVIDENCE    →  one-shot. User uploads 0–10 photos and signals done.
                 No LLM call. Advances to PAYOUT.

  PAYOUT      →  one-shot. User submits bank details form (validated by
                 the serializer at the view layer). No LLM call.
                 Advances to CONFIRM.

  CONFIRM     →  generates the AI summary of the full narrative for the
                 admin queue, marks the conversation terminal. The
                 conversation service runs ``persona.on_close`` after
                 this turn, which is what actually creates the
                 SupportTicket + RefundIntent.

  CLOSED      →  terminal. Further messages raise ConversationAlreadyClosed.

Special path — UNDERSTAND turn cap exceeded:
  - Required fields captured → force-advance to EVIDENCE with
    ``state.forced_advance=True`` (carried into ticket.needs_review).
  - Required fields STILL missing → abort: close conversation, no
    ticket created, customer redirected to support out-of-band.
"""
from __future__ import annotations

from typing import Any

from django.conf import settings

from chatbot.personas.dispute import prompts, schemas, validators
from chatbot.services.content_safety import (
    fallback_message,
    redact_input,
    validate_output,
)
from chatbot.services.ports import ConversationalAgent, TurnResult


# Persona-specific output validators. Single source of truth — the
# Persona protocol no longer declares ``extra_output_validators`` (it
# was always dead code, since the adapter discards what it's given and
# the flow is the only consumer of these). The flow knows its own
# content rules, so they live with the flow.
_DISPUTE_EXTRA_VALIDATORS = [
    validators.no_sla_other_than_canonical,
    validators.no_guarantee_or_policy_claims,
]


# ---- Phase constants -----------------------------------------------------

PHASE_UNDERSTAND = "UNDERSTAND"
PHASE_EVIDENCE = "EVIDENCE"
PHASE_PAYOUT = "PAYOUT"
PHASE_CONFIRM = "CONFIRM"
PHASE_CLOSED = "CLOSED"

PHASE_REQUIRED_FIELDS: dict[str, list[str]] = {
    PHASE_UNDERSTAND: ["issue_summary"],
    PHASE_EVIDENCE: [],
    PHASE_PAYOUT: ["bank_name", "account_title", "iban"],
    PHASE_CONFIRM: [],
}


# ---- Exceptions ----------------------------------------------------------

class UnsupportedMessageKind(Exception):
    """Raised when the flow rejects a message_kind for the current phase.

    Translated to ``400 unsupported_message_kind`` by the view layer.
    """


class ConversationAlreadyClosed(Exception):
    """Raised when handle_user_turn is called on a CLOSED conversation.

    Translated to ``409 conversation_closed`` by the view layer.
    """


# ---- The flow ------------------------------------------------------------

class DisputeFlow:
    """Stateless turn handler. All state lives on the Conversation row;
    this class is pure logic that returns ``TurnResult`` objects. The
    conversation service handles persistence and quota."""

    # ---- FlowEngine Protocol surface -------------------------------------

    def opening_turn(
        self,
        conversation,
        agent: ConversationalAgent,
    ) -> TurnResult:
        """Produce the warm greeting that opens the conversation.

        Templated (no LLM call) — single-sentence greetings don't benefit
        much from LLM warmth, and skipping this call saves quota for the
        multi-turn UNDERSTAND phase where the LLM actually earns its keep.
        """
        ctx = self._booking_context(conversation)
        greeting = (
            f"Hi — sorry to hear that {ctx['service_name']} on "
            f"{ctx['date_iso']} didn't go well. Could you tell me what "
            f"happened?"
        )
        return TurnResult(
            bot_message=greeting,
            ui_input_kind="text",
            ui_form_schema=None,
            ui_hint="Tell me what happened",
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
        phase = conversation.state.get("phase", PHASE_UNDERSTAND)

        if phase == PHASE_CLOSED:
            raise ConversationAlreadyClosed()

        if phase == PHASE_UNDERSTAND:
            if message_kind != "text":
                raise UnsupportedMessageKind(
                    f"UNDERSTAND expects 'text', got {message_kind!r}"
                )
            return self._handle_understand(conversation, payload, agent)

        if phase == PHASE_EVIDENCE:
            if message_kind != "attachment_done":
                raise UnsupportedMessageKind(
                    f"EVIDENCE expects 'attachment_done', got {message_kind!r}"
                )
            return self._handle_evidence_done(conversation)

        if phase == PHASE_PAYOUT:
            if message_kind != "form":
                raise UnsupportedMessageKind(
                    f"PAYOUT expects 'form', got {message_kind!r}"
                )
            return self._handle_payout_form(conversation, payload, agent)

        # PHASE_CONFIRM is no longer a discrete turn — payout submit
        # finalises the ticket inline (avoids the "user must type
        # anything to actually file" UX trap). The constant remains for
        # backward-readability of legacy state strings; legacy
        # conversations stuck in CONFIRM are unreachable in practice
        # (cleared during the pre-launch reset) and fall through to the
        # unknown-phase error below.

        raise UnsupportedMessageKind(f"unknown_phase:{phase}")

    def is_terminal(self, conversation) -> bool:
        return conversation.state.get("phase") == PHASE_CLOSED

    def directive_from_state(self, conversation) -> dict:
        """Produce the (ui_input_kind, ui_form_schema, ui_hint) tuple for
        the conversation's CURRENT state — no LLM call, no state change.

        Called by ``_serialize_conversation_start`` when ``start`` returns
        an existing in-progress conversation (resume path). Without this,
        the start serializer would hardcode ``ui_input_kind="text"`` and
        mount the wrong composer for a user resuming mid-evidence /
        mid-payout (e.g. after logout + back in).

        Returns a dict shaped to drop into the start response:
        ``{"ui_input_kind": str, "ui_form_schema": dict|None,
            "ui_hint": str}``.
        """
        phase = conversation.state.get("phase") or PHASE_UNDERSTAND
        if phase == PHASE_UNDERSTAND:
            return {
                "ui_input_kind": "text",
                "ui_form_schema": None,
                "ui_hint": "Tell me what happened",
            }
        if phase == PHASE_EVIDENCE:
            return {
                "ui_input_kind": "attachment",
                "ui_form_schema": None,
                "ui_hint": (
                    "Attach photos of the issue (optional, up to 10)"
                ),
            }
        if phase == PHASE_PAYOUT:
            return {
                "ui_input_kind": "form",
                "ui_form_schema": schemas.BANK_FORM_SCHEMA,
                "ui_hint": (
                    "If a refund is approved, where should we send it?"
                ),
            }
        # PHASE_CONFIRM is legacy / unreachable; PHASE_CLOSED is rendered
        # by the frontend off the ``is_closed`` flag (TerminalDirective)
        # so the directive shape here is just a safe placeholder.
        return {
            "ui_input_kind": "close" if phase == PHASE_CLOSED else "none",
            "ui_form_schema": None,
            "ui_hint": "",
        }

    # ---- Phase handlers --------------------------------------------------

    def _handle_understand(
        self,
        conversation,
        user_message: str,
        agent: ConversationalAgent,
    ) -> TurnResult:
        turn_cap = settings.CHATBOT_UNDERSTAND_TURN_CAP
        if conversation.turn_count >= turn_cap:
            return self._understand_cap_exceeded(conversation)

        ctx = self._booking_context(conversation)
        system_prompt = prompts.understand_system_prompt(ctx)
        history = self._build_history(conversation)
        redacted = redact_input(user_message or "")

        out = agent.generate(
            system_prompt=system_prompt,
            history=history,
            user_message=redacted,
            response_schema=schemas.DISPUTE_TURN_SCHEMA,
            tools=None,
        )

        raw_bot_text = out.get("text") or ""
        structured = out.get("structured") or {}

        # Validate the user-facing message with global checks AND the
        # dispute persona's extras (no SLA invention, no policy claims).
        # On rejection: substitute canned fallback, but PRESERVE captured
        # fields below — the user's progress is independent of a single
        # rejected response.
        if out.get("fallback_used"):
            bot_message = fallback_message("dispute", "turn_message")
        else:
            is_safe, _reason = validate_output(
                raw_bot_text,
                persona_key="dispute",
                kind="turn_message",
                extra_validators=_DISPUTE_EXTRA_VALIDATORS,
            )
            bot_message = (
                raw_bot_text if is_safe
                else fallback_message("dispute", "turn_message")
            )
        new_fields = structured.get("fields_captured") or {}
        llm_says_complete = bool(structured.get("phase_complete"))
        is_off_topic = bool(structured.get("asked_off_topic"))

        # Merge captured fields. Only non-empty values overwrite — the LLM
        # can fill in a previously-empty field but cannot blank one out.
        prev = dict(conversation.state.get("captured_fields") or {})
        for k, v in new_fields.items():
            if v:
                prev[k] = v

        state_patch: dict[str, Any] = {"captured_fields": prev}
        if is_off_topic:
            state_patch["off_topic_count"] = (
                conversation.state.get("off_topic_count", 0) + 1
            )

        # SM-side validation: advance ONLY if required fields actually
        # present. The LLM advises (phase_complete), the SM decides.
        required = PHASE_REQUIRED_FIELDS[PHASE_UNDERSTAND]
        have_required = all(prev.get(f) for f in required)

        if llm_says_complete and have_required:
            state_patch["phase"] = PHASE_EVIDENCE
            ui_kind = "attachment"
            ui_hint = "Attach photos of the issue (optional, up to 10)"
        else:
            ui_kind = "text"
            ui_hint = "Continue describing the issue"

        return TurnResult(
            bot_message=bot_message,
            ui_input_kind=ui_kind,
            ui_form_schema=None,
            ui_hint=ui_hint,
            state_patch=state_patch,
            is_terminal=False,
        )

    def _understand_cap_exceeded(self, conversation) -> TurnResult:
        prev = dict(conversation.state.get("captured_fields") or {})
        required = PHASE_REQUIRED_FIELDS[PHASE_UNDERSTAND]
        have_required = all(prev.get(f) for f in required)

        if not have_required:
            # Abort cleanly. No ticket filed. The customer is told to use
            # Help out-of-band — filing an empty narrative is worse than
            # nothing.
            return TurnResult(
                bot_message=prompts.UNDERSTAND_ABORT_MESSAGE,
                ui_input_kind="close",
                ui_form_schema=None,
                ui_hint="",
                state_patch={
                    "phase": PHASE_CLOSED,
                    "aborted_reason": "insufficient_info_after_cap",
                },
                is_terminal=True,
            )

        # Required fields captured but LLM kept saying not-complete.
        # Force-advance. The eventual ticket will carry needs_review=True
        # so admin double-checks the AI summary.
        return TurnResult(
            bot_message=prompts.FORCED_ADVANCE_MESSAGE,
            ui_input_kind="attachment",
            ui_form_schema=None,
            ui_hint="Attach photos of the issue (optional, up to 10)",
            state_patch={
                "phase": PHASE_EVIDENCE,
                "forced_advance": True,
            },
            is_terminal=False,
        )

    def _handle_evidence_done(self, conversation) -> TurnResult:
        # No LLM call. 0 photos is allowed — some disputes have no visual
        # evidence ("tech never arrived"). Photos are uploaded via the
        # separate /attachments/ endpoint; this turn just advances phase.
        return TurnResult(
            bot_message=prompts.PAYOUT_INTRO,
            ui_input_kind="form",
            ui_form_schema=schemas.BANK_FORM_SCHEMA,
            ui_hint="If a refund is approved, where should we send it?",
            state_patch={"phase": PHASE_PAYOUT},
            is_terminal=False,
        )

    def _handle_payout_form(
        self,
        conversation,
        form_payload: dict,
        agent: ConversationalAgent,
    ) -> TurnResult:
        # The view's serializer is the authoritative validator (IBAN regex,
        # required fields, length caps). We trust the payload here.
        #
        # We inline the former CONFIRM step here — summarise the narrative
        # for the admin queue and return ``is_terminal=True`` in the same
        # turn. The previous two-step (PAYOUT→CONFIRM as a separate turn)
        # required the user to send a second arbitrary message to actually
        # file the ticket, which most users never figured out.
        narrative_text = self._collect_narrative(conversation)
        summary_text = self._summarize_narrative(narrative_text, agent)

        is_safe, reason = validate_output(
            summary_text, persona_key="dispute", kind="summary"
        )
        if not is_safe:
            summary_text = fallback_message("dispute", "summary")
            needs_review_summary = True
            needs_review_reason = reason or "summary_validation_failed"
        else:
            needs_review_summary = False
            needs_review_reason = ""

        # The visible BOT bubble is CONFIRM_INTRO ("filing now"); the
        # templated closing message with the ticket id is appended as a
        # SYSTEM message by the conversation service after on_close runs.
        return TurnResult(
            bot_message=prompts.CONFIRM_INTRO,
            ui_input_kind="close",
            ui_form_schema=None,
            ui_hint="",
            state_patch={
                "phase": PHASE_CLOSED,
                "bank_draft": form_payload,
                "ai_summary": summary_text,
                "ai_summary_lang": "en",
                "needs_review_summary": needs_review_summary,
                "needs_review_reason": needs_review_reason,
            },
            is_terminal=True,
        )

    # ---- Helpers ---------------------------------------------------------

    def _booking_context(self, conversation) -> dict:
        """Fetch booking facts for the system prompt and the templated
        greeting. Tolerates a missing booking — we'd rather degrade the
        prompt than crash the flow."""
        # Local import to keep flow module importable without bookings.
        from bookings.models import JobBooking

        booking_id = conversation.context.get("booking_id")
        if not booking_id:
            return _DEFAULT_BOOKING_CTX

        try:
            b = (
                JobBooking.objects
                .select_related("technician", "technician__user", "service")
                .get(id=booking_id)
            )
        except JobBooking.DoesNotExist:
            return _DEFAULT_BOOKING_CTX

        tech_user = getattr(b.technician, "user", None) if b.technician_id else None
        tech_first = (
            tech_user.first_name if (tech_user and tech_user.first_name)
            else "the technician"
        )
        service_name = b.service.name if b.service_id else "the service"
        date_iso = (
            b.scheduled_start.date().isoformat() if b.scheduled_start else ""
        )
        amount = str(b.price_amount) if b.price_amount is not None else ""

        return {
            "service_name": service_name,
            "tech_first_name": tech_first,
            "date_iso": date_iso,
            "amount": amount,
        }

    def _build_history(self, conversation) -> list[dict]:
        """Format prior messages as LLM history. Excludes the very latest
        user message — the caller passes that as user_message to the
        adapter so the adapter can present it in vendor-specific shape."""
        msgs = list(conversation.messages.order_by("created_at"))
        # Drop the trailing USER message if it's the latest one — that's
        # the one being processed right now.
        if msgs and msgs[-1].role == "USER":
            msgs = msgs[:-1]
        return [
            {
                "role": "user" if m.role == "USER" else "bot",
                "text": m.text,
            }
            for m in msgs
            if m.text
        ]

    def _collect_narrative(self, conversation) -> str:
        """Concatenate all USER text messages — the customer's full
        narrative across the UNDERSTAND phase."""
        return "\n".join(
            m.text
            for m in conversation.messages
                .filter(role="USER")
                .order_by("created_at")
            if m.text
        )

    def _summarize_narrative(
        self,
        narrative_text: str,
        agent: ConversationalAgent,
    ) -> str:
        """LLM call: produce a neutral 2-4 sentence English summary."""
        if not narrative_text.strip():
            return "Narrative unclear — admin to contact customer."

        out = agent.generate(
            system_prompt=prompts.SUMMARIZE_NARRATIVE_PROMPT,
            history=[],
            user_message=narrative_text,
            response_schema=None,
            tools=None,
        )
        # The adapter hardcodes its fallback text to the "turn_message"
        # canned string (it doesn't know the call site's ``kind``). We
        # check ``fallback_used`` explicitly so a summarisation failure
        # surfaces the summary-shaped canned text on the ticket — not
        # "Sorry, I couldn't process that. Please try rephrasing." which
        # is nonsense in an admin queue context.
        if out.get("fallback_used"):
            return fallback_message("dispute", "summary")
        return out.get("text") or fallback_message("dispute", "summary")


_DEFAULT_BOOKING_CTX = {
    "service_name": "the service",
    "tech_first_name": "the technician",
    "date_iso": "the booking date",
    "amount": "",
}
