# BOOKINGS API CONTRACT
**Project**: Home Services Marketplace App
**Status**: Living Documentation

---

## 1. INSTANT BOOKING

### 1.1 Create Instant Booking
**Description**: The checkout endpoint. Creates an `AWAITING` `JobBooking` after passing the defensive check pipeline: address ownership, technician approval status, catalog consistency, promo firewall, geofence, and an atomic race-condition lock on the technician's schedule. The booking transitions to `CONFIRMED` once the dispatched technician accepts within the SLA window (see §1.3); a tap to decline (§1.4) or an SLA-timeout flips it to `REJECTED`. The persisted `price_amount` is server-derived from the resolved catalog references — clients never put a price on the wire. Called immediately after the customer selects a time slot from the Availability endpoint (`/api/customers/technicians/{id}/availability/`).

**URL**: `/api/bookings/instant-book/`
**Method**: `POST`
**Auth**: Required (`IsAuthenticated`). Send token in the `Authorization: Token <token>` header.

---

#### Request Body (`application/json`)

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `technician_id` | int | **Yes** | Primary key of the `TechnicianProfile` to book. |
| `address_id` | int | **Yes** | Primary key of the `CustomerAddress` for the job location. Must belong to the authenticated user. |
| `service_id` | int | **Yes** | Parent `Service` the customer was browsing. Threaded through from the discovery URL (search match, gig tile, category tile, promo banner) — never user-typed. |
| `sub_service_id` | int | No | Specific `SubService` if the customer picked a fixed-price gig (Scenario A) or a labor gig via the search bar (Scenario B). Omit for category / inspection bookings (Scenario C). |
| `promotion_id` | int | No | Active `Promotion` the customer arrived with. Omit unless the customer reached this technician via a promo banner. **Forbidden** with a fixed-price `sub_service_id` (write-side promo firewall). |
| `scheduled_start` | string (ISO 8601) | **Yes** | Job start time. Must be a timezone-aware datetime (e.g., PKT `+05:00` from the slot's `iso_start` field). |
| `scheduled_end` | string (ISO 8601) | **Yes** | Job end time. Must be strictly after `scheduled_start`. Pass the slot's `iso_end` field directly. |

**Removed**: `price_context` and `price_amount` were previously ingress fields. The server now derives both the customer-receipt label and the persisted figure from the resolved catalog references + the technician's skill row; clients should stop sending either.

**Flutter integration note**: `scheduled_start` and `scheduled_end` should be taken directly from the `iso_start` / `iso_end` fields returned by the Availability endpoint — no timezone conversion needed. `service_id` / `sub_service_id` / `promotion_id` are the same query params Flutter already passes to `/profile/{id}/` and `/availability/{id}/` — thread them through into the booking POST body.

#### Sample Request — Scenario C (inspection)
```json
{
  "technician_id": 42,
  "address_id": 7,
  "service_id": 3,
  "scheduled_start": "2026-04-08T10:00:00+05:00",
  "scheduled_end": "2026-04-08T11:00:00+05:00"
}
```

#### Sample Request — Scenario A (fixed-price gig)
```json
{
  "technician_id": 42,
  "address_id": 7,
  "service_id": 3,
  "sub_service_id": 17,
  "scheduled_start": "2026-04-08T10:00:00+05:00",
  "scheduled_end": "2026-04-08T11:00:00+05:00"
}
```

#### Sample Request — Scenario D (promo on parent service)
```json
{
  "technician_id": 42,
  "address_id": 7,
  "service_id": 3,
  "promotion_id": 9,
  "scheduled_start": "2026-04-08T10:00:00+05:00",
  "scheduled_end": "2026-04-08T11:00:00+05:00"
}
```

---

#### Response Contract (201 Created)
```json
{
  "booking_id": 123
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `booking_id` | int | Primary key of the newly created `JobBooking`. Store this for the Active Job Screen and crash recovery (Tier 3 cache). |

---

#### Defensive Check Pipeline

The service runs these checks in strict order. The first failure short-circuits and returns the appropriate error — no check is skipped.

| # | Check | Implementation | Failure Response |
| :--- | :--- | :--- | :--- |
| 1 | **Address Ownership** | `CustomerAddress.objects.get(id=address_id, customer__user=request.user)` | 400 `validation_error` |
| 2 | **Technician Status** | `TechnicianProfile.objects.filter(status='APPROVED').get(pk=technician_id)` | 404 `not_found` |
| 3 | **Catalog Consistency** | `service`/`sub_service`/`promotion` resolve, `sub_service.service == service`, `promotion.target_service == service` | 400 `validation_error` |
| 4 | **Promo Firewall** | If `sub_service.is_fixed_price=True`, reject any `promotion_id` | 400 `validation_error` |
| 5 | **Geofence** | Haversine distance ≤ `tech.max_travel_radius_km` | 400 `out_of_service_area` |
| 6 | **Slot Race Lock** | `transaction.atomic()` + `select_for_update()` + overlap query | 409 `slot_unavailable` |

After step 4 the resolver derives the persisted `price_amount` deterministically (fixed-gig: `sub_service.base_price`; labor: `TechnicianSkill.labor_rate` or sub-service fallback; inspection: `service.base_inspection_fee`). The figure is stamped onto the row at creation — there's no separate validation step because no client value exists to validate.

**Why this order?** Address check is cheapest (single indexed lookup). Technician fetch is next. Catalog/promo checks come before geofence because they're pure-Python comparisons against already-loaded rows. The DB lock is last because acquiring it is the most expensive operation.

#### Geofence Detail
- Distance is calculated using the **Haversine formula** (great-circle distance).
- The cap is `tech.max_travel_radius_km` — set per-technician during onboarding.
- If the technician has no `base_latitude` / `base_longitude` set, the check always fails with `out_of_service_area`.
- The error message includes the actual distance and the technician's radius for Flutter to display (e.g., *"Your address is 14.2 km away (limit: 10 km)"*).

#### Race Condition Detail
- Uses `transaction.atomic()` + `SELECT FOR UPDATE` on the technician row to serialize concurrent booking attempts.
- Overlap check uses **half-open interval semantics**: `existing.scheduled_start < new.scheduled_end AND existing.scheduled_end > new.scheduled_start`. A booking starting exactly when another ends is **not** a conflict.
- Only `PENDING`, `AWAITING`, and `CONFIRMED` bookings block a slot. `CANCELLED`, `REJECTED`, and `COMPLETED` do not. (`AWAITING` is included because a dispatched-but-not-yet-accepted booking still reserves the technician's time window.)

---

#### Error Envelopes

All errors follow the standard envelope contract.

**401 — Unauthenticated**
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Unauthorized.",
  "errors": {}
}
```

**400 — Validation Error** (missing / invalid field)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid booking data.",
  "errors": {
    "scheduled_end": ["scheduled_end must be after scheduled_start."]
  }
}
```

**400 — Invalid Address** *(IDOR-safe: same response whether address doesn't exist or belongs to another user)*
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid address.",
  "errors": {
    "address_id": ["No matching address found for this account."]
  }
}
```

