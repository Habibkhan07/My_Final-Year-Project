"""DisputePersona — the dispute resolution plugin.

Wires together flow + prompts + schemas + validators + outputs. Registered
into the chatbot framework's persona registry by
``ChatbotConfig.ready()``.

Eligibility rules (mirrors the customer-visible ``show_dispute_button``):
  - The booking must exist and belong to the requesting user.
  - The booking status must be ``COMPLETED`` or
    ``COMPLETED_INSPECTION_ONLY``. Disputes opened earlier than that
    have nothing to dispute yet.

Concurrency: ``is_eligible_to_start`` locks the booking row with
``select_for_update``, and the conversation service's
``start_conversation`` runs inside ``transaction.atomic``. So two
parallel POSTs racing to create a chat on the same booking serialize on
this lock — the second sees the first's conversation via
``find_existing_open`` and gets a resume rather than a duplicate row.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

from bookings.models import JobBooking
from chatbot.personas.dispute.flow import DisputeFlow
from chatbot.personas.dispute.outputs import finalize_dispute

if TYPE_CHECKING:
    from chatbot.models import Conversation


_DISPUTE_ELIGIBLE_STATUSES = (
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
)


class DisputePersona:
    """The dispute resolution persona — v1's only registered persona."""

    key = "dispute"
    display_name = "Dispute Resolution"
    flow_engine = DisputeFlow()
    tools: list = []  # no tools in v1; structurally satisfies the Protocol

    # The Persona Protocol declares system_prompt and response_schema as
    # required attributes for future personas that ARE static-prompt-driven.
    # The dispute persona builds prompts dynamically with booking context
    # inside DisputeFlow, so these are placeholders that no code reads.
    system_prompt: str = "(dynamic — built by DisputeFlow with booking context)"
    response_schema: dict | None = None

    # ---- Persona Protocol surface ---------------------------------------

    def is_eligible_to_start(self, user, context: dict) -> bool:
        """Authorize and gate. Must be called inside a transaction so the
        booking-row lock is honored.

        Returns True if the (user, booking) pair can open a dispute.
        Returns False on IDOR (other user's booking), missing booking,
        or wrong status — never raises, lets the caller produce a clean
        ``not_eligible`` error envelope.
        """
        booking_id = context.get("booking_id")
        if not booking_id:
            return False
        try:
            booking = (
                JobBooking.objects.select_for_update()
                .get(id=booking_id, customer=user)
            )
        except JobBooking.DoesNotExist:
            # Covers both "no such booking" and "wrong customer" (IDOR).
            return False
        return booking.status in _DISPUTE_ELIGIBLE_STATUSES

    def find_existing_open(self, user, context: dict):
        """Return an existing open dispute conversation for this booking,
        or None. Called by the conversation service to support
        resume-on-restart instead of duplicate-conversation errors.
        """
        from chatbot.models import Conversation

        booking_id = context.get("booking_id")
        if not booking_id:
            return None
        return (
            Conversation.objects
            .filter(
                user=user,
                persona_key=self.key,
                is_closed=False,
                context__booking_id=booking_id,
            )
            .first()
        )

    def initial_state(self, context: dict) -> dict:
        return {
            "phase": "UNDERSTAND",
            "captured_fields": {},
            "bank_draft": {},
            "off_topic_count": 0,
            "forced_advance": False,
        }

    def on_close(self, conversation: "Conversation") -> dict:
        return finalize_dispute(conversation)
