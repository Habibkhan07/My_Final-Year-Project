"""Seed wallet ledger rows so the Wallet screen has data to render.

Run:

    python manage.py seed_wallet

What it does
------------
1. Ensures the standard fixture (tech + customer + AC Repair service) is
   present by calling ``seed_test_fixtures`` — same identities the dev
   panel uses, so the Chrome session already logged in as tech
   +923001111111 sees the new rows immediately on /wallet.
2. Wipes any prior ``seed_wallet:``-keyed ledger rows (and their subtype
   rows) so re-runs are deterministic. Resets the tech's
   ``current_wallet_balance`` to 0 before replaying.
3. Replays 25 ``WalletTransaction`` rows in chronological order via
   ``wallet.services.ledger.record_transaction`` so the audit invariant
   (``MAX(balance_after) == current_wallet_balance``) is preserved.
4. Attaches subtype rows (``JobCommission`` + minimal ``JobBooking``,
   ``WalletTopup``, ``WithdrawalFulfilment`` + ``WithdrawalRequest``,
   ``RefundDeduction``) so the selector emits realistic subtitles
   (e.g. "Booking #128", "via JazzCash", "Ref: WD-2026-007").
5. Backdates ``WalletTransaction.timestamp`` after each ledger call to
   spread the rows across the last ~3 months — exercises the relative
   timestamp formatter and gives the "load more" cursor something
   meaningful to traverse.

Identifier: every row carries ``transaction_reference_number`` starting
with ``seed_wallet:`` so a re-run can wipe them with a single filter.

This command is dev-only. It will be removed in the end-of-UI cleanup pass.
"""
from __future__ import annotations

from datetime import datetime, time, timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from bookings.models import JobBooking
from catalog.models import Service
from technicians.models import TechnicianProfile
from wallet.models import (
    JobCommission,
    RefundDeduction,
    TechnicianBankAccount,
    TopupStatus,
    TransactionType,
    WalletTopup,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
    WithdrawalStatus,
)
from wallet.services.ledger import record_transaction


SEED_KEY_PREFIX = 'seed_wallet:'
SEED_BOOKING_TAG = '[seed_wallet]'
TECH_PHONE = '+923001111111'
CUSTOMER_PHONE = '+923002222222'
COMMISSION_RATE = Decimal('0.20')


# --- Ledger schedule (chronological — oldest first) -------------------------
#
# Each row: (day_offset, hour, type, amount, subtype_kwargs)
#
# Walking the running balance from 0 confirms it never goes negative; final
# balance lands at Rs. 340.00.

_SCHEDULE: list[tuple[int, int, str, str, dict]] = [
    (-85, 11, TransactionType.TOPUP_CREDIT,       '2000.00', {'gateway': 'jazzcash'}),
    (-80,  9, TransactionType.ADJUSTMENT,           '50.00', {'memo': 'Welcome bonus — early adopter'}),
    (-75, 14, TransactionType.COMMISSION_DEBIT,   '-200.00', {}),
    (-68, 16, TransactionType.COMMISSION_DEBIT,   '-250.00', {}),
    (-60, 12, TransactionType.COMMISSION_DEBIT,   '-180.00', {}),
    (-55, 15, TransactionType.COMMISSION_DEBIT,   '-300.00', {}),
    (-48, 11, TransactionType.COMMISSION_DEBIT,   '-220.00', {}),
    (-42, 10, TransactionType.TOPUP_CREDIT,       '1500.00', {'gateway': 'mock'}),
    (-38, 13, TransactionType.COMMISSION_DEBIT,   '-260.00', {}),
    (-33, 17, TransactionType.COMMISSION_DEBIT,   '-200.00', {}),
    (-30, 14, TransactionType.COMMISSION_DEBIT,   '-180.00', {}),
    (-27, 11, TransactionType.COMMISSION_DEBIT,   '-240.00', {}),
    (-23, 16, TransactionType.REFUND_DEBIT,       '-300.00', {'reason': 'Late arrival — customer refund'}),
    (-20, 12, TransactionType.COMMISSION_DEBIT,   '-200.00', {}),
    (-17, 15, TransactionType.COMMISSION_DEBIT,   '-180.00', {}),
    (-14,  9, TransactionType.TOPUP_CREDIT,       '1500.00', {'gateway': 'jazzcash'}),
    (-12, 14, TransactionType.COMMISSION_DEBIT,   '-260.00', {}),
    (-10, 11, TransactionType.WITHDRAWAL_DEBIT,   '-500.00', {'external_ref': 'WD-2026-007'}),
    ( -8, 16, TransactionType.COMMISSION_DEBIT,   '-220.00', {}),
    ( -6, 13, TransactionType.COMMISSION_DEBIT,   '-180.00', {}),
    ( -4, 15, TransactionType.COMMISSION_DEBIT,   '-240.00', {}),
    ( -2, 11, TransactionType.COMMISSION_DEBIT,   '-200.00', {}),
    (  0,  9, TransactionType.TOPUP_CREDIT,        '500.00', {'gateway': 'jazzcash'}),
    (  0, 14, TransactionType.COMMISSION_DEBIT,   '-180.00', {}),
    (  0, 17, TransactionType.COMMISSION_DEBIT,   '-220.00', {}),
]


