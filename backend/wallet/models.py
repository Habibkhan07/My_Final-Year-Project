"""Wallet domain models — tech-facing virtual wallet ledger + payout rails.

Schema follows the thesis Figure 3.15 financial-and-support diagram with three
implementation-grade deviations (called out where they occur):

1. ``WalletTopup.wallet_transaction`` is NULLABLE (relaxed 1:0..1 vs thesis 1:1)
   so an in-flight top-up can persist its gateway state without contaminating
   the ledger with a placeholder zero-amount row.
2. ``WalletTransaction.balance_after`` is added (not in thesis) as a forensic
   audit invariant: ``MAX(balance_after) WHERE technician=X`` must equal
   ``TechnicianProfile.current_wallet_balance``.
3. ``WithdrawalRequest`` uses two nullable FKs (bank / jazzcash) + a
   ``CheckConstraint`` for "exactly one" rather than a generic relation —
   keeps SQL queryable without ContentType joins.

All ledger writes funnel through ``wallet.services.ledger.record_transaction``,
which enforces ``transaction.atomic() + select_for_update()`` on the technician
row. Models themselves contain no business logic.
"""
from django.conf import settings
from django.db import models
from django.db.models import Q

from technicians.models import TechnicianProfile


# --- Ledger ------------------------------------------------------------------

class TransactionType(models.TextChoices):
    """Closed enum of every kind of wallet entry the platform writes.

    The wallet is the tech's **platform-side deposit** — NOT a record of
    customer-to-tech cash. Per the project rules: "Customer ↔ Technician =
    CASH ONLY"; "Wallet Lockout: balance < threshold → blocked until
    top-up". So the only things that touch the wallet are platform-tech
    money movements:

    * Top-up — tech adds funds to maintain their deposit (JazzCash).
    * Commission — platform takes its cut on completed jobs.
    * Withdrawal — tech withdraws excess deposit (admin-processed).
    * Refund — admin debits tech's deposit to fund a customer refund.
    * Adjustment — admin manual ledger correction.

    Cash collected from customers, inspection fees, and cancellation
    charges are CASH exchanges and never write to the wallet. The
    dashboard's metrics row owns visibility of cash earnings (see
    feedback memory: wallet-vs-metrics-separation).

    Adding a new variant later is a no-op DB migration (choices live in
    Python). The sign of ``WalletTransaction.amount`` is documentation
    via the ``_DEBIT``/``_CREDIT`` suffix; the ledger service guarantees
    correct sign at write time.
    """
    COMMISSION_DEBIT = 'COMMISSION_DEBIT', 'Commission debit'
    TOPUP_CREDIT = 'TOPUP_CREDIT', 'Top-up credit'
    WITHDRAWAL_DEBIT = 'WITHDRAWAL_DEBIT', 'Withdrawal debit'
    REFUND_DEBIT = 'REFUND_DEBIT', 'Refund debit'
    ADJUSTMENT = 'ADJUSTMENT', 'Manual adjustment'


class WalletTransaction(models.Model):
    """Generic ledger row. Specialized 1:1 subtype models hang off this.

    A ``WalletTransaction`` represents a single signed amount applied to a
    technician's wallet. The accompanying subtype row (``JobCommission``,
    ``WalletTopup``, ``RefundDeduction``, etc.) holds kind-specific fields
    so this table stays narrow and forensically queryable.

    Idempotency is keyed on ``transaction_reference_number`` when the caller
    supplies one (e.g. ``f'booking:{id}:commission'``). The ledger service
    uses a partial-unique index here so a retry safely returns the existing
    row instead of double-writing.
    """
    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.PROTECT,
        related_name='wallet_transactions',
    )
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Signed. Positive = credit (tech earns), negative = debit.',
    )
    transaction_type = models.CharField(
        max_length=40,
        choices=TransactionType.choices,
    )
    balance_after = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='TechnicianProfile.current_wallet_balance snapshot AFTER this row was applied.',
    )
    gateway_reference = models.CharField(
        max_length=128,
        blank=True,
        default='',
        help_text='Opaque gateway transaction id (e.g. JazzCash ppmpf-xxx). Empty for non-gateway rows.',
    )
    transaction_reference_number = models.CharField(
        max_length=128,
        blank=True,
        default='',
        help_text='Internal idempotency key. Empty allowed; uniqueness enforced via partial index.',
    )
    is_manual_adjustment = models.BooleanField(
        default=False,
        help_text='True for admin-initiated ADJUSTMENT rows. Default False for system-written entries.',
    )
    memo = models.CharField(max_length=255, blank=True, default='')
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        indexes = [
            models.Index(fields=['technician', '-timestamp']),
        ]
        constraints = [
            # Partial unique on transaction_reference_number where set. Allows
            # multiple rows with '' (non-idempotent writes like ADJUSTMENT)
            # while preventing duplicate inserts for the same key.
            models.UniqueConstraint(
                fields=['transaction_reference_number'],
                condition=~Q(transaction_reference_number=''),
                name='wallet_walletxn_unique_txn_ref',
            ),
        ]

    def __str__(self) -> str:
        sign = '+' if self.amount >= 0 else ''
        return f'{self.technician_id} {sign}{self.amount} {self.transaction_type} @ {self.timestamp:%Y-%m-%d %H:%M}'


