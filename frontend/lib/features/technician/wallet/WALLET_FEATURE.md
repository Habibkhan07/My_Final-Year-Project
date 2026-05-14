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
- **TopUpButton**: brand-blue ElevatedButton. Tap → opens the JazzCash top-up flow (sheet → webview → result sheet). See "Top-up flow" below.
- **WithdrawButton**: OutlinedButton; currently shows snackbar "Withdrawal requests open Thursday".
- **TransactionsSection**: header "Recent activity" → list of `TransactionRow`s OR "No wallet activity yet" empty-state pill OR 5-row skeleton OR inline error+retry. Pagination kicks off when the section is mounted with `hasMore` true (post-frame trigger); a later commit will move to SliverList for proper on-scroll loading.
- **TransactionRow**: Dumb-UI — leading 40px tinted circle (icon from `ui_icon`, tint from `ui_amount_color`), title (`ui_title`), subtitle (`ui_subtitle` + relative timestamp like "2h ago"), trailing signed `Rs. X` (green for credits, neutral for debits).

## Top-up flow (JazzCash Hosted Checkout)

Multi-screen state machine driven by `topupProvider` (sync `Notifier<TopupState>`):

```
TopUpButton.onPressed
  ↓ showModalBottomSheet
TopupAmountSheet
  amount + 4 quick-pick chips (Rs. 200 / 500 / 1000 / 2000)
  Continue → notifier.start(amount) → POST /api/technicians/wallet/topups/
  ↓ sheet pops; flow == awaitingGateway
TopUpButton.ref.listen detects awaitingGateway
  ↓ Navigator.push
JazzCashWebviewScreen (webview_flutter)
  - loads session.redirectUrl (our bridge URL)
  - bridge auto-POSTs the JazzCash form (real) or shows Pay/Decline (mock)
  - NavigationDelegate intercepts /api/wallet/gateway/jazzcash/return/
    → notifier.onGatewayReturned() → flow == verifying → pop
  - back / close → notifier.onGatewayAborted() → flow == failed(UserAborted)
TopupNotifier polls GET /topups/<id>/ every 2s (max 15 attempts = 30s budget)
  - terminal status → flow == success / failed
TopUpButton.ref.listen detects terminal flow
  ↓ showModalBottomSheet
TopupResultSheet
  - success: green check + "Rs. X added to your wallet" + Done
  - failed:  red icon + plain-language copy from sealed TopupFailure + Close / Try again
```

State shape (`presentation/notifiers/topup_state.dart`):

```dart
class TopupState {
  final TopupFlow flow;        // idle / starting / awaitingGateway /
                               // verifying / success / failed
  final TopupSession? session;       // populated after `start` succeeds
  final TopupStatus? terminalStatus; // populated by terminal poll
  final TopupFailure? failure;       // sealed family — see below
}
```

### Sealed `TopupFailure` family (`domain/failures/topup_failure.dart`)

Pattern-match these in the result sheet's switch:

| Failure | When it fires | Tech-facing copy |
|---|---|---|
| `TopupInvalidAmount(min, max)` | 400 amount validation | "Enter between Rs.100 and Rs.25,000." |
| `TopupGatewayUnavailable` | 503 — JazzCash creds missing | "Top-up is temporarily unavailable. Try again later." |
| `TopupNetworkFailure` | SocketException during start/poll | "No internet connection. Check your settings." |
| `TopupServerFailure(msg)` | Backend 5xx / FormatException | (uses `msg`) |
| `TopupPermissionFailure` | 401 / 403 / 404 (IDOR) | "Your session has expired. Sign in again." |
| `TopupUserAborted` | Webview close button / back gesture | "You cancelled the top-up." |
| `TopupPollTimeout` | 30s poll budget exhausted | "Couldn't confirm in time. Pull to refresh shortly." |

### Realtime balance patch (free)

Successful top-up writes a `TOPUP_CREDIT` ledger row via `record_transaction`,
which fires `wallet_balance_updated` on `transaction.on_commit`. The existing
`WalletNotifier.onBalanceEvent` patches the balance card in-place — no extra
notifier work needed.

### `--dart-define` knob

The webview's `NavigationDelegate` matches the return URL prefix derived from
`AppConstants.baseUrl` minus the trailing `/api`. If the backend's
`JAZZCASH_RETURN_URL` host differs (e.g. ngrok tunnel pointing at a different
prefix than `AppConstants.baseUrl` would build), the match will miss. Future
work: lift the FE's return-URL match string to a `--dart-define` so it can
be set independently. Tracked in `flag.md` if it becomes a real issue.

## Routing

`/wallet` mounted at top level (tech-only — gated by `START_AS` redirect /
auth state, same surface as the dashboard pill that opens it).

Dashboard's wallet pill `onTap` → `GoRouter.of(context).push('/wallet')`.

## Withdrawal flow

Tech-facing surface for the submit-then-admin-fulfilment withdrawal
lifecycle. The full backend contract lives in
`backend/wallet/api/WALLET_API.md` under "Withdrawals".

### Endpoints consumed

| Endpoint | Frontend caller | Throws |
|---|---|---|
| `GET /api/technicians/wallet/payout-accounts/` | `WithdrawNotifier.build` | `WithdrawalFailure` |
| `POST /api/technicians/wallet/withdrawals/` | `WithdrawNotifier.submit` | `WithdrawalFailure` |
| `GET /api/technicians/wallet/withdrawals/` | `WithdrawalHistoryNotifier`, `pendingWithdrawalProvider` | `WithdrawalFailure` |

### Domain layer

- `PayoutAccount` sealed family (`BankPayoutAccount`, `JazzCashPayoutAccount`)
  — exhaustive switch surface for the picker. Raw account number / mobile
  number are NEVER carried; server only ships the masked form.
