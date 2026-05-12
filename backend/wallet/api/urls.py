"""Wallet URL routes — mounted under ``/api/technicians/wallet/``.

Empty-path route gives the balance endpoint at the mount prefix itself.
Thursday's additions (topups, withdrawals, gateway callback) live here
too, so the wallet app owns its own URL surface and the parent
``technicians/api/urls.py`` only does an ``include``.
"""
from django.urls import path

from wallet.api.views import WalletBalanceView

urlpatterns = [
    # GET → balance + as_of timestamp
    path('', WalletBalanceView.as_view(), name='wallet-balance'),
]
