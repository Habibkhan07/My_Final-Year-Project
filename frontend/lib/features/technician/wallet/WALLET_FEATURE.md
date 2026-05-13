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
  Future<WalletState> getBalance();                                    // throws WalletFailure subclass
  Future<WalletTransactionPage> listTransactions({String? cursor});   // throws WalletFailure subclass
}
```

Backed by:
- `GET /api/technicians/wallet/` — balance snapshot:
  ```json
  { "balance": "1500.00", "as_of": "2026-05-13T22:30:00Z" }
  ```
- `GET /api/technicians/wallet/transactions/?cursor=…&page_size=…` — cursor-paginated ledger:
  ```json
  {
    "next_cursor": "MjAyNi0wNS0xM1QxMjowMHwxMjM=" | null,
    "results": [
      {
        "id": 42, "type": "COMMISSION_DEBIT",
        "amount": "-200.00", "balance_after": "800.00",
        "timestamp": "2026-05-13T12:00:00Z", "memo": "",
        "ui_icon": "commission", "ui_title": "Platform commission",
        "ui_subtitle": "Booking #128", "ui_amount_color": "debit"
      }
    ]
  }
  ```
  Five `type` values: `COMMISSION_DEBIT`, `TOPUP_CREDIT`, `WITHDRAWAL_DEBIT`, `REFUND_DEBIT`, `ADJUSTMENT`. Cash exchanges deliberately NOT included (wallet-vs-metrics separation rule). `ui_*` fields are shaped server-side so the Flutter row widget never branches on `type`.

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

## Notifiers

```dart
@riverpod  // keepAlive: false — wallet screen is a leaf route, not a tab
class WalletNotifier extends _$WalletNotifier {
  Future<WalletState> build();    // initial fetch + listens to systemEventProvider
  Future<void> refresh();         // pull-to-refresh, AsyncValue.guard
  void onBalanceEvent(double);    // realtime patch
}

@riverpod  // keepAlive: false — same dispose lifecycle
class WalletTransactionsNotifier extends _$WalletTransactionsNotifier {
  Future<WalletTransactionsState> build();   // first-page fetch
  Future<void> refresh();                    // pull-to-refresh
  Future<void> loadMore();                   // appends next page; re-entry-safe
}
```

`WalletTransactionsState = (page, isLoadingMore)`. `loadMore` no-ops when the cursor is null or already loading; on error it surfaces the failure but keeps existing rows visible so the user can retry.

## UI

- **WalletScreen**: AppBar "Wallet" + combined pull-to-refresh (refreshes both balance + history together) → balance card → Top up → Withdraw → **Recent activity** section.
- **BalanceCard**: gradient hero (primaryContainer → primary), big "Rs. 1,500".
- **TopUpButton**: ElevatedButton; currently shows snackbar "JazzCash top-up is launching Thursday".
- **WithdrawButton**: OutlinedButton; currently shows snackbar "Withdrawal requests open Thursday".
- **TransactionsSection**: header "Recent activity" → list of `TransactionRow`s OR "No wallet activity yet" empty-state pill OR 5-row skeleton OR inline error+retry. Pagination kicks off when the section is mounted with `hasMore` true (post-frame trigger); a later commit will move to SliverList for proper on-scroll loading.
- **TransactionRow**: Dumb-UI — leading 40px tinted circle (icon from `ui_icon`, tint from `ui_amount_color`), title (`ui_title`), subtitle (`ui_subtitle` + relative timestamp like "2h ago"), trailing signed `Rs. X` (green for credits, neutral for debits).

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