- `PayoutAccounts` (parallel `bank_accounts` + `jazzcash_accounts` lists).
- `WithdrawalRequest` + `PayoutDescriptor` + `WithdrawalStatus` enum (with
  backwards-compat `fromWire` fallback to `pendingReview`).
- `WithdrawalHistoryPage` cursor-paginated wrapper (mirrors
  `WalletTransactionPage`).

### Sealed `WithdrawalFailure` family (`domain/failures/withdrawal_failure.dart`)

Pattern-match in the withdraw sheet's `_failureCopy` switch — adding a
new case is a compile-time error.

| Failure | Wire code | Tech-facing copy |
|---|---|---|
| `InsufficientFundsFailure(requestedPkr, availablePkr)` | 400 `insufficient_funds` | "You tried to withdraw Rs. X but only Rs. Y is available." |
| `WalletLockoutForWithdrawalFailure(balancePkr, owedPkr)` | 403 `wallet_lockout` | "Wallet is locked (Rs. X owed). Top up to continue." |
| `DuplicatePendingWithdrawalFailure(pendingRequestId)` | 409 `duplicate_pending_withdrawal` | "A previous withdrawal is still under review." |
| `InactiveTechnicianForWithdrawalFailure(status)` | 403 `inactive_technician` | "Account not approved" / "Account deactivated." |
| `InvalidPayoutAccountFailure` | 400 `validation_error` on payout id | "Payout account is no longer available. Pick another." |
| `WithdrawalAmountOutOfRangeFailure(message)` | 400 `validation_error` on amount | (server message) |
| `WithdrawalValidationFailure(message)` | 400 `validation_error` other | (server message) |
| `WithdrawalNetworkFailure` | SocketException | "No internet connection. Check your settings." |
| `WithdrawalServerFailure(msg)` | 5xx / FormatException | (uses msg) |
| `WithdrawalPermissionFailure` | 401/403 generic | "You do not have permission to withdraw." |

**Offline-first opt-out:** `WithdrawalRepositoryImpl` deliberately does
NOT read or write a local cache. Withdrawals are money-movement
requests; serving a stale view of the balance and treating the submit
as "success" is a financial-correctness bug. Same rule as the wallet
balance read (Fix #9).

### State machine — `WithdrawNotifier` / `WithdrawState`

```dart
class WithdrawState {
  final WithdrawFlow flow;     // loadingAccounts / editing / submitting / success / failed
  final PayoutAccounts? accounts;
  final String amountInput;    // raw, string-typed for mid-edit values
  final PayoutAccount? selectedTarget;
  final WithdrawalRequest? submitted;
  final WithdrawalFailure? failure;
}
```

Transitions:

```
build()              → loadingAccounts → editing | failed
setAmount/selectTarget → editing (clears any prior failure)
submit()             → submitting → success | failed
reset()              → editing (preserves fetched accounts)
```

On `submit` success the notifier `ref.invalidate`s
`pendingWithdrawalProvider` + `withdrawalHistoryProvider` so the
wallet screen's pending pill and the history screen show the
just-submitted row without a manual pull.

### UI surfaces

- **`WithdrawButton`** — outlined CTA on the wallet screen. Pre-disabled
  when `walletProvider.isLockedOut` (saves a round-trip). Tap opens
  `WithdrawSheet` via `showModalBottomSheet` (top-up styling).
- **`WithdrawSheet`** — modal sheet with the form body + inline error
  banner + success body. Brand-blue ElevatedButton for submit;
  sealed `_failureCopy` switch drives the inline banner.
- **`PendingWithdrawalStrip`** — wallet-screen pill above the CTAs.
  Visible only when the tech has a `PENDING_REVIEW` or `APPROVED`
  request. Tap → pushes `/withdrawals/history`.
- **`WithdrawalHistoryScreen`** — newest-first list with pull-to-refresh
  and on-scroll load-more. `WithdrawalHistoryRow` is a dumb-UI
  presenter; status pill colour is the only enum-driven branch.
- **"View withdrawal history" text link** under the Withdraw CTA on
  the wallet screen.

### Routing

```dart
GoRoute(path: '/wallet', builder: ...),
GoRoute(path: '/withdrawals/history', builder: ...),
```

Both reached via `context.push(...)` from in-screen taps.

### Cross-feature realtime

None — withdrawal submission does NOT broadcast a realtime event.
Admin-side fulfilment writes a `WITHDRAWAL_DEBIT` ledger row, which
fires the existing `wallet_balance_updated` event that the balance
card and dashboard pill already consume. So:

- tech submits → pending pill appears (via `ref.invalidate`)
- admin processes (out-of-band) → balance updates via realtime →
  pending pill disappears on next pull-to-refresh (the history row
  flips to `PROCESSED` and `isInFlight` becomes false).

A dedicated `withdrawal_processed` event is post-viva work — keeps
the realtime contract simpler for the demo loop.

## Still out of scope (post-viva work)

- Tech-facing "Add bank account" UI (admin seeds for demo; JazzCash
  account auto-created on first top-up).
- Dedicated `withdrawal_processed` realtime event (currently relies on
  the wallet balance update + history pull-to-refresh).
- V4.0 Linking + Recurring (one-tap repeat top-ups using stored token).

Top-up endpoints (`POST /topups/`, `GET /topups/<id>/`,
`GET /topups/<id>/bridge/`, `POST /gateway/jazzcash/return/`) and
withdrawal endpoints (`GET /payout-accounts/`, `POST /withdrawals/`,
`GET /withdrawals/`) all shipped — see
`backend/wallet/api/WALLET_API.md` for the full contracts.
