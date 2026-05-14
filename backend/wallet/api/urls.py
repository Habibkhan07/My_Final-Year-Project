"""Wallet URL routes — mounted under ``/api/technicians/wallet/``.

The wallet app owns its own URL surface so the parent
``technicians/api/urls.py`` only does an ``include``. The gateway-facing
``/api/wallet/gateway/jazzcash/return/`` route lives in ``core/urls.py``
directly because it is NOT tech-authenticated.
"""
from django.urls import path

from wallet.api.views import (
    PayoutAccountListView,
    TopupBridgeView,
    TopupCreateView,
    TopupStatusView,
    WalletBalanceView,
    WalletTransactionListView,
    WithdrawalRequestView,
)

urlpatterns = [
    # GET → balance + as_of timestamp
    path('', WalletBalanceView.as_view(), name='wallet-balance'),
    # GET → cursor-paginated wallet ledger (commission / topup /
    # withdrawal / refund / adjustment rows only — no cash exchanges)
    path('transactions/', WalletTransactionListView.as_view(), name='wallet-transactions'),
    # POST → start a top-up; returns {topup_id, redirect_url} where
    # redirect_url is the bridge URL the Flutter webview opens.
    path('topups/', TopupCreateView.as_view(), name='wallet-topup-create'),
    # GET → poll the topup's terminal status (used by the FE while the
    # webview is open).
    path('topups/<int:topup_id>/', TopupStatusView.as_view(), name='wallet-topup-status'),
    # GET → bridge view; signed token in ?t= is the auth (5-min TTL).
    # Renders an auto-submitting JazzCash form OR a manual Pay/Decline
    # page when gateway_name='mock'.
    path('topups/<int:topup_id>/bridge/', TopupBridgeView.as_view(), name='wallet-topup-bridge'),
    # GET → active bank + JazzCash payout accounts (masked) feeding the
    # withdrawal-submit picker.
    path('payout-accounts/', PayoutAccountListView.as_view(), name='wallet-payout-accounts'),
    # POST → submit a new withdrawal request (PENDING_REVIEW).
    # GET  → cursor-paginated history of this tech's own requests.
    path('withdrawals/', WithdrawalRequestView.as_view(), name='wallet-withdrawals'),
]
