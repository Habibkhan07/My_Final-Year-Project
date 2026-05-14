"""PII redaction at the LLM input boundary + output validation gate.

Two guarantees applied framework-wide — every persona inherits them:

  1. ``redact_input`` substitutes ``[REDACTED]`` for PII shapes BEFORE the
     text is handed to the LLM adapter. Even if a user pastes an IBAN
     mid-narrative or a prompt-injection attempt embeds a phone number,
     the LLM never sees the actual digits.

  2. ``validate_output`` rejects LLM responses that:
       - exceed a length cap (per ``kind`` — turn_message, summary, closing)
       - contain PII shapes (LLM hallucinating an IBAN back at the user)
       - echo the ``[REDACTED]`` marker (a sign the prompt leaked into the
         response — visible to user as `"Your [REDACTED] is..."`)
       - trip any persona-declared extra validator
     On rejection the adapter substitutes a canned ``fallback_message``.

The denylist patterns are deliberately Pakistan-tuned (PK IBAN prefix,
+92/03 phone shape, 13-digit CNIC) since this is the only market we serve
in v1. Adding a country = adding patterns here, not re-architecting.
"""
from __future__ import annotations

import re
from typing import Callable


# -- PII patterns ----------------------------------------------------------
# Patterns are intentionally permissive — false positives (over-redaction)
# are far cheaper than false negatives (leaking PII to the LLM provider).

# IBAN: ISO 13616 — country (2 letters) + 2 check digits + 11-30 alphanumeric.
# Captures Pakistani PK36... and accepts other countries for forward
# compatibility (we won't ship a non-PK booking in v1, but a customer
# might paste a foreign IBAN by mistake).
_IBAN_RE = re.compile(r"\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b")

# Pakistani mobile: +92 3xx 1234567 or 03xx 1234567, with optional spaces.
_PHONE_RE = re.compile(r"(?:\+92|0)\s?3\d{2}[-\s]?\d{7}")

# CNIC: 13 digits, optionally formatted 12345-1234567-1.
_CNIC_RE = re.compile(r"\b\d{5}-?\d{7}-?\d\b")

# Email (loose; we only care about pattern, not RFC correctness).
_EMAIL_RE = re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b")

# URL (http/https only — we don't strip bare-host references, that would
# over-redact legitimate text like "yourbank.com sent me a code").
_URL_RE = re.compile(r"https?://\S+", re.IGNORECASE)

# Sentinel used by ``redact_input``. The output validator checks for this
# marker being echoed back from the LLM (a sign the prompt leaked).
_REDACTED_MARKER_RE = re.compile(r"\[REDACTED\]", re.IGNORECASE)

_REDACT_PATTERNS: tuple[re.Pattern, ...] = (
    _IBAN_RE,
    _PHONE_RE,
    _CNIC_RE,
    _EMAIL_RE,
    _URL_RE,
)

REDACTION_MARKER = "[REDACTED]"


# -- Length caps -----------------------------------------------------------

LENGTH_CAPS: dict[str, int] = {
    "turn_message": 600,
    "summary": 400,
    "closing": 200,
}


# -- Public API ------------------------------------------------------------

def redact_input(text: str) -> str:
    """Substitute ``[REDACTED]`` for any PII-shaped substring.

    Called on EVERY user-provided string before it reaches the LLM.
    Idempotent: re-redacting already-redacted text returns the same
    string (the marker itself doesn't match any redaction pattern).
    """
    if not text:
        return text
    out = text
    for pattern in _REDACT_PATTERNS:
        out = pattern.sub(REDACTION_MARKER, out)
    return out


def validate_output(
    text: str,
    *,
    persona_key: str,
    kind: str,
    extra_validators: list[Callable[[str], tuple[bool, str | None]]] | None = None,
) -> tuple[bool, str | None]:
    """Check an LLM-produced string against framework + persona rules.

    Returns ``(True, None)`` if safe to show to the user, or
    ``(False, reason)`` to trigger fallback. ``reason`` is a short
    snake_case identifier suitable for logging and for storing in
    ``SupportTicket.needs_review_reason`` (via the ``chat_log`` JSON).
    """
    if not text:
        return False, "empty_output"

    cap = LENGTH_CAPS.get(kind)
    if cap is not None and len(text) > cap:
        return False, "length_cap_exceeded"

    # PII regex denylist (the LLM should not produce these; if it does we
    # never show the user — a hallucinated IBAN or phone in a refund
    # confirmation would be a trust-destroying demo failure).
    for pattern, reason in (
        (_IBAN_RE, "output_contains_iban"),
        (_PHONE_RE, "output_contains_phone"),
        (_CNIC_RE, "output_contains_cnic"),
        (_EMAIL_RE, "output_contains_email"),
        (_URL_RE, "output_contains_url"),
        (_REDACTED_MARKER_RE, "output_echoes_redaction_marker"),
    ):
        if pattern.search(text):
            return False, reason

    # Persona-declared validators run last so a persona can add MORE
    # restrictions (e.g. dispute rejects "policy says" / "guarantee" /
    # alternate SLA timeframes) but cannot weaken the framework checks.
    if extra_validators:
        for v in extra_validators:
            ok, reason = v(text)
            if not ok:
                return False, reason

    return True, None


# -- Fallback messages -----------------------------------------------------
# Static canned strings used when the LLM call fails or ``validate_output``
# rejects the response. v1 ships English only; Urdu localization is a
# flagged v1.1 task.

_FALLBACKS: dict[str, str] = {
    "turn_message": "Sorry, I couldn't process that. Please try rephrasing.",
    "summary": "Narrative captured — admin will review.",
    "closing": "Thanks. Your ticket has been filed.",
    "default": "Sorry, something went wrong. Please try again.",
}


def fallback_message(persona_key: str, kind: str, lang: str = "en") -> str:
    """Return a canned safe message for ``kind`` (turn_message, summary,
    closing). ``persona_key`` and ``lang`` accepted for forward
    compatibility — v1 returns the same English string regardless."""
    return _FALLBACKS.get(kind, _FALLBACKS["default"])
