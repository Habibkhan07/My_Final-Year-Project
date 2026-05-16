"""GeneralHelpPersona — free-form Q&A about the Karigar platform.

Second persona registered with the framework after ``dispute``. Wired
into the registry by ``ChatbotConfig.ready``. Adding this persona did
not require edits to ``chatbot.views``, ``chatbot.services``,
``chatbot.adapters``, or ``chatbot.serializers`` — only the registry
import line in ``apps.py``. That's the pluggable-framework claim made
concrete.

Eligibility: any authenticated user can start a session at any time.
There is no booking or precondition to check.

Resume policy: we do NOT implement ``find_existing_open``. Each call to
``POST /api/chat/general/start/`` creates a fresh conversation. The
backend keeps the full transcript so an admin or future feature can
revisit it, but the user sees a clean greeting on every open. This
keeps the UX simple for viva and avoids edge cases (resume of a stale
session that talked about old prices, etc.). Opt-in resume is a
v1.1 addition — uncomment the method below and the orchestration
service picks it up.
"""
from __future__ import annotations

from typing import TYPE_CHECKING

from chatbot.personas.general.flow import GeneralChatFlow

if TYPE_CHECKING:
    from chatbot.models import Conversation


class GeneralHelpPersona:
    """The general help persona."""

    key = "general"
    display_name = "Help"
    flow_engine = GeneralChatFlow()
    tools: list = []  # no tools in v1

    # The Persona Protocol declares these for static-prompt personas.
    # We build prompts dynamically per turn (live service list) inside
    # the flow, so these are placeholders that no code reads.
    system_prompt: str = "(dynamic — built by GeneralChatFlow per turn)"
    response_schema: dict | None = None

    # ---- Persona Protocol surface ---------------------------------------

    def is_eligible_to_start(self, user, context: dict) -> bool:
        """Any authenticated user can open a help conversation.

        Authentication is enforced by the view layer
        (``IsAuthenticated``); this method is a business-rule gate
        that has no business rule to enforce for general help.
        """
        return True

    # ``find_existing_open`` deliberately omitted. The orchestration
    # service treats its absence as "always create fresh" (see
    # ``conversation.start_conversation``). Opt in later by adding the
    # method back.

    def initial_state(self, context: dict) -> dict:
        # Single phase. The framework expects ``state['phase']`` to be
        # populated for serialization (it surfaces as ``current_phase``
        # in the start response).
        return {"phase": "CHAT"}

    def on_close(self, conversation: "Conversation") -> dict:
        """No side effects on close — general help produces no tickets,
        refund intents, or persisted artifacts. The conversation row
        and its messages remain for audit, that's all."""
        return {}
