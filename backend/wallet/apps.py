from django.apps import AppConfig


class WalletConfig(AppConfig):
    """Tech-facing virtual wallet (commission ledger + JazzCash top-up rails).

    Implements ``FinancePort`` (declared in ``bookings.services.finance_ports``)
    via ``adapters.wallet_finance_adapter.WalletFinanceAdapter``. Every wallet
    mutation funnels through ``services.ledger.record_transaction`` so the
    ``balance_after`` audit invariant and ``select_for_update`` lock ordering
    are enforced in one place.
    """
    name = 'wallet'
