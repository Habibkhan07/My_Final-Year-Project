# Realtime Events — `job_new_request` Backend Patch & Frontend Sync Brief

> ⚠️ **Snapshot — 2026-04-27 patch.** This is a frozen handoff brief, not a living doc. It is superseded where it conflicts with current source-of-truth docs (`backend/bookings/api/BOOKINGS_API.md`, `backend/realtime/api/EVENT_DISPATCH_API.md`, `frontend/lib/features/booking/BOOKING_FEATURE.md`). Trust those over this file.
>
> **Known stale references after flag #1 closed (2026-05-01):**
> - The `accepted_at` column has been removed; the booking lifecycle now uses an explicit `AWAITING` status. The SLA timer flips `AWAITING → REJECTED` (was: flipped `CONFIRMED → REJECTED` iff `accepted_at IS NULL`).
> - §5 (SLA timer), §6 (technician-acceptance hole), and §10 (source-of-truth file index) reference `accepted_at` and migration `0004_jobbooking_accepted_at.py` — read those sections for historical context only.
> - For local end-to-end testing: simulate acceptance by flipping `JobBooking.status` from `AWAITING` to `CONFIRMED` via Django Admin / shell (was: setting `accepted_at = timezone.now()`).
>
> **Purpose.** Handoff document for the backend changes shipped in the
> instant-book → technician event-dispatch patch (2026-04-27). Read this
> before touching `frontend/lib/core/realtime/` or the technician's
> "incoming job request" feature.
>
> **Companion docs:**
> - `REALTIME_STREAMS_PATCH_SUMMARY.md` — the streams pipeline brief that mirrors this one.
> - `backend/realtime/api/EVENT_DISPATCH_API.md` — event-envelope and dispatcher contract.
> - `backend/bookings/api/BOOKINGS_API.md` — full booking API + the post-booking side-effects section.
> - `flag.md` — accepted shortcuts (both `accepted_at` and `service_name = price_context` are now ✅ resolved; see flag.md for the closure notes).

---

## 1. What this patch does

When a customer finalizes a booking via `POST /api/bookings/instant-book/` and the four defensive checks pass, the backend now **fans a `job_new_request` event** to the assigned technician (WebSocket + FCM fallback) and **arms an SLA timeout** that mutates booking state if the technician fails to acknowledge.

Both side effects fire **after** the DB transaction commits — a rolled-back booking produces no phantom event, no phantom push, no phantom queued task.

---

## 2. Naming change (breaking — sync this first)

The event-type registry constant was **renamed**:

| Before                     | After                       |
| :--- | :--- |
| `EventType.JOB_DISPATCHED` | `EventType.JOB_NEW_REQUEST` |
| `"job_dispatched"`         | `"job_new_request"`         |

**Frontend impact.** The Flutter `WsFrameDispatcher` route key for this event is now `"job_new_request"`, not `"job_dispatched"`. There are **no `job_dispatched` references left in the backend** (audited; rename is full-coverage including factories and tests).

`is_critical: True`, `display_name: "New Job Available"` — both unchanged.

---

