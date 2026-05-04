# CUSTOMER BOOKINGS API CONTRACT
**Project**: Home Services Marketplace App
**Status**: Living Documentation
**Scope**: Customer-side "My Bookings" tab — paginated list + counts. The booking *detail* screen is a separate sprint (flag #26) and ships its own endpoint.

---

## 1. LIST CUSTOMER BOOKINGS

### 1.1 Description

The endpoint that powers the customer's **My Bookings** tab. Returns the authenticated customer's bookings as a paginated list, filtered by either a high-level **segment** (`upcoming` / `past`) or an explicit **status** csv. The list is realtime-mutable: the Flutter notifier re-fetches on tab open / pull-to-refresh, and patches individual items in place when `job_accepted` / `booking_rejected` events arrive over the WebSocket — so this endpoint never serves as a polling source.

The card-level wire shape is intentionally lighter than the (forthcoming) detail response: just the fields a `BookingCard` needs. Detail-screen-only fields (full address, sub-service description, status timeline, quote line items) live on `GET /api/bookings/<id>/` when that lands.

**URL** — `GET /api/bookings/`
**Auth** — JWT (`IsAuthenticated`). Anonymous → `401 unauthorized`.

---

### 1.2 Query Parameters

All optional. Sensible defaults bake into the selector.

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `segment` | string enum | `upcoming` | `upcoming` (status ∈ {AWAITING, CONFIRMED, PENDING} AND `scheduled_end >= now`) or `past` (terminal status OR aged-out scheduled_end). Dumb-UI shortcut sent by Flutter's segmented control. |
| `status` | csv string | — | Explicit status filter override: `AWAITING,CONFIRMED`. When set, ignores `segment`'s time-window predicate. Reserved for future filter-chip UIs. |
| `cursor` | opaque string | — | Token from the previous response's `next_cursor`. URL-safe base64 of `{ss, id}` — clients must treat as opaque. |
| `page_size` | int | 20 | Hard cap 50. Out-of-range values surface as `400 validation_error`. |
| `since` | string (ISO-8601) | — | `created_at__gte` filter for incremental sync. Reserved for future polling consumers; the v1 list notifier does not use it. |

**Sort order** — `upcoming` returns `scheduled_start ASC` (next-soonest first; the user opened the tab to find what's imminent). `past` returns `scheduled_start DESC` (most-recent first). Explicit `status` filter falls back to `scheduled_start DESC`.

**Why cursor and not page numbers?** The bookings list mutates in realtime — a tech accepts mid-scroll and a new `CONFIRMED` row slides in at the head. Page-based pagination would surface that row again on page 2. The cursor encodes the seek predicate `(scheduled_start, id) > (last_ss, last_id)` and is stable across inserts.

---

### 1.3 Sample Request

```
GET /api/bookings/?segment=upcoming&page_size=20
Authorization: Token <jwt>
```

```
GET /api/bookings/?segment=past&cursor=eyJzcyI6IjIwMjYtMDUtMDRUMDM6MDA6MDArMDA6MDAiLCJpZCI6OTk0ODJ9
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
      "technician": {
        "id": 17,
        "display_name": "Ahmed Khan",
        "profile_picture_url": "/media/tech_profiles/17.jpg"
      },
      "address_label": "Home — DHA Phase 5, Lahore",
      "scheduled_start": "2026-05-06T15:00:00+00:00",
      "scheduled_end":   "2026-05-06T17:00:00+00:00",
      "created_at":      "2026-05-05T09:12:00+00:00",
      "price": {
        "amount": 2500,
        "context": "Fixed Price",
        "ui_label": "Rs. 2,500"
      },
      "ui": {
        "badge_text": "Confirmed",
        "badge_tone": "positive",
        "headline":   "Confirmed with Ahmed Khan"
      }
    }
  ],
  "next_cursor": "eyJzcyI6IjIwMjYtMDUtMDZUMTU6MDA6MDArMDA6MDAiLCJpZCI6OTk0ODJ9",
  "has_more": true,
  "server_time": "2026-05-05T12:34:56+00:00"
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `items[]` | array | Page of booking cards. Empty when no rows match. |
| `items[].id` | int | `JobBooking.id` — primary key, used for detail navigation and event matching. |
| `items[].status` | string enum | `AWAITING` / `CONFIRMED` / `COMPLETED` / `CANCELLED` / `REJECTED` / `PENDING`. The Flutter event-patch mapper consumes this for status comparison; it never drives display copy. |
| `items[].service` | object | `{name, icon_name}`. `icon_name` keys into Flutter's `IconAssets.path()` — see CLAUDE.md catalog image design. |
| `items[].technician` | object | `{id, display_name, profile_picture_url}`. `display_name` is `user.get_full_name()` falling back to `username` — same fallback chain as the realtime payload. `profile_picture_url` may be null. |
| `items[].address_label` | string \| null | Composed `{label} — {locality_label}` one-liner. Null when the address FK is `SET_NULL` (deleted address row). The card hides the row when null. |
| `items[].scheduled_start` | string (ISO-8601) | UTC. **Flutter formats** the locale-aware date label — the server never sends pre-rendered date strings (timezone-dependent display is a client concern). |
| `items[].scheduled_end` | string (ISO-8601) | Same wire format as `scheduled_start`. |
| `items[].created_at` | string (ISO-8601) | Booking creation timestamp. |
| `items[].price.amount` | int (rupees) | `JobBooking.price_amount` truncated to int — for sort / math / analytics. |
| `items[].price.context` | string | `JobBooking.price_context` (e.g. `"Fixed Price"`, `"Labor Fee"`, `"Inspection Fee"`). Empty string when not set. |
| `items[].price.ui_label` | string | Pre-formatted Rs. label (e.g. `"Rs. 2,500"`). Comma grouping done once on the server — Dumb-UI principle. |
| `items[].ui.badge_text` | string | Status pill copy. See §1.7 for the canonical status → ui table. |
| `items[].ui.badge_tone` | string enum | `positive` / `warning` / `negative` / `neutral` / `info`. Flutter maps to design tokens. |
| `items[].ui.headline` | string | One-line subhead under the service name (e.g. `"Confirmed with Ahmed Khan"`). |
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

**400 — Validation Error** (page_size out of range, malformed `since`, etc.)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid query parameters.",
  "errors": {
    "page_size": ["Ensure this value is less than or equal to 50."]
  }
}
```

---

### 1.6 Realtime Patch Contract

The list does not poll. It is patched in place by the Flutter list notifier when a typed event arrives over WS:

| Event | Effect |
| :--- | :--- |
| `job_accepted` | Find item where `id == payload.job_id`. Flip `status` to `CONFIRMED`. Recompute `ui` block client-side from the same status → ui table this endpoint uses on the server (§1.7). |
| `booking_rejected` | Same lookup. Flip `status` to `REJECTED`. Use `payload.reason` (`technician_declined` or `sla_timeout`) to pick the headline copy. Item slides from Upcoming → Past on next render. |
| Event for unknown `job_id` | Notifier enqueues a background list re-fetch; the new row appears on next page render. |

The status → ui table is **mirrored** in `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` — when copy changes here, that file MUST change in lockstep. Drift surfaces as a flicker on event arrival (server says "Confirmed", client temporarily shows a different headline) — bounded but visible.

---

### 1.7 Canonical Status → UI Table

Both this endpoint and the Flutter event-patch mapper resolve the `ui` block from the table below. Single source of truth.

| `status` | Reason discriminator | `badge_text` | `badge_tone` | `headline` |
| :--- | :--- | :--- | :--- | :--- |
| `AWAITING` | — | "Awaiting tech" | `warning` | `"Waiting for {tech_name} to confirm"` |
| `CONFIRMED` | — | "Confirmed" | `positive` | `"Confirmed with {tech_name}"` |
| `COMPLETED` | — | "Completed" | `positive` | `"Completed by {tech_name}"` |
| `CANCELLED` | — | "Cancelled" | `neutral` | `"You cancelled this booking"` |
| `REJECTED` | `technician_declined` (or unknown) | "Unavailable" | `negative` | `"{tech_name} couldn't take this"` |
| `REJECTED` | `sla_timeout` | "Timed out" | `negative` | `"{tech_name} didn't respond in time"` |
| `PENDING` (legacy) | — | "Pending" | `neutral` | "Booking is being prepared" |

`{tech_name}` is `user.get_full_name()` falling back to `user.username`. Mirrors the realtime payload's `technician_display_name` resolution.

The `REJECTED` row queries the latest matching `EventLog` row for the booking and reads `payload.reason` to pick a sub-row. Rows with no log entry (legacy bookings predating `EventLog`) fall back to the `technician_declined` copy, the safest default.

---

## 2. BOOKINGS COUNTS

### 2.1 Description

Cheap aggregate counts for the segmented-control badges. Two `COUNT(*)` queries — no row materialization, no joins.

**URL** — `GET /api/bookings/counts/`
**Auth** — JWT (`IsAuthenticated`).
**Body** — none.

---

### 2.2 Response Contract — `200 OK`

```json
{
  "upcoming": 1,
  "past": 12,
  "server_time": "2026-05-05T12:34:56+00:00"
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `upcoming` | int | Count of bookings matching the same predicate as `?segment=upcoming` on the list endpoint. |
| `past` | int | Count of bookings matching `?segment=past`. |
| `server_time` | string (ISO-8601 UTC) | Server clock at response time. |

The two segments together do **not** necessarily sum to the customer's total bookings — `past` includes "still in `CONFIRMED` but `scheduled_end` is in the past" rows. This deliberately aligns with what the user expects to see in each tab.

---

### 2.3 Errors

Only `401 unauthorized`. The endpoint takes no parameters.

---

## 3. SECURITY NOTES

- **IDOR** — both endpoints scope every query to `JobBooking.objects.filter(customer=request.user)` inside the selector. Non-owned rows never enter the queryset, so no per-row permission check is required at the view layer.
- **Cursor opacity** — the cursor is a base64-encoded JSON `{ss, id}` tuple. Decoding errors raise `CursorDecodeError`, which the view maps to `400 invalid_cursor`. A tampered cursor cannot escalate to a different user's rows because the queryset is already user-scoped before the cursor predicate applies.
- **Rejection-reason lookup** — the `EventLog` query is also scoped to the current user, providing a belt-and-braces IDOR guard even though the booking queryset already constrained the `job_id` set.

---

## 4. FRONTEND INTEGRATION GUIDE

```
Customer taps "Bookings" tab in home shell
  ↓
SelectedSegmentNotifier defaults to "upcoming"
  ↓
CustomerBookingsListNotifier.build()
  - GET /api/bookings/?segment=upcoming
  - cache to SharedPreferences (network-first; cache only consulted on SocketException)
  - register ref.listen(systemEventProvider, ...) for jobAccepted/bookingRejected
  ↓
Pull-to-refresh → repeat
Scroll near bottom → loadMore() with next_cursor
Switch segment → re-build with segment=past

Realtime patch:
  job_accepted arrives
    → find item where id == payload.job_id
    → applyJobAccepted() recomputes ui block via mirrored mapper
    → emit new state

Boot:
  customerBookingsListProvider registered in realtimeBootHooksProvider
  bootAfterAuth() reads it BEFORE WS connect cascade fires
  (per CLAUDE.md list-route wakeup rule)
```

The list screen widget itself is not built in this sprint — only the data + domain + presentation/providers stack lands. The screen, segmented control, card widget, and tab onTap wiring follow in the next sprint.
