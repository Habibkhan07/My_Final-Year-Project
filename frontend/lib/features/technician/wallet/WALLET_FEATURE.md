# Wallet Feature (Tech)

Tech-only virtual wallet screen. Tonight ships balance display + Top up + Withdraw stubs.
Thursday wires the actual top-up and withdrawal flows behind the same buttons.

## Domain

### Entity — `WalletState`
| Field      | Type      | Source                                          |
|------------|-----------|-------------------------------------------------|
| `balance`  | `double`  | parsed from server's Decimal-as-string          |
| `asOf`     | DateTime  | server-provided timestamp of the snapshot       |

### Failures (sealed)
- **`WalletNetworkFailure`** — device offline. NO cache fallback per Fix #9 (wallet is financial truth).
- **`WalletServerFailure`** — backend 5xx / unparseable.
- **`WalletPermissionFailure`** — backend 401/403 (not a tech, invalid token).

## Repository contract

```dart
abstract class WalletRepository {
  Future<WalletState> getBalance();  // throws WalletFailure subclass
}
```

Backed by `GET /api/technicians/wallet/`. Response shape:
```json
{ "balance": "1500.00", "as_of": "2026-05-13T22:30:00Z" }
```

## Realtime — `WALLET_BALANCE_UPDATED`

Backend `wallet.services.ledger.record_transaction` broadcasts this event on every
ledger write via `transaction.on_commit`. Wire string: `wallet_balance_updated`.

Payload:
```json
{ "balance": "1700.00", "transaction_id": 42, "transaction_type": "COMMISSION_DEBIT" }
```

Two FE notifiers consume it:
1. `TechnicianDashboardNotifier.onWalletBalanceEvent` — patches the dashboard pill.
2. `WalletNotifier.onBalanceEvent` — patches the wallet screen balance card.

Both patch in-place (no AsyncLoading flash). Pipeline-level dedup at `SystemEventNotifier`.

## Notifier — `WalletNotifier`

```dart
@riverpod  // keepAlive: false — wallet screen is a leaf route, not a tab
class WalletNotifier extends _$WalletNotifier {
  Future<WalletState> build();    // initial fetch + listens to systemEventProvider
  Future<void> refresh();         // pull-to-refresh, AsyncValue.guard
  void onBalanceEvent(double);    // realtime patch
}
```

## UI

- **WalletScreen**: AppBar "Wallet" + RefreshIndicator scroll + balance card + 2 CTA buttons.
- **BalanceCard**: gradient hero (primaryContainer → primary), big "Rs. 1,500".
- **TopUpButton**: ElevatedButton; tonight shows snackbar "JazzCash top-up is launching Thursday".
- **WithdrawButton**: OutlinedButton; tonight shows snackbar "Withdrawal requests open Thursday".

## Routing

`/wallet` mounted at top level (tech-only — gated by `START_AS` redirect /
auth state, same surface as the dashboard pill that opens it).

Dashboard's wallet pill `onTap` → `GoRouter.of(context).push('/wallet')`.

## Out of scope tonight (locks Thursday additions)

- POST `/api/wallet/topups/` + JazzCash redirect flow
- POST `/api/wallet/withdrawals/` + payout account form
- POST `/api/wallet/gateways/jazzcash/callback/` (webhook)
- `WithdrawRequestAdmin.approve_and_process` Django action
- Auto-creating `TechnicianJazzCashAccount` on first top-up

The backend schemas for all of the above (`WalletTopup`, `WithdrawalRequest`,
`WithdrawalFulfilment`, `TechnicianBankAccount`, `TechnicianJazzCashAccount`)
shipped tonight in `0001_initial` so Thursday is pure plumbing.
