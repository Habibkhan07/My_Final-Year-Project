"""Tests for chatbot.personas.dispute.validators.

These extra validators ride on top of the global content-safety checks
to prevent the LLM from making promises or quoting policy. Each
validator returns ``(True, None)`` for safe text and ``(False, reason)``
for rejection.
"""
from __future__ import annotations

from chatbot.personas.dispute.validators import (
    no_guarantee_or_policy_claims,
    no_sla_other_than_canonical,
)


class TestNoSlaOtherThanCanonical:
    def test_safe_text_passes(self):
        ok, reason = no_sla_other_than_canonical(
            "Thanks for the details. Could you tell me what happened next?"
        )
        assert ok is True
        assert reason is None

    def test_rejects_within_n_days(self):
        ok, reason = no_sla_other_than_canonical(
            "Your refund will be processed within 5 days."
        )
        assert ok is False
        assert reason == "output_invents_sla"

    def test_rejects_within_n_hours(self):
        ok, reason = no_sla_other_than_canonical(
            "We'll review within 24 hours."
        )
        assert ok is False

    def test_rejects_business_days(self):
        ok, reason = no_sla_other_than_canonical(
            "Review takes within 2 business days."
        )
        assert ok is False

    def test_rejects_working_days_variant(self):
        ok, reason = no_sla_other_than_canonical(
            "Within 3 working days."
        )
        assert ok is False

    def test_case_insensitive(self):
        ok, reason = no_sla_other_than_canonical(
            "WITHIN 7 DAYS we will resolve."
        )
        assert ok is False


class TestNoGuaranteeOrPolicyClaims:
    def test_safe_text_passes(self):
        ok, reason = no_guarantee_or_policy_claims(
            "Could you tell me what time the issue happened?"
        )
        assert ok is True
        assert reason is None

    def test_rejects_guarantee(self):
        ok, reason = no_guarantee_or_policy_claims(
            "We guarantee you'll get a refund."
        )
        assert ok is False
        assert reason == "output_makes_policy_claim"

    def test_rejects_policy_says(self):
        ok, reason = no_guarantee_or_policy_claims(
            "Our policy says you can get a full refund."
        )
        assert ok is False

    def test_rejects_refund_will_arrive(self):
        ok, reason = no_guarantee_or_policy_claims(
            "Your refund will arrive shortly."
        )
        assert ok is False

    def test_rejects_we_will_refund(self):
        ok, reason = no_guarantee_or_policy_claims(
            "We will refund you the full amount."
        )
        assert ok is False

    def test_case_insensitive(self):
        ok, reason = no_guarantee_or_policy_claims(
            "We GUARANTEE this won't happen again."
        )
        assert ok is False