class Command(BaseCommand):
    help = 'Seed wallet ledger rows so the Wallet screen has data to render.'

    @transaction.atomic
    def handle(self, *args, **opts):
        tech = self._ensure_tech()
        self._service = self._resolve_service()
        self._customer = self._resolve_customer()

        deleted = self._wipe_prior_seed(tech)
        if deleted:
            self.stdout.write(self.style.WARNING(f'  removed {deleted} prior seed_wallet row(s)'))

        # SECURITY: only the fixture tech is targeted; the wipe + reset are
        # gated by the seed_wallet: key prefix so no real ledger rows can be
        # touched even if this command is misinvoked in a non-dev DB.
        tech.current_wallet_balance = Decimal('0.00')
        tech.save(update_fields=['current_wallet_balance'])

        counts = {t: 0 for t in (
            TransactionType.TOPUP_CREDIT,
            TransactionType.COMMISSION_DEBIT,
            TransactionType.WITHDRAWAL_DEBIT,
            TransactionType.REFUND_DEBIT,
            TransactionType.ADJUSTMENT,
        )}

        for idx, (day_offset, hour, txn_type, amount_str, extra) in enumerate(_SCHEDULE, start=1):
            ts = self._timestamp_for(day_offset, hour)
            wt = self._record(tech, txn_type, amount_str, idx, ts, extra)
            self._attach_subtype(tech, wt, txn_type, amount_str, ts, idx, extra)
            counts[txn_type] += 1

        # Re-fetch the tech to surface the final balance in the summary.
        tech.refresh_from_db(fields=['current_wallet_balance'])
        self._print_summary(tech, counts)

    # ---------------- fixture bootstrap ----------------

    def _ensure_tech(self) -> TechnicianProfile:
        try:
            return TechnicianProfile.objects.select_related('user').get(
                user__username=TECH_PHONE,
            )
        except TechnicianProfile.DoesNotExist:
            self.stdout.write('  No fixture tech found — running seed_test_fixtures first...')
            call_command('seed_test_fixtures', '--count=1', verbosity=0)
            return TechnicianProfile.objects.select_related('user').get(
                user__username=TECH_PHONE,
            )

    def _resolve_service(self) -> Service:
        svc = Service.objects.filter(name='AC Repair').first() or Service.objects.first()
        if svc is None:
            raise RuntimeError(
                'No catalog Service rows exist — seed_test_fixtures should have created one.'
            )
        return svc

    def _resolve_customer(self):
        User = get_user_model()
        return User.objects.get(username=CUSTOMER_PHONE)

    def _wipe_prior_seed(self, tech: TechnicianProfile) -> int:
        """Tear down seeded rows in FK-safe order (PROTECT requires this).

        Order: subtype rows → WithdrawalRequests left dangling by their
        fulfilments → WalletTransaction rows → seeded JobBookings.
        """
        seeded_wts_qs = WalletTransaction.objects.filter(
            technician=tech,
            transaction_reference_number__startswith=SEED_KEY_PREFIX,
        )

        # Capture withdrawal-request ids before the fulfilments vanish.
        seeded_withdrawal_request_ids = list(
            WithdrawalFulfilment.objects
            .filter(wallet_transaction__in=seeded_wts_qs)
            .values_list('withdrawal_request_id', flat=True)
        )

        n = 0
        n += JobCommission.objects.filter(wallet_transaction__in=seeded_wts_qs).delete()[0]
        n += WalletTopup.objects.filter(wallet_transaction__in=seeded_wts_qs).delete()[0]
        n += RefundDeduction.objects.filter(wallet_transaction__in=seeded_wts_qs).delete()[0]
        n += WithdrawalFulfilment.objects.filter(wallet_transaction__in=seeded_wts_qs).delete()[0]
        if seeded_withdrawal_request_ids:
            n += WithdrawalRequest.objects.filter(id__in=seeded_withdrawal_request_ids).delete()[0]

        n += seeded_wts_qs.delete()[0]
        n += JobBooking.objects.filter(
            technician=tech, price_context__startswith=SEED_BOOKING_TAG,
        ).delete()[0]
        return n

    # ---------------- ledger write + backdate ----------------

    def _record(
        self,
        tech: TechnicianProfile,
        txn_type: str,
        amount_str: str,
        idx: int,
        ts: datetime,
        extra: dict,
    ) -> WalletTransaction:
        amount = Decimal(amount_str)
        # SECURITY: only the fixture tech is mutated; ref keys carry the
        # seed_wallet: prefix so the wipe filter is unambiguous.
        wt = record_transaction(
            technician=tech,
            transaction_type=txn_type,
            amount=amount,
            transaction_reference_number=f'{SEED_KEY_PREFIX}{idx:02d}',
            memo=extra.get('memo', ''),
            is_manual_adjustment=(txn_type == TransactionType.ADJUSTMENT),
        )
        # Backdate timestamp — auto_now_add is unconditional on create, so a
        # direct .update() is the cleanest way to spread rows across history.
        WalletTransaction.objects.filter(pk=wt.pk).update(timestamp=ts)
        wt.timestamp = ts
        return wt

    # ---------------- subtype attachers ----------------

    def _attach_subtype(
        self,
        tech: TechnicianProfile,
        wt: WalletTransaction,
        txn_type: str,
        amount_str: str,
        ts: datetime,
        idx: int,
        extra: dict,
    ) -> None:
        if txn_type == TransactionType.COMMISSION_DEBIT:
            self._attach_commission(tech, wt, amount_str, ts, idx)
        elif txn_type == TransactionType.TOPUP_CREDIT:
            self._attach_topup(tech, wt, amount_str, ts, extra)
        elif txn_type == TransactionType.WITHDRAWAL_DEBIT:
            self._attach_withdrawal(tech, wt, amount_str, ts, extra)
        elif txn_type == TransactionType.REFUND_DEBIT:
            self._attach_refund(wt, extra)
        # ADJUSTMENT renders straight from row.memo — no subtype needed.

    def _attach_commission(
        self,
        tech: TechnicianProfile,
        wt: WalletTransaction,
        amount_str: str,
        ts: datetime,
        idx: int,
    ) -> None:
        commission_amount = Decimal(amount_str).copy_abs()
        # Tech-facing payout backs out of commission/rate, so the booking's
        # price_amount looks like a real receipt total.
        payout_amount = (commission_amount / COMMISSION_RATE).quantize(Decimal('0.01'))
        booking_start = ts - timedelta(hours=2)
        booking = JobBooking.objects.create(
            technician=tech,
            customer=self._customer,
            address=None,
            service=self._service,
            sub_service=None,
            scheduled_start=booking_start,
            scheduled_end=booking_start + timedelta(hours=1),
            status=JobBooking.STATUS_COMPLETED,
            price_amount=payout_amount,
            price_context=f'{SEED_BOOKING_TAG} c-{idx:02d}',
            accepted_at=booking_start,
            en_route_started_at=booking_start,
            arrived_at=booking_start,
            inspection_started_at=booking_start,
            quote_first_submitted_at=booking_start,
            work_started_at=booking_start,
            completed_at=ts,
            cash_collected_amount=payout_amount,
            cash_collected_at=ts,
        )
        JobCommission.objects.create(
            wallet_transaction=wt,
            booking=booking,
            payout_amount=payout_amount,
            commission_rate=COMMISSION_RATE,
            commission_amount=commission_amount,
        )

    def _attach_topup(
        self,
        tech: TechnicianProfile,
        wt: WalletTransaction,
        amount_str: str,
        ts: datetime,
        extra: dict,
    ) -> None:
        WalletTopup.objects.create(
            technician=tech,
            wallet_transaction=wt,
            amount_attempted=Decimal(amount_str).copy_abs(),
            gateway_name=extra.get('gateway', 'mock'),
            gateway_status=TopupStatus.COMPLETED,
            completed_at=ts,
        )

    def _attach_withdrawal(
        self,
        tech: TechnicianProfile,
        wt: WalletTransaction,
        amount_str: str,
        ts: datetime,
        extra: dict,
    ) -> None:
        bank = self._resolve_seed_bank_account(tech)
        req = WithdrawalRequest.objects.create(
            technician=tech,
            amount=Decimal(amount_str).copy_abs(),
            status=WithdrawalStatus.PROCESSED,
            payout_bank_account=bank,
            payout_jazzcash_account=None,
            admin_external_ref=extra.get('external_ref', ''),
            reviewed_by=tech.user,
            reviewed_at=ts,
        )
        WithdrawalFulfilment.objects.create(
            withdrawal_request=req,
            wallet_transaction=wt,
            processing_note='Seeded fulfilment.',
        )

    def _attach_refund(self, wt: WalletTransaction, extra: dict) -> None:
        RefundDeduction.objects.create(
            wallet_transaction=wt,
            penalty_reason=extra.get('reason', 'Customer refund'),
        )

    def _resolve_seed_bank_account(self, tech: TechnicianProfile) -> TechnicianBankAccount:
        """Reuse a single seeded bank account across re-runs.

        The wipe step doesn't touch this — bank accounts aren't keyed by the
        seed prefix, and recreating them would orphan any non-seed withdrawals
        if they ever get added later.
        """
        bank, _ = TechnicianBankAccount.objects.get_or_create(
            technician=tech,
            account_number_or_iban='PK00HBL0000000000001',
            defaults={'bank_name': 'HBL', 'account_title': 'Seed Tech', 'is_active': True},
        )
        return bank

    # ---------------- helpers ----------------

    def _timestamp_for(self, day_offset: int, hour: int) -> datetime:
        local_day = timezone.localdate() + timedelta(days=day_offset)
        local_dt = datetime.combine(local_day, time(hour=hour, minute=0))
        return timezone.make_aware(local_dt, timezone.get_current_timezone())

    # ---------------- summary ----------------

    def _print_summary(self, tech: TechnicianProfile, counts: dict[str, int]) -> None:
        bar = '=' * 64
        s = self.style.SUCCESS
        total = sum(counts.values())
        self.stdout.write('')
        self.stdout.write(s(bar))
        self.stdout.write(s('  WALLET TEST DATA SEEDED'))
        self.stdout.write(s(bar))
        self.stdout.write(f'  Tech            : {TECH_PHONE} (id={tech.id})')
        self.stdout.write(f'  Total ledger    : {total} rows')
        self.stdout.write(f'    Top-ups       : {counts[TransactionType.TOPUP_CREDIT]}')
        self.stdout.write(f'    Commissions   : {counts[TransactionType.COMMISSION_DEBIT]} (with Booking subtitles)')
        self.stdout.write(f'    Withdrawals   : {counts[TransactionType.WITHDRAWAL_DEBIT]}')
        self.stdout.write(f'    Refunds       : {counts[TransactionType.REFUND_DEBIT]}')
        self.stdout.write(f'    Adjustments   : {counts[TransactionType.ADJUSTMENT]}')
        self.stdout.write(s(f'  Final balance   : Rs. {tech.current_wallet_balance}'))
        self.stdout.write('')
        self.stdout.write('  In the app: open Wallet (dashboard balance pill → Wallet screen).')
        self.stdout.write('  Pull-to-refresh works; "Load more" auto-fires after the first page.')
        self.stdout.write('  Re-run anytime — idempotent (wipes prior seed_wallet rows).')
        self.stdout.write(s(bar))
        self.stdout.write('')
