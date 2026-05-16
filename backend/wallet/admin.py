"""Django Admin for the wallet domain.

Two distinct surfaces here:

* **Ledger-side** (``WalletTransaction``, ``JobCommission``,
  ``RefundDeduction``, ``WalletTopup``) — strictly read-only. Every
  write must flow through ``wallet.services.ledger.record_transaction``
  so the ``balance_after`` invariant and the lockout signal stay
  intact. Admin views the rows; never edits.
* **Withdrawal lifecycle** (``WithdrawalRequest``) — gains two custom
  actions: **Approve & process** (writes WITHDRAWAL_DEBIT + creates
  ``WithdrawalFulfilment`` atomically via
  ``approve_and_process_withdrawal``) and **Reject** (no ledger
  movement, captures an admin note). Both actions render an
  intermediate confirmation page so the admin can paste the external
  bank reference before committing the debit.

PII (payout-account numbers) is shown only on the detail page; the
list view masks all account numbers / MSISDNs to keep queue
screenshots shareable.
"""
from __future__ import annotations

from decimal import Decimal
from django import forms
import logging

from django.contrib import admin, messages
from django.db import IntegrityError
from django.shortcuts import redirect, render
from django.urls import path, reverse
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

_logger = logging.getLogger(__name__)

from core.common.admin_permissions import EngineerOnlyAdminMixin
from core.common.admin_ui import money_rs, pill, truncate
from wallet.exceptions import InsufficientFundsError
from wallet.models import (
    JobCommission,
    RefundDeduction,
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    TopupStatus,
    TransactionType,
    WalletTopup,
    WalletTransaction,
    WithdrawalFulfilment,
    WithdrawalRequest,
    WithdrawalStatus,
)
from wallet.services.withdrawal_fulfilment_service import (
    WithdrawalNotPending,
    approve_and_process_withdrawal,
    reject_withdrawal,
)


# ---------------------------------------------------------------------------
# Shared base + tone tables
# ---------------------------------------------------------------------------


_FINANCE_ADMIN_GROUP = "finance_admin"


def _is_finance_admin(user) -> bool:
    """True for active superusers OR active staff in the finance_admin group.

    Mirrors ``disputes.admin._is_finance_admin``. Centralised here so any
    future wallet PII surface can reuse the same gate.
    """
    if not user.is_active or not user.is_staff:
        return False
    if user.is_superuser:
        return True
    return user.groups.filter(name=_FINANCE_ADMIN_GROUP).exists()


class _ReadOnlyAdmin(admin.ModelAdmin):
    """Every field read-only; add / delete disabled.

    The ledger service is the only sanctioned writer for these rows.
    Admin views the audit trail forensically — never mutates.
    """

    def has_add_permission(self, request) -> bool:
        return False

    def has_delete_permission(self, request, obj=None) -> bool:
        return False

    def has_change_permission(self, request, obj=None) -> bool:
        return True

    def get_readonly_fields(self, request, obj=None):
        return [f.name for f in self.model._meta.fields]


class _FinanceAdminGatedReadOnly(_ReadOnlyAdmin):
    """Read-only admin gated to the ``finance_admin`` group.

    Used for payout-account models (bank + JazzCash) and the withdrawal
    request — anything that exposes customer/tech account PII. Staff
    outside the group cannot see the model in the admin index at all.
    """

    def has_module_permission(self, request):
        return _is_finance_admin(request.user)

    def has_view_permission(self, request, obj=None):
        return _is_finance_admin(request.user)


_TXN_TONES: dict[str, str] = {
    TransactionType.TOPUP_CREDIT: 'positive',
    TransactionType.COMMISSION_DEBIT: 'warning',
    TransactionType.WITHDRAWAL_DEBIT: 'info',
    TransactionType.REFUND_DEBIT: 'negative',
    TransactionType.ADJUSTMENT: 'neutral',
}

_TOPUP_TONES: dict[str, str] = {
    TopupStatus.PENDING: 'neutral',
    TopupStatus.REDIRECTED: 'info',
    TopupStatus.COMPLETED: 'positive',
    TopupStatus.FAILED: 'negative',
    TopupStatus.EXPIRED: 'neutral',
    TopupStatus.ABANDONED: 'neutral',
}

