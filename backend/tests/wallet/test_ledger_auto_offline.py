"""Auto-offline on negative-balance ledger writes.

Pins the rule that ``record_transaction`` flips ``TechnicianProfile.is_online``
to False inside the same atomic block when the ledger write drives balance
into the red. The recovery side is deliberately asymmetric: top-ups that
clear lockout do NOT auto-flip back to online — coming back online is an
explicit tech action.

Authoritative reference: memory ``wallet-money-mechanics``.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import TransactionType
from wallet.services.ledger import record_transaction


# ──────────────────────────────────────────────────────────────────────
# Forward direction — negative-driving writes flip is_online to False.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAutoOfflineForwardTransition:
    """Going from non-negative to negative on an online tech forces offline."""

    def test_commission_drives_negative_flips_offline(self):
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-300.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-200.00')
        assert tech.is_online is False

    def test_refund_drives_negative_flips_offline(self):
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('50.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.REFUND_DEBIT,
            amount=Decimal('-200.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-150.00')
        assert tech.is_online is False

    def test_negative_adjustment_drives_negative_flips_offline(self):
        """Admin debit that crosses zero — same rule, regardless of type."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('-200.00'),
            is_manual_adjustment=True,
            memo='Backfill missed commission',
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-100.00')
        assert tech.is_online is False

    def test_one_paisa_negative_flips_offline(self):
        """Boundary: strictly negative triggers — even one paisa under."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-100.01'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-0.01')
        assert tech.is_online is False


# ──────────────────────────────────────────────────────────────────────
# Non-transitions — writes that don't cross zero leave is_online alone.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAutoOfflineNonTransitions:
    """Writes that stay non-negative don't touch is_online."""

    def test_commission_that_keeps_balance_positive_does_not_flip(self):
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('1000.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-200.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('800.00')
        assert tech.is_online is True  # unchanged

    def test_balance_landing_exactly_zero_does_not_flip(self):
        """The lockout rule is strict ``< 0``. Zero is the boundary,
        not in lockout — auto-offline must NOT fire."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.WITHDRAWAL_DEBIT,
            amount=Decimal('-100.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('0.00')
        assert tech.is_online is True  # zero is NOT lockout

    def test_topup_on_positive_balance_does_not_change_is_online(self):
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('500.00'),
            is_online=True,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('1000.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('1500.00')
        assert tech.is_online is True


# ──────────────────────────────────────────────────────────────────────
# Already offline — subsequent writes on locked tech don't toggle.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAutoOfflineIdempotentOnAlreadyOffline:
    """Already-offline tech stays offline regardless of write direction."""

    def test_commission_deepening_negative_keeps_offline(self):
        """Locked + offline tech who completes another job — commission
        records, balance dips further, is_online stays False (idempotent)."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('-100.00'),
            is_online=False,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-50.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('-150.00')
        assert tech.is_online is False

    def test_offline_tech_stays_offline_on_positive_balance_ledger_write(self):
        """A tech who was offline for ANY reason (lockout or manual toggle)
        stays offline — record_transaction never auto-onlines them."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=False,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-50.00'),
        )

        tech.refresh_from_db()
        assert tech.is_online is False


# ──────────────────────────────────────────────────────────────────────
# Recovery asymmetry — top-up clears lockout but does NOT re-online.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestAutoOfflineRecoveryAsymmetry:
    """The intentional asymmetry: going OFFLINE is automatic; coming
    BACK ONLINE is a manual tech action."""

    def test_topup_clearing_lockout_does_not_auto_online(self):
        """The recovery loop is intentionally visible: tech sees they were
        force-offlined, taps top-up, then explicitly taps back online."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('-200.00'),
            is_online=False,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.TOPUP_CREDIT,
            amount=Decimal('500.00'),
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('300.00')
        # Lockout cleared, but tech still offline — manual toggle required.
        assert tech.is_online is False

    def test_adjustment_clearing_lockout_does_not_auto_online(self):
        """Admin credit that clears lockout — same rule. Coming back
        online is a tech-initiated action regardless of how lockout
        was cleared (top-up, admin adjustment, or any future path)."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('-100.00'),
            is_online=False,
        )

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.ADJUSTMENT,
            amount=Decimal('200.00'),
            is_manual_adjustment=True,
            memo='Goodwill credit',
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == Decimal('100.00')
        assert tech.is_online is False


# ──────────────────────────────────────────────────────────────────────
# Update-fields hygiene — only mutated columns hit the DB.
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestUpdateFieldsScope:
    """Confirm we don't accidentally widen the UPDATE statement and
    risk write-collision with concurrent unrelated field writes."""

    def test_non_offlining_write_writes_only_balance(self, mocker):
        """A write that doesn't change is_online must NOT include it in
        update_fields — otherwise unrelated concurrent writes (e.g. an
        is_online toggle) could lose their value."""
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('1000.00'),
            is_online=True,
        )

        spy = mocker.spy(type(tech), 'save')

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-100.00'),
        )

        # Find the .save() call made by the ledger (there's one per write).
        ledger_save_call = next(
            c for c in spy.call_args_list
            if c.kwargs.get('update_fields') is not None
        )
        assert ledger_save_call.kwargs['update_fields'] == ['current_wallet_balance']

    def test_offlining_write_includes_is_online_in_update_fields(self, mocker):
        tech = TechnicianProfileFactory(
            current_wallet_balance=Decimal('100.00'),
            is_online=True,
        )

        spy = mocker.spy(type(tech), 'save')

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-200.00'),
        )

        ledger_save_call = next(
            c for c in spy.call_args_list
            if c.kwargs.get('update_fields') is not None
        )
        assert ledger_save_call.kwargs['update_fields'] == [
            'current_wallet_balance',
            'is_online',
        ]
