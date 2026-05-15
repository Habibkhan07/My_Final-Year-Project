# TECHNICIAN SCHEDULED JOBS API CONTRACT
**Project**: Home Services Marketplace App
**Status**: Living Documentation
**Scope**: Tech-side "Schedule" tab — paginated list + counts. Audience-flipped counterpart of `CUSTOMER_BOOKINGS_API.md`. Same cursor / segment / wire envelope; tech-framed copy and `customer` + `payout` blocks replace the customer's `technician` + `price` blocks.

---

## 1. LIST SCHEDULED JOBS

### 1.1 Description

The endpoint that powers the technician's **Schedule** tab. Returns the authenticated tech's bookings as a paginated list, filtered by either a high-level **segment** (`upcoming` / `past`) or an explicit **status** csv. The list is realtime-mutable: the Flutter notifier re-fetches on tab open / pull-to-refresh, and patches individual items in place when typed events arrive over WebSocket — so this endpoint never serves as a polling source.

The card-level wire shape is intentionally lighter than the (forthcoming) detail response: just the fields a tech-side `TechJobCard` needs. Detail-screen-only fields (full address, sub-service description, status timeline, quote line items, attached photos) live on `GET /api/bookings/<id>/` when that lands.

**URL** — `GET /api/technicians/me/scheduled-jobs/`
**Auth** — JWT (`IsAuthenticated`). Anonymous → `401 unauthorized`. Non-tech user (no `tech_profile`) → `403 permission_denied`.

---

### 1.2 Query Parameters

All optional. Sensible defaults bake into the selector.

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `segment` | string enum | `upcoming` | `upcoming` (active mid-job statuses OR ageable statuses where `scheduled_end >= now`) or `past` (terminal statuses OR aged-out ageable rows). |
| `status` | csv string | — | Explicit status filter override: `CONFIRMED,EN_ROUTE`. When set, ignores `segment`'s time-window predicate. Reserved for future filter-chip UIs. |
| `cursor` | opaque string | — | Token from the previous response's `next_cursor`. URL-safe base64 of `{ss, id}` — clients must treat as opaque. |
| `page_size` | int | 20 | Hard cap 50. Out-of-range values surface as `400 validation_error`. |
| `since` | string (ISO-8601) | — | `created_at__gte` filter for incremental sync. Reserved; the v1 list notifier does not use it. |