class WithdrawalFulfilmentInline(admin.TabularInline):
    """Read-only inline on the WithdrawalRequest detail page.

    Replaces the removed standalone ``WithdrawalFulfilmentAdmin``. Shows
    the 1:1 fulfilment record (admin's external reference + the ledger
    row that landed the WITHDRAWAL_DEBIT) directly on the request page.
    """

    from wallet.models import WithdrawalFulfilment as _WF
    model = _WF
    extra = 0
    can_delete = False
    fields = ('wallet_transaction_link', 'processing_note', 'fulfilled_at')
    readonly_fields = fields

    def has_add_permission(self, request, obj=None):
        return False

    @admin.display(description='Ledger row')
    def wallet_transaction_link(self, obj):
        """Render the ledger row's key fields inline.

        ``WalletTransaction`` has no standalone admin — its only
        surface is the WalletLedgerInline on the technician detail
        page. Linking here would 404, so we surface the row info
        directly instead.
        """
        if not obj.wallet_transaction_id:
            return '—'
        wt = obj.wallet_transaction
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-size:12px">'
            '#{} · {} · {} · balance after {}'
            '</span>',
            wt.id,
            wt.get_transaction_type_display(),
            money_rs(wt.amount),
            money_rs(wt.balance_after),
        )


_WITHDRAWAL_TONES: dict[str, str] = {
    WithdrawalStatus.PENDING_REVIEW: 'warning',
    WithdrawalStatus.APPROVED: 'info',
    WithdrawalStatus.PROCESSED: 'positive',
    WithdrawalStatus.REJECTED: 'negative',
}


# ---------------------------------------------------------------------------
# Ledger
# ---------------------------------------------------------------------------


# Wallet ledger — registered under finance gating so the finance
# dashboard tiles can deep-link to filtered changelist views (commission
# this month, this year, etc.). Supervisor / engineer don't see it in
# the sidebar; the tech-scoped WalletLedgerInline on the technician
# detail page still serves the per-tech audit need.
@admin.register(WalletTransaction)
class WalletTransactionAdmin(_FinanceAdminGatedReadOnly):
    list_display = (
        'timestamp',
        'tech_link',
        'type_pill',
        'amount_label',
        'balance_label',
        'manual_flag',
        'gateway_reference',
        'memo_short',
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
    list_per_page = 40
    list_select_related = ('technician', 'technician__user')

    @admin.display(description='Tech', ordering='technician__user__username')
    def tech_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Type', ordering='transaction_type')
    def type_pill(self, obj):
        return pill(
            obj.get_transaction_type_display(),
            _TXN_TONES.get(obj.transaction_type, 'neutral'),
        )

    @admin.display(description='Amount', ordering='amount')
    def amount_label(self, obj):
        color = '#166534' if obj.amount >= 0 else '#991b1b'
        sign = '+' if obj.amount >= 0 else ''
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600;color:{}">{}{}</span>',
            color, sign, money_rs(obj.amount),
        )

    @admin.display(description='Balance after', ordering='balance_after')
    def balance_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace">{}</span>',
            money_rs(obj.balance_after),
        )

    @admin.display(description='Manual', boolean=True, ordering='is_manual_adjustment')
    def manual_flag(self, obj):
        return obj.is_manual_adjustment

    @admin.display(description='Memo')
    def memo_short(self, obj):
        return truncate(obj.memo, 40)


# JobCommissionAdmin standalone unregistered — 1:1 with JobBooking,
# reachable via the booking detail page (commission summary appears in
# the booking change view fieldsets if needed). Engineer-only before.
class JobCommissionAdmin(EngineerOnlyAdminMixin, _ReadOnlyAdmin):
    list_display = (
        'id',
        'recorded_at',
        'booking_link',
        'payout_label',
        'rate_label',
        'commission_label',
    )
    search_fields = ('booking__id', 'deduction_note')
    date_hierarchy = 'recorded_at'
    ordering = ('-recorded_at',)
    list_per_page = 40
    list_select_related = ('booking', 'wallet_transaction')

    @admin.display(description='Booking', ordering='booking_id')
    def booking_link(self, obj):
        url = reverse('admin:bookings_jobbooking_change', args=[obj.booking_id])
        return format_html('<a href="{}">#{}</a>', url, obj.booking_id)

    @admin.display(description='Payout', ordering='payout_amount')
    def payout_label(self, obj):
        return money_rs(obj.payout_amount)

    @admin.display(description='Rate')
    def rate_label(self, obj):
        return f'{obj.commission_rate * 100:.0f}%'

    @admin.display(description='Commission', ordering='commission_amount')
    def commission_label(self, obj):
        return format_html(
            '<span style="color:#991b1b;font-weight:600">{}</span>',
            money_rs(obj.commission_amount),
        )