# --- Subtypes (1:1 or 1:0..1 with WalletTransaction) -------------------------

class TopupStatus(models.TextChoices):
    """Lifecycle of a top-up attempt.

    PENDING        Created the moment the tech taps "Top up Rs.X". No gateway call yet.
    REDIRECTED     ``initiate_topup`` returned a redirect URL; tech sent to gateway.
    COMPLETED      Gateway callback verified success. WalletTransaction now exists.
    FAILED         Gateway callback verified failure. No WalletTransaction.
    EXPIRED        Tech never returned from gateway flow within TTL.
    ABANDONED      Tech navigated away or cancelled in gateway UI.
    """
    PENDING = 'PENDING', 'Pending'
    REDIRECTED = 'REDIRECTED', 'Redirected to gateway'
    COMPLETED = 'COMPLETED', 'Completed'
    FAILED = 'FAILED', 'Failed'
    EXPIRED = 'EXPIRED', 'Expired'
    ABANDONED = 'ABANDONED', 'Abandoned'


class WalletTopup(models.Model):
    """A single top-up attempt — gateway in-flight state + final outcome.

    DEVIATION FROM THESIS: ``wallet_transaction`` is nullable. The thesis
    diagram shows ``WalletTopup 1—1 WalletTransaction`` strict, but that
    forces us to either (a) write a placeholder zero-amount transaction
    on every tap (contaminates the ledger) or (b) have no place to persist
    in-flight state between redirect and callback. The relaxation: a
    WalletTopup exists immediately on tap; the WalletTransaction is only
    created once ``gateway_status`` transitions to COMPLETED.
    """
    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.PROTECT,
        related_name='wallet_topups',
    )
    wallet_transaction = models.OneToOneField(
        WalletTransaction,
        on_delete=models.PROTECT,
        related_name='topup',
        null=True,
        blank=True,
    )
    amount_attempted = models.DecimalField(max_digits=10, decimal_places=2)
    gateway_name = models.CharField(
        max_length=32,
        help_text='Registry key in settings.PAYMENT_GATEWAYS (e.g. "jazzcash", "mock").',
    )
    gateway_status = models.CharField(
        max_length=20,
        choices=TopupStatus.choices,
        default=TopupStatus.PENDING,
    )
    gateway_session_id = models.CharField(max_length=128, blank=True, default='')
    gateway_redirect_url = models.URLField(blank=True, default='')
    gateway_callback_payload = models.JSONField(null=True, blank=True)
    initiated_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['technician', '-initiated_at']),
            models.Index(fields=['gateway_status']),
        ]

    def __str__(self) -> str:
        return f'Topup {self.id} tech={self.technician_id} {self.amount_attempted} {self.gateway_status}'


class JobCommission(models.Model):
    """Per-booking commission record. Created on IN_PROGRESS → COMPLETED.

    The 1:1 link to ``JobBooking`` is the idempotency guarantee — the booking
    can only have one commission. Re-calls from the orchestrator (e.g. retry)
    hit the OneToOne and short-circuit.
    """
    wallet_transaction = models.OneToOneField(
        WalletTransaction,
        on_delete=models.PROTECT,
        related_name='job_commission',
    )
    booking = models.OneToOneField(
        'bookings.JobBooking',
        on_delete=models.PROTECT,
        related_name='commission',
    )
    payout_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Tech-facing revenue this booking. Commission_amount = payout_amount * commission_rate.',
    )
    commission_rate = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        help_text='Snapshot of PLATFORM_COMMISSION_RATE at the moment of recording. Decoupled from globals.',
    )
    commission_amount = models.DecimalField(max_digits=10, decimal_places=2)
    deduction_note = models.CharField(max_length=255, blank=True, default='')
    recorded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f'Commission booking={self.booking_id} {self.commission_amount} (rate={self.commission_rate})'


class RefundDeduction(models.Model):
    """Charge debited from the tech's wallet because admin issued a refund.

    Schema lands tonight; no code creates rows until the dispute/refund
    admin flow lands on chatbot/dispute day. Empty table is harmless.
    """
    wallet_transaction = models.OneToOneField(
        WalletTransaction,
        on_delete=models.PROTECT,
        related_name='refund_deduction',
    )
    penalty_reason = models.CharField(max_length=255)

    def __str__(self) -> str:
        return f'RefundDeduction wt={self.wallet_transaction_id} ({self.penalty_reason})'