**Sort order** — `upcoming` returns `scheduled_start ASC` (next-soonest first; tech opened the tab to see what's coming). `past` returns `scheduled_start DESC` (most-recent first). Explicit `status` filter falls back to `scheduled_start DESC`.

**Why cursor and not page numbers?** The bookings list mutates in realtime. A customer cancels mid-scroll, a new booking gets routed in, the tech accepts an incoming job — page-based pagination would surface a moved row twice or skip a new one. The cursor encodes the seek predicate `(scheduled_start, id) > (last_ss, last_id)` and is stable across inserts.

**Segment semantics — what lives where:**

* **Upcoming** =
  * Active mid-job statuses (always, regardless of `scheduled_end`): `EN_ROUTE`, `ARRIVED`, `INSPECTING`, `QUOTED`, `IN_PROGRESS`. A job actively in progress is *still* a live job even if the originally scheduled window has elapsed.
  * Ageable statuses while `scheduled_end >= now`: `PENDING` (legacy), `AWAITING` (new request the tech hasn't acted on yet), `CONFIRMED` (accepted but not yet en-route).
* **Past** =
  * Terminal statuses: `COMPLETED`, `COMPLETED_INSPECTION_ONLY`, `CANCELLED`, `REJECTED`, `NO_SHOW`, `DISPUTED`.
  * Ageable statuses (`PENDING` / `AWAITING` / `CONFIRMED`) whose `scheduled_end < now` — i.e. the slot passed and the lifecycle stalled.

The two segments together do **not** necessarily sum to the technician's total bookings, by design — an ageable row at exactly `scheduled_end == now` is borderline; the predicate keeps it in Upcoming.

`AWAITING` showing up in a tech's Upcoming is rare and transient — the dispatcher's SLA timeout flips the row to `REJECTED` if the tech does not act in the window. It's included for completeness; if the tech sees one, it represents an action they owe.

---

### 1.3 Sample Request

```
GET /api/technicians/me/scheduled-jobs/?segment=upcoming&page_size=20
Authorization: Token <jwt>
```

```
GET /api/technicians/me/scheduled-jobs/?segment=past&cursor=eyJzcyI6IjIwMjYtMDUtMDRUMDM6MDA6MDArMDA6MDAiLCJpZCI6OTk0ODJ9
Authorization: Token <jwt>
```

---

### 1.4 Response Contract — `200 OK`

```json
{
  "items": [
    {
      "id": 99482,
      "status": "CONFIRMED",
      "service": {
        "name": "AC Repair",
        "icon_name": "ac_repair"
      },
      "customer": {
        "id": 4012,
        "display_name": "Sara Mahmood",
        "profile_picture_url": null
      },
      "address_label": "Home — DHA Phase 5, Lahore",
      "scheduled_start": "2026-05-16T15:00:00+00:00",
      "scheduled_end":   "2026-05-16T17:00:00+00:00",
      "created_at":      "2026-05-15T09:12:00+00:00",
      "payout": {
        "amount": 2000,
        "context": "Est. payout",
        "ui_label": "Rs. 2,000"
      },
      "ui": {
        "badge_text": "Confirmed",
        "badge_tone": "positive",
        "headline":   "Booked with Sara Mahmood"
      }
    }
  ],
  "next_cursor": "eyJzcyI6IjIwMjYtMDUtMTZUMTU6MDA6MDArMDA6MDAiLCJpZCI6OTk0ODJ9",
  "has_more": true,
  "server_time": "2026-05-15T12:34:56+00:00"
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `items[]` | array | Page of scheduled-job cards. Empty when no rows match. |
| `items[].id` | int | `JobBooking.id` — primary key, used for detail navigation and event matching. |
| `items[].status` | string enum | One of the full `JobBooking.STATUS_CHOICES` set. The Flutter event-patch mapper consumes this for status comparison; it never drives display copy. |
| `items[].service` | object | `{name, icon_name}`. `icon_name` keys into Flutter's `IconAssets.path()` — see CLAUDE.md catalog image design. |
| `items[].customer` | object | `{id, display_name, profile_picture_url}`. `display_name` is `user.get_full_name()` falling back to `username`. `profile_picture_url` is **always null in v1** — `CustomerProfile` does not yet expose a picture field; FE renders an initials avatar. |
| `items[].address_label` | string \| null | Composed `{label} — {locality_label}` one-liner — the **destination** for the tech. Falls back to the `actual_address_snapshot` if the address row was deleted. Null when neither source is populated; the card hides the row. |
| `items[].scheduled_start` | string (ISO-8601) | UTC. **Flutter formats** the locale-aware date label — the server never sends pre-rendered date strings (timezone-dependent display is a client concern). |
| `items[].scheduled_end` | string (ISO-8601) | Same wire format as `scheduled_start`. |
| `items[].created_at` | string (ISO-8601) | Booking creation timestamp. |
| `items[].payout.amount` | int (rupees) | Tech's net take-home for this booking. See §1.6. |
| `items[].payout.context` | string | Short qualifier — see §1.6 for the value table. Empty string suppresses the FE row. |
| `items[].payout.ui_label` | string | Pre-formatted Rs. label (e.g. `"Rs. 1,620"`). Comma grouping done once on the server — Dumb-UI principle. |
| `items[].ui.badge_text` | string | Status pill copy. See §1.8 for the canonical tech-framed status → ui table. |
| `items[].ui.badge_tone` | string enum | `positive` / `warning` / `negative` / `neutral` / `info`. Flutter maps to design tokens. |
| `items[].ui.headline` | string | One-line subhead under the service name, tech-POV (e.g. `"Booked with Sara Mahmood"`, `"You declined this job"`). |
| `next_cursor` | string \| null | Token to fetch the next page. Null when `has_more` is false. |
| `has_more` | bool | True when the underlying queryset has rows beyond this page. |
| `server_time` | string (ISO-8601 UTC) | Server clock at response time. The Flutter card uses it to anchor "Today / Tomorrow / In 30 min" formatting — avoids device-clock skew misrepresenting whether a booking is imminent. |

---

### 1.5 Error Envelopes (standard contract)

**401 — Unauthenticated**
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Unauthorized.",
  "errors": {}
}
```

**403 — Not a Technician**
```json
{
  "status": 403,
  "code": "permission_denied",
  "message": "User is not a registered technician.",
  "errors": {"user": ["Technician profile not found."]}
}
```

**400 — Invalid Status Filter**
```json
{
  "status": 400,
  "code": "invalid_status_filter",
  "message": "Invalid query parameters.",
  "errors": {
    "status": ["Unknown status value(s): WAITING."]
  }
}
```

**400 — Invalid Cursor** (malformed token)
```json
{
  "status": 400,
  "code": "invalid_cursor",
  "message": "Cursor is malformed.",
  "errors": {
    "cursor": ["Cursor is malformed."]
  }
}
```

**400 — Validation Error** (page_size out of range, malformed `since`, unknown segment)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid query parameters.",
  "errors": {
    "page_size": ["Ensure this value is between 1 and 50."]
  }
}
```

---

### 1.6 Payout Resolution Table

Tech-side payout is computed two-tier — authoritative for COMPLETED rows, projected for everything else.

| Status | Source | `payout.amount` | `payout.context` |
| :--- | :--- | :--- | :--- |
| `COMPLETED` (with `JobCommission`) | `JobCommission.payout_amount - commission_amount` (snapshotted, ledger-truth) | int net | `"After Rs. {commission} commission"` |
| `COMPLETED` (no `JobCommission` — seed/legacy only) | `price_amount * TECHNICIAN_NET_RATE` | int projected | `"Payout"` |
| `COMPLETED_INSPECTION_ONLY` | `JobBooking.inspection_fee` (tech kept the cash; no commission per `WalletFinanceAdapter`) | int fee | `"Inspection fee (cash)"` |
| `REJECTED` / `CANCELLED` / `NO_SHOW` / `DISPUTED` | `price_amount * TECHNICIAN_NET_RATE` | int projected | `"Forgone"` |
| Everything else (`AWAITING`, `CONFIRMED`, `EN_ROUTE`, …) | `price_amount * TECHNICIAN_NET_RATE` | int projected | `"Est. payout"` |

`TECHNICIAN_NET_RATE` is `1 - PLATFORM_COMMISSION_RATE`, sourced from `bookings.services.job_request_dispatch`. At time of writing the rate is 0.20, so net is 0.80.

**Why `JobCommission.payout_amount` is the gross customer bill, not the net:** the field is named for the value sent into `WalletFinanceAdapter.record_commission(amount=...)`, where `amount` is the cash collected from the customer. The net is `payout_amount - commission_amount`. This selector encapsulates the naming confusion at the boundary — no downstream caller needs to know.

---

### 1.7 Realtime Patch Contract

The list does not poll. It is patched in place by the Flutter list notifier when a typed event arrives over WS:

| Event | Effect |
| :--- | :--- |
| `job_accepted` | Find item where `id == payload.job_id` (i.e. the row this tech just accepted). Flip `status` to `CONFIRMED`. Recompute `ui` client-side from the mirrored status → ui table (§1.8). |
| `booking_rejected` | Same lookup. Flip `status` to `REJECTED`. Use `payload.reason` (`technician_declined` or `sla_timeout`) to pick the headline copy. Item slides from Upcoming → Past on next render. |
| `tech_en_route` / `tech_arrived` / status-flip events from the orchestrator | Re-fetch the row's status from the payload, recompute `ui`. The page is re-rendered; collapse-fade handles same-segment vs cross-segment moves. |
| Event for unknown `job_id` | Notifier enqueues a background list re-fetch; the new row appears on next page render. |

The status → ui table is **mirrored** in `frontend/lib/features/technician/schedule/data/mappers/scheduled_job_event_patch_mapper.dart` (to be written in the FE chunk) — when copy changes here, that file MUST change in lockstep. Drift surfaces as a flicker on event arrival.

---

### 1.8 Canonical Tech-framed Status → UI Table

Both this endpoint and the Flutter event-patch mapper resolve the `ui` block from the table below. Single source of truth.

| `status` | Reason discriminator | `badge_text` | `badge_tone` | `headline` |
| :--- | :--- | :--- | :--- | :--- |
| `AWAITING` | — | "New request" | `warning` | `"Tap to review — {customer_name}"` |
| `CONFIRMED` | — | "Confirmed" | `positive` | `"Booked with {customer_name}"` |
| `EN_ROUTE` | — | "On the way" | `info` | `"You're on the way to {customer_name}"` |
| `ARRIVED` | — | "Arrived" | `info` | "You've arrived at the address" |
| `INSPECTING` | — | "Inspecting" | `info` | "Preparing the quote" |
| `QUOTED` | — | "Quote sent" | `warning` | `"Awaiting {customer_name}'s review"` |
| `IN_PROGRESS` | — | "In progress" | `info` | "Working on the job" |
| `COMPLETED` | — | "Completed" | `positive` | `"Completed for {customer_name}"` |
| `COMPLETED_INSPECTION_ONLY` | — | "Inspection only" | `neutral` | "Customer declined the quote — inspection fee kept" |
| `CANCELLED` | `cancel_reason == 'technician_cancelled'` | "Cancelled" | `neutral` | "You cancelled this booking" |
| `CANCELLED` | `cancel_reason == 'customer_rescheduled'` | "Cancelled" | `neutral` | `"{customer_name} rescheduled"` |
| `CANCELLED` | `cancel_reason starts with 'customer_'` | "Cancelled" | `neutral` | `"{customer_name} cancelled"` |
| `CANCELLED` | unknown / missing | "Cancelled" | `neutral` | "Booking was cancelled" |
| `REJECTED` | `rejection_reason == 'sla_timeout'` | "Timed out" | `negative` | "You missed the response window" |
| `REJECTED` | `technician_declined` / unknown | "Declined" | `negative` | "You declined this job" |
| `NO_SHOW` | — | "No-show" | `negative` | "Customer wasn't there" |
| `DISPUTED` | — | "Disputed" | `negative` | "A dispute was opened on this booking" |
| `PENDING` (legacy) | — | "Pending" | `neutral` | "Booking is being prepared" |

`{customer_name}` is `user.get_full_name()` falling back to `user.username`. Mirrors the realtime payload's `customer_display_name` resolution.

The `REJECTED` row queries the latest matching `EventLog` row (`user=tech_user, target_role=TECHNICIAN, event_type=booking_rejected`) and reads `payload.reason`. Rows with no log entry fall back to the `technician_declined` copy, the safest default.

---

## 2. SCHEDULED JOBS COUNTS

### 2.1 Description

Cheap aggregate counts for the segmented-control badges. Two `COUNT(*)` queries — no row materialization, no joins.

**Earnings deliberately not surfaced here.** The Metrics tab (`/api/technicians/metrics/`) owns "how much have I earned" — period-bucketed gross revenue. The Wallet tab owns the net balance. The Schedule tab counts only **what jobs exist**; conflating the three surfaces would muddle their responsibilities (see CLAUDE.md `wallet-vs-metrics-separation` feedback memory).

**URL** — `GET /api/technicians/me/scheduled-jobs/counts/`
**Auth** — JWT (`IsAuthenticated`).
**Body** — none.

---

### 2.2 Response Contract — `200 OK`

```json
{
  "upcoming": 3,
  "past": 47,
  "server_time": "2026-05-15T12:34:56+00:00"
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `upcoming` | int | Count of bookings matching the same predicate as `?segment=upcoming` on the list endpoint. |
| `past` | int | Count of bookings matching `?segment=past`. |
| `server_time` | string (ISO-8601 UTC) | Server clock at response time. |

The two segments together do **not** necessarily sum to the technician's total bookings — see §1.2.

---

### 2.3 Errors

`401 unauthorized` (anonymous) or `403 permission_denied` (non-tech user). The endpoint takes no parameters.

---

## 3. SECURITY NOTES

- **IDOR** — both endpoints scope every query to `JobBooking.objects.filter(technician=request.user.tech_profile)` inside the selector. Non-owned rows never enter the queryset, so no per-row permission check is required at the view layer.
- **Non-tech access** — the view resolves `request.user.tech_profile` in a try/except. A logged-in customer (no `tech_profile`) sees `403 permission_denied`. Anonymous sees `401` from DRF's auth middleware before the view runs.
- **Cursor opacity** — the cursor is a base64-encoded JSON `{ss, id}` tuple. Decoding errors raise `CursorDecodeError`, which the view maps to `400 invalid_cursor`. A tampered cursor cannot escalate to a different tech's rows because the queryset is already tech-scoped before the cursor predicate applies.
- **Rejection-reason lookup** — the `EventLog` query is scoped to `user=tech_user, target_role=TECHNICIAN`, providing belt-and-braces IDOR even though the booking queryset already constrained the `job_id` set.

---

## 4. FRONTEND INTEGRATION GUIDE

```
Technician taps "Schedule" tab in bottom nav
  ↓
SelectedSegmentNotifier defaults to "upcoming"
  ↓
ScheduledJobsListNotifier.build()
  - GET /api/technicians/me/scheduled-jobs/?segment=upcoming
  - cache to SharedPreferences (network-first; cache only consulted on SocketException)
  - register ref.listen(systemEventProvider, ...) for jobAccepted /
    bookingRejected / techEnRoute / techArrived / inspectionStarted /
    quoteGenerated / jobCompleted etc.
  ↓
Pull-to-refresh → repeat
Scroll near bottom → loadMore() with next_cursor
Switch segment → re-build with segment=past

Realtime patch:
  job_accepted arrives for this tech
    → find item where id == payload.job_id
    → applyJobAccepted() recomputes ui via mirrored mapper
    → emit new state
  booking_rejected (sla_timeout) arrives
    → mapper picks the timed-out headline

Day grouping (Upcoming tab only):
  - Group items by date in tech's local time, anchored to server_time
    + monotonic stopwatch (avoids clock-skew bugs).
  - Sticky-ish inline group headers:
      "Today" / "Tomorrow" / weekday name for ≤ 7 days out / "Fri 23 May"
      for further out.

Boot:
  scheduledJobsListProvider registered in realtimeBootHooksProvider
  bootAfterAuth() reads it BEFORE WS connect cascade fires
  (per CLAUDE.md list-route wakeup rule)
```

The list screen widget, segmented control, card widget, and tab `onTap` wiring follow in the FE sprint — this contract doc lands with the backend and is the source-of-truth the FE consumes against.