# RefundDeductionAdmin standalone unregistered — 1:1 with WalletTransaction
# and visible inline alongside the dispute resolution audit trail.
class RefundDeductionAdmin(EngineerOnlyAdminMixin, _ReadOnlyAdmin):
    list_display = ('id', 'wallet_transaction', 'penalty_reason')
    search_fields = ('penalty_reason', 'wallet_transaction__technician__user__username')


# ---------------------------------------------------------------------------
# Top-ups
# ---------------------------------------------------------------------------


# WalletTopupAdmin standalone unregistered — purely forensic; if a top-up
# fails or gets stuck the engineer queries via shell or watches the wallet
# REST endpoints. Pre-prune this surface only existed because the gateway
# adapter wrote to it; nothing operational happens here.
class WalletTopupAdmin(_ReadOnlyAdmin):
    list_display = (
        'id',
        'initiated_at',
        'tech_link',
        'amount_label',
        'gateway_pill',
        'status_pill',
        'wallet_transaction',
        'completed_at',
    )
    list_filter = ('gateway_status', 'gateway_name')
    search_fields = (
        'technician__user__username',
        'gateway_session_id',
    )
    date_hierarchy = 'initiated_at'
    ordering = ('-initiated_at',)
    list_per_page = 40
    list_select_related = ('technician', 'technician__user', 'wallet_transaction')

    @admin.display(description='Tech', ordering='technician__user__username')
    def tech_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Amount', ordering='amount_attempted')
    def amount_label(self, obj):
        return money_rs(obj.amount_attempted)

    @admin.display(description='Gateway', ordering='gateway_name')
    def gateway_pill(self, obj):
        return pill(obj.gateway_name, 'info')

    @admin.display(description='Status', ordering='gateway_status')
    def status_pill(self, obj):
        return pill(
            obj.get_gateway_status_display(),
            _TOPUP_TONES.get(obj.gateway_status, 'neutral'),
        )


# ---------------------------------------------------------------------------
# Payout accounts
# ---------------------------------------------------------------------------


# TechnicianBankAccountAdmin standalone unregistered — full PII now shows
# directly on the WithdrawalRequest change view (the only place finance
# needs to see it). Separate sidebar entry was a PII surface in plain sight.
class TechnicianBankAccountAdmin(_FinanceAdminGatedReadOnly):
    """PII-gated to finance_admin group.

    Full ``account_number_or_iban`` is shown on the detail page (finance
    needs it to issue payouts) but never in list_display. It is also
    deliberately NOT in ``search_fields`` — exact-match search on the
    IBAN is itself a PII-enumeration vector.
    """

    list_display = (
        'id',
        'tech_link',
        'bank_name',
        'account_title',
        'masked_number',
        'active_pill',
        'captured_at',
    )
    list_filter = ('bank_name', 'is_active')
    search_fields = (
        'technician__user__username',
        'account_title',
    )
    list_select_related = ('technician', 'technician__user')

    @admin.display(description='Tech', ordering='technician__user__username')
    def tech_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Account')
    def masked_number(self, obj):
        n = obj.account_number_or_iban
        return f'••••{n[-4:]}' if n and len(n) >= 4 else '••••'

    @admin.display(description='Active', ordering='is_active')
    def active_pill(self, obj):
        return pill('Active', 'positive') if obj.is_active else pill('Disabled', 'neutral')


