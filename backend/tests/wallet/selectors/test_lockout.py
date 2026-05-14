"""Tests for ``wallet.selectors.lockout`` — single source of truth for
the negative-balance lockout rule.

Pins:

* ``is_wallet_locked`` returns True iff ``balance < 0`` (strictly).
  Zero is NOT locked; one paisa negative IS locked.
* ``lockout_status`` returns a Dumb-UI payload whose ``balance_pkr`` and
  ``owed_pkr`` reconcile to zero on locked accounts (no paisa drift).
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from tests.factories.technicians import TechnicianProfileFactory
from wallet.selectors.lockout import is_wallet_locked, lockout_status


# ──────────────────────────────────────────────────────────────────────
# is_wallet_locked — strict ``< 0`` semantics.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestIsWalletLocked:
    def test_zero_balance_is_not_locked(self):
        """Zero is the boundary — exactly zero is NOT lockout."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        assert is_wallet_locked(tech) is False

    def test_positive_balance_is_not_locked(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('500.00'))
        assert is_wallet_locked(tech) is False

    def test_one_paisa_negative_is_locked(self):
        """The boundary is strict — any negative value triggers lockout."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-0.01'))
        assert is_wallet_locked(tech) is True

    def test_deeply_negative_is_locked(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-1000.00'))
        assert is_wallet_locked(tech) is True

    def test_uses_balance_from_passed_instance_not_db(self):
        """The selector reads ``technician.current_wallet_balance`` directly.
        Caller is responsible for instance freshness — verified by the
        in-memory mutation here."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('100.00'))
        assert is_wallet_locked(tech) is False

        # In-memory mutation (not persisted). Selector observes it.
        tech.current_wallet_balance = Decimal('-1.00')
        assert is_wallet_locked(tech) is True


# ──────────────────────────────────────────────────────────────────────
# lockout_status — Dumb-UI payload shape.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestLockoutStatus:
    def test_zero_balance_payload(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        assert lockout_status(tech) == {
            "is_locked_out": False,
            "balance_pkr": 0,
            "owed_pkr": 0,
        }

    def test_positive_balance_payload(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('500.00'))
        assert lockout_status(tech) == {
            "is_locked_out": False,
            "balance_pkr": 500,
            "owed_pkr": 0,
        }

    def test_negative_whole_balance(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-200.00'))
        assert lockout_status(tech) == {
            "is_locked_out": True,
            "balance_pkr": -200,
            "owed_pkr": 200,
        }

    def test_paisa_fraction_owed_rounds_up(self):
        """Owed must round UP so paying that amount clears the lockout —
        truncation would leave the tech a paisa short and still locked.
        Balance also floors to keep the visual invariant balance + owed == 0."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-100.01'))
        result = lockout_status(tech)

        assert result["is_locked_out"] is True
        assert result["owed_pkr"] == 101  # floor(-100.01) → -101, owed = 101
        assert result["balance_pkr"] == -101
        # The visual reconciliation invariant.
        assert result["balance_pkr"] + result["owed_pkr"] == 0

    def test_one_paisa_negative_payload(self):
        """Even one paisa underwater is locked. Owed rounds up to Rs. 1
        so a Rs. 1 top-up takes the tech to +0.99 — out of lockout."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-0.01'))
        result = lockout_status(tech)

        assert result["is_locked_out"] is True
        assert result["owed_pkr"] == 1
        assert result["balance_pkr"] == -1
        assert result["balance_pkr"] + result["owed_pkr"] == 0

    def test_deep_negative_with_paisa(self):
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('-1234.56'))
        result = lockout_status(tech)

        assert result["is_locked_out"] is True
        assert result["owed_pkr"] == 1235  # floor(-1234.56) = -1235, owed = 1235
        assert result["balance_pkr"] == -1235

    def test_status_matches_is_wallet_locked(self):
        """The two APIs MUST agree on the boolean — they are the same rule."""
        for balance_str in ('0.00', '0.01', '-0.01', '500.00', '-500.00', '-100.99'):
            tech = TechnicianProfileFactory(current_wallet_balance=Decimal(balance_str))
            assert lockout_status(tech)["is_locked_out"] is is_wallet_locked(tech), (
                f'Disagreement at balance={balance_str}'
            )