**404 — Technician Not Found** (non-existent, PENDING, or REJECTED)
```json
{
  "status": 404,
  "code": "not_found",
  "message": "Technician not found.",
  "errors": {}
}
```

**400 — Out of Service Area**
```json
{
  "status": 400,
  "code": "out_of_service_area",
  "message": "This technician does not service your area. Your address is 14.2 km away (limit: 10 km).",
  "errors": {}
}
```

**409 — Slot Unavailable** *(another customer booked this slot between your availability check and this request)*
```json
{
  "status": 409,
  "code": "slot_unavailable",
  "message": "This time slot was just booked. Please choose another.",
  "errors": {}
}
```

**400 — Inconsistent Booking Intent** *(catalog references in the body don't form a coherent triplet — sub-service's parent isn't `service_id`, or promotion targets a different service)*
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Inconsistent booking intent.",
  "errors": {
    "sub_service_id": ["Sub-service does not belong to the supplied service."]
  }
}
```

**400 — Promo Firewall** *(`promotion_id` paired with a fixed-price sub-service — discount stacking is forbidden)*
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Promotions cannot be applied to fixed-price gigs.",
  "errors": {
    "promotion_id": ["Discount stacking is not allowed on fixed-price sub-services."]
  }
}
```

---

#### Flutter Integration Guide

```
Availability Screen (Endpoint 1.4)
  ↓  customer taps a slot
  slot.iso_start → scheduled_start
  slot.iso_end   → scheduled_end

Checkout Screen
  ↓  customer confirms price + address
  POST /api/bookings/instant-book/
  
On 201 → store booking_id in Tier 3 cache (crash recovery)
       → navigate to Active Job Screen

On 409 → show "This slot was just taken" Snackbar
       → pop back to Availability Screen so customer can pick again

On 400 out_of_service_area → show error.message directly (already human-readable)
On 400 validation_error    → highlight error.errors fields in the form
On 404                     → show generic "Technician not available" and navigate back
```

---

### 1.2 Post-Booking Side Effects — Realtime Event + SLA Timer

When the four checks pass and the `JobBooking` row is **committed**, the service layer performs two side effects in a single `transaction.on_commit` callback:

1. **Broadcast** a `job_new_request` event to the assigned technician's WebSocket (and FCM, persisted to `EventLog`).
2. **Arm** an SLA-timeout Celery task that mutates booking state if the technician fails to acknowledge.

Neither side effect runs on any error path. A rolled-back transaction produces no phantom event, push, or queued timeout.

#### Wire envelope (technician socket)

```json
{
  "kind": "event",
  "id": "<uuid4>",
  "rawType": "job_new_request",
  "targetRole": "technician",
  "timestamp": "2026-04-27T20:14:42.000Z",
  "payload": {
    "job_id": 99482,
    "service_name": "AC Deep Wash",
    "booking_type": "FIXED_GIG",
    "scheduled_start_iso": "2026-04-08T05:00:00Z",
    "payout": "1200",
    "payout_context": "Fixed-price gig — full payout",
    "expires_in_seconds": 900,
    "ui_location_label": "Gulberg, Lahore"
  }
}
```

| Payload field | Type | Source |
| :--- | :--- | :--- |
| `job_id` | int | `JobBooking.id` |
| `service_name` | string | `JobBooking.sub_service.name` if set, else `JobBooking.service.name`. The more specific catalog name wins. |
| `booking_type` | string enum | One of `INSPECTION` / `FIXED_GIG` / `LABOR_GIG`. Derived from the FK shape: no sub_service → `INSPECTION`; sub_service with `is_fixed_price=True` → `FIXED_GIG`; sub_service with `is_fixed_price=False` → `LABOR_GIG`. The technician's app routes the on-site flow on this discriminator (Complete vs. Build Quote). |
| `scheduled_start_iso` | string (ISO-8601 UTC, `Z` suffix) | `JobBooking.scheduled_start` serialized verbatim. **Flutter formats** the locale-aware label — Dumb-UI principle, no server-side display strings on the wire. |
| `payout` | string (integer rupees) | `JobBooking.price_amount × 0.80`, rounded half-up to the nearest rupee, returned as a string for parse-fidelity on Flutter |
| `payout_context` | string | Short prose the technician card renders verbatim under the payout. One of three values keyed by `booking_type`: `"Inspection visit — quote built on-site"`, `"Fixed-price gig — full payout"`, `"Labor agreed up front"`. Prevents the reject-from-confusion failure mode where a Rs. 400 inspection fee looks indistinguishable from a Rs. 400 fixed gig. |
| `expires_in_seconds` | int | Two-tier dispatch SLA — see below |
| `ui_location_label` | string \| null | Pre-composed locality (e.g. `"Gulberg, Lahore"`) sourced from `JobBooking.address.locality_label` — populated client-side at address creation (session 4) and stored on `CustomerAddress`. Dumb-UI: technician's card renders the string verbatim and hides the row when null. Null on two paths: (a) the booking's `address` FK is SET_NULL (deleted address row), (b) the address pre-dates the locality columns and has not been backfilled. The full street address is never broadcast pre-accept (privacy + anti-poach). |