# TechnicianJazzCashAccountAdmin standalone unregistered — same rationale
# as bank account; full MSISDN appears on the WithdrawalRequest detail page.
class TechnicianJazzCashAccountAdmin(_FinanceAdminGatedReadOnly):
    """PII-gated to finance_admin group. Full MSISDN excluded from search."""

    list_display = (
        'id',
        'tech_link',
        'account_title',
        'masked_mobile',
        'active_pill',
        'captured_at',
    )
    list_filter = ('is_active',)
    search_fields = (
        'technician__user__username',
        'account_title',
    )
    list_select_related = ('technician', 'technician__user')

    @admin.display(description='Tech', ordering='technician__user__username')
    def tech_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Mobile')
    def masked_mobile(self, obj):
        m = obj.mobile_number
        return f'{m[:5]}•••{m[-3:]}' if m and len(m) >= 8 else '•••'

    @admin.display(description='Active', ordering='is_active')
    def active_pill(self, obj):
        return pill('Active', 'positive') if obj.is_active else pill('Disabled', 'neutral')


# ---------------------------------------------------------------------------
# Withdrawals — request + fulfilment
# ---------------------------------------------------------------------------


class _ApproveAndProcessForm(forms.Form):
    """Intermediate page form for the bulk approve action."""

    admin_external_ref = forms.CharField(
        widget=forms.TextInput(attrs={
            'placeholder': 'e.g. JC-MERCH-2026-05-20-7821 or HBL wire ref',
            'style': 'width:480px',
        }),
        label=_('External payout reference'),
        required=True,
        min_length=1,
        max_length=128,
        help_text=_('The bank wire reference, JazzCash merchant txn id, or '
                    'similar identifier from your out-of-band payout. '
                    'Surfaces back to the tech on their withdrawal history.'),
    )
    admin_notes = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 3, 'cols': 60}),
        label=_('Internal notes (optional)'),
        required=False,
        max_length=2000,
    )

    def clean_admin_external_ref(self):
        # min_length=1 lets a single space through; the service then strips
        # and raises uncaught ValueError → 500. Validate at the form layer.
        value = (self.cleaned_data.get('admin_external_ref') or '').strip()
        if not value:
            raise forms.ValidationError(
                _('Reference is required — whitespace alone is not accepted.'),
            )
        return value


class _RejectWithdrawalForm(forms.Form):
    admin_notes = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 3, 'cols': 60}),
        label=_('Rejection reason (required, internal-only)'),
        required=True,
        min_length=1,
        max_length=2000,
    )

    def clean_admin_notes(self):
        value = (self.cleaned_data.get('admin_notes') or '').strip()
        if not value:
            raise forms.ValidationError(
                _('Reason is required — whitespace alone is not accepted.'),
            )
        return value