# --- Payout accounts (two distinct tables per thesis) ------------------------

class TechnicianBankAccount(models.Model):
    """Bank-transfer payout target for withdrawals.

    Tech can have multiple; admin processes withdrawals against whichever
    the tech selected on the WithdrawalRequest. Soft-deleted via is_active=False
    to preserve historical link integrity.
    """
    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.PROTECT,
        related_name='bank_accounts',
    )
    bank_name = models.CharField(max_length=128)
    account_title = models.CharField(max_length=128)
    account_number_or_iban = models.CharField(max_length=64)
    is_active = models.BooleanField(default=True)
    captured_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=['technician', 'is_active'])]

    def __str__(self) -> str:
        return f'{self.bank_name} ••{self.account_number_or_iban[-4:]} (tech={self.technician_id})'


class TechnicianJazzCashAccount(models.Model):
    """JazzCash mobile-wallet payout target for withdrawals.

    On a tech's first successful JazzCash top-up the gateway adapter
    auto-creates one of these with the MSISDN it transacted against,
    so withdrawals to "same JazzCash you topped up from" are zero-touch.
    """
    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.PROTECT,
        related_name='jazzcash_accounts',
    )
    account_title = models.CharField(max_length=128)
    mobile_number = models.CharField(
        max_length=20,
        help_text='Pakistan MSISDN. Format normalisation belongs at the serializer, not the model.',
    )
    is_active = models.BooleanField(default=True)
    captured_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=['technician', 'is_active'])]

    def __str__(self) -> str:
        return f'JazzCash {self.mobile_number} (tech={self.technician_id})'


# --- Withdrawal lifecycle (request + admin fulfilment split per thesis) ------

class WithdrawalStatus(models.TextChoices):
    PENDING_REVIEW = 'PENDING_REVIEW', 'Pending review'
    APPROVED = 'APPROVED', 'Approved (queued for processing)'
    REJECTED = 'REJECTED', 'Rejected'
    PROCESSED = 'PROCESSED', 'Processed (paid out)'


class WithdrawalRequest(models.Model):
    """Tech-initiated withdrawal request. Admin processes manually.

    Exactly one of ``payout_bank_account`` / ``payout_jazzcash_account`` is
    non-null, enforced by a CheckConstraint. The tech picks the target on
    submission; admin sees both the amount and the destination in admin.
    """
    technician = models.ForeignKey(
        TechnicianProfile,
        on_delete=models.PROTECT,
        related_name='withdrawal_requests',
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(
        max_length=20,
        choices=WithdrawalStatus.choices,
        default=WithdrawalStatus.PENDING_REVIEW,
    )
    payout_bank_account = models.ForeignKey(
        TechnicianBankAccount,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='withdrawal_requests',
    )
    payout_jazzcash_account = models.ForeignKey(
        TechnicianJazzCashAccount,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='withdrawal_requests',
    )
    admin_external_ref = models.CharField(
        max_length=128,
        blank=True,
        default='',
        help_text='Admin-entered reference from the out-of-band payout (JazzCash merchant txn id, bank wire ref, etc.).',
    )
    admin_notes = models.TextField(blank=True, default='')
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_withdrawals',
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    requested_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['technician', '-requested_at']),
            models.Index(fields=['status']),
        ]
        constraints = [
            models.CheckConstraint(
                # XOR: exactly one payout account must be non-null.
                # Django 6 renamed ``check=`` → ``condition=`` on CheckConstraint.
                condition=(
                    Q(payout_bank_account__isnull=False, payout_jazzcash_account__isnull=True)
                    | Q(payout_bank_account__isnull=True, payout_jazzcash_account__isnull=False)
                ),
                name='wallet_withdrawalrequest_exactly_one_payout_account',
            ),
        ]

    def __str__(self) -> str:
        return f'Withdrawal #{self.id} tech={self.technician_id} {self.amount} {self.status}'


class WithdrawalFulfilment(models.Model):
    """Admin-recorded fulfilment of a withdrawal request.

    Created when admin clicks "Approve & Process" in Django Admin. Links to
    the ``WalletTransaction`` (WITHDRAWAL_DEBIT row) that finalized the debit
    from the tech's wallet. The split from ``WithdrawalRequest`` matches the
    thesis schema: request = what tech submitted; fulfilment = what admin did.
    """
    withdrawal_request = models.OneToOneField(
        WithdrawalRequest,
        on_delete=models.PROTECT,
        related_name='fulfilment',
    )
    wallet_transaction = models.OneToOneField(
        WalletTransaction,
        on_delete=models.PROTECT,
        related_name='withdrawal_fulfilment',
    )
    processing_note = models.TextField(blank=True, default='')
    fulfilled_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f'WithdrawalFulfilment for request={self.withdrawal_request_id}'
