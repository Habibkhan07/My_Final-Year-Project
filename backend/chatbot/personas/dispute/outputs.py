"""Side effects the dispute persona produces when a conversation closes.

``finalize_dispute`` is called from ``DisputePersona.on_close``. It runs
inside the conversation service's transaction (which holds a row lock
on the Conversation), so calls serialize naturally — no extra locking
needed here.

Idempotency: if ``conversation.output_refs`` already holds a
``support_ticket_id``, we return it without re-creating. Otherwise we
delegate to ``disputes.services.ticket_creation`` and return the
new ticket's id.
"""
from __future__ import annotations


def finalize_dispute(conversation) -> dict:
    """Produce a SupportTicket (+ RefundIntent) for a closed dispute
    conversation. Returns the ``output_refs`` dict the conversation
    service writes onto ``Conversation.output_refs``."""
    # Idempotency short-circuit (re-entry from a replay / retry).
    existing = (conversation.output_refs or {}).get("support_ticket_id")
    if existing:
        return dict(conversation.output_refs)

    # Local import: keeps chatbot.personas.dispute importable without
    # the disputes app, and avoids a circular-import risk between the
    # two app trees at module-load time.
    from disputes.services.ticket_creation import create_from_chatbot_session

    ticket = create_from_chatbot_session(conversation=conversation)
    return {"support_ticket_id": ticket.id}
