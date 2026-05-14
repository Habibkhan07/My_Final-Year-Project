"""Tests for chatbot.services.content_safety.

Three contracts pinned here:
  1. PII redaction at the LLM-input boundary catches every documented
     pattern (IBAN, PK phone, CNIC, email, URL) and is idempotent.
  2. Output validation rejects LLM responses that contain PII shapes,
     exceed length caps, or echo the redaction marker.
  3. Persona-declared extra validators compose with the global checks.
"""
from __future__ import annotations

from chatbot.services.content_safety import (
    REDACTION_MARKER,
    fallback_message,
    redact_input,
    validate_output,
)


class TestRedactInput:
    def test_strips_pakistani_iban(self):
        out = redact_input("My IBAN is PK36HABB0011223344556677 for refunds.")
        assert "PK36HABB0011223344556677" not in out
        assert REDACTION_MARKER in out

    def test_strips_pakistani_phone_variants(self):
        for phone in ("+923001234567", "03001234567", "+92 300 1234567"):
            out = redact_input(f"Call me at {phone} please")
            assert phone not in out, f"Failed for {phone!r} → {out!r}"
            assert REDACTION_MARKER in out

    def test_strips_cnic_both_formats(self):
        for cnic in ("12345-1234567-1", "1234512345671"):
            out = redact_input(f"My CNIC is {cnic} thanks")
            assert cnic not in out, f"Failed for {cnic!r}"

    def test_strips_email(self):
        out = redact_input("Reach me at user@example.com")
        assert "user@example.com" not in out
        assert REDACTION_MARKER in out

    def test_strips_url(self):
        out = redact_input("See https://evil.example/path?q=1 for details")
        assert "https://evil.example" not in out

    def test_idempotent(self):
        once = redact_input("Phone 03001234567 IBAN PK36HABB0011223344556677")
        twice = redact_input(once)
        assert once == twice, "redact_input is not idempotent"

    def test_empty_string_passthrough(self):
        assert redact_input("") == ""

    def test_preserves_clean_content(self):
        clean = "Hello, my AC is leaking water on the floor."
        assert redact_input(clean) == clean


class TestValidateOutput:
    def test_safe_text_passes(self):
        ok, reason = validate_output(
            "This looks like a normal bot message.",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is True
        assert reason is None

    def test_rejects_empty_output(self):
        ok, reason = validate_output(
            "", persona_key="dispute", kind="turn_message"
        )
        assert ok is False
        assert reason == "empty_output"

    def test_rejects_over_cap_turn_message(self):
        ok, reason = validate_output(
            "x" * 601, persona_key="dispute", kind="turn_message"
        )
        assert ok is False
        assert reason == "length_cap_exceeded"

    def test_rejects_over_cap_summary(self):
        ok, reason = validate_output(
            "x" * 401, persona_key="dispute", kind="summary"
        )
        assert ok is False
        assert reason == "length_cap_exceeded"

    def test_rejects_iban_in_output(self):
        ok, reason = validate_output(
            "Your refund goes to PK36HABB0011223344556677.",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is False
        assert reason == "output_contains_iban"

    def test_rejects_phone_in_output(self):
        ok, reason = validate_output(
            "Please call +923001234567 to confirm.",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is False
        assert reason == "output_contains_phone"

    def test_rejects_email_in_output(self):
        ok, reason = validate_output(
            "Contact admin@example.com",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is False
        assert reason == "output_contains_email"

    def test_rejects_url_in_output(self):
        ok, reason = validate_output(
            "See https://malicious.example/policy",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is False
        assert reason == "output_contains_url"

    def test_rejects_redaction_marker_echo(self):
        # If the LLM parrots the marker back, the user sees a broken
        # message like "Your [REDACTED] will be used for the refund."
        ok, reason = validate_output(
            "Your [REDACTED] will be used for the refund.",
            persona_key="dispute",
            kind="turn_message",
        )
        assert ok is False
        assert reason == "output_echoes_redaction_marker"

    def test_persona_extra_validators_rejection_wins(self):
        def reject_word_guarantee(text: str):
            if "guarantee" in text.lower():
                return False, "uses_forbidden_word_guarantee"
            return True, None

        ok, reason = validate_output(
            "We guarantee a refund.",
            persona_key="dispute",
            kind="turn_message",
            extra_validators=[reject_word_guarantee],
        )
        assert ok is False
        assert reason == "uses_forbidden_word_guarantee"

    def test_persona_extra_validators_allow_when_clean(self):
        def always_pass(text: str):
            return True, None

        ok, reason = validate_output(
            "All good.",
            persona_key="dispute",
            kind="turn_message",
            extra_validators=[always_pass],
        )
        assert ok is True
        assert reason is None

    def test_extra_validators_run_after_framework_checks(self):
        # Framework rejection (IBAN) should fire before extra validator.
        # Verifies short-circuit order; the extra validator must NOT run.
        called = {"count": 0}

        def spy(text: str):
            called["count"] += 1
            return True, None

        validate_output(
            "Account PK36HABB0011223344556677 will be used.",
            persona_key="dispute",
            kind="turn_message",
            extra_validators=[spy],
        )
        assert called["count"] == 0


class TestFallbackMessage:
    def test_returns_nonempty_string(self):
        msg = fallback_message("dispute", "turn_message")
        assert isinstance(msg, str)
        assert len(msg) > 0

    def test_unknown_kind_returns_default(self):
        unknown = fallback_message("dispute", "nonexistent_kind")
        default = fallback_message("dispute", "default")
        assert unknown == default
