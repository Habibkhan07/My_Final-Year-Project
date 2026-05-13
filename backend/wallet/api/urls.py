"""Wallet URL routes — mounted under ``/api/technicians/wallet/``.

The wallet app owns its own URL surface so the parent
``technicians/api/urls.py`` only does an ``include``.
"""
from django.urls import path

from wallet.api.views import WalletBalanceView, WalletTransactionListView

urlpatterns = [
    # GET → balance + as_of timestamp
    path('', WalletBalanceView.as_view(), name='wallet-balance'),
    # GET → cursor-paginated wallet ledger (commission / topup /
    # withdrawal / refund / adjustment rows only — no cash exchanges)
    path('transactions/', WalletTransactionListView.as_view(), name='wallet-transactions'),
]
