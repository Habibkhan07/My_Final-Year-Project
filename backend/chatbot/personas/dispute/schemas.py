"""JSON schemas for the dispute persona.

Two schemas:
  - ``DISPUTE_TURN_SCHEMA`` — the structured-output contract for every
    LLM call in the UNDERSTAND phase. The adapter passes this as
    ``response_schema`` and parses the JSON result; the flow reads
    ``phase_complete`` (advisory) and ``fields_captured`` (validated
    against the flow's own required-field list).
  - ``BANK_FORM_SCHEMA`` — UI hint for the frontend bank-details form.
    The serializer is the real validator; this schema just tells Flutter
    which fields to render and their basic shapes.
"""
from __future__ import annotations


# ---- Structured output schema for LLM turn -------------------------------
# Gemini's response_schema follows an OpenAPI-subset shape — ``type``,
# ``properties``, ``required``, etc. The flow tolerates a malformed
# response (the adapter falls back); this schema improves the odds but
# is not a security boundary.

DISPUTE_TURN_SCHEMA: dict = {
    "type": "object",
    "properties": {
        "message_to_user": {
            "type": "string",
            "description": (
                "The chat-bubble text the customer will see. "
                "2-3 sentences maximum. In the customer's own language."
            ),
        },
        "phase_complete": {
            "type": "boolean",
            "description": (
                "Set true ONLY when issue_summary is captured AND the "
                "customer seems done sharing facts. The system "
                "validates required fields independently — lying here "
                "does not advance the conversation."
            ),
        },
        "fields_captured": {
            "type": "object",
            "properties": {
                "issue_summary": {
                    "type": "string",
                    "description": "What went wrong, in the customer's words.",
                },
                "amount_paid": {
                    "type": "string",
                    "description": "Total paid in PKR if mentioned. String "
                                   "(users say 'Rs 3500', 'thirty-five hundred', etc).",
                },
                "date_of_failure": {
                    "type": "string",
                    "description": "When the issue happened/was noticed.",
                },
                "contacted_technician": {
                    "type": "string",
                    "description": "yes / no / unclear — did the customer try to contact the tech?",
                },
            },
        },
        "asked_off_topic": {
            "type": "boolean",
            "description": (
                "True if the customer's message was off-topic for dispute "
                "intake (refund policy, general questions, etc). You "
                "should have redirected them in message_to_user."
            ),
        },
    },
    "required": [
        "message_to_user",
        "phase_complete",
        "fields_captured",
        "asked_off_topic",
    ],
}


# ---- Bank details form schema --------------------------------------------
# Consumed by the frontend to render the PAYOUT form inline in the chat.
# The DRF serializer (``chatbot.serializers.DisputeChatPayoutSerializer``)
# is the authoritative validator at submission time.

BANK_FORM_SCHEMA: dict = {
    "fields": [
        {
            "key": "bank_name",
            "label": "Bank name",
            "type": "text",
            "required": True,
            "max_length": 64,
            "hint": "e.g. HBL, Meezan, UBL",
        },
        {
            "key": "account_title",
            "label": "Account title (as on account)",
            "type": "text",
            "required": True,
            "max_length": 128,
            "hint": "Full name as it appears on the bank statement",
        },
        {
            "key": "iban",
            "label": "IBAN",
            "type": "text",
            "required": True,
            "pattern": r"^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$",
            "hint": "Pakistani IBANs start with PK followed by 22 characters",
        },
    ],
}
