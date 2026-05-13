# Wallet API

Tech-facing wallet endpoints (balance, transaction history, top-up) +
JazzCash gateway return callback.

All endpoints follow the standard error envelope on failure:

```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Human readable string",
  "errors": {"field_name": ["Specific error"]}
}
```

---

## `GET /api/technicians/wallet/`

Returns the tech's current wallet balance + a snapshot timestamp.
Realtime `wallet_balance_updated` events patch this between explicit
reads — typical refresh cadence is event-driven, not polling.

**Auth:** `IsAuthenticated` + technician profile required (else 403).

**Response 200:**

```json
{
  "balance": "1500.00",
  "as_of": "2026-05-13T22:30:00Z"
}
```

---

## `GET /api/technicians/wallet/transactions/`

Cursor-paginated ledger of platform-side transactions (commission,
top-up, withdrawal, refund, adjustment). Cash exchanges are NOT here —
those live on the Metrics screen per the wallet-vs-metrics separation
rule.

**Query params:**

| Param | Type | Default | Notes |
|---|---|---|---|
| `cursor` | string | none (page 1) | Opaque base64 cursor returned from a prior page. |
| `page_size` | int | 20 | 1 ≤ page_size ≤ 50. |

**Response 200:**

```json
{
  "next_cursor": "MjAyNi0wNS0xM1QxMjowMHwxMjM=",
  "results": [
    {
      "id": 42,
      "type": "COMMISSION_DEBIT",
      "amount": "-200.00",
      "balance_after": "800.00",
      "timestamp": "2026-05-13T12:00:00Z",
      "memo": "",
      "ui_icon": "commission",
      "ui_title": "Platform commission",
      "ui_subtitle": "Booking #128",
      "ui_amount_color": "debit"
    }
  ]
}
```

`next_cursor` is `null` on the last page. The `ui_*` fields are shaped
server-side so the Flutter `TransactionRow` widget never branches on
`type`.

---

## Top-up flow

The tech tops up their wallet via JazzCash Hosted Checkout. End-to-end
sequence:

```
[Flutter]  POST /api/technicians/wallet/topups/   {amount: 1000}
           ← {topup_id, redirect_url}                  (our bridge URL)

[Flutter]  push WebView(redirect_url)
[WebView]  GET  /api/technicians/wallet/topups/<id>/bridge/?t=<signed>
           ← HTML: auto-submitting JazzCash form (or mock Pay/Decline)

[WebView]  POST <JazzCash hosted URL>                  (form auto-submit)
[JazzCash] customer enters mobile + CNIC + OTP + MPIN
[JazzCash] POST  /api/wallet/gateway/jazzcash/return/  (result fields)

[Backend]  verify pp_SecureHash → record_transaction → 200 + HTML
[WebView]  Flutter NavigationDelegate detects /return/ URL → pop
[Flutter]  poll GET /api/technicians/wallet/topups/<id>/ until terminal
```

The Return URL is BOTH the user-redirect AND the webhook — JazzCash
POSTs the browser to it with the authoritative result fields. There is
no separate IPN.

### `POST /api/technicians/wallet/topups/`

Start a Hosted Checkout top-up.

**Auth:** `IsAuthenticated` + technician profile required.

**Body:**

```json
{ "amount": 1000 }
```

Amount is whole rupees, **Rs.100 ≤ amount ≤ Rs.25,000**.

**Response 201:**

```json
{
  "topup_id": 42,
  "redirect_url": "https://api.example.com/api/technicians/wallet/topups/42/bridge/?t=<signed_token>"
}
```

The `redirect_url` is built from `SITE_URL` + the reversed
`wallet-topup-bridge` route + a `TimestampSigner`-signed token. The
Flutter app pushes it into a webview — do not interpret the URL,
just open it.

**Errors:**

| Status | Code | Notes |
|---|---|---|
| 400 | `validation_error` | Amount missing / non-integer / out of range. |
| 401 | (DRF default) | Missing/invalid JWT. |
| 403 | `permission_denied` | User has no technician profile. |
| 503 | `gateway_unavailable` | `DEFAULT_PAYMENT_GATEWAY=jazzcash` but one of the `JAZZCASH_*` env vars is empty. The adapter raises `ImproperlyConfigured` at construct time; the view maps it to 503 + envelope. |

### `GET /api/technicians/wallet/topups/<id>/`

Poll a topup's status. The Flutter `TopupNotifier` polls this every 2s
while the webview is open, max 15 attempts (30s budget).

**Auth:** `IsAuthenticated` + scoped to `request.user.tech_profile`. Tech
A receives 404 for tech B's topup.

**Response 200:**

```json
{
  "topup_id": 42,
  "status": "REDIRECTED",
  "amount": "1000.00",
  "gateway_name": "jazzcash",
  "initiated_at": "2026-05-14T10:00:00Z",
  "completed_at": null
}
```

`status` values: `PENDING / REDIRECTED / COMPLETED / FAILED / EXPIRED / ABANDONED`.

### `GET /api/technicians/wallet/topups/<id>/bridge/?t=<signed_token>`

**Internal — opened by the Flutter webview only.** Renders an HTML page
that auto-submits the JazzCash form (real gateway) OR shows manual
Pay/Decline buttons (mock gateway demo fallback).