## 3. The wire envelope

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
    "scheduled_start_iso": "2026-04-08T05:00:00Z",
    "payout": "1200",
    "expires_in_seconds": 900
  }
}
```

### Payload field table

| Field | Type | Notes for frontend |
| :--- | :--- | :--- |
| `job_id` | int | `JobBooking.id`. Use as the cache key for the incoming-request screen. |
| `service_name` | string | Display label. **Known debt** (`flag.md` item 2) — currently sourced from `price_context`, may read like `"AC Repair — 2 hrs"` until the `JobBooking ↔ SubService` M2M is in. Render as-is. |
| `scheduled_start_iso` | string (ISO-8601 UTC, `Z` suffix) | **Flutter formats this**. The backend deliberately does not pre-format the day/time — Dumb-UI principle. Convert to PKT (`Asia/Karachi`) on render. |
| `payout` | string | Integer rupees, e.g. `"1200"`. Already net of the 20% platform commission. Render verbatim. |
| `expires_in_seconds` | int | Countdown for the technician's accept/decline UI. Drive the timer from this — do **not** recompute from another field, it would desync from the server-side SLA timer (see §5). |

---

## 4. Why `scheduled_start_iso` (and not `scheduled_time_ui`)

An earlier draft of this patch sent a pre-formatted display string (`"Tomorrow • 10:00 AM"`). That violated the **Dumb-UI principle** in `CLAUDE.md` and the event-envelope rule in `EVENT_DISPATCH_API.md` ("the envelope intentionally contains no UI strings"). Final shape sends raw ISO; Flutter renders.

**Frontend formatter contract suggestion:**
- Today (PKT) → `"Today • h:mm a"`
- Tomorrow (PKT) → `"Tomorrow • h:mm a"`
- Otherwise → `"EEE, MMM d • h:mm a"` (e.g. `"Mon, May 04 • 10:00 AM"`)

This matches the format the backend was rendering before the rule alignment, so existing mocks/Figma still apply.

---

## 5. The SLA timer (server-side, you don't drive it)

`expires_in_seconds` is also the Celery countdown for `bookings.tasks.expire_pending_job_booking`. Two-tier rule (server-authoritative):

| Tier | Condition | Value |
| :--- | :--- | :--- |
| ASAP | `scheduled_start − now ≤ 2h` (incl. past — defensive) | `60` |
| Scheduled | `scheduled_start − now > 2h` | `900` (15 min) |

When the timer fires, the backend flips `JobBooking.status` from `CONFIRMED` to `REJECTED` **iff** `accepted_at IS NULL`. The task is idempotent (re-fetch under `select_for_update`, four guard branches, all tested).

**Frontend implication.** When the technician's countdown hits zero, do **not** assume the booking is expired client-side. The booking state is owned by the server. Either:
- Wait for the next backend event signaling expiry (not yet wired — see §7), or
- Re-fetch the booking on countdown completion.

---

## 6. The technician-acceptance hole (deliberate)

The technician-acceptance endpoint (which sets `accepted_at = timezone.now()` and presumably emits a `job_accepted` customer-side event) is **not in this patch**. Until that lands:

- Every dispatched booking's SLA timer will fire and flip status to `REJECTED`.
- For local end-to-end testing, set `accepted_at` directly via Django Admin or a shell mutation to simulate acceptance.

This is why we added `accepted_at` as a side field rather than a status enum — see `flag.md` item 1 for the proper refactor.

---

## 7. What the frontend session needs to do

1. **Update the WsFrameDispatcher route key** from `"job_dispatched"` → `"job_new_request"` (if it was wired previously).
2. **Define the Freezed payload model** to match §3, e.g.:
   ```dart
   @freezed
   class JobNewRequestPayload with _$JobNewRequestPayload {
     const factory JobNewRequestPayload({
       required int jobId,
       required String serviceName,
       required DateTime scheduledStartIso,  // parse the ISO string
       required String payout,
       required int expiresInSeconds,
     }) = _JobNewRequestPayload;
   }
   ```
3. **Build the incoming-request screen** with a countdown driven by `expiresInSeconds`. On expiry, re-fetch the booking rather than assume client-side state.
4. **Format `scheduledStartIso` per §4** — locale-aware in `Asia/Karachi`.
5. **Add the feature doc** (`<FEATURE>_FEATURE.md`) per `CLAUDE.md:208`.
6. **Consume the `service_name` as-is** (don't try to re-derive it). The label may carry pricing context until the M2M lands; that is intentional and tracked in `flag.md`.

---

## 8. Failure isolation (what the frontend can rely on)

| Backend failure mode | Frontend symptom |
| :--- | :--- |
| Channels / Redis down | Booking still committed. Event reaches the technician on next reconnect via `GET /api/events/sync/?since=<...>`. |
| FCM broker down | In-app socket still works. No system tray push for offline technicians until the broker recovers. |
| Celery broker down | Booking still committed. SLA simply does not auto-expire (technician can still accept manually); no double-bookings — the slot lock in `JobBooking` overlap check is authoritative. |

All three failure modes are covered by narrow try/except barrels in `EventDispatchService` — none of them propagate to the customer-facing `POST /api/bookings/instant-book/` response.

---

## 9. Test coverage shipped with this patch

| File | Cases |
| :--- | :--- |
| `tests/bookings/services/test_job_request_dispatch.py` | 20 |
| `tests/bookings/services/test_tasks.py` | 9 |
| `tests/bookings/services/test_instant_book_service.py` (extension) | 5 (on-commit dispatch class) |
| `tests/bookings/api/test_instant_book_api.py` (extension) | 5 (view-side dispatch class) |
| `tests/bookings/adapters/test_celery_scheduler.py` | 3 |

Total: 42 new cases. All `EventDispatchService` and `apply_async` calls are mocked — no real network or broker traffic in CI.

---

## 10. Source-of-truth file index

```
backend/bookings/
  models.py                              # JobBooking + accepted_at field
  tasks.py                               # @shared_task expire_pending_job_booking
  api/BOOKINGS_API.md                    # endpoint contract incl. side effects
  services/
    instant_book_service.py              # registers transaction.on_commit(...)
    job_request_dispatch.py              # builds payload, broadcasts, arms SLA
    ports.py                             # JobDispatchScheduler Protocol
  adapters/
    __init__.py                          # get_default_scheduler() (lazy import)
    celery_scheduler.py                  # CelerySchedulerAdapter
  migrations/
    0004_jobbooking_accepted_at.py
backend/realtime/constants/event_types.py  # JOB_NEW_REQUEST registry entry
flag.md                                    # known debt (read before refactor)
CLAUDE.md                                  # Async Tasks Port/Adapter pattern (mandatory)
```
