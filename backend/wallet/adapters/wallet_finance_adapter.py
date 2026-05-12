"""WalletFinanceAdapter — concrete ``FinancePort`` implementation.

Tonight's purpose: replace ``NullFinanceAdapter`` so the booking
orchestrator actually moves money on every transition that the project
considers a platform-tech financial event.

Scope-by-hook (matches the FinancePort contract and the user-confirmed
business rules):

* ``can_accept_job``           → ``(True, None)`` always (lockout deferred Thu).
* ``record_commission``        → writes COMMISSION_DEBIT + JobCommission row.
                                  Commission = ``amount * PLATFORM_COMMISSION_RATE``
                                  (20%, snapshotted onto JobCommission).
* ``apply_inspection_fee_decision('accepted')``  → no-op.
   Money flows through ``record_cash_collected`` later (which itself is a
   no-op — customer-tech is cash-only; the wallet sees commission only).
* ``apply_inspection_fee_decision('declined')``  → no-op.
   Customer paid Rs.500 cash directly to the tech (terminal status
   COMPLETED_INSPECTION_ONLY). Per existing FinancePort docstring,
   commission is NOT levied on this path; tech keeps the 500 as
   compensation for the wasted visit. Revisit post-viva if business
   policy changes; flag entry opened.
* ``apply_cancellation_charge``  → no-op for all (actor, phase) tuples.
   Customer-cancel post-arrival is structurally impossible (customer
   declines quote instead). Tech-cancel reliability penalty deferred to
   v1.1. Cancellation fees, when they exist, are cash exchanges.
* ``record_cash_collected``    → no-op.
   Cash to tech's pocket. The wallet tracks platform-tech money flow
   (deposit + commission + top-up + withdraw); customer-tech cash is
   outside its scope. Dashboard's metrics row covers the cash-collected
   visibility need.

Every wallet write goes through ``wallet.services.ledger.record_transaction``
which is the single ACID-guaranteed ledger-write site.

Idempotency: ``record_commission`` keys on ``f'booking:{booking.id}:commission'``
so a retry from the orchestrator (e.g. concurrent transition) returns the
existing ledger row instead of double-debiting. The 1:1 OneToOne constraint
on ``JobCommission.booking`` is the database-level guarantee.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Literal

from django.db import IntegrityError

from bookings.services.job_request_dispatch import PLATFORM_COMMISSION_RATE
from wallet.models import JobCommission, TransactionType, WalletTransaction
from wallet.services.ledger import record_transaction


# SECURITY: every adapter method receives the booking row from the orchestrator,
# which itself fetched it under ``select_for_update`` after an IDOR guard.
# This adapter trusts its input. No new auth boundary is introduced here.


class WalletFinanceAdapter:
    """Implements ``bookings.services.finance_ports.FinancePort`` structurally."""

    # ------------------------------------------------------------------
    # Lockout
    # ------------------------------------------------------------------
    def can_accept_job(
        self,
        *,
        technician,
        payout_amount: Decimal,
    ) -> tuple[bool, str | None]:
        """Always permit for tonight.

        Lockout enforcement (``current_wallet_balance < threshold → block``)
        is deferred to Thursday 05-14 when the JazzCash top-up flow lands.
        Locking techs out tonight without a top-up path would brick every
        seeded tech on first commission write.
        """
        return (True, None)

    # ------------------------------------------------------------------
    # Booking financial events
    # ------------------------------------------------------------------
    def record_commission(self, *, booking, amount: Decimal) -> None:
        """Debit the tech's wallet for the platform commission on this booking.

        Called from ``bookings/services/orchestrator.py`` on the
        IN_PROGRESS → COMPLETED transition, alongside ``record_cash_collected``.
        Runs inside the orchestrator's ``transaction.atomic()`` block.

        Atomicity contract: any exception propagates and the surrounding
        transaction (which also commits the booking status flip) rolls back.
        The orchestrator chose this sequencing on purpose — if commission
        accounting fails, the COMPLETED transition is reverted too.
        """
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount))

        # Short-circuit if commission was already recorded for this booking.
        # OneToOne on JobCommission.booking is the database guarantee, but
        # a pre-check keeps the happy-path query count lower than catching
        # IntegrityError after the fact.
        if JobCommission.objects.filter(booking=booking).exists():
            return None

        commission_rate = PLATFORM_COMMISSION_RATE
        commission_amount = (amount * commission_rate).quantize(Decimal('0.01'))

        # Idempotency key for the ledger row. If the orchestrator retries,
        # ``record_transaction`` returns the existing WalletTransaction.
        idempotency_key = f'booking:{booking.id}:commission'

        wt = record_transaction(
            technician=booking.technician,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=-commission_amount,  # negative = debit (tech balance shrinks)
            transaction_reference_number=idempotency_key,
            memo=f'Commission on booking #{booking.id} (cash collected Rs.{amount})',
        )

        # Attach the JobCommission subtype row. Done after the ledger write
        # so the 1:1 FK target exists. If a race produced two parallel
        # commission attempts, the OneToOne on .booking catches the second
        # — we treat IntegrityError as "another thread won," return cleanly.
        try:
            JobCommission.objects.create(
                wallet_transaction=wt,
                booking=booking,
                payout_amount=amount,
                commission_rate=commission_rate,
                commission_amount=commission_amount,
                deduction_note=f'Platform commission {commission_rate:%}',
            )
        except IntegrityError:
            # Concurrent commission attempt already wrote the subtype row.
            # The ledger write was idempotent via transaction_reference_number,
            # so no double-debit occurred.
            pass

        return None

    def apply_inspection_fee_decision(
        self,
        *,
        booking,
        decision: Literal['accepted', 'declined'],
    ) -> None:
        """Inspection-fee bookkeeping — both branches are wallet no-ops.

        ``accepted`` → customer absorbed the Rs.500 into the final bill.
        Final cash flows through ``record_cash_collected`` later (also a
        wallet no-op — see class docstring). The wallet sees nothing now;
        the commission deduction on COMPLETED captures the platform's cut.

        ``declined`` → terminal status COMPLETED_INSPECTION_ONLY. Customer
        pays Rs.500 cash directly to the tech for the visit. Per the
        existing FinancePort contract, no commission is taken on this path
        (tech keeps the full Rs.500). Revisit post-viva if business policy
        changes.

        Hook retained for forensic completeness — Thursday's withdraw flow
        may want a JournalEntry here, but for tonight no wallet entry is
        written and the function returns immediately.
        """
        return None

    def apply_cancellation_charge(
        self,
        *,
        booking,
        actor: Literal['customer', 'tech'],
        phase: Literal['pre_accept', 'pre_arrival', 'post_arrival'],
    ) -> None:
        """Cancellation charges are cash exchanges; wallet is unaffected.

        * Customer-cancel pre_accept / pre_arrival: no fee owed (customer's
          cancel window closes at EN_ROUTE per UX rules; pre-arrival is
          actually "AWAITING/CONFIRMED" only, no fee).
        * Customer-cancel post_arrival: structurally impossible — customer
          declines the quote instead, which routes through
          ``apply_inspection_fee_decision('declined')``.
        * Tech-cancel any phase: reliability penalty deferred to v1.1.

        Any future tech-cancel-penalty implementation would write a
        ``REFUND_DEBIT`` or a new ``RELIABILITY_PENALTY_DEBIT`` row here.
        """
        return None

    def record_cash_collected(
        self,
        *,
        booking,
        amount: Decimal,
        method: str,
    ) -> None:
        """Cash to tech's pocket. Wallet is platform-tech only — no entry.

        The dashboard's ``cashCollectedToday`` metric (already wired) gives
        the tech visibility into cash earnings; the wallet screen shows
        their deposit balance separately. See feedback memory
        ``wallet-vs-metrics-separation``.

        Hook retained because the FinancePort signature requires it.
        """
        return None
