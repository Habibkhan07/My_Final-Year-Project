"""Build SupportTicket + RefundIntent rows from a closed chatbot session.

The dispute persona's ``on_close`` (in
``chatbot.personas.dispute.outputs.finalize_dispute``) calls this
function after the customer completes the chat. Everything happens in
one atomic transaction so a partial-write race can never leave the
admin queue with a ticket that has no narrative or bank intent.

The booking-side audit + realtime side-effects (``dispute_opened_at``
stamp, optional status flip to DISPUTED, ``DISPUTE_OPENED`` broadcast
to both audiences) are produced by the shared
``bookings.services.orchestrator.apply_dispute_opened_side_effects``
helper — same helper the form-intake path uses — so both intake
methods leave the same audit + realtime footprint.

Idempotency: callers must check ``conversation.output_refs`` before
calling; this function does not double-check (the conversation service
holds a row lock on the Conversation through on_close, so concurrent
finalize calls serialize on that lock).
"""
from __future__ import annotations

from django.db import transaction

from bookings.models import JobBooking, SupportTicket
from bookings.services.orchestrator import apply_dispute_opened_side_effects
from disputes.models import RefundIntent


@transaction.atomic
def create_from_chatbot_session(*, conversation) -> SupportTicket:
    """Create a SupportTicket (+ RefundIntent if bank details captured)
    from a closed dispute-persona Conversation.

    Reads from ``conversation``:
      - ``context["booking_id"]``     → the JobBooking to attach to
      - ``state["ai_summary"]``       → admin-queue convenience text
      - ``state["captured_fields"]``  → amount, date, contacted_tech, etc
      - ``state["bank_draft"]``       → bank_name, account_title, iban
      - ``state["forced_advance"]``   → True if UNDERSTAND turn cap was hit
      - ``state["needs_review_*"]``   → summary validation flags
      - ``messages`` (related)        → full transcript for chat_log
      - ``attachments`` (related)     → file paths for chat_log

    Returns the created ``SupportTicket``. The caller writes the
    returned ticket's id back to ``conversation.output_refs``.
    """
    booking_id = conversation.context.get("booking_id")
    if not booking_id:
        # SECURITY: this is reachable only via a persona's on_close path
        # which has already authorized the conversation; surfacing a
        # ValueError here is purely defensive.
        raise ValueError("Conversation context missing booking_id")

    # Lock the booking row for the duration of ticket creation —
    # prevents a concurrent path (e.g. orchestrator transitioning the
    # booking to DISPUTED) from racing the ticket insert.
    booking = JobBooking.objects.select_for_update().get(id=booking_id)

    state = conversation.state or {}
    bank_draft = state.get("bank_draft") or {}
    captured = state.get("captured_fields") or {}
    ai_summary = state.get("ai_summary") or ""
    ai_summary_lang = state.get("ai_summary_lang") or "en"

    # Raw narrative = concatenation of all USER text messages, the
    # source of truth admin reads when ai_summary is needs_review.
    raw_narrative = "\n".join(
        m.text
        for m in conversation.messages.filter(role="USER").order_by("created_at")
        if m.text
    ).strip()

    # Transcript snapshot — every message, in order, with metadata.
    messages_snapshot = [
        {
            "role": m.role,
            "text": m.text,
            "phase": m.phase,
            "lang": m.lang,
            "created_at": m.created_at.isoformat(),
        }
        for m in conversation.messages.order_by("created_at")
    ]

    # Attachment paths only (files live in chatbot.Attachment table; the
    # admin custom view will render them). Storing relative paths avoids
    # double-storage and lets admin queries find images via the
    # conversation FK on the ticket-side later if needed.
    attachment_paths = [
        {
            "file": a.file.name if a.file else "",
            "mime_type": a.mime_type,
            "size_bytes": a.size_bytes,
        }
        for a in conversation.attachments.all()
    ]

    # needs_review = summary validation tripped OR turn cap forced advance.
    # Either condition means "human, please double-check before deciding".
    needs_review = bool(
        state.get("needs_review_summary") or state.get("forced_advance")
    )
    needs_review_reason = (
        state.get("needs_review_reason")
        or ("forced_advance" if state.get("forced_advance") else "")
    )

    chat_log = {
        "conversation_id": conversation.id,
        "ai_summary": ai_summary,
        "ai_summary_lang": ai_summary_lang,
        "captured_fields": captured,
        "needs_review": needs_review,
        "needs_review_reason": needs_review_reason,
        "messages": messages_snapshot,
        "attachments": attachment_paths,
    }

    ticket = SupportTicket.objects.create(
        booking=booking,
        opened_by=conversation.user,
        dispute_intake_method=SupportTicket.INTAKE_CHATBOT,
        initial_reason=raw_narrative or "Narrative unclear — see chat_log.",
        chat_log=chat_log,
    )

    # RefundIntent only if the full bank form was captured (PAYOUT phase
    # reached + all three fields present). The view's BankFormSerializer
    # is the production gate; this triple-check guards replay paths
    # (manual repair, test fixtures) where ``bank_draft`` may be
    # partially populated and avoids storing a half-blank RefundIntent.
    if (
        bank_draft.get("bank_name")
        and bank_draft.get("account_title")
        and bank_draft.get("iban")
    ):
        RefundIntent.objects.create(
            ticket=ticket,
            bank_name=bank_draft["bank_name"],
            account_title=bank_draft["account_title"],
            iban=bank_draft["iban"],
        )

    # Audit + realtime side effects (shared with the form path). The
    # chatbot is always customer-initiated — the persona's eligibility
    # check scopes the booking lookup to ``customer=user``.
    apply_dispute_opened_side_effects(
        ticket=ticket,
        booking=booking,
        opener_role="customer",
    )

    return ticket