@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    """Withdrawal queue — the admin's fulfilment workbench.

    PII-gated to ``finance_admin`` (only that group + superusers see the
    queue). The ``approve_and_process`` action is the only sanctioned
    write path from admin and runs through the wallet ledger service so
    the WITHDRAWAL_DEBIT + WithdrawalFulfilment rows land atomically.
    """

    def has_module_permission(self, request):
        return _is_finance_admin(request.user)

    def has_view_permission(self, request, obj=None):
        return _is_finance_admin(request.user)

    def has_change_permission(self, request, obj=None):
        return _is_finance_admin(request.user)

    list_display = (
        'tech_link',
        'amount_label',
        'status_pill',
        'payout_target',
        'requested_at',
        'admin_external_ref',
        'reviewed_by',
        'quick_actions',
    )
    list_filter = ('status',)
    search_fields = (
        'technician__user__username',
        'admin_external_ref',
        'admin_notes',
    )
    date_hierarchy = 'requested_at'
    ordering = ('status', '-requested_at')  # PENDING_REVIEW floats up
    list_per_page = 30
    list_select_related = (
        'technician',
        'technician__user',
        'payout_bank_account',
        'payout_jazzcash_account',
        'reviewed_by',
    )
    actions = ('action_approve_and_process', 'action_reject')

    def get_inlines(self, request, obj=None):
        # Fulfilment exists only for PROCESSED requests; show its row inline
        # so admin can jump to the ledger transaction without a separate page.
        if obj is not None and obj.status == WithdrawalStatus.PROCESSED:
            return [WithdrawalFulfilmentInline]
        return []

    # Every business-meaningful field is read-only. Status / external-ref /
    # notes are written only by the approve/reject service through
    # ``transaction.atomic() + select_for_update``; allowing the standard
    # Save button to mutate them would let an admin mark a request
    # PROCESSED without writing the WITHDRAWAL_DEBIT ledger row. The
    # action panel + bulk actions are now the only sanctioned mutation
    # path.
    readonly_fields = (
        'technician',
        'amount',
        'status',
        'payout_bank_account',
        'payout_jazzcash_account',
        'payout_account_details',
        'admin_external_ref',
        'admin_notes',
        'requested_at',
        'reviewed_by',
        'reviewed_at',
    )

    fieldsets = (
        ('Request', {
            'fields': (
                'technician', 'amount', 'status', 'requested_at',
            ),
        }),
        ('Payout target (PII)', {
            'description': 'Full account details — visible only to finance_admin '
                           'group. Use this to send the out-of-band payout, then '
                           'paste the gateway reference in the action panel above.',
            'fields': ('payout_account_details',),
        }),
        ('Admin audit', {
            'fields': (
                'admin_external_ref', 'admin_notes',
                'reviewed_by', 'reviewed_at',
            ),
        }),
    )

    @admin.display(description='Account details (unmasked)')
    def payout_account_details(self, obj):
        """Render full payout account PII inline on the change page.

        Replaces the standalone bank/jazzcash account admin pages so
        finance has a single workbench: the withdrawal request itself.
        IBAN / MSISDN are visible in plain text here because finance
        needs them to issue the payout — the gate is the parent admin's
        ``has_view_permission``, which restricts the entire page to
        the ``finance_admin`` group.
        """
        if obj.payout_bank_account_id:
            acct = obj.payout_bank_account
            return format_html(
                '<div style="line-height:1.6">'
                '<div><b>Method:</b> Bank transfer</div>'
                '<div><b>Bank:</b> {}</div>'
                '<div><b>Account title:</b> {}</div>'
                '<div><b>IBAN / account #:</b> '
                '<code style="background:#fef3c7;padding:2px 6px;border-radius:4px">{}</code></div>'
                '<div style="color:#64748b;font-size:11px;margin-top:6px">'
                'Captured {}</div></div>',
                acct.bank_name, acct.account_title,
                acct.account_number_or_iban,
                acct.captured_at.strftime('%Y-%m-%d %H:%M') if acct.captured_at else '—',
            )
        if obj.payout_jazzcash_account_id:
            acct = obj.payout_jazzcash_account
            return format_html(
                '<div style="line-height:1.6">'
                '<div><b>Method:</b> JazzCash mobile wallet</div>'
                '<div><b>Account title:</b> {}</div>'
                '<div><b>Mobile (MSISDN):</b> '
                '<code style="background:#fef3c7;padding:2px 6px;border-radius:4px">{}</code></div>'
                '<div style="color:#64748b;font-size:11px;margin-top:6px">'
                'Captured {}</div></div>',
                acct.account_title, acct.mobile_number,
                acct.captured_at.strftime('%Y-%m-%d %H:%M') if acct.captured_at else '—',
            )
        return format_html('<em style="color:#9ca3af">{}</em>', '— no payout account —')

    def has_add_permission(self, request):
        # Withdrawals are submitted by techs via /api/technicians/wallet/withdrawals/.
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    # ---- list cells ---------------------------------------------------------

    @admin.display(description='Tech', ordering='technician__user__username')
    def tech_link(self, obj):
        url = reverse('admin:technicians_technicianprofile_change', args=[obj.technician_id])
        return format_html(
            '<a href="{}">{}</a>',
            url,
            obj.technician.user.get_full_name() or obj.technician.user.username,
        )

    @admin.display(description='Amount', ordering='amount')
    def amount_label(self, obj):
        return format_html(
            '<span style="font-family:ui-monospace,monospace;font-weight:600">{}</span>',
            money_rs(obj.amount),
        )

    @admin.display(description='Status', ordering='status')
    def status_pill(self, obj):
        return pill(
            obj.get_status_display(),
            _WITHDRAWAL_TONES.get(obj.status, 'neutral'),
        )

    @admin.display(description='Actions')
    def quick_actions(self, obj):
        """Inline Process / Reject buttons for the single-row case."""
        if obj.status != WithdrawalStatus.PENDING_REVIEW:
            return format_html('<span style="color:#9ca3af;font-size:11px">{}</span>', '—')
        process_url = reverse('admin:wallet_withdrawalrequest_quick_process', args=[obj.pk])
        reject_url = reverse('admin:wallet_withdrawalrequest_quick_reject', args=[obj.pk])
        return format_html(
            '<a class="fx-qbtn fx-qbtn-process" href="{}">✓ Process</a>'
            '<a class="fx-qbtn fx-qbtn-reject" href="{}">✗ Reject</a>',
            process_url, reject_url,
        )

    # ---- per-row custom URLs ------------------------------------------------

    def get_urls(self):
        urls = super().get_urls()
        custom = [
            path(
                '<int:request_id>/quick-process/',
                self.admin_site.admin_view(self.quick_process_view),
                name='wallet_withdrawalrequest_quick_process',
            ),
            path(
                '<int:request_id>/quick-reject/',
                self.admin_site.admin_view(self.quick_reject_view),
                name='wallet_withdrawalrequest_quick_reject',
            ),
        ]
        return custom + urls

    def quick_process_view(self, request, request_id: int):
        """Single-row Approve & process page."""
        try:
            row = WithdrawalRequest.objects.select_related(
                'technician', 'technician__user',
                'payout_bank_account', 'payout_jazzcash_account',
            ).get(pk=request_id)
        except WithdrawalRequest.DoesNotExist:
            self.message_user(request, _('Withdrawal not found.'), messages.ERROR)
            return redirect('admin:wallet_withdrawalrequest_changelist')

        if row.status != WithdrawalStatus.PENDING_REVIEW:
            self.message_user(
                request,
                _('Withdrawal #%(id)s is in status %(status)s — already processed.') % {
                    'id': row.pk, 'status': row.get_status_display(),
                },
                level=messages.WARNING,
            )
            return redirect('admin:wallet_withdrawalrequest_changelist')

        if request.method == 'POST':
            form = _ApproveAndProcessForm(request.POST)
            if form.is_valid():
                try:
                    approve_and_process_withdrawal(
                        request_id=row.pk,
                        admin_user=request.user,
                        admin_external_ref=form.cleaned_data['admin_external_ref'],
                        admin_notes=form.cleaned_data['admin_notes'],
                    )
                    self.message_user(
                        request,
                        _('Processed withdrawal #%(id)s.') % {'id': row.pk},
                        level=messages.SUCCESS,
                    )
                    return redirect('admin:wallet_withdrawalrequest_change', row.pk)
                except WithdrawalNotPending as exc:
                    self.message_user(
                        request,
                        _('Status changed to %(s)s — refusing.') % {'s': exc.current_status},
                        level=messages.WARNING,
                    )
                except InsufficientFundsError:
                    self.message_user(
                        request,
                        _('Tech balance dropped below request amount — refusing.'),
                        level=messages.ERROR,
                    )
                except IntegrityError:
                    _logger.exception('Withdrawal #%s ledger integrity error', row.pk)
                    self.message_user(
                        request,
                        _('Ledger conflict — please retry. (Logged.)'),
                        level=messages.ERROR,
                    )
                except Exception:
                    _logger.exception('Withdrawal #%s unexpected error', row.pk)
                    self.message_user(
                        request,
                        _('Unexpected error processing withdrawal. (Logged.)'),
                        level=messages.ERROR,
                    )
        else:
            form = _ApproveAndProcessForm()

        balance = row.technician.current_wallet_balance or Decimal('0')
        delta = balance - row.amount
        wallet_status = {
            'balance_label': money_rs(balance),
            'is_sufficient': delta >= 0,
            'delta_label': (
                f'Rs. {int(delta):,} remaining after payout'
                if delta >= 0
                else f'Rs. {int(-delta):,} short — backend will refuse the debit'
            ),
        }
        return render(
            request,
            'admin/wallet/quick_process.html',
            context={
                'title': f'Process withdrawal #{row.pk}',
                'request_row': row,
                'form': form,
                'opts': self.model._meta,
                'wallet_status': wallet_status,
            },
        )

    def quick_reject_view(self, request, request_id: int):
        """Single-row Reject page."""
        try:
            row = WithdrawalRequest.objects.select_related(
                'technician', 'technician__user',
            ).get(pk=request_id)
        except WithdrawalRequest.DoesNotExist:
            self.message_user(request, _('Withdrawal not found.'), messages.ERROR)
            return redirect('admin:wallet_withdrawalrequest_changelist')

        if row.status != WithdrawalStatus.PENDING_REVIEW:
            self.message_user(
                request,
                _('Withdrawal #%(id)s is in status %(status)s — refusing.') % {
                    'id': row.pk, 'status': row.get_status_display(),
                },
                level=messages.WARNING,
            )
            return redirect('admin:wallet_withdrawalrequest_changelist')

        if request.method == 'POST':
            form = _RejectWithdrawalForm(request.POST)
            if form.is_valid():
                try:
                    reject_withdrawal(
                        request_id=row.pk,
                        admin_user=request.user,
                        admin_notes=form.cleaned_data['admin_notes'],
                    )
                    self.message_user(
                        request,
                        _('Rejected withdrawal #%(id)s.') % {'id': row.pk},
                        level=messages.SUCCESS,
                    )
                    return redirect('admin:wallet_withdrawalrequest_changelist')
                except WithdrawalNotPending as exc:
                    self.message_user(
                        request,
                        _('Status changed to %(s)s — refusing.') % {'s': exc.current_status},
                        level=messages.WARNING,
                    )
                except IntegrityError:
                    _logger.exception('Withdrawal #%s reject integrity error', row.pk)
                    self.message_user(
                        request,
                        _('Ledger conflict — please retry. (Logged.)'),
                        level=messages.ERROR,
                    )
                except Exception:
                    _logger.exception('Withdrawal #%s reject unexpected error', row.pk)
                    self.message_user(
                        request,
                        _('Unexpected error rejecting withdrawal. (Logged.)'),
                        level=messages.ERROR,
                    )
        else:
            form = _RejectWithdrawalForm()

        return render(
            request,
            'admin/wallet/quick_reject.html',
            context={
                'title': f'Reject withdrawal #{row.pk}',
                'request_row': row,
                'form': form,
                'opts': self.model._meta,
            },
        )

    # ---- detail-page action panel ------------------------------------------

    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Inject the action panel above the form when the row is pending."""
        try:
            row = WithdrawalRequest.objects.get(pk=object_id)
        except WithdrawalRequest.DoesNotExist:
            row = None

        extra_context = dict(extra_context or {})
        if row and row.status == WithdrawalStatus.PENDING_REVIEW:
            extra_context['fx_action_panel'] = {
                'title': 'This withdrawal is awaiting review',
                'sub': 'Process via the bank wire / JazzCash merchant app first, '
                       'then click the button to write the WITHDRAWAL_DEBIT and '
                       'mark it processed.',
                'process_url': reverse(
                    'admin:wallet_withdrawalrequest_quick_process', args=[row.pk],
                ),
                'reject_url': reverse(
                    'admin:wallet_withdrawalrequest_quick_reject', args=[row.pk],
                ),
            }
        return super().change_view(request, object_id, form_url, extra_context)

    @admin.display(description='Payout to')
    def payout_target(self, obj):
        if obj.payout_bank_account_id:
            acct = obj.payout_bank_account
            n = acct.account_number_or_iban or ''
            masked = f'••••{n[-4:]}' if len(n) >= 4 else '••••'
            return format_html(
                '<div style="line-height:1.3"><div style="font-weight:600">{}</div>'
                '<div style="color:#6b7280;font-size:11px">{} · {}</div></div>',
                acct.bank_name, acct.account_title, masked,
            )
        if obj.payout_jazzcash_account_id:
            acct = obj.payout_jazzcash_account
            m = acct.mobile_number or ''
            masked = f'{m[:5]}•••{m[-3:]}' if len(m) >= 8 else '•••'
            return format_html(
                '<div style="line-height:1.3"><div style="font-weight:600">JazzCash</div>'
                '<div style="color:#6b7280;font-size:11px">{} · {}</div></div>',
                acct.account_title, masked,
            )
        return '—'

    # ---- actions ------------------------------------------------------------

    @admin.action(description='Approve & process (writes WITHDRAWAL_DEBIT)')
    def action_approve_and_process(self, request, queryset):
        """Two-phase action: render the form, then atomically fulfil each row."""
        pending = queryset.filter(status=WithdrawalStatus.PENDING_REVIEW)
        skipped = queryset.exclude(status=WithdrawalStatus.PENDING_REVIEW)

        if not pending.exists():
            self.message_user(
                request,
                _('None of the selected withdrawals are pending review.'),
                level=messages.WARNING,
            )
            return None

        if 'apply' in request.POST:
            form = _ApproveAndProcessForm(request.POST)
            if form.is_valid():
                ref = form.cleaned_data['admin_external_ref']
                notes = form.cleaned_data['admin_notes']
                processed = 0
                errors: list[str] = []
                for row in pending:
                    try:
                        approve_and_process_withdrawal(
                            request_id=row.pk,
                            admin_user=request.user,
                            admin_external_ref=ref,
                            admin_notes=notes,
                        )
                        processed += 1
                    except WithdrawalNotPending as exc:
                        errors.append(f'#{row.pk}: {exc.current_status}')
                    except InsufficientFundsError:
                        errors.append(
                            f'#{row.pk}: tech balance dropped below request amount '
                            '(commission write race) — request stays pending.'
                        )
                    except IntegrityError:
                        _logger.exception('Bulk approve #%s integrity error', row.pk)
                        errors.append(f'#{row.pk}: ledger conflict (logged)')
                    except Exception:
                        _logger.exception('Bulk approve #%s unexpected error', row.pk)
                        errors.append(f'#{row.pk}: unexpected error (logged)')

                if processed:
                    self.message_user(
                        request,
                        _('Processed %(n)d withdrawal(s).') % {'n': processed},
                        level=messages.SUCCESS,
                    )
                if errors:
                    self.message_user(
                        request,
                        _('Skipped: %(e)s') % {'e': '; '.join(errors)},
                        level=messages.WARNING,
                    )
                return None
        else:
            form = _ApproveAndProcessForm()

        return render(
            request,
            'admin/wallet/withdrawal_action.html',
            context={
                'title': 'Approve & process withdrawals',
                'action_verb': 'Approve & process',
                'requests': pending,
                'skipped': skipped,
                'form': form,
                'action': 'action_approve_and_process',
            },
        )

    @admin.action(description='Reject (no ledger movement)')
    def action_reject(self, request, queryset):
        pending = queryset.filter(status=WithdrawalStatus.PENDING_REVIEW)

        if not pending.exists():
            self.message_user(
                request,
                _('None of the selected withdrawals are pending review.'),
                level=messages.WARNING,
            )
            return None

        if 'apply' in request.POST:
            form = _RejectWithdrawalForm(request.POST)
            if form.is_valid():
                notes = form.cleaned_data['admin_notes']
                rejected = 0
                errors: list[str] = []
                for row in pending:
                    try:
                        reject_withdrawal(
                            request_id=row.pk,
                            admin_user=request.user,
                            admin_notes=notes,
                        )
                        rejected += 1
                    except WithdrawalNotPending:
                        pass
                    except Exception:
                        _logger.exception('Bulk reject #%s unexpected error', row.pk)
                        errors.append(f'#{row.pk}')
                if rejected:
                    self.message_user(
                        request,
                        _('Rejected %(n)d withdrawal(s).') % {'n': rejected},
                        level=messages.SUCCESS,
                    )
                if errors:
                    self.message_user(
                        request,
                        _('Failed: %(e)s — logged for review.') % {'e': ', '.join(errors)},
                        level=messages.ERROR,
                    )
                return None
        else:
            form = _RejectWithdrawalForm()

        return render(
            request,
            'admin/wallet/withdrawal_action.html',
            context={
                'title': 'Reject withdrawals',
                'action_verb': 'Reject',
                'requests': pending,
                'skipped': queryset.exclude(status=WithdrawalStatus.PENDING_REVIEW),
                'form': form,
                'action': 'action_reject',
            },
        )


# WithdrawalFulfilmentAdmin removed in the scope-reduction pass — every
# fulfilment row is 1:1 with a WithdrawalRequest and is reached more
# naturally via an inline on the request change page (added separately).
# Standalone admin duplicated that surface without adding value.

    @admin.display(description='Note')
    def note_short(self, obj):
        return truncate(obj.processing_note, 60)
