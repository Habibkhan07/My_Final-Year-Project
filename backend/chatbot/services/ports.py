"""Protocols and value types — the seams that make the chatbot pluggable.

Three pluggable seams:
  - ``ConversationalAgent`` decouples the LLM vendor from personas. Adapters
    are selected by the ``LLM_ADAPTER`` setting (today: ``gemini``).
  - ``FlowEngine`` decouples per-persona turn logic from the orchestration
    service. State-machine personas (dispute) and free-form personas
    (future general bot) both satisfy this Protocol — different bodies,
    same shape.
  - ``Persona`` is the top-level plugin record kept in the registry.

Protocols are structural (not ``runtime_checkable``) — a concrete class
need not inherit anything, it just needs to match the shape. Test fakes
inline these inline without ceremony.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Literal, Protocol, TYPE_CHECKING, TypedDict

if TYPE_CHECKING:
    from chatbot.models import Conversation


# ---- Value types ----------------------------------------------------------

class AgentOutput(TypedDict):
    """Result of a single ``ConversationalAgent.generate`` call.

    ``fallback_used=True`` means the call hit a guarded failure (timeout,
    parse error, output-validation rejection, safety block) and ``text``
    is a canned safe message rather than fresh LLM content. Callers use
    this flag to set ``needs_review`` on resulting tickets.
    """
    text: str
    structured: dict | None
    tool_calls: list[dict]
    finish_reason: str
    fallback_used: bool


UiInputKind = Literal["text", "attachment", "form", "none", "close"]


@dataclass(frozen=True)
class TurnResult:
    """One step's state-advance + UI instruction.

    Producers (``FlowEngine`` implementations) return this from
    ``opening_turn`` and ``handle_user_turn``. The conversation service
    persists ``bot_message`` as a Message row, merges ``state_patch`` into
    ``Conversation.state``, and the view serializes the UI fields for the
    frontend. ``is_terminal=True`` causes the service to close the
    conversation and trigger ``Persona.on_close``.
    """
    bot_message: str
    ui_input_kind: UiInputKind
    ui_form_schema: dict | None
    ui_hint: str
    state_patch: dict
    is_terminal: bool


# Callable shape: ``(text) -> (is_safe, reason_or_None)``
OutputValidator = Callable[[str], "tuple[bool, str | None]"]


# ---- Tool (declared for Persona stability; not executed in v1) ------------

class Tool(Protocol):
    """A function-call tool spec.

    The Gemini adapter's tool-calling branch is wired but unexercised in
    v1 — every shipped persona declares ``tools=[]``. Defined here so
    adding tool support to a future persona doesn't require changing the
    Persona Protocol shape.
    """
    name: str
    description: str
    json_schema: dict

    def execute(self, args: dict, user) -> dict: ...


# ---- ConversationalAgent (the LLM seam) -----------------------------------

class ConversationalAgent(Protocol):
    """The vendor-neutral LLM interface.

    Single method. The caller (a FlowEngine) supplies the system prompt,
    the conversation history, and optionally a JSON schema for structured
    output and/or persona-declared output validators. The adapter handles
    vendor-specific concerns: timeout, retry, structured-output parsing,
    output validation, fallback.
    """
    def generate(
        self,
        *,
        system_prompt: str,
        history: list[dict],
        user_message: str,
        response_schema: dict | None = None,
        tools: list[Tool] | None = None,
        extra_validators: list[OutputValidator] | None = None,
    ) -> AgentOutput: ...


# ---- FlowEngine (per-persona turn orchestration) -------------------------

class FlowEngine(Protocol):
    """Drives turns inside a conversation.

    The conversation service owns lifecycle (start, advance, close) and
    cross-cutting concerns (quota, persistence). The flow owns
    domain-specific logic: which question to ask, whether the user's
    answer captured what we needed, when to advance phase, when to
    terminate.
    """

    def opening_turn(
        self,
        conversation: "Conversation",
        agent: ConversationalAgent,
    ) -> TurnResult:
        """Produce the first bot message (no user input yet)."""

    def handle_user_turn(
        self,
        conversation: "Conversation",
        message_kind: str,
        payload: Any,
        agent: ConversationalAgent,
    ) -> TurnResult:
        """Process one user-driven turn (text, form submit, or
        attachment-done signal) and return the next bot response."""

    def is_terminal(self, conversation: "Conversation") -> bool:
        """True when the conversation has reached its end state."""


# ---- Persona (top-level plugin) ------------------------------------------

class Persona(Protocol):
    """Top-level plugin record. Registered in ``chatbot.personas``."""

    key: str                               # e.g. "dispute"
    display_name: str
    flow_engine: FlowEngine
    tools: list[Tool]                       # empty for v1 personas
    system_prompt: str
    response_schema: dict | None
    # NOTE: persona-level output validators were removed in v1.1 — they
    # were dead code (the Gemini adapter discards what it's given and
    # the flow is the only real consumer). Validators now live with the
    # flow that uses them (e.g. ``_DISPUTE_EXTRA_VALIDATORS`` in
    # ``personas/dispute/flow.py``). Adding back later is a Protocol
    # extension if a persona ever wants to expose validators to the
    # adapter chain.

    def is_eligible_to_start(self, user, context: dict) -> bool:
        """Authorization + business-rule gate run before a conversation
        is created. Implementations MAY take row locks (the dispute
        persona locks the relevant Booking row) — the conversation
        service wraps this call in a transaction."""

    def initial_state(self, context: dict) -> dict:
        """Initial ``Conversation.state`` payload for a fresh session."""

    def on_close(self, conversation: "Conversation") -> dict:
        """Run side effects when the conversation closes (e.g. create a
        SupportTicket + RefundIntent). Returns the dict written to
        ``Conversation.output_refs`` — handles for whatever was created.
        Idempotent: replaying must not duplicate side effects."""
