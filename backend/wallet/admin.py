"""Django Admin for the wallet domain.

Tonight: all admins are read-only views so the supervisor can observe the
ledger forensically without anyone fudging rows through the UI. Direct
admin creation of ``WalletTransaction`` would bypass
``ledger.record_transaction`` and break the ``balance_after`` audit
invariant.

Thursday: ``WithdrawalRequestAdmin`` gains an ``approve_and_process``
admin action (custom button) that internally calls a service which goes
through ``record_transaction`` to write the WITHDRAWAL_DEBIT row + the
WithdrawalFulfilment side. That action is the only sanctioned write
path from admin.
"""
from __future__ import annotations

from django.contrib import admin

from wallet.models import (
    JobCommission,
    RefundDeduction,
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    WalletTopup,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
)


class _ReadOnlyAdmin(admin.ModelAdmin):
    """Mixin: every field becomes read-only in the change/add view.

    Tonight we never want admin to write through the form-side write path
    on these tables; the ledger service is the only sanctioned write site.
    """
    def has_add_permission(self, request) -> bool:
        return False

    def has_delete_permission(self, request, obj=None) -> bool:
        return False

    def has_change_permission(self, request, obj=None) -> bool:
        # Allow VIEW (browsing), but no edit. ``view`` permission is what
        # Django uses for the read-only detail page.
        return True

    def get_readonly_fields(self, request, obj=None):
        return [f.name for f in self.model._meta.fields]


# --- Ledger -------------------------------------------------------------------

@admin.register(WalletTransaction)
class WalletTransactionAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'technician',
        'transaction_type',
        'amount',
        'balance_after',
        'is_manual_adjustment',
        'gateway_reference',
        'transaction_reference_number',
        'timestamp',
    )
    list_filter = ('transaction_type', 'is_manual_adjustment')
    search_fields = (
        'technician__user__username',
        'technician__user__first_name',
        'gateway_reference',
        'transaction_reference_number',
        'memo',
    )
    date_hierarchy = 'timestamp'
    ordering = ('-timestamp',)


@admin.register(JobCommission)
class JobCommissionAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'booking',
        'payout_amount',
        'commission_rate',
        'commission_amount',
        'recorded_at',
    )
    search_fields = ('booking__id', 'deduction_note')
    date_hierarchy = 'recorded_at'
    ordering = ('-recorded_at',)


@admin.register(RefundDeduction)
class RefundDeductionAdmin(_ReadOnlyAdmin):
    list_display = ('id', 'wallet_transaction', 'penalty_reason')


# --- Top-ups (Thursday-active, viewable tonight) ------------------------------

@admin.register(WalletTopup)
class WalletTopupAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'technician',
        'amount_attempted',
        'gateway_name',
        'gateway_status',
        'wallet_transaction',
        'initiated_at',
        'completed_at',
    )
    list_filter = ('gateway_status', 'gateway_name')
    search_fields = (
        'technician__user__username',
        'gateway_session_id',
    )
    date_hierarchy = 'initiated_at'
    ordering = ('-initiated_at',)


# --- Payout accounts ----------------------------------------------------------

@admin.register(TechnicianBankAccount)
class TechnicianBankAccountAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'technician',
        'bank_name',
        'account_title',
        'account_number_or_iban',
        'is_active',
        'captured_at',
    )
    list_filter = ('bank_name', 'is_active')
    search_fields = (
        'technician__user__username',
        'account_title',
        'account_number_or_iban',
    )


@admin.register(TechnicianJazzCashAccount)
class TechnicianJazzCashAccountAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'technician',
        'account_title',
        'mobile_number',
        'is_active',
        'captured_at',
    )
    list_filter = ('is_active',)
    search_fields = (
        'technician__user__username',
        'mobile_number',
    )


# --- Withdrawals (Thursday-active, viewable tonight) --------------------------

@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(_ReadOnlyAdmin):
    """Tonight: read-only view. Thursday: ``approve_and_process`` action."""
    list_display = (
        'id',
        'technician',
        'amount',
        'status',
        'payout_bank_account',
        'payout_jazzcash_account',
        'admin_external_ref',
        'reviewed_by',
        'requested_at',
        'reviewed_at',
    )
    list_filter = ('status',)
    search_fields = (
        'technician__user__username',
        'admin_external_ref',
        'admin_notes',
    )
    date_hierarchy = 'requested_at'
    ordering = ('-requested_at',)


@admin.register(WithdrawalFulfilment)
class WithdrawalFulfilmentAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'withdrawal_request',
        'wallet_transaction',
        'fulfilled_at',
    )
    date_hierarchy = 'fulfilled_at'
    ordering = ('-fulfilled_at',)