**Auth:** none — the `t=` parameter is a `TimestampSigner`-signed token
bound to the topup id with a 5-minute TTL. Forged or expired tokens
return 400.

**Response 200:** HTML. The Flutter `NavigationDelegate` ignores the
content; it only cares that the URL loaded.

### `POST /api/wallet/gateway/jazzcash/return/`

**JazzCash → backend** callback. Always returns 200 with a small HTML
page (any non-200 triggers JazzCash retries). The gateway adapter's
`verify_topup` performs the security check via `pp_SecureHash`.

Mounted at the root URLconf (NOT under `/api/technicians/`) — this is
gateway-facing, not tech-facing.

**Auth:** none, CSRF-exempt. Security boundary is the SecureHash check
inside `apply_gateway_callback` + the idempotency guard on terminal
statuses (replay-safe).

---

## Environment variables

These come from the **JazzCash merchant onboarding pack**. Self-register
on the JazzCash sandbox merchant portal; the onboarding email lists
your Merchant ID, Password, Hashkey/Integrity Salt, **Sandbox URL**,
and Production URL. Paste into `backend/.env`:

```ini
# Switches the wallet to the real adapter. Default in core/settings.py
# is 'mock'; flip to 'jazzcash' once all five JAZZCASH_* creds below
# are filled in. Keep 'mock' for demo-day fallback (see below).
DEFAULT_PAYMENT_GATEWAY=jazzcash

# From the onboarding email — use EXACTLY the values JazzCash issued.
JAZZCASH_MERCHANT_ID=<your_merchant_id>
JAZZCASH_PASSWORD=<your_password>
JAZZCASH_INTEGRITY_SALT=<your_hashkey>
# The "Sandbox URL" the onboarding pack lists for HTTP POST Page
# Redirection / Hosted Checkout. Do not invent this — copy from the
# pack. (Sandbox + production URLs differ; production switch is a
# one-line env change.)
JAZZCASH_HOSTED_URL=<sandbox_url_from_onboarding_pack>
# Your own publicly-reachable URL that JazzCash will POST the result
# to. In local dev this is your ngrok / cloudflared tunnel + the path
# /api/wallet/gateway/jazzcash/return/.
JAZZCASH_RETURN_URL=https://<your-ngrok-host>/api/wallet/gateway/jazzcash/return/
JAZZCASH_TOPUP_TTL_MINUTES=15

# Public origin of this Django app — must match the host JazzCash can
# reach. In local dev this is your ngrok or cloudflared tunnel hostname.
SITE_URL=https://<your-ngrok-host>
```

If any of the five `JAZZCASH_*` credential vars is empty, instantiating
`JazzCashHostedGateway` raises `ImproperlyConfigured` at first use.
That includes test runs that override `DEFAULT_PAYMENT_GATEWAY=jazzcash`
— use `@override_settings` to provide test values.

### Local sandbox dev — webhook reachability

JazzCash sandbox cannot reach `localhost`. Choose one:

```bash
# Option 1: ngrok (free tier OK for dev)
ngrok http 8000
# → copy https URL into JAZZCASH_RETURN_URL and SITE_URL

# Option 2: cloudflared (free, stable hostname requires account)
cloudflared tunnel --url http://localhost:8000
```

Re-run `python manage.py runserver` after updating `.env`.

### Demo-day safety net

`DEFAULT_PAYMENT_GATEWAY=mock` runs the full webview flow against a
local "Mock JazzCash sandbox" bridge page (Pay / Decline buttons). No
JazzCash sandbox connectivity required. End-to-end fully testable —
the only difference is the bridge page UI.

---

## SecureHash algorithm

JazzCash's public sandbox docs do NOT publish the SecureHash
specification. The adapter uses the algorithm Pakistani fintech
integrator libraries converge on:

```
hash_input = IntegritySalt + "&" + "&".join(values_sorted_by_key)
pp_SecureHash = HMAC-SHA-256(key=IntegritySalt, msg=hash_input).hex().upper()
```

Where `values_sorted_by_key` are the non-empty `pp_*` field values
sorted alphabetically by key name, excluding `pp_SecureHash` itself.

Before flipping `DEFAULT_PAYMENT_GATEWAY=jazzcash` in any environment
that processes real money, **calibrate the algorithm against a verified
sandbox roundtrip**: trigger a top-up, observe JazzCash's response,
confirm our `verify_topup` accepts the inbound `pp_SecureHash`. If it
rejects with `hash_mismatch`, the algorithm needs adjustment (byte
order, field set, encoding) — recalibrate the
`test_jazzcash_hosted_gateway.py` test vector simultaneously.

---

## Realtime events

Every `record_transaction` call broadcasts a `wallet_balance_updated`
event via `transaction.on_commit`:

```json
{
  "balance": "1700.00",
  "transaction_id": 42,
  "transaction_type": "TOPUP_CREDIT"
}
```

Two Flutter notifiers consume it:

1. `TechnicianDashboardNotifier.onWalletBalanceEvent` — patches the
   dashboard wallet pill.
2. `WalletNotifier.onBalanceEvent` — patches the wallet screen balance
   card.

Both patch in-place without `AsyncLoading` flashes. Pipeline-level dedup
at `SystemEventNotifier`.

The transactions history list (`WalletTransactionsNotifier`) currently
shows new rows only after pull-to-refresh — see flag
`wallet-history-realtime-deferred`.
