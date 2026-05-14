"""Output validators specific to the dispute persona.

Registered as ``DisputePersona.extra_output_validators``. The
``content_safety.validate_output`` framework function composes these
with the global PII denylist — these extend, not weaken, the global
checks.

The LLM is expressly told (in the UNDERSTAND system prompt) NOT to
quote policy or invent SLA timeframes. These validators are belt-and-
suspenders: if the LLM violates its prompt anyway, we substitute a
fallback message rather than show the user a hallucinated commitment.
"""
from __future__ import annotations

import re


_INVENT_SLA_RE = re.compile(
    r"within\s+\d+\s*(?:day|hour|week|month|business\s+day|working\s+day)s?",
    re.IGNORECASE,
)

_FORBIDDEN_SUBSTRINGS = (
    "guarantee",
    "policy says",
    "our policy",
    "your refund will arrive",
    "refund will be issued",
    "we will refund",
    "definitely a refund",
    "your refund is approved",
)


def no_sla_other_than_canonical(text: str) -> tuple[bool, str | None]:
    """Reject outputs that name a specific SLA timeframe.

    The canonical SLA string is rendered by the templated closing
    message — the LLM should never quote a timeframe inline. If it does,
    fall back so the customer doesn't see a competing/wrong commitment.
    """
    if _INVENT_SLA_RE.search(text):
        return False, "output_invents_sla"
    return True, None


def no_guarantee_or_policy_claims(text: str) -> tuple[bool, str | None]:
    """Reject outputs that quote policy or promise specific outcomes."""
    lower = text.lower()
    for needle in _FORBIDDEN_SUBSTRINGS:
        if needle in lower:
            return False, "output_makes_policy_claim"
    return True, None