#### Commission rule (`payout`)

- `PLATFORM_COMMISSION_RATE = 0.20` → technician sees `price_amount × 0.80`.
- Returned as an integer string (e.g. `"1200"`), not a Decimal or float — keeps the wire format stable and avoids client-side float drift.

#### Two-tier dispatch SLA (`expires_in_seconds`)

Computed at broadcast time from `scheduled_start − timezone.now()`:

| Tier | Condition | `expires_in_seconds` (raw) |
| :--- | :--- | :--- |
| ASAP | `delta ≤ 2h` (incl. past — defensive against stale slots) | `60` |
| Scheduled | `delta > 2h` | `900` (15 min) |

**Hard wire floor**: every emitted `expires_in_seconds` is then `max(value, 300)` — a 5-minute minimum required by the technician swipe-to-accept UI (low-literacy user, budget Android, often holding tools or in transit). In practice the ASAP tier's raw `60` is lifted to `300` on the wire; the Scheduled tier's `900` is unchanged. Floor lives at the dispatch site (`bookings/services/job_request_dispatch.py::MIN_DISPATCH_SLA`); any future caller of the dispatch service or per-booking-type policy must respect it.

The same (post-floor) value is sent in the payload (so the technician's UI counts down in sync) **and** passed to `JobDispatchScheduler.schedule_sla_timeout(...)` as the Celery `countdown` — flooring once before both calls keeps the wire and the server-side SLA timer locked together. Drift would let `AWAITING → REJECTED` fire before the frontend's drain visually reaches zero, surfacing accept-just-past-expiry as a silent 409.

#### SLA timeout — DB state mutation

When the timer fires, `bookings.tasks.expire_pending_job_booking(booking_id)` runs under `SELECT FOR UPDATE` and:

| Booking state when task fires | Outcome |
| :--- | :--- |
| Booking not found | no-op |
| `status != AWAITING` | no-op (technician already accepted → CONFIRMED, or another path moved it through cancelled / completed / rejected) |
| `status == AWAITING` | `status = REJECTED`, persisted via `update_fields=["status"]` + `booking_rejected` event emitted to the customer on commit (see §1.4 below) |

The `AWAITING` status itself encodes the "still waiting on tech accept" signal — there is no side-field to read.

On a successful flip the task emits `booking_rejected` to the customer with `reason="sla_timeout"` via `transaction.on_commit`, reusing the same wire envelope the technician-decline arm uses with `reason="technician_declined"` (see §1.4). The task is idempotent — re-runs short-circuit on the non-AWAITING guard before mutating or emitting.

#### Architecture — Port and Adapter

The service layer never imports Celery. The wiring graph:

```
bookings/services/job_request_dispatch.py
        │  depends on Protocol
        ▼
bookings/services/ports.py            (Port)
        ▲  structurally implemented by
        │
bookings/adapters/celery_scheduler.py (Adapter — only file that imports the task)
        │  invokes
        ▼
bookings/tasks.py                     (@shared_task expire_pending_job_booking)
```

`bookings/adapters/__init__.get_default_scheduler()` resolves the production adapter via a **lazy import**, so `bookings.services.*` modules stay free of queue-library imports at top level. Tests pass a fake `JobDispatchScheduler` directly to `dispatch_job_new_request_event(...)`.

#### Failure isolation

| Failure | Effect |
| :--- | :--- |
| Channels / Redis down | Booking still committed; `EventLog` row still written; FCM still queued (best-effort barrels in `EventDispatchService`). |
| FCM broker down | Booking still committed; warning logged; in-app socket still receives the frame on reconnect via `GET /api/events/sync/`. |
| Celery broker down for SLA queue | Booking still committed; SLA simply will not auto-expire. The technician accept/decline flow is still authoritative; missing the timer cannot create double-bookings (existing bookings keep their slot lock). |

Cross-reference: realtime envelope + `EventDispatchService` semantics live in [`backend/realtime/api/EVENT_DISPATCH_API.md`](../../realtime/api/EVENT_DISPATCH_API.md).

---

### 1.3 Accept Job Booking

**URL** — `POST /api/bookings/<int:booking_id>/accept/`
**Auth** — JWT (`IsAuthenticated`). Anonymous → `401 unauthorized`.
**Body** — empty. The booking id rides the URL; the acting technician is taken from the authenticated user.

#### Success — `200 OK`

```json
{ "booking_id": 99482, "status": "CONFIRMED" }
```

The `status` string echoes the persisted column verbatim so the Flutter client can reuse the same constant as the rest of its booking model.

#### Errors (standard envelope)

| Status | `code` | When |
| :--- | :--- | :--- |
| `401` | `unauthorized` | Anonymous request — DRF default envelope. |
| `404` | `not_found` | Booking does not exist **OR** is assigned to a different technician. The two cases are deliberately collapsed (IDOR-safe — caller cannot enumerate other technicians' booking ids). A logged-in customer hitting this endpoint also receives `404`. |
| `409` | `booking_no_longer_available` | Booking has left `AWAITING` and the request is not the same-tech idempotent `CONFIRMED` repeat. The live row state is echoed back as `errors.current_status` for client-side debugging. |

```json
// 409 example — SLA fired before the technician's tap landed
{
  "status": 409,
  "code": "booking_no_longer_available",
  "message": "This job is no longer available.",
  "errors": { "current_status": ["REJECTED"] }
}
```

#### Idempotency

Re-calling accept on a booking that is **already `CONFIRMED` for the same technician** returns `200` with the same body and emits **no second** customer event. Protects against retries (network blip, double-tap, FCM-driven repeat tap).

#### Race semantics

The service runs inside `transaction.atomic()` + `select_for_update()`, serializing against:

| Concurrent path | Outcome on accept |
| :--- | :--- |
| SLA-timeout Celery task fires first | accept observes `status=REJECTED` → `409 booking_no_longer_available` (`current_status: REJECTED`) |
| Customer cancels first | `409` (`current_status: CANCELLED`) |
| Same-tech idempotent retry | `200` (no re-emit) |

The SLA Celery task is **not** explicitly revoked. Once status moves out of `AWAITING`, the task's existing idempotent guard (`status != AWAITING → no-op` in `bookings/tasks.py`) makes it a harmless no-op when it eventually fires. Adding a Port-level revoke would buy nothing functional and would couple the Port to a queue-library primitive.

#### Customer-facing event — `job_accepted`

On successful transition (not idempotent retry), the service registers a `transaction.on_commit` callback that broadcasts a `job_accepted` event to the booking's customer. A rolled-back transaction never produces a phantom event.

```json
{
  "kind": "event",
  "id": "<uuid4>",
  "rawType": "job_accepted",
  "targetRole": "customer",
  "timestamp": "2026-05-03T08:14:42.000Z",
  "recipient_user_id": 42,
  "expires_at": null,
  "payload": {
    "job_id": 99482,
    "technician_id": 17,
    "technician_display_name": "Ali Khan",
    "scheduled_start_iso": "2026-04-08T05:00:00Z",
    "service_name": "AC Deep Wash"
  }
}
```

| Payload field | Type | Source / notes |
| :--- | :--- | :--- |
| `job_id` | int | `JobBooking.id` |
| `technician_id` | int | `TechnicianProfile.id` (tech-profile id, not user id) — the customer's surface uses this to nav to the technician's profile. |
| `technician_display_name` | string | `user.get_full_name()`, falling back to `user.username` when both name fields are blank. |
| `scheduled_start_iso` | string (ISO-8601 UTC, `Z`) | Same wire format as `job_new_request`. |
| `service_name` | string | Sub-service name when set, else parent service — mirrors `job_new_request`. |

`expires_at` is `null` — `job_accepted` is informational, no SLA. `is_critical=false` in the registry (flipped at flag #25 close, mirroring `booking_rejected`): the customer doesn't need to ACK an informational confirmation, and `EventLog` persistence + `/api/events/sync/` replay cover the offline case. `display_name="Booking confirmed"` (was `"Job Accepted"`) — customer-facing string for the FCM tray push.

The customer-side Flutter surface (flag #25 close) is a `lowUrgency` `MaterialBanner` reading `"Booking confirmed — <technician_display_name> is on the way"`, tapping into the same `/customer/booking/:job_id` placeholder route that `booking_rejected` lands on. The rich detail screen is deferred (flag #26).

---

### 1.4 Decline Job Booking

**URL** — `POST /api/bookings/<int:booking_id>/decline/`
**Auth** — JWT (`IsAuthenticated`).
**Body** — empty.

#### Success — `200 OK`

```json
{ "booking_id": 99482, "status": "REJECTED" }
```

#### Errors

Identical envelope shape and codes as accept (`401` / `404` / `409`).

| `current_status` on 409 | Meaning |
| :--- | :--- |
| `CONFIRMED` | The technician already accepted this booking — declining after accept is not allowed. |
| `CANCELLED` | Customer cancelled before the decline landed. |
| `COMPLETED` / `PENDING` | Booking is in a state that cannot be declined. |

#### Idempotency

Re-calling decline on a booking that is **already `REJECTED`** returns `200`. This **also** covers the SLA-fired-first race: the technician's intent (decline) and the system's outcome (rejected) are the same end state, so reporting success is correct. No second event is emitted.

#### Customer-facing event — `booking_rejected`

On successful transition, the service emits `booking_rejected` to the customer via `transaction.on_commit`.

```json
{
  "rawType": "booking_rejected",
  "targetRole": "customer",
  "payload": {
    "job_id": 99482,
    "technician_id": 17,
    "scheduled_start_iso": "2026-04-08T05:00:00Z",
    "service_name": "AC Deep Wash",
    "reason": "technician_declined"
  }
}
```

`reason` discriminates the emit pathway:

| `reason` value | Emitter | Meaning |
| :--- | :--- | :--- |
| `technician_declined` | `bookings/services/job_request_action.py::decline_job_booking` | Assigned technician explicitly declined the offer. |
| `sla_timeout` | `bookings/tasks.py::expire_pending_job_booking` | Technician did not respond within the dispatch SLA window; the task flipped the row to `REJECTED`. |

Both arms route through the shared `_emit_booking_rejected(booking, reason=...)` helper so the wire envelope is identical — the customer-side surface is a single subscriber regardless of which pathway flipped the booking to `REJECTED`. Registry display name is `Booking unavailable`; `is_critical=false` (informational — `EventLog` persistence + sync-replay cover offline cases without the per-event ACK contract).

---

## 2. FRONTEND CONTRACT — flag #2 catalog-FK rollout

This section documents the cross-stack contract for the catalog-FK rollout. §2.1 and §2.2 describe behavior live on the Flutter checkout. §2.3–§2.6 describe technician-side work still pending — the on-site `bookingType` routing and `JobNewRequestPayload` model. Out of scope: any rename of `SystemEventNotifier`, any second WebSocket connection, any client-originated stream ingress (the realtime split owns those — see `REALTIME_STREAMS_PATCH_SUMMARY.md`).

### 2.1 Checkout request body — three new fields, two removed

The Flutter checkout screen builds the `POST /api/bookings/instant-book/` body as follows:

- **`service_id` (required).** Same value Flutter passes as `service_id` to `/profile/{id}/` and `/availability/{id}/` — carries the customer's discovery intent through.
- **`sub_service_id` (optional).** Sent when the customer reached this technician via a fixed-price gig tile (Scenario A) or a search-bar match against a specific sub-service (Scenario B). Omitted for parent-category clicks (Scenario C) and bare promo-banner clicks (Scenario D).
- **`promotion_id` (optional).** Sent only when the customer arrived via a promo banner. Never paired with a fixed-price `sub_service_id` — the server rejects that combination (write-side promo firewall), and Flutter blocks it client-side too via an assertion in `InstantBookingNotifier.book` to avoid a wasted round trip.
- **`price_context` is no longer sent.** The server derives the customer-receipt label (`"Inspection Fee"` / `"Fixed Price"` / `"Labor Fee"`) from the resolved catalog references. Flutter still reads `JobBooking.price_context` from any persisted booking response.
- **`price_amount` is no longer sent.** The server derives the figure from the resolved catalog references + the technician's skill row and stamps it onto the booking. Flutter still renders `TechnicianProfileEntity.primaryPrice` on the review sheet for the customer to confirm — that value comes from the same resolver, so display and persistence stay in sync.

The IDs Flutter sends are the ones the customer's discovery URL carried — never user-typed at the checkout screen. If the discovery context is lost (e.g., deep link with no IDs), Flutter defaults to category-only Scenario C: `service_id` derived from the technician's primary skill or a UI-level service picker.

### 2.2 Checkout error handling — two field-keyed validation errors

Both return HTTP 400 with `code: "validation_error"`. Flutter maps the field-level keys to user-facing toasts via this dictionary (server text is diagnostic-friendly, not user-friendly — Flutter never displays it raw):

| Error envelope `errors` key | Likely cause | Toast Flutter shows |
| :--- | :--- | :--- |
| `{ "sub_service_id": [...] }` | Stale Flutter cache: the discovery context combined a sub-service with the wrong parent service. | "This gig is no longer available. Refresh and try again." → pop back to discovery. |
| `{ "promotion_id": [...] }` (firewall) | Customer somehow has a promo applied to a fixed-price gig. | "This gig already has a fixed price — promotions don't apply." → pop back to gig screen with promo cleared. |

Implementation lives in `frontend/lib/features/booking/presentation/widgets/review_booking_sheet.dart` (`_resolveErrorPresentation`). The previous `price_amount` mismatch envelope was retired alongside the field itself — the server is now end-to-end authoritative on the figure, so a mismatch is impossible.

### 2.3 Technician job-card model — three new fields

The `job_new_request` payload (received over the WS event pipeline, also returned by `/api/events/sync/` on reconnect) now carries:

```dart
@freezed
class JobNewRequestPayload with _$JobNewRequestPayload {
  const factory JobNewRequestPayload({
    required int jobId,
    required String serviceName,
    required BookingType bookingType,           // added in earlier rollout
    required DateTime scheduledStartIso,
    required String payout,
    required String payoutContext,              // added in earlier rollout
    required int expiresInSeconds,
    required String? locationLabel,             // NEW — `ui_location_label`
  }) = _JobNewRequestPayload;
}

enum BookingType { inspection, fixedGig, laborGig }
```

`bookingType` and `payoutContext` are **always present** on freshly dispatched events. `locationLabel` is **always present** on the wire (the field is always sent, value may be null). Older `EventLog` rows replayed via `/api/events/sync/` predate these rollouts — defensive parsing should treat all three as optional on the deserialization model and fall back gracefully (see §2.5).

### 2.4 Technician on-site flow — route on `bookingType`

The job card's affordances differ per type. Recommended switch:

```dart
switch (payload.bookingType) {
  case BookingType.inspection:
    // After accept → navigate to address → "Build Quote" screen as the
    // primary completion path. payoutContext under the headline payout
    // tells the technician the Rs. 400 is the visit fee, not the whole job.
    break;
  case BookingType.fixedGig:
    // After accept → navigate to address → "Mark Complete" button as the
    // primary completion path. Optional "Add line item" affordance for
    // on-site upsell — the customer must approve before any extra work.
    break;
  case BookingType.laborGig:
    // Same shape as fixed gig at the start; the labor scope is pre-agreed.
    // Same optional "Add line item" upsell affordance.
    break;
}
```

Render `payoutContext` verbatim under the `payout` figure (Dumb-UI principle — server picks the prose, Flutter doesn't compose strings).

### 2.5 Backwards compatibility for replayed events

`EventLog` rows persisted before successive rollouts contain older payload shapes:
- Pre-`booking_type` rollout rows lack `booking_type` and `payout_context`.
- Pre-`ui_location_label` rollout rows additionally lack `ui_location_label`.

On reconnect, `/api/events/sync/` returns these alongside fresh ones.

Flutter's deserializer should:
- Treat `bookingType`, `payoutContext`, and `locationLabel` as **nullable** on the Freezed model.
- When `bookingType` is null, default the card to a neutral layout (treat as `LABOR_GIG`-style: Mark Complete + optional upsell) and hide the `payoutContext` line.
- When `locationLabel` is null, hide the address row entirely (no placeholder).
- Once historical `EventLog` rows have aged out (two acceptance-window cycles after each backend rollout), the corresponding fields can be tightened to required.

### 2.6 Frontend test coverage

- ✅ **Checkout request-body builder** — each of the four scenarios (A/B/C/D) produces the expected JSON; Scenario-A + promo combination is blocked at the Flutter layer too via a `book(...)` assertion. (`test/features/booking/data/models/booking_models_test.dart`, `test/features/booking/presentation/providers/booking_notifier_test.dart`)
- ✅ **400 error mapping** — each new field-level error key maps to the expected toast + navigation action. (`test/features/booking/data/repositories/booking_repository_impl_test.dart`, `test/features/booking/presentation/widgets/review_booking_sheet_test.dart`)
- ⏳ **`JobNewRequestPayload` deserialization** — parses fresh payloads (with `bookingType` / `payoutContext`) and replayed payloads (without) without throwing.
- ⏳ **Technician job-card widget** — snapshot one card per `BookingType` to lock the layout differences.

---

## 3. ORCHESTRATOR — PHASE MARKERS (TECH)

The orchestrator transitions from session 1 are exposed here as
HTTP endpoints. Every transition raises `BookingValidationError`
on a wrong-from-state, IDOR-mismatch, or missing-resource error;
the canonical envelope handler (`core.common.failures.exception`)
formats `{status, code, message, errors}`.

Every endpoint requires `Authorization: Token <token>`.

### 3.1 `POST /api/bookings/{booking_id}/start-inspection/`

Tech-only. `ARRIVED → INSPECTING`. Idempotent on already-INSPECTING.

**Body**: empty.

**Response (`200 OK`)**:
```json
{ "id": 123, "status": "INSPECTING", "inspection_started_at": "2026-05-08T10:23:45Z" }
```

**Errors**:
- `403 not_a_technician` — caller has no `tech_profile`.
- `403 not_assigned_to_you` — caller is not this booking's tech.
- `404 booking_not_found` — booking missing.
- `400 invalid_transition` — booking not in ARRIVED. `errors.current_status` echoes actual state.

### 3.2 `POST /api/bookings/{booking_id}/en-route/`

Tech-only manual override. `CONFIRMED → EN_ROUTE`. Same orchestrator
function the auto path (tech-location ingress) calls; `source='manual'` on
this path is informational only.

**Body**: empty.

**Response (`200 OK`)**:
```json
{ "id": 123, "status": "EN_ROUTE", "en_route_started_at": "2026-05-08T10:23:45Z" }
```

**Errors**: as 3.1, with `400 invalid_transition` when not in CONFIRMED.

### 3.3 `POST /api/bookings/{booking_id}/arrived/`

Tech-only manual override. `EN_ROUTE → ARRIVED`. Optional GPS coords
for the strict-mode geofence check.

**Body** (optional):
```json
{ "current_lat": 31.5204, "current_lng": 74.3587 }
```

**Response (`200 OK`)**:
```json
{ "id": 123, "status": "ARRIVED", "arrived_at": "2026-05-08T10:23:45Z" }
```

**Geofence**: when `BOOKING_GEOFENCE_STRICT=True` AND both coords are
supplied AND the Haversine distance to the customer's address exceeds
100m, the view rejects with `400 not_at_customer_location` and
`errors.current_lat = ["distance Nm exceeds 100m"]`. In lenient mode
(default) the same mismatch logs a warning but allows. The auto path
(`POST .../tech-location/`) is unaffected — it never auto-flips on a
mismatch regardless of the env flag.

---

## 4. ORCHESTRATOR — QUOTE FLOW

### 4.1 `POST /api/bookings/{booking_id}/quotes/`

Tech-only. Creates a new `Quote` with revision_number = max(prev) + 1
and one `QuoteLineItem` per body item. Recomputes total. On
`is_upsell=true` the booking stays in IN_PROGRESS; on `false` it flips
INSPECTING → QUOTED.

**Body**:
```json
{
  "is_upsell": false,
  "line_items": [
    { "sub_service_id": 17, "quantity": 1, "priced_at": "1500.00" }
  ]
}
```

**Response (`201 Created`)**:
```json
{
  "id": 56,
  "booking_id": 123,
  "revision_number": 1,
  "status": "SUBMITTED",
  "total_amount": "1500.00",
  "is_upsell": false,
  "line_items": [
    {
      "id": 88,
      "sub_service_id": 17,
      "sub_service_name": "AC compressor refill",
      "quantity": 1,
      "priced_at": "1500.00",
      "line_total": "1500.00"
    }
  ],
  "submitted_at": "2026-05-08T10:25:00Z"
}
```

**Errors**:
- `400 validation_error` — body shape invalid (DRF serializer level).
- `400 invalid_quote_empty` — empty `line_items` (orchestrator).
- `400 quote_band_violation` — fixed-price priced ≠ base, or labor priced outside [base, max]. `errors[f'line_items[{idx}].priced_at']` carries the actual band.
- `400 invalid_transition` — booking not in INSPECTING (regular) or IN_PROGRESS (upsell).
- `403 not_a_technician`, `403 not_assigned_to_you`.

Realtime: customer receives `quote_generated` with `total_amount` and `is_upsell`.

### 4.2 `POST /api/bookings/{booking_id}/quotes/{quote_id}/approve/`

Customer-only. `QUOTED → IN_PROGRESS` (regular) or no-op-on-status with
`BookingItem` rows appended (upsell). Stamps `final_cash_to_collect`
floor-at-0 = `base_services_total − inspection_fee`.

**Body**: empty.

**Response (`200 OK`)**:
```json
{ "booking_id": 123, "status": "IN_PROGRESS", "final_cash_to_collect": "1000.00" }
```

**Errors**:
- `400 invalid_transition` — quote isn't SUBMITTED, or upsell on non-IN_PROGRESS booking.
- `404 quote_not_found` — quote missing OR belongs to a different booking (IDOR-safe).
- `403 not_a_customer`.

Realtime: tech receives `quote_approved` with `is_upsell`, `total_amount` (this quote's), and `final_cash_to_collect` (cumulative — tech's cash button binds without re-fetch).

### 4.3 `POST /api/bookings/{booking_id}/quotes/{quote_id}/decline/`

Customer-only. `QUOTED → COMPLETED_INSPECTION_ONLY` (terminal). Sets
`final_cash_to_collect` = `inspection_fee` (Rs. 500 for INSPECTION-flow,
0 for fixed/labor-gig).

**Body**:
```json
{ "reason": "Quote was higher than expected." }
```

**Response (`200 OK`)**:
```json
{ "booking_id": 123, "status": "COMPLETED_INSPECTION_ONLY", "final_cash_to_collect": "500.00" }
```

**Errors**: as 4.2.

Realtime: tech receives `quote_declined` with `reason`.

### 4.4 `POST /api/bookings/{booking_id}/quotes/{quote_id}/request-revision/`

Customer-only. `QUOTED → INSPECTING`. The targeted quote becomes
SUPERSEDED; the tech can submit a fresh revision.

**Body**:
```json
{ "reason": "Can you skip line item 2 to bring the total down?" }
```

**Response (`200 OK`)**:
```json
{ "booking_id": 123, "status": "INSPECTING", "superseded_quote_id": 56 }
```

Realtime: tech receives `quote_revision_requested` with `quote_id` and `reason`.

---

## 5. ORCHESTRATOR — COMPLETION

### 5.1 `POST /api/bookings/{booking_id}/confirm-cash-received/`

Tech-only. Combined complete + cash collection. `IN_PROGRESS → COMPLETED`.

**Body**:
```json
{ "amount": "1500.00", "method": "cash" }
```

`method` only accepts `"cash"` for v1 (CLAUDE.md). Anything else gets
`400 invalid_input` with `errors.method` echoing the allowed list.

**Response (`200 OK`)**:
```json
{
  "id": 123,
  "status": "COMPLETED",
  "cash_collected_amount": "1500.00",
  "cash_collected_at": "2026-05-08T11:45:00Z",
  "cash_collection_method": "cash",
  "completed_at": "2026-05-08T11:45:00Z"
}
```

**Errors**:
- `400 invalid_input` — amount ≤ 0, unparseable decimal, or unsupported method.
- `400 invalid_transition` — booking not in IN_PROGRESS.
- `403 not_a_technician`, `403 not_assigned_to_you`, `404 booking_not_found`.

Realtime: customer receives `payment_received` then `job_completed`.

---

## 6. ORCHESTRATOR — TERMINATIONS

### 6.1 `POST /api/bookings/{booking_id}/cancel/` — customer

Customer-only. Maps phase → `cancel_reason` (`customer_cancelled_*`).
Disallowed in IN_PROGRESS — open a dispute instead.

**Response (`200 OK`)**:
```json
{ "id": 123, "status": "CANCELLED", "cancel_reason": "customer_cancelled_post_accept", "final_cash_to_collect": null }
```

**Errors**:
- `400 cancellation_not_allowed` — booking is IN_PROGRESS or terminal.
- `403 not_a_customer`, `403 not_assigned_to_you`, `404 booking_not_found`.

### 6.2 `POST /api/bookings/{booking_id}/tech-cancel/` — technician

Tech-only. Writes a `TechReliabilityIncident(TECH_CANCEL)` row.

**Body**: `{ "reason": "..." }` (optional, future use).

**Response (`200 OK`)**: `{ "id": 123, "status": "CANCELLED", "cancel_reason": "technician_cancelled" }`.

### 6.3 `POST /api/bookings/{booking_id}/no-show/`

Either party. Actor role is **derived from auth**, never from the body.

**Tech path** (auth user is the booking's tech):
- Allowed from {ARRIVED, INSPECTING, QUOTED}.
- 15-min wait clock anchored on `arrived_at`.

**Customer path** (auth user is the booking's customer):
- Allowed from {CONFIRMED, EN_ROUTE, ARRIVED}.
- 15-min wait clock anchored on `scheduled_start`.
- Writes a `TechReliabilityIncident(TECH_NO_SHOW)` row.

**Body**: empty.

**Response (`200 OK`)**:
```json
{ "id": 123, "status": "NO_SHOW", "no_show_actor": "tech", "no_show_at": "2026-05-08T10:45:00Z" }
```

**Errors**:
- `400 no_show_too_early` — wait clock not yet elapsed; `errors.wait_seconds` carries the remaining seconds.
- `400 invalid_transition` — booking not in an allowed from-state.
- `403 not_a_participant` — caller is neither customer nor tech.

Realtime: counterparty receives `booking_no_show` with `reported_by`.

### 6.4 `POST /api/bookings/{booking_id}/disputes/` — multipart

Either party. Optional photo evidence (≤ 5 MB).

**Body** (multipart):
- `initial_reason` — string, 10–2000 chars (required).
- `photo` — image file (optional).

**Response (`201 Created`)**:
```json
{ "ticket_id": 7, "booking_id": 123, "booking_status": "DISPUTED", "dispute_intake_method": "FORM" }
```

**Errors**:
- `400 dispute_not_disputable_status` — booking is pre-CONFIRMED.
- `403 not_assigned_to_you` — caller is neither party.
- Standard 400 envelope for missing `initial_reason` / oversize `photo`.

Realtime: counterparty receives `dispute_opened`.

### 6.5 `POST /api/bookings/{booking_id}/reschedule/` — customer

Customer-only. CANCELs the original (reason `customer_rescheduled`) and
creates a child `JobBooking(parent_booking=original, status=AWAITING)`.
The child is dispatched as a fresh job request via the existing
`dispatch_job_new_request_event`.

**Body**:
```json
{
  "new_scheduled_start": "2026-05-20T15:00:00+05:00",
  "new_scheduled_end":   "2026-05-20T17:00:00+05:00"
}
```

**Response (`201 Created`)**:
```json
{
  "original_booking_id": 123,
  "original_status": "CANCELLED",
  "child_booking_id": 124,
  "child_status": "AWAITING"
}
```

**Errors**:
- `400 reschedule_not_allowed` — original not in {AWAITING, CONFIRMED}, or new slot overlaps another booking on the same tech.
- `403 not_a_customer`, `404 booking_not_found`.

Realtime: tech receives `booking_rescheduled` with `new_booking_id` and `new_scheduled_start`. The dispatch service then fires `job_new_request` for the child with a fresh SLA.

---

## 7. GPS INGRESS + AUTO-TRANSITION

### 7.1 `POST /api/bookings/{booking_id}/tech-location/`

See [`STREAMS_TECH_GPS.md`](../../realtime/api/STREAMS_TECH_GPS.md) for
the full stream contract. Summary:

- Tech-only ingress.
- Throttled at 1 call per 4 seconds per (tech, booking).
- Publishes a `tech_gps` stream frame to `tracking_job_{id}`.
- Calls `auto_transition.evaluate_on_location` which may fire
  CONFIRMED → EN_ROUTE (>200m) or EN_ROUTE → ARRIVED (≤100m).
- Returns `{published, transition_fired}`.
- Terminal-status booking → silent no-op (returns 200, `published: false`).

---

## 8. BOOKING DETAIL (READ)

### 8.1 `GET /api/bookings/{booking_id}/`

Either participant. Composed payload for the orchestrator screen.

**No HTTP cache** (audit P1-04). Realtime events drive frontend
re-fetches; a stale 5-second cache would silently mask fresh state.

**URL convention for `ui.*.endpoint` strings.** Every `endpoint` value
in the `ui` block is a path **relative to `/api/`** — i.e. it starts at
`/bookings/...`, NOT `/api/bookings/...`. The frontend's
`BookingActionExecutor` prepends `AppConstants.baseUrl` (which already
includes the `/api` prefix) before dispatching, so embedding the prefix
in the response would produce `http://host/api/api/bookings/...` and
404 every action POST. Pinned by invariant tests in
`tests/bookings/selectors/test_orchestrator_ui_selector.py`.

**Customer quote-action endpoints interpolate the live `active_quote.id`.**
The `approve` / `decline` / `request-revision` endpoints in the QUOTED
state's `ui` block are emitted with the actual quote id substituted —
never a literal `<id>` placeholder. If `active_quote` is `None` (a
defensive case the orchestrator's submit-quote contract guarantees
never happens), the QUOTED state degrades to a "Quote details are
unavailable. Refresh in a moment." body with `tone: warning` and no
primary action, rather than 500ing.

**Response (`200 OK`)** — abbreviated:
```json
{
  "id": 123,
  "status": "QUOTED",
  "service": { "id": 3, "name": "AC Service", "icon_name": "ac_repair" },
  "sub_service": null,
  "technician": {
    "id": 42,
    "display_name": "Ali Raza",
    "profile_picture_url": "http://api.example.com/media/tech_profiles/42.jpg"
  },
  "customer": { "id": 9, "full_name": "Sara K.", "phone_no": "+923001234567" },
  "address": {
    "label": "Home",
    "latitude": "31.520400",
    "longitude": "74.358700",
    "address_text": "Apt 4B, Liberty Market"
  },
  "address_snapshot": "Apt 4B, Liberty Market — DHA Phase 5",
  "scheduled_start": "2026-05-08T10:00:00+05:00",
  "scheduled_end":   "2026-05-08T11:00:00+05:00",
  "phase_timestamps": { "accepted_at": "...", "en_route_started_at": "...", "...": "..." },
  "pricing": {
    "inspection_fee": "500.00",
    "base_services_total": "1500.00",
    "discount_applied": null,
    "final_cash_to_collect": "1000.00",
    "promo_code_snapshot": null,
    "promo_discount_snapshot": null
  },
  "cash_collection": { "amount": null, "at": null, "method": "cash" },
  "parent_booking_id": null,
  "child_booking_id": null,
  "cancel_reason": null,
  "no_show_actor": null,
  "active_quote": { "id": 56, "revision_number": 1, "status": "SUBMITTED", "...": "..." },
  "booking_items": [],
  "open_tickets_count": 0,
  "ui": {
    "status_label": "Quote ready",
    "body_text": "Review the quote and approve, decline, or ask for a revision.",
    "primary_action": { "label": "Approve quote", "endpoint": "/bookings/123/quotes/56/approve/", "method": "POST", "style": "primary" },
    "secondary_actions": [ { "...": "..." } ],
    "show_tracking": false,
    "show_quote_card": true,
    "show_dispute_button": false,
    "tone": "info"
  },
  "available_transitions": ["approve_quote", "decline_quote", "request_revision", "cancel_by_customer"]
}
```

**Selected field semantics**:

| Field | Type | Notes |
|---|---|---|
| `technician.profile_picture_url` | string \| null | Absolute URL (built via `request.build_absolute_uri(...)`) when the row has a picture; `null` otherwise. The Flutter `CachedNetworkImage` consumes the absolute URL directly with no client-side host concatenation. |
| `parent_booking_id` | int \| null | Reverse pointer — set on the *child* of a reschedule chain so the screen can render "Rescheduled from #N". |
| `child_booking_id` | int \| null | Forward pointer — set on the *cancelled original* of a reschedule chain (most-recent child wins; tolerates a chain longer than one). The orchestrator screen renders a "Continued on #N" callout and routes the link to the child. Without this, a customer who returns to the original via a stale FCM tap is stranded. Added in sprint v1, session 3. |
| `booking_items[]` | array | Snapshot of accepted quote line items. Wire shape: `{id, sub_service_id, sub_service_name, quantity, price_charged, line_total, sourced_quote_id}`. **Distinct from `active_quote.line_items[]`** — `BookingItem` has `price_charged` (locked at approval); `QuoteLineItem` has `priced_at` (locked at quote submission). The two diverge if the technician edits the quote post-submission and the customer approves the latest revision. |
| `open_tickets_count` | int | Count of non-resolved `SupportTicket` rows for this booking. Drives the "Open dispute" button suppression on the secondary-actions slot when ≥ 1. |

**Errors**:
- `403 not_a_participant` — caller is neither customer nor assigned tech.
- `404 booking_not_found`.

**Dumb-UI fields**:
- `ui.*` — all copy + button labels + slot toggles. The Flutter screen
  renders `ui` verbatim; never branches on `status` for copy.
- `available_transitions` — orchestrator function names that are valid
  *right now* for the viewer. Used to enable/disable action buttons.
  Stays in sync with the orchestrator's actual validity (test-enforced
  in `tests/bookings/selectors/test_transition_validator_selector.py`).
