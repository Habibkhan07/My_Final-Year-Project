# Booking Orchestrator Sprint — v1

> Sprint meta-document. This is the canonical source of truth for cross-session architectural decisions. Lives at `booking_orchestrator_sprint/BOOKING_ORCHESTRATOR_SPRINT.md` alongside this sprint's six session files (`session_1_*.md` … `session_6_*.md`). Each session file references this document in its **Sprint context** preamble instead of restating the same decisions six times.
>
> **This is v1.** Polish, iOS push, AI chatbot intake, full background geolocation, reviews, and the wallet/JazzCash sprint are deferred to future sprints (see §23). flags are opened/closed accordingly.

---

## Table of contents

- [§1 Sprint goal](#1-sprint-goal)
- [§2 Source-of-truth precedence](#2-source-of-truth-precedence-this-sprint-only)
- [§3 Mandatory pre-reads](#3-mandatory-pre-reads)
- [§4 Architectural decisions (the 16)](#4-architectural-decisions-the-16)
- [§5 Status enum and transition table](#5-status-enum-and-transition-table)
- [§6 Quote schema (Quote, QuoteLineItem, BookingItem)](#6-quote-schema-quote-quotelineitem-bookingitem)
- [§7 Cancellation policy](#7-cancellation-policy)
- [§8 No-show policy](#8-no-show-policy)
- [§9 Finance ports (the deferred-finance seam)](#9-finance-ports-the-deferred-finance-seam)
- [§10 Tracking architecture](#10-tracking-architecture)
- [§11 AI Chatbot — stub with seam](#11-ai-chatbot--stub-with-seam)
- [§12 parent_booking_id semantics (reschedule chain)](#12-parent_booking_id-semantics-reschedule-chain)
- [§13 Maps stack (dual provider)](#13-maps-stack-dual-provider)
- [§14 Tech-side UX simplification](#14-tech-side-ux-simplification)
- [§15 Edge case resolutions (the 15)](#15-edge-case-resolutions-the-15)
- [§16 New events + new stream types](#16-new-events--new-stream-types)
- [§17 New columns on existing models](#17-new-columns-on-existing-models)
- [§18 New models](#18-new-models)
- [§19 Six-session breakdown](#19-six-session-breakdown)
- [§20 Per-session flag.md transitions](#20-per-session-flagmd-transitions)
- [§21 Sprint Definition of Done](#21-sprint-definition-of-done)
- [§22 Anti-patterns (do not do)](#22-anti-patterns-do-not-do)
- [§23 What this sprint does NOT include](#23-what-this-sprint-does-not-include)
- [§24 Frontend transport layer (canonical http pattern)](#24-frontend-transport-layer-canonical-http-pattern)
- [§25 Audit cycle 1 resolutions](#25-audit-cycle-1-resolutions)

---

## §1 Sprint goal

Ship a production-grade booking orchestrator covering the full lifecycle from booking creation through cash settlement, including live tracking, multi-revision quoting with face-to-face bargain support, cancellation, no-show, and form-based dispute opening. The orchestrator is one Flutter screen (`BookingOrchestratorScreen`) driven by server-emitted UI hints, one backend service (`bookings/services/orchestrator.py`) that owns every status transition, and a uniform realtime/stream pipeline.

End at finance's doorstep. Wallet, commission deduction, JazzCash top-up, and audit-grade ledger writes are the **next** sprint. Every place finance will touch the orchestrator is a `Protocol` port with a null adapter that no-ops; finance sprint plugs in real adapters without revisiting orchestrator code.

---

## §2 Source-of-truth precedence (this sprint only)

When two sources disagree, follow this order:

1. **CLAUDE.md** — non-negotiable architectural rules (Riverpod patterns, error pipeline, dumb-UI principle, per-event feature wiring, port-and-adapter for Celery, etc.).
2. **Existing shipped code** — if a pattern is already in production (e.g. shared `/ws/events/` socket, `EventDispatchService.broadcast_event`, `publish_stream`), extend it rather than replace it.
3. **This sprint document** — for cross-cutting decisions specific to the booking orchestrator.
4. **Per-session `session_N_*.md`** — for session-local decisions (file paths, design tokens, animation timing).
5. **The thesis (`main.pdf`, Chapter 3)** — reference-only. Has known errors. Use for big-picture intent (multi-phase lifecycle shape, JobCommission per-job ledger model, JazzCash webhook signature verification, GPS 5s tick, dispute → ticket → admin verdict). Do **not** defend implementation choices on grounds of "matching the thesis"; thesis can be revised post-sprint if the divergence matters academically.

Known thesis divergences in this sprint:
- `CustomerProfile` 1:1 User → using `User` directly per CLAUDE.md unified-user principle.
- 5-status enum → using granular ~13-status enum with phase timestamps (§5).
- `BookingItem`-only quote model → using `Quote` + `QuoteLineItem` (working/revisions) + `BookingItem` (final approved snapshot, matches thesis at the snapshot stage).
- Separate `/ws/tracking/{job_id}/` socket → reusing shared `/ws/events/` with a dynamic job-scoped channel-layer subgroup (§10).

---

## §3 Mandatory pre-reads

Read these before opening any session file. Reading order matters.

1. `CLAUDE.md` — full file. Especially: realtime pipeline, per-event feature wiring, Async Tasks (Celery) port-and-adapter, error propagation pipeline.
2. `flag.md` — current open flags (especially #5, #8, #10, #15, #16, #18, #21, #23, #24, #26).
3. `backend/bookings/api/BOOKINGS_API.md` — existing endpoint contracts.
4. `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` — customer list contract + status→ui resolver.
5. `backend/realtime/api/EVENT_DISPATCH_API.md` — event envelope + ACK contract.
6. `backend/realtime/api/STREAM_DISPATCH_API.md` — stream envelope contract.
7. `frontend/lib/features/technician/incoming_job_requests/INCOMING_JOB_REQUESTS_FEATURE.md` — canonical per-event feature reference impl.
8. `session_4_customer_bookings_list_ui.md` — voice and elaboration level for orchestrator-screen sessions.

---

## §4 Architectural decisions (the 16)

Locked. Each links to its detail section.

| # | Decision | Section |
|---|---|---|
| 1 | Granular status enum (~13 values) with phase timestamps | §5 |
| 2 | Quote model: `Quote` + `QuoteLineItem` (revisable) + `BookingItem` (final snapshot) | §6 |
| 3 | Cancellation policy: 4-bucket (pre-accept free / post-accept-pre-arrival Rs.500 / post-arrival Rs.500 / tech-cancel reliability penalty) | §7 |
| 4 | No-show: manual on either side; auto-detection deferred | §8 |
| 5 | Finance ports + null adapter; real adapters next sprint | §9 |
| 6 | Tracking on shared `/ws/events/` with dynamic job-scoped subgroup, 5s tick | §10 |
| 7 | Tech GPS broadcast via Android **foreground service** (iOS deferred per flag #10) | §10 |
| 8 | AI Chatbot stub-with-seam: form-intake this sprint, schema designed for chatbot adapter | §11 |
| 9 | `parent_booking_id` for reschedule chain (child on reschedule, parent → CANCELLED) | §12 |
| 10 | Maps dual-provider: Google for prod, OSM (existing) for dev/test, swappable adapter | §13 |
| 11 | Cash collection: tech taps "Cash Collected: Rs.X" → stamps booking columns + fires `payment_received`; null adapter for finance | §9, §17 |
| 12 | Promotion snapshotted onto `JobBooking` (`promo_code_snapshot`, `promo_discount_snapshot`) | §17 |
| 13 | `SubService.max_price` added; labor-line band = `[base_price, max_price]`; fixed-price `max_price` is null | §6, §17 |
| 14 | Skip `CustomerProfile` model; use `User` directly | §2 |
| 15 | Booking-type adaptation via server-emitted `available_transitions` array; UI never hardcodes booking-type lifecycle | §5 |
| 16 | **Tech-side UX simplification** (8 rules: auto-transitions where geofence permits, single-tap cash collection, chip-stack quote builder, automatic bargain navigation, customer-only dispute/reschedule, overflow tech-cancel, single-tap no-show, one-card-at-a-time) | §14 |

---

## §5 Status enum and transition table

The orchestrator screen is a status-driven slot machine. Every status maps deterministically to one configuration of header / timeline / body / primary action / secondary action via server-emitted `ui.*` fields. The frontend never branches on status to compute copy or button labels.

### Status values (in lifecycle order)

| Status | Wire string | Description | Terminal? |
|---|---|---|---|
| `AWAITING` | `"AWAITING"` | Booking created, dispatched to tech, awaiting accept (existing) | No |
| `CONFIRMED` | `"CONFIRMED"` | Tech accepted (existing) | No |
| `EN_ROUTE` | `"EN_ROUTE"` | Tech tapped "Start journey"; GPS broadcast active | No |
| `ARRIVED` | `"ARRIVED"` | Tech tapped "Arrived"; geofence-validated (lenient by default) | No |
| `INSPECTING` | `"INSPECTING"` | Tech tapped "Begin assessment"; on-site, pre-quote | No |
| `QUOTED` | `"QUOTED"` | Tech submitted a quote revision; awaiting customer decision | No |
| `IN_PROGRESS` | `"IN_PROGRESS"` | Customer approved a quote; tech performing work | No |
| `COMPLETED` | `"COMPLETED"` | Tech tapped "Mark Complete" + cash collected, full job | **Yes** |
| `COMPLETED_INSPECTION_ONLY` | `"COMPLETED_INSPECTION_ONLY"` | Customer declined the quote; only inspection performed; Rs.500 collected | **Yes** |
| `CANCELLED` | `"CANCELLED"` | Cancelled by customer or tech (see `cancel_reason`) | **Yes** |
| `REJECTED` | `"REJECTED"` | Tech declined or SLA timeout (existing) | **Yes** |
| `NO_SHOW` | `"NO_SHOW"` | Marked no-show by either party (see `no_show_actor`) | **Yes** |
| `DISPUTED` | `"DISPUTED"` | Dispute opened on this booking; admin resolves to a final terminal | **Yes** (via admin) |

**Removed**: `PENDING` is a legacy status (pre-migration 0007); not used in new lifecycle. New bookings are created directly in `AWAITING`.

### Transition table

Every transition is mediated by `bookings/services/orchestrator.py`. The orchestrator is the only writer of `JobBooking.status` and the only caller of `EventDispatchService.broadcast_event` for booking events. All transitions are wrapped in `transaction.atomic()` + `select_for_update()` and use `update_fields=["status", ...timestamp_field]`.

| From → To | Triggered by | Endpoint | Event fired (recipient) | Finance port called | Notes |
|---|---|---|---|---|---|
| (none) → `AWAITING` | Customer booking creation | `POST /api/bookings/instant-book/` (existing) | `job_new_request` (tech) | — | Existing flow, no change. |
| `AWAITING` → `CONFIRMED` | Tech accept (existing) | `POST /api/bookings/<id>/accept/` (existing) | `job_accepted` (customer) | `can_accept_job` (lockout check, null=allow) | Existing flow, add port call. |
| `AWAITING` → `REJECTED` | Tech decline / SLA timeout (existing) | `POST /api/bookings/<id>/decline/` / Celery `expire_pending_job_booking` | `booking_rejected` (customer) | — | Existing. |
| `CONFIRMED` → `EN_ROUTE` | **Auto** when tech's GPS moves >200m from accept-location (manual override exists) | `POST /api/bookings/<id>/en-route/` | `tech_en_route` (customer) | — | Stamps `en_route_started_at`. See §14 rule 1. |
| `EN_ROUTE` → `ARRIVED` | **Auto** when geofence detects tech within 100m of customer address (manual override exists) | `POST /api/bookings/<id>/arrived/` | `tech_arrived` (customer) | — | Stamps `arrived_at`. Geofence: lenient (warn-only) by default; strict via env. See §14 rule 1. |
| `ARRIVED` → `INSPECTING` | **Auto** when tech opens the quote builder | `POST /api/bookings/<id>/start-inspection/` | (none — non-critical UI flip) | — | Stamps `inspection_started_at`. See §14 rule 1. |
| `INSPECTING` → `QUOTED` | Tech submits quote (revision N) | `POST /api/bookings/<id>/quotes/` (with line items) | `quote_generated` (customer) | — | Creates `Quote` row with `revision_number`, line items. Stamps `quote_first_submitted_at` if first. |
| `QUOTED` → `IN_PROGRESS` | Customer approves quote | `POST /api/bookings/<id>/quotes/<q>/approve/` | `quote_approved` (tech) | `apply_inspection_fee_decision('accepted')` | Snapshots quote line items into `BookingItem` rows. Stamps `work_started_at`. |
| `QUOTED` → `COMPLETED_INSPECTION_ONLY` | Customer declines quote | `POST /api/bookings/<id>/quotes/<q>/decline/` | `quote_declined` (tech) | `apply_inspection_fee_decision('declined')` | Stamps `final_cash_to_collect = inspection_fee`, `completed_at`. Tech leaves. |
| `QUOTED` → `INSPECTING` | Customer wants to bargain | `POST /api/bookings/<id>/quotes/<q>/request-revision/` | `quote_revision_requested` (tech) | — | Marks current Quote as `SUPERSEDED`. Tech revises and resubmits → new Quote with `revision_number+1`. |
| `IN_PROGRESS` → `QUOTED` | Mid-job upsell: tech submits new quote on top of approved one | `POST /api/bookings/<id>/quotes/` (with line items, marker `is_upsell=True`) | `quote_generated` (customer) | — | Same flow as above; existing `BookingItem` rows from approved quote stay; on approve, new lines append. |
| `IN_PROGRESS` → `COMPLETED` | Tech taps single "Cash Collected: Rs.X" button (combined complete + cash, no separate Mark Complete) | `POST /api/bookings/<id>/confirm-cash-received/` | `payment_received` (customer) | `record_cash_collected`, `record_commission` | Stamps `completed_at`, `cash_collected_at`, `cash_collected_amount`, `cash_collection_method`. See §14 rule 2. |
| `AWAITING` → `CANCELLED` | Customer cancel | `POST /api/bookings/<id>/cancel/` | `booking_cancelled` (tech) | — | Reason: `customer_cancelled_pre_accept`. No fee. |
| `CONFIRMED`, `EN_ROUTE` → `CANCELLED` | Customer cancel | `POST /api/bookings/<id>/cancel/` | `booking_cancelled` (tech) | `apply_cancellation_charge('customer', 'pre_arrival')` | Reason: `customer_cancelled_post_accept`. Rs.500 owed (recorded as `final_cash_to_collect`). |
| `ARRIVED`, `INSPECTING`, `QUOTED` → `CANCELLED` | Customer cancel | same | same | `apply_cancellation_charge('customer', 'post_arrival')` | Reason: `customer_cancelled_post_arrival`. Rs.500 owed. |
| Any non-terminal → `CANCELLED` | Tech cancel | `POST /api/bookings/<id>/tech-cancel/` | `booking_cancelled` (customer) | `apply_cancellation_charge('tech', <phase>)` | Reason: `technician_cancelled`. No fee but `TechReliabilityIncident` row written to admin log table (was a realtime event in v0.9; replaced per audit P0-08). |
| `ARRIVED`, `INSPECTING`, `QUOTED` → `NO_SHOW` | Tech taps "Customer no-show" (after `arrived_at + 15min`) | `POST /api/bookings/<id>/no-show/` (actor=tech) | `booking_no_show` (customer) | — | Stamps `no_show_at`, `no_show_actor='tech'`. |
| `CONFIRMED`, `EN_ROUTE`, `ARRIVED` → `NO_SHOW` | Customer taps "Tech no-show" (after `scheduled_start + 15min` without `ARRIVED`) | `POST /api/bookings/<id>/no-show/` (actor=customer) | `booking_no_show` (tech) | — | Stamps `no_show_at`, `no_show_actor='customer'`. |
| Any post-completion or `IN_PROGRESS` → `DISPUTED` | Either party opens dispute | `POST /api/bookings/<id>/disputes/` (form intake) | `dispute_opened` (admin + counterparty) | — | Stamps `dispute_opened_at`. Creates `SupportTicket(dispute_intake_method='form')` with optional photo. |
| `DISPUTED` → `COMPLETED` / `COMPLETED_INSPECTION_ONLY` / `CANCELLED` | Admin resolves dispute | `POST /api/admin/tickets/<id>/resolve/` | `dispute_resolved` (both parties) | (none this sprint; finance sprint adds refund logic) | Final outcome chosen by admin. |
| `IN_PROGRESS` → `CANCELLED` | **Not allowed** | — | — | — | Mid-job abort = dispute, not cancel. |

### Booking type adaptation

Three booking types coexist (`INSPECTION`, `FIXED_GIG`, `LABOR_GIG` per existing `pricing_selector.py` resolver). The orchestrator screen adapts via the serializer-emitted `available_transitions` array on the booking detail response. Frontend never hardcodes.

All booking types follow the same lifecycle (every booking eventually reaches `QUOTED` because real-world reality may add line items even to a fixed-gig booking — e.g., AC wash that turns into AC wash + refill).

---

## §6 Quote schema (Quote, QuoteLineItem, BookingItem)

Three tables, distinct roles. Working + revision history on `Quote`/`QuoteLineItem`; final accepted snapshot on `BookingItem` (matches thesis ERD intent for `BookingItem`).

### Quote

```python
class Quote(models.Model):
    booking = models.ForeignKey(JobBooking, related_name="quotes")
    revision_number = models.PositiveIntegerField()  # 1-indexed; increments per submission
    status = models.CharField(choices=[
        ("DRAFT", "Draft"),               # tech is building, not yet sent
        ("SUBMITTED", "Submitted"),       # sent to customer, awaiting decision
        ("APPROVED", "Approved"),         # customer approved, line items snapshotted to BookingItem
        ("DECLINED", "Declined"),         # customer declined → terminal COMPLETED_INSPECTION_ONLY
        ("SUPERSEDED", "Superseded"),     # customer requested revision; new Quote with rev+1 follows
    ])
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)  # derived = sum(line_items.line_total)
    is_upsell = models.BooleanField(default=False)  # True if submitted during IN_PROGRESS (mid-job)
    decision_reason = models.TextField(blank=True)  # set by customer on decline or revision request
    created_at = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField(null=True)
    decided_at = models.DateTimeField(null=True)
    
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["booking", "revision_number"],
                name="unique_quote_revision_per_booking",
            ),
        ]
```

### QuoteLineItem

```python
class QuoteLineItem(models.Model):
    quote = models.ForeignKey(Quote, related_name="line_items")
    sub_service = models.ForeignKey(SubService, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)  # for "3 ceiling lights"
    priced_at = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)  # = quantity * priced_at
```

**Validation on quote submission** (in `quote_service.submit_quote`):
- For each line item: `sub_service` must be from the same `Service` as the booking (catalog-firewall).
- For labor sub-services (`is_fixed_price=False`): `priced_at` must be in `[base_price, max_price]`.
- For fixed-price sub-services (`is_fixed_price=True`): `priced_at` must equal `base_price`.
- `total_amount` = sum of `line_total`. Must be > 0 (empty quote rejected with `400 invalid_quote_empty`).

### BookingItem

```python
class BookingItem(models.Model):
    booking = models.ForeignKey(JobBooking, related_name="items")
    sub_service = models.ForeignKey(SubService, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)
    sourced_quote = models.ForeignKey(Quote, null=True, on_delete=models.PROTECT)  # which approved quote this came from
    created_at = models.DateTimeField(auto_now_add=True)
```

`BookingItem` is **populated only when a Quote is APPROVED**. Snapshotted from `QuoteLineItem` rows. For mid-job upsell: existing `BookingItem` rows stay; new lines append from the upsell quote.

`BookingItem` is the source of truth for "what work was actually performed." Finance sprint reads from here for reconciliation.

### Bargain loop

```
INSPECTING → quote_v1 SUBMITTED → QUOTED 
          ↘ approve → IN_PROGRESS (Quote.APPROVED, BookingItem populated)
          ↘ decline → COMPLETED_INSPECTION_ONLY (Quote.DECLINED)
          ↘ bargain → INSPECTING (Quote.SUPERSEDED, tech revises) → quote_v2 → QUOTED → ...
```

Bargain loops are uncapped — no max-revisions cap. Real-world bargains in person typically resolve in 1–3 rounds.

---

## §7 Cancellation policy

| Phase | Trigger | Status flip | Fee owed | Event reason |
|---|---|---|---|---|
| `AWAITING` | Customer cancels | → `CANCELLED` | None | `customer_cancelled_pre_accept` |
| `CONFIRMED`, `EN_ROUTE` | Customer cancels | → `CANCELLED` | Rs.500 (= `inspection_fee`) recorded as `final_cash_to_collect`, no wallet movement this sprint | `customer_cancelled_post_accept` |
| `ARRIVED`, `INSPECTING`, `QUOTED` | Customer cancels | → `CANCELLED` | Rs.500, same as above | `customer_cancelled_post_arrival` |
| Any non-terminal | Tech cancels | → `CANCELLED` | None; reliability penalty event logged for admin review | `technician_cancelled` |
| `IN_PROGRESS` | Either | **Not allowed** — must use dispute flow | — | — |

- Cancellation event: `booking_cancelled` (recipient = the other party).
- Cancellation by tech writes a row to `TechReliabilityIncident` (admin log table, §11.5). The v0.9 plan emitted a realtime `tech_reliability_penalty` event but `EventLog.target_role` doesn't allow `admin` values (audit P0-08); the table replaces the event for v1.
- Reschedule (§12) is structurally a cancellation + new booking, so it goes through the same flow with a `parent_booking_id` link.

---

## §8 No-show policy

Both sides have a manual button. Auto-detection deferred (flag).

| Side | Visible when | Effect |
|---|---|---|
| Tech | Booking has been `ARRIVED` for ≥15 minutes without progressing | Status → `NO_SHOW`, `no_show_actor='tech'` (tech reports customer no-show) |
| Customer | `scheduled_start + 15 minutes` has passed without booking reaching `ARRIVED` | Status → `NO_SHOW`, `no_show_actor='customer'` (customer reports tech no-show) |

- Event: `booking_no_show` (recipient = other party, plus admin for reliability tracking).
- 15-minute thresholds are hardcoded constants this sprint; configurable in a later sprint.
- No financial consequence in v1 (deferred to finance sprint, where tech-side no-show by customer triggers Rs.500 owed; tech-side no-show by tech triggers reliability penalty).

---

## §9 Finance ports (the deferred-finance seam)

All money-touching operations are mediated by Protocols defined in `backend/bookings/services/finance_ports.py`. The orchestrator and transition services depend on the Protocol, never on a concrete adapter. A `NullFinanceAdapter` is wired now; finance sprint replaces it with a real adapter.

### Protocol signatures

```python
# backend/bookings/services/finance_ports.py

from typing import Protocol
from decimal import Decimal

class FinancePort(Protocol):
    def can_accept_job(
        self, *, technician, payout_amount: Decimal
    ) -> tuple[bool, str | None]:
        """Lockout check before tech accepts. Returns (allowed, reason_code_or_None).
        Null adapter: always (True, None)."""

    def record_commission(
        self, *, booking, amount: Decimal
    ) -> None:
        """Called at COMPLETED. Will create JobCommission + WalletTransaction in finance sprint.
        Null adapter: no-op."""

    def apply_inspection_fee_decision(
        self, *, booking, decision: str  # 'accepted' | 'declined'
    ) -> None:
        """On QUOTED → IN_PROGRESS or COMPLETED_INSPECTION_ONLY transition.
        accepted: inspection fee credited toward final bill (computed in pricing service).
        declined: inspection fee owed as cash (recorded in JobBooking.final_cash_to_collect).
        Null adapter: no-op (the booking column writes happen in orchestrator regardless)."""

    def apply_cancellation_charge(
        self, *, booking, actor: str, phase: str
    ) -> None:
        """On any → CANCELLED transition.
        actor: 'customer' | 'tech'
        phase: 'pre_accept' | 'pre_arrival' | 'post_arrival'
        Null adapter: no-op (penalty/fee columns written by orchestrator regardless)."""

    def record_cash_collected(
        self, *, booking, amount: Decimal, method: str
    ) -> None:
        """On COMPLETED transition after tech taps Cash Collected.
        Will create WalletTransaction and JobCommission in finance sprint.
        Null adapter: no-op."""
```

### Null adapter

```python
# backend/bookings/adapters/null_finance.py

class NullFinanceAdapter:
    def can_accept_job(self, *, technician, payout_amount):
        return (True, None)
    def record_commission(self, *, booking, amount):
        return None
    def apply_inspection_fee_decision(self, *, booking, decision):
        return None
    def apply_cancellation_charge(self, *, booking, actor, phase):
        return None
    def record_cash_collected(self, *, booking, amount, method):
        return None
```

### Wiring

```python
# backend/bookings/adapters/__init__.py

def get_default_finance_service():
    from .null_finance import NullFinanceAdapter
    return NullFinanceAdapter()
```

Service code accepts `finance: FinancePort | None = None` and resolves with `finance or get_default_finance_service()`. Tests inject fakes; production gets the null adapter today and the real adapter post-finance-sprint.

---

## §10 Tracking architecture

Tech's GPS streams to customer in near-real-time using the existing dual-barrel pipeline.

### Backend

- **Stream type**: `tech_gps`
- **Channel-layer subgroup**: `tracking_job_{booking_id}` (per-job, dynamic). Multiple watchers possible (customer, future admin support).
- **Publisher**: `realtime.streams.publish_stream(stream_type='tech_gps', group=f'tracking_job_{booking_id}', payload={...})`. The existing `publish_stream` signature accepts a `group` override; if it currently only supports user-scoped groups, this sprint extends it.
- **Ingress endpoint**: `POST /api/bookings/<id>/tech-location/` — tech app posts `{lat, lng, accuracy_meters?, heading?}` every 5 seconds. View thinly delegates to `streams.publish_stream`. Rate-limited at the view layer (max 1 per 4s per tech to absorb clock drift).
- **Subscription mechanism**: WS consumer accepts an upstream message `{action: "subscribe_tracking", booking_id: N}` to add the consumer to `tracking_job_N`, and `{action: "unsubscribe_tracking", booking_id: N}` to remove. This is the **first** legitimate upstream message the consumer accepts; until now the consumer was strictly downstream-only. CLAUDE.md's "WS consumer stays one-way and logic-less" rule is amended for tracking subscription only. Document the amendment in CLAUDE.md when this lands.
- **Authorization**: subscription is allowed only if the requesting user is the customer or technician on that booking. Validated in the consumer.
- **Frame envelope**: `{kind: "stream", streamType: "tech_gps", timestamp: iso_z, payload: {lat, lng, accuracy_meters?, heading?, booking_id}}`. No DB write, no FCM, no ACK (per CLAUDE.md stream contract).

### Frontend

- **Tech side**: Android foreground service streams location via `geolocator.getPositionStream(distanceFilter: 10m, accuracy: high)`. Each fix POSTs to `/tech-location/`. Service starts on `EN_ROUTE`, stops on `COMPLETED` / `COMPLETED_INSPECTION_ONLY` / `CANCELLED` / `NO_SHOW`. Persistent notification: "Tracking job to {customer_name}". `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` permissions in AndroidManifest.
- **Customer side**: when orchestrator screen mounts and booking status ∈ {`EN_ROUTE`, `ARRIVED`}, the screen sends `subscribe_tracking` via `WsConnectionNotifier`. On unmount or status change to terminal, sends `unsubscribe_tracking`.
- **Stream consumer pattern** (codebase's first): `technicianLocationStreamProvider(bookingId).family` registers a handler with `WsFrameDispatcher`, holds the latest `LatLng` + timestamp in state. The map widget watches it and updates the marker.
- **Stream-staleness detection**: customer-side notifier checks "last frame timestamp" against current time; if >60s stale, surfaces a soft "Technician offline" banner. Booking status unchanged.
- **Tick rate**: 5 seconds (per thesis). The 4s server-side rate limit absorbs clock drift.
- **iOS**: deferred; flag opened.

---

## §11 AI Chatbot — stub with seam

The project's identity is "Smart Technician Booking Application **With AI Chatbot Assistant**." Full chatbot integration is a separate sprint (involves Claude API per CLAUDE.md, conversation persistence, photo upload pipeline, ticket auto-generation from chat). This sprint ships the **dispute opening** flow with a form intake but designs the data shape so the chatbot adapter plugs in additively later.

### SupportTicket schema (sprint-introduced)

```python
class SupportTicket(models.Model):
    booking = models.ForeignKey(JobBooking, related_name="tickets")
    opened_by = models.ForeignKey(User, related_name="opened_tickets")
    dispute_intake_method = models.CharField(choices=[
        ("FORM", "Form"),       # this sprint
        ("CHATBOT", "Chatbot"), # future sprint
    ], default="FORM")
    initial_reason = models.TextField()  # form intake: customer's initial message
    chat_log = models.JSONField(null=True, blank=True)  # future: chatbot transcript
    status = models.CharField(choices=[
        ("OPEN", "Open"),
        ("RESOLVED", "Resolved"),
    ], default="OPEN")
    resolution_outcome = models.CharField(choices=[
        ("NONE", "None"),
        ("REFUND_CUSTOMER", "Refund Customer"),
        ("PENALIZE_TECH", "Penalize Tech"),
        ("DISMISS", "Dismiss"),
    ], default="NONE")
    resolution_notes = models.TextField(blank=True)
    opened_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
```

### TicketEvidence schema

```python
class TicketEvidence(models.Model):
    ticket = models.ForeignKey(SupportTicket, related_name="evidence")
    uploaded_by = models.ForeignKey(User)
    image = models.ImageField(upload_to="dispute_evidence/")
    caption = models.TextField(blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
```

### What this sprint ships

- Form intake (`initial_reason` + optional one photo per ticket).
- `POST /api/bookings/<id>/disputes/` — opens ticket with `dispute_intake_method='FORM'`, fires `dispute_opened` event, flips booking to `DISPUTED`.
- `POST /api/admin/tickets/<id>/resolve/` — admin resolves (Django Admin custom action), fires `dispute_resolved` event, sets booking's final terminal.
- Multiple tickets per booking allowed; one open ticket flips booking to `DISPUTED`.

### What chatbot sprint adds later

- `dispute_intake_method='CHATBOT'` path: customer chats with AI, conversation persisted in `chat_log`.
- Auto-creation of ticket when chatbot decides "this needs human".
- Auto-attachment of photos uploaded during chat.
- No schema changes needed — `chat_log` field already reserved.

---

## §12 parent_booking_id semantics (reschedule chain)

Single use case in v1: customer-initiated reschedule.

- Customer requests reschedule via `POST /api/bookings/<id>/reschedule/` with new `scheduled_start, scheduled_end`.
- Backend creates a **new** `JobBooking` row with `parent_booking_id = <original.id>`, status `AWAITING`, copies tech_id (re-dispatches to same tech), copies address.
- Original booking transitions to `CANCELLED` with `cancel_reason='customer_rescheduled'`.
- Original tech gets `booking_rescheduled` event (recipient: tech) — non-critical; UI surfaces as a banner. New `job_new_request` follows for the new booking row.
- Reschedule is allowed only from `AWAITING` and `CONFIRMED` (not after `EN_ROUTE`).
- Cancelling a child booking is independent (does not cascade to parent — parent is already CANCELLED).
- Orchestrator screen header on the new booking shows "Rescheduled from booking #N" with a tap-link to the old detail (read-only).

---

## §13 Maps stack (dual provider)

- **Production**: `google_maps_flutter` for tiles + Google Directions API for polyline/ETA. ToS-clean (Google polyline on Google tiles).
- **Dev/test/demo**: existing `flutter_map` (OSM) widget at `frontend/lib/core/widgets/map/app_map.dart` + OSRM (or fixture-based) for directions. Used because the Google Maps API key is not yet provisioned.
- **Selection**: `--dart-define=MAP_PROVIDER=google|osm` at build time. Default `osm` until API key lands.
- **Adapter abstraction**:
  - `IAppMap` widget interface — provider-agnostic.
  - `IDirectionsService` interface — provider-agnostic.
  - `GoogleAppMap` + `GoogleDirectionsService` impls.
  - `OsmAppMap` + `OsrmDirectionsService` (or `FixtureDirectionsService` for tests) impls.
- **Production-quality dev variant**: the OSM variant must be polished, not stubbed. Demos may run from the dev build.
- The existing OSM-based `LocationPicker` (address selection) stays untouched; address picking is non-tracking surface.
- Flag #16 stays open until the production build wires the Google API key with `assert(!kReleaseMode)` gate.

---

## §14 Tech-side UX simplification

The Pakistani plumber, electrician, AC tech, or other domestic worker is the lowest-tech user in the system. The booking orchestrator's data model is rich (every status, every event, every audit row) — but the technician's UI must be simple enough that an unfamiliar user can complete a happy-path job in **2 taps with zero training**: tap Accept on the incoming offer, tap "Cash Collected" at the end.

These rules are non-negotiable for sessions 3–6. The data model from §5 is unchanged; the rules govern *which* transitions surface a button and *which* happen invisibly.

### The 8 simplification rules

1. **Auto-transition wherever geofence/heuristic permits.** Tech never taps these:
   - `CONFIRMED → EN_ROUTE` auto when tech's GPS moves >200m from accept-location.
   - `EN_ROUTE → ARRIVED` auto when geofence detects tech within 100m of customer address.
   - `ARRIVED → INSPECTING` auto when tech opens the quote builder.

   The transitions still flow through the same orchestrator service (atomic, idempotent, fires events). They're triggered by the location-ingress endpoint or implicit UI navigation, not by a button. Manual override endpoints exist for failure cases (GPS spotty, geofence too tight) but are surfaced only via long-press or admin override, not as primary tech buttons.

2. **Combine "Mark Complete" + "Cash Collected" into a single tap.** `IN_PROGRESS → COMPLETED` happens when tech taps a single button reading "Cash Collected: Rs.X" (X pre-populated from `final_cash_to_collect`). One tap flips status, fires `payment_received`, calls finance ports. There is no separate "Mark Complete" button.

3. **Quote builder is a chip stack of the tech's known skills.** Each chip shows the sub-service name + the tech's default labor rate. One tap to add a line item; tap again to remove. Number-edit field per item for quantity. Catalog browsing is a "+" button at the bottom for unusual additions, not the primary path. AC tech doing AC wash: one chip "AC Wash – Rs.1500", tap, submit. Done.

4. **Bargain-back navigation is automatic.** When `quote_revision_requested` event arrives, tech is taken straight to the quote builder with the previous (now SUPERSEDED) quote pre-loaded. No banner, no "click to revise" interstitial. The quote builder simply appears as the current state.

5. **Dispute and reschedule UIs are customer-only.** Tech never sees an "open dispute" or "reschedule" button. When customer triggers either, tech sees a read-only banner ("Customer has reported an issue. Admin will contact you" / "Customer rescheduled to {new time}") with no buttons.

6. **Tech-cancel is in a 3-dot overflow menu.** Buried, with a confirmation modal explaining the reliability penalty before submission. Not on the main action area to prevent accidental taps.

7. **No-show is a single tap.** Tech sees one "Customer didn't show" button visible only after `arrived_at + 15min` of no progress. Single confirmation modal ("Yes, customer didn't show"). No reason picker, no text field.

8. **One card on screen at any time.** The orchestrator screen shows whatever is current: the en-route map, the quote builder, the cash-collection card. No tabs, no settings, no menus on the primary view. Whatever the next action is, that card has one primary button (or zero if auto-transitioning).

### Implementation impact across sessions

| Session | Adds for these rules |
|---|---|
| 2 (backend transitions) | `bookings/services/auto_transition.py::evaluate_on_location(booking, lat, lng)` invoked from the `tech-location` ingress endpoint; checks geofence rules (200m for `EN_ROUTE`, 100m for `ARRIVED`) and calls orchestrator transition methods if criteria met. The `mark_complete` and `confirm_cash_received` actions collapse into a single endpoint that does both atomically. |
| 3 (orchestrator skeleton) | Slot architecture supports "no primary action" / auto-transitioning states. Tech-side primary action area can render zero buttons when an auto-transition is pending. |
| 4 (live tracking) | Client-side fallback: tech app evaluates geofence on each location fix as a redundancy in case the location-ingress is throttled or temporarily offline. |
| 5 (quote flow + cash) | Quote builder built chip-stack-first (skill chips with default rates pre-filled). Cash-collection screen has the single combined button. |
| 6 (edges + polish) | Tech cancel placed in overflow menu; no-show button as single tap; dispute and reschedule screens are customer-only (tech-side renders read-only banners only). |

### Customer side — separate UX guidance

The customer is likely smartphone-savvy (downloaded app, browsed catalogue, picked tech). They can handle slightly more controls — the 3-action quote sheet (Approve / Decline / Bargain in person), dispute open form with photo upload, etc. Still: prefer plain language over jargon; single-action sheets over multi-tab screens; Material 3 surfaces over custom chrome.

---

## §15 Edge case resolutions (the 15)

Locked answers. Each is implemented in the indicated session.

| # | Edge case | Resolution | Session |
|---|---|---|---|
| 1 | Mid-job upsell during `IN_PROGRESS` | Allow new `Quote` revision with `is_upsell=True`. On approve, line items append to `BookingItem`. Status loops `IN_PROGRESS` → `QUOTED` → `IN_PROGRESS`. | 2, 5 |
| 2 | Quote-decision SLA (customer doesn't decide) | No auto-SLA. Tech presses "Customer not deciding" → `NO_SHOW` flow with `no_show_actor='tech'`. | 2, 5 |
| 3 | Reschedule | Child booking with `parent_booking_id`; original → CANCELLED. | 2, 6 |
| 4 | Race: customer cancel vs arrived | `select_for_update` serializes; loser gets `409 booking_no_longer_available` echoing `current_status`. UI snackbar. | 2 |
| 5 | Cash-collection offline | Hard-block "Cash Collected" button; show offline banner. Re-enable on reconnect. | 5 |
| 6 | Disputes on `COMPLETED_INSPECTION_ONLY` | Allowed. Dispute pipeline doesn't care about which terminal. | 2, 6 |
| 7 | Multiple disputes on one booking | N tickets allowed. Booking stays `DISPUTED` while any ticket is `OPEN`. | 2, 6 |
| 8 | Tech accepts but never starts journey | Customer can flip to `NO_SHOW` after `scheduled_start + 15min` without `ARRIVED`. | 2, 6 |
| 9 | Reviews/ratings | Out of scope. Defer to its own future sprint. Open flag. | — |
| 10 | Promotion expiration mid-flow | Snapshotted at booking creation (`promo_code_snapshot`, `promo_discount_snapshot`). Booking honors original. | 1 |
| 11 | Tech goes offline mid-`EN_ROUTE` | 60s no GPS frames → soft "Technician offline" banner. Booking status unchanged. | 4 |
| 12 | Quote line item removal via bargain | Works naturally — revision N has 3 items, revision N+1 has 2. No special handling. | 2, 5 |
| 13 | Customer is also a technician | Per-booking role, not per-user. Orchestrator already keys on booking. | structurally satisfied |
| 14 | Booking attachments (evidence photos) | Reserve `BookingAttachment` schema. No UI this sprint. | 1 |
| 15 | Concurrent bookings | Already works; bookings list handles two simultaneous active states. | structurally satisfied |

Additional locked decisions surfaced during edge-grinding:

- **Empty / zero-total quote**: rejected at submit-time with `400 invalid_quote_empty`.
- **Geofence on Mark Arrived**: lenient default (warn-log only); configurable strict via `BOOKING_GEOFENCE_STRICT=True` env. Strict mode rejects with `400 not_at_customer_location`.
- **Promotion `funded_by`**: respected in pricing computation. Tech's quote-builder UI shows "you're discounted Rs.X for this promo, your effective rate floor is now Rs.Y" when applicable. Schema + computation lands in session 5; full UI polish deferred to a future post-sprint pass (this sprint has 6 sessions; the v0.9 plan's "session 9" reference was a stale typo, fixed per audit P3-06).
- **Customer leaves mid-`IN_PROGRESS` before cash**: tech can still tap "Mark Complete" but "Cash Collected" requires non-zero amount; tech can collect cash later by re-opening the orchestrator screen and tapping "Cash Collected". Status stays `IN_PROGRESS` until cash collected.

---

## §16 New events + new stream types

### Events (added to `realtime/constants/event_types.py`)

| Wire string | is_critical | Recipient | Where broadcast | Notes |
|---|---|---|---|---|
| `quote_revision_requested` | False | Tech | Customer's `request-revision` endpoint | NEW. Customer asks tech to bargain/revise. |
| `quote_declined` | False | Tech | Customer's `decline` endpoint | NEW. Customer terminally declines quote. |
| `booking_cancelled` | False | Counterparty | Cancel endpoints | Reason discriminator: `customer_cancelled_pre_accept` / `..._post_accept` / `..._post_arrival` / `technician_cancelled` / `customer_rescheduled`. |
| `booking_no_show` | False | Counterparty | No-show endpoint | `no_show_actor` discriminator. **Audit P1-14**: admin half dropped (same reason as `dispute_opened`); admin reliability auditing happens via DB, not WS push. |
| `booking_rescheduled` | False | Tech | Reschedule endpoint | New booking id in payload. |
| ~~`tech_reliability_penalty`~~ | — | — | — | **Removed per audit P0-08.** `EventLog.target_role` only supports `customer`/`technician`; admin broadcast unsupported. Tech-cancel writes a row to `TechReliabilityIncident` (§11.5) instead. |
| `quote_generated` | True | Customer | Submit-quote endpoint | EXISTING in enum; first wired publisher this sprint. |
| `quote_approved` | True | Tech | Approve-quote endpoint | EXISTING in enum; first wired publisher. |
| `tech_en_route` | False | Customer | EN_ROUTE endpoint | EXISTING in enum; first wired publisher. |
| `tech_arrived` | False | Customer | ARRIVED endpoint | EXISTING in enum; first wired publisher. |
| `job_completed` | True | Customer | COMPLETED transition | EXISTING in enum; first wired publisher. |
| `payment_received` | False | Customer | confirm-cash-received endpoint | EXISTING in enum; first wired publisher. |
| `dispute_opened` | True | Counterparty | Dispute open endpoint | EXISTING in enum; first wired publisher. **Audit P1-14**: admin half dropped (admin sees disputes via Django Admin). |
| `dispute_resolved` | True | Both parties | Admin resolve endpoint | EXISTING in enum; first wired publisher. |

### Stream types

| Stream type | Group | Cadence | Payload | Notes |
|---|---|---|---|---|
| `tech_gps` | `tracking_job_{id}` | 5s tick (rate-limited at 4s) | `{lat, lng, accuracy_meters?, heading?, booking_id}` | NEW. First stream consumer in the codebase. |

`wallet_balance` and `wallet_low_balance` streams/events stay deferred to finance sprint.

---

## §17 New columns on existing models

### `JobBooking` (large additive migration)

Phase timestamps:
- `accepted_at`, `en_route_started_at`, `arrived_at`, `inspection_started_at`, `quote_first_submitted_at`, `work_started_at`, `completed_at`

Cash collection:
- `final_cash_to_collect` (Decimal, server-derived)
- `cash_collected_amount` (Decimal, nullable)
- `cash_collected_at` (DateTime, nullable)
- `cash_collection_method` (CharField, default `'cash'`)

Pricing breakdown:
- `inspection_fee` (Decimal — snapshot of `service.base_inspection_fee` at booking time)
- `base_services_total` (Decimal — sum of `BookingItem.line_total`)
- `discount_applied` (Decimal — promo discount actually applied)

Promotion snapshot (denormalized to survive promo deletion/expiry):
- `promo_code_snapshot` (CharField, nullable)
- `promo_discount_snapshot` (Decimal, nullable)

Address snapshot:
- `actual_address_snapshot` (TextField — denormalized address text at booking time)

Reschedule chain:
- `parent_booking_id` (FK to self, nullable, `on_delete=SET_NULL`, `related_name='child_bookings'`)

Cancellation audit:
- `cancelled_at` (DateTime, nullable)
- `cancelled_by` (FK to User, nullable)
- `cancel_reason` (CharField — see §7 reasons)

No-show audit:
- `no_show_at` (DateTime, nullable)
- `no_show_actor` (CharField, choices: `'tech'`, `'customer'`)

Dispute audit:
- `dispute_opened_at` (DateTime, nullable)

### `SubService`

- `max_price` (Decimal, nullable) — labor band ceiling. For fixed-price gigs: null. For labor gigs: ceiling, with `base_price` as the floor.

### `Service`

No additions this sprint.

### `Promotion`

No additions this sprint (snapshot lives on `JobBooking`).

---

## §18 New models

| Model | Purpose | Section |
|---|---|---|
| `Quote` | Working/revision quote rows | §6 |
| `QuoteLineItem` | Working/revision line items | §6 |
| `BookingItem` | Final accepted line-item snapshot | §6 |
| `SupportTicket` | Dispute ticket (form intake this sprint, chatbot-ready) | §11 |
| `TicketEvidence` | Photos attached to dispute tickets | §11 |
| `BookingAttachment` | Reserved schema for booking-lifecycle photos (no UI this sprint, edge case #14) | (data-only) |
| `TechReliabilityIncident` | Admin-visible log of tech-cancel events (replaces the dropped `tech_reliability_penalty` realtime event per audit P0-08) | §11.5 |

### §11.5 `TechReliabilityIncident` (added per audit P0-08)

Replaces the dropped `tech_reliability_penalty` realtime event. The `EventLog.target_role` field only allows `customer` and `technician`; the v0.9 sprint plan tried to push an `admin` value which would fail at save. Instead we log to a dedicated table that admin reads via Django Admin.

```python
class TechReliabilityIncident(models.Model):
    INCIDENT_TECH_CANCEL = 'TECH_CANCEL'
    INCIDENT_TECH_NO_SHOW = 'TECH_NO_SHOW'
    INCIDENT_CHOICES = [
        (INCIDENT_TECH_CANCEL, 'Tech cancelled job'),
        (INCIDENT_TECH_NO_SHOW, 'Tech reported as no-show by customer'),
    ]

    technician = models.ForeignKey('technicians.TechnicianProfile', on_delete=models.CASCADE,
                                    related_name='reliability_incidents')
    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE,
                                 related_name='tech_reliability_incidents')
    incident_type = models.CharField(max_length=32, choices=INCIDENT_CHOICES)
    phase = models.CharField(max_length=32, blank=True, default='')   # 'pre_arrival' | 'post_arrival' | etc.
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['technician', '-created_at'])]
```

Written by `orchestrator.cancel_by_tech` and `orchestrator.mark_no_show` (when `actor_role='customer'` reporting tech). Admin views via standard `ModelAdmin` registration. Future "reliability score" sprint reads this table for aggregate computations.

`BookingAttachment` schema:

```python
class BookingAttachment(models.Model):
    booking = models.ForeignKey(JobBooking, related_name="attachments")
    uploaded_by = models.ForeignKey(User)
    kind = models.CharField(choices=[
        ("BEFORE", "Before"),
        ("AFTER", "After"),
        ("QUOTE", "Quote evidence"),
        ("OTHER", "Other"),
    ])
    image = models.ImageField(upload_to="booking_attachments/")
    caption = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

Schema-only this sprint; no upload UI, no admin attachment view.

---

## §19 Six-session breakdown

| # | File | Scope summary |
|---|---|---|
| 1 | `session_1_backend_foundations.md` | Status enum migration, all new models (`Quote`, `QuoteLineItem`, `BookingItem`, `SupportTicket`, `TicketEvidence`, `BookingAttachment`), all new `JobBooking` columns, `SubService.max_price`, `finance_ports.py` + `null_finance.py`, central `bookings/services/orchestrator.py` transition gateway (no endpoints yet), all transition-service stubs for session 2 to plug into, full service+selector tests. **No endpoints, no realtime publishers, no UI.** |
| 2 | `session_2_backend_transitions.md` | All transition endpoints (en_route, arrived, start_inspection, submit_quote, approve_quote, decline_quote, request_revision, mark_complete, confirm_cash_received, cancel, tech_cancel, mark_no_show, open_dispute, admin_resolve_dispute, reschedule, tech_location). Each fires its event + calls finance ports. New events added to enum. `tech_gps` stream + ingress endpoint + dynamic subgroup subscription mechanism in WS consumer. Geofence validation (lenient default). `auto_transition.py::evaluate_on_location` (per §14 rule 1). Full API tests. |
| 3 | `session_3_orchestrator_frontend_skeleton.md` | `BookingOrchestratorScreen` at `/booking/:job_id`, `bookingDetailProvider` hydration, status-driven slot architecture, role discrimination, ~12 per-event notifiers (CLAUDE.md per-event-feature template), bookings-list patch mapper extended for new transitions, urgency-router updates, `GoRoute` registration, `realtimeBootHooksProvider` registry additions, stub widgets per state. Full notifier + screen tests. |
| 4 | `session_4_live_tracking_and_dual_maps.md` | `IAppMap` + `IDirectionsService` adapter abstraction, Google + OSM impls, `--dart-define=MAP_PROVIDER` selection, live-tracking widget integrated into orchestrator's body slot, **Android foreground location service** (FOREGROUND_SERVICE permission, persistent notification, geolocator stream wiring), customer-side stream-consumer pattern (codebase's first), polyline + ETA on both providers, stream-staleness "tech offline" banner. |
| 5 | `session_5_quote_flow_and_cash_collection.md` | Tech-side quote builder screen (chip-stack of skills, line-item picker, band validation, pre-populate from standing rate, mid-job upsell support), customer-side quote approval sheet with bargain button (3-action: Approve/Decline/Bargain in person), bargain-ceiling indicator on customer view for labor lines, cash-collection completion screen (single combined button per §14 rule 2, hard-block on offline), customer-leaves-mid-IN_PROGRESS handling. |
| 6 | `session_6_lifecycle_edges_and_polish.md` | Customer/tech cancel flows with timing-aware copy (tech cancel in overflow per §14 rule 6), reschedule flow (child booking creation), no-show buttons (single tap per §14 rule 7), dispute open form (customer-only per §14 rule 5, form-intake, chatbot-shaped data), admin dispute resolution (Django Admin custom action wired to backend service from session 2), SLA countdown polish (live ticking on AWAITING), tech-offline banner integration, flag #26 closed, deferred-flags appended. |

Each session file lives in `booking_orchestrator_sprint/` and follows the rigid template established by the prior-sprint files at the repo root (`session_1_wire_main_isolate.md` … `session_4_customer_bookings_list_ui.md`): Sprint context (link to `BOOKING_ORCHESTRATOR_SPRINT.md`), Decisions taken (session-local only), Files this session touches, Pre-flight checks, Per-file detailed changes (before/after where applicable), Gotchas, Verification (manual + automated), What this session does NOT fix, Definition of done (checklist).

---

## §20 Per-session flag.md transitions

| Session | Closes | Opens / extends |
|---|---|---|
| 1 | — | Opens: `ai-chatbot-deferred`, `reviews-deferred`, `bank-accounts-deferred`, `admin-realtime-channel-deferred` (per audit P0-08; needed before re-introducing `tech_reliability_penalty` / admin event broadcasts). |
| 2 | — | Opens: `geofence-strictness-config-tbd`, `wallet-commission-deferred-to-finance-sprint`, `tech-location-rate-limit-not-distributed` (per audit P1-07; in-memory throttle is per-process). |
| 3 | — | — |
| 4 | (touches #16: API key still TBD; adapter shipped) | Opens: `ios-foreground-service-deferred`, `ws-stream-multi-handler-deferred` (per audit P0-07; dispatcher is single-handler-per-type for v1). |
| 5 | — | — |
| 6 | Closes #26 (booking detail screen) | Opens: `auto-no-show-detection-deferred`, `chatbot-intake-future-sprint` (with seam designed), `eventlog-retention-policy-tbd` (per audit P2-03). |

Each session's "Definition of done" checklist includes "flag.md updated per §20" as a verification item.

---

## §21 Sprint Definition of Done

- All six session files committed and their per-session DoD checklists green.
- Backend test suite green: `pytest backend/`.
- Frontend test suite green: `flutter test`.
- Manual end-to-end QA passes the happy path:
  - Customer books → tech accepts → tech taps Start journey → ARRIVED → Begin assessment → submits quote → customer approves → IN_PROGRESS → tech mid-job submits upsell quote → customer approves → tech taps Mark Complete → tech taps Cash Collected: Rs.X → COMPLETED.
- Manual edge-path QA passes:
  - Customer cancels at AWAITING (free).
  - Customer cancels at CONFIRMED (Rs.500 owed).
  - Customer cancels at ARRIVED (Rs.500 owed).
  - Tech cancels at CONFIRMED (no fee, reliability event logged).
  - Quote bargain loop: customer hits "Bargain in person", tech revises, customer approves on rev 2.
  - Quote decline → COMPLETED_INSPECTION_ONLY (Rs.500 cash collected).
  - Customer no-show (tech triggers).
  - Tech no-show (customer triggers).
  - Reschedule (parent → CANCELLED, child → AWAITING with link).
  - Dispute open (form-intake) → admin resolves to REFUND_CUSTOMER.
- Live tracking demo passes on Android: tech's foreground service streams location, customer sees marker move with polyline + ETA, tech-offline banner appears after 60s if tech kills the foreground service.
- `flag.md` reflects all opens/closes per §20.
- `BOOKING_ORCHESTRATOR_SPRINT.md` (this file) committed with no `[TBD]` markers in critical sections.

---

## §22 Anti-patterns (do not do)

- **Do not** scatter `JobBooking.status` mutations across multiple services. The orchestrator service is the single writer.
- **Do not** branch on raw status in Flutter widgets to compute copy or button labels. Read server-emitted `ui.*` fields.
- **Do not** import Celery directly from any service in `bookings/services/`. Use the existing port-and-adapter pattern.
- **Do not** import wallet/commission concretely. Depend on `FinancePort` Protocol; resolve via `get_default_finance_service()`.
- **Do not** collapse the events-publisher and streams-publisher into one. They stay distinct (CLAUDE.md non-negotiable).
- **Do not** push tracking frames into `EventLog`. Streams are transient.
- **Do not** treat the thesis ERD as authoritative. Reference-only.
- **Do not** bundle global theme refactors or design-system passes into these sessions (memory: planned UI cleanup pass is post-feature-stabilization).
- **Do not** rename channel-layer groups or event names mid-sprint. The `_events` suffix is historical and intentionally retained (CLAUDE.md).
- **Do not** save sprint-specific architectural decisions to memory. They live here.

---

## §23 What this sprint does NOT include

Out of scope; deferred to future sprints with flags opened in §20.

- **Wallet ledger**: `WalletTransaction`, `JobCommission`, withdrawal requests, JazzCash top-up, JazzCash webhook handling. Finance sprint.
- **Real commission deduction**: orchestrator calls `FinancePort.record_commission`; null adapter no-ops. Finance sprint.
- **AI Chatbot dispute intake**: form-intake only this sprint; chatbot adapter is future sprint.
- **iOS foreground location service**: Android-only this sprint per flag #10.
- **Full background geolocation** (when app is killed): not in scope. Tech expected to keep foreground service alive.
- **Auto no-show detection** (Celery-driven): manual on either side this sprint.
- **Reviews and ratings**: Bayesian rolled-up score already exists in matchmaking; the `Review` model + endpoint is a separate sprint.
- **Bank accounts** (`TechnicianBankAccount`, `CustomerBankAccount`): finance sprint.
- **`BookingAttachment` UI**: schema-only this sprint; upload UI future sprint.
- **Wallet balance live stream + low-balance banner**: deferred event types stay declared but unwired; finance sprint adds the publisher and consumer.
- **Reviews on `COMPLETED_INSPECTION_ONLY`**: edge case for the reviews sprint.
- **Geofence strictness configurable per-tech / per-service**: env-level toggle this sprint; per-entity config later.
- **Stitch divergences logged**: the orchestrator screen's visual design will lean on Session 4's tokens; any explicit Stitch reference work happens during the planned UI cleanup pass.

---

## §24 Frontend transport layer (canonical http pattern)

**Audit P0-03 resolution.** The v0.9 plan wrote every Flutter data source with `Dio`. The codebase uses `package:http` (verified in `pubspec.yaml`: `http: ^1.2.0`). All sessions 3–6 data source examples are written in Dio and would not compile.

**Decision**: stay on `http`. Don't introduce Dio. The sprint doesn't actually use any Dio-specific feature (interceptors, cancellation tokens, retry adapters). Migration is mechanical.

### URL convention (audit C2-P0-01)

`AppConstants.baseUrl` (verified at `lib/core/constants.dart`) is `'http://127.0.0.1:8000/api'` — **the `/api` prefix is already baked in**. Endpoint paths concatenated to `baseUrl` MUST start with `/<resource>/`, NOT `/api/<resource>/`. The codebase convention (verified in `customer_bookings_remote_data_source.dart`, `address_remote_data_source.dart`, `incoming_job_remote_data_source.dart`) is `'${AppConstants.baseUrl}/bookings/'` etc.

The same rule applies to backend `orchestrator_ui.py` selector handlers that emit `endpoint=` strings for `BookingActionExecutor`: emit `/bookings/<id>/cancel/`, NOT `/api/bookings/<id>/cancel/`. The frontend executor concatenates `${baseUrl}${endpoint}` and would otherwise produce `.../api/api/...`.

### Canonical data source pattern (use everywhere in sessions 3–6)

```dart
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/common/errors/http_failure.dart';
import '../../../core/constants.dart';

class FooRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  FooRemoteDataSource(this._client, this._secureStorage);

  Future<FooModel> fetchOne(int id) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/foo/$id/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    _ensureOk(response);
    return FooModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<int> createOne(FooRequestModel body) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/foo/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body.toJson()),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['id'] as int;
  }

  /// Throws [HttpFailure] on non-2xx; SocketException bubbles to the repository
  /// where it's caught and mapped to the feature's NetworkFailure sealed class.
  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } catch (_) { /* non-JSON body */ }
    throw HttpFailure(
      statusCode: response.statusCode,
      code: envelope?['code'] as String? ?? 'unknown',
      message: envelope?['message'] as String? ?? 'Request failed (${response.statusCode}).',
      errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
```

### Multipart pattern (for `OpenDisputeView` photo upload — session 6)

```dart
Future<void> openDispute(int bookingId, String reason, XFile? photo) async {
  final token = await _secureStorage.read(key: 'auth_token');
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/disputes/'),
  );
  if (token != null) request.headers['Authorization'] = 'Token $token';
  request.fields['initial_reason'] = reason;
  if (photo != null) {
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
  }
  final streamed = await _client.send(request);
  final response = await http.Response.fromStream(streamed);
  _ensureOk(response);
}
```

### Provider wiring (audit C2-P1-06)

The codebase already exposes `eventHttpClient` in `lib/core/realtime/presentation/providers/dependency_injection.dart`. Sessions 3–6 reuse the same instance via:

```dart
@Riverpod(keepAlive: true)
FlutterSecureStorage orchestratorSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

@Riverpod(keepAlive: true)
FooRemoteDataSource fooRemoteDataSource(Ref ref) => FooRemoteDataSource(
  ref.read(eventHttpClientProvider),
  ref.read(orchestratorSecureStorageProvider),
);
```

The codebase convention is **per-feature secure-storage providers** (verified: `eventSecureStorage`, `customerBookingsSecureStorage`, `addressSecureStorage`, etc.). Do **not** import `flutterSecureStorageProvider` from the auth feature — that creates a cross-feature dependency. Define `orchestratorSecureStorage` once in the orchestrator feature's `dependency_injection.dart` and reuse across every data source in sessions 3-6.

Do **not** `http.Client()` per data source — share the singleton client via the existing `eventHttpClient` provider (it's already keepAlive and survives widget lifecycles).

### Repository error mapping (unchanged from v0.9 plan)

```dart
try {
  final model = await _remote.fetchOne(id);
  return FooMapper.toDomain(model);
} on SocketException {
  throw const FooNetworkFailure();
} on HttpFailure catch (e) {
  throw _mapHttpFailure(e, id);
} catch (e) {
  throw UnknownFooFailure(e.toString());
}
```

This pattern subsumes every "Dio impl" code block in sessions 3–6. Where a session shows `final Dio _dio` / `_dio.get(...)` / `DioException`, mentally substitute the canonical pattern above.

### Foreground service isolate exception

The flutter_foreground_task isolate (session 4 §4.10) needs its own `http.Client` instance — Riverpod providers don't cross isolate boundaries. Construct a fresh `http.Client()` inside the foreground task handler's `onStart`. Document explicitly in session 4.

---

## §25 Audit cycle 1 resolutions

The 6-session plan went through one round of independent audit (`AUDIT.md` in this folder). Resolutions are summarized here so the meta-doc reflects current truth.

### P0 (blockers, all resolved)

| ID | Issue | Resolution |
|---|---|---|
| P0-01 | `BookingValidationError` claimed-but-undefined | Session 1 File 12 explicitly **adds** the class. |
| P0-02 | `request.user.technician_profile` wrong related_name | Session 2 uses `request.user.tech_profile` everywhere. |
| P0-03 | Sprint code uses Dio; pubspec has http | This §24 defines the canonical http pattern; sessions 3–6 reference it instead of inline Dio. |
| P0-04 | `event_urgency_router.dart` path missing `presentation/` | Sessions 3, 4 use full path `lib/core/realtime/presentation/router/event_urgency_router.dart`. |
| P0-05 | Catalog migration named 0009, should be 0008 | Session 1 renamed to `0008_subservice_max_price.py`. |
| P0-06 | Settings file `karigar/` doesn't exist | Session 2 uses `backend/core/settings.py`. |
| P0-07 | `WsFrameDispatcher.unregister` arity mismatch | Session 4 uses single-arg `unregister(streamType)`; multi-handler refactor deferred via flag `ws-stream-multi-handler-deferred`. |
| P0-08 | `tech_reliability_penalty` admin target_role unsupported | Dropped from §16 events table; replaced by `TechReliabilityIncident` log table (§11.5). |

### P1 (high, all resolved)

| ID | Issue | Resolution |
|---|---|---|
| P1-01 | Customer `phone_no` doesn't exist on User | Session 2 reads `booking.customer.userprofile.phone` via prefetch. |
| P1-02 | Tech `profile_url` wrong field | Session 2 uses `booking.technician.profile_picture.url` with `request.build_absolute_uri`. |
| P1-03 | `promo_code_snapshot` write site missing | Session 1 modifies `instant_book_service.py` to write the snapshot at booking creation. |
| P1-04 | Cache + realtime stale data | Session 2 drops `cache_control` decorator entirely. |
| P1-05 | Stream notifier mutates state from build | Session 4 uses `Future.microtask` + `ref.mounted` guard. |
| P1-06 | WS reconnect re-subscribe hand-waved | Session 4 adds `WsConnectionNotifier.connectionEvents` Stream + `TrackingSubscriptionController` listens. |
| P1-07 | Per-process throttle | Session 2 keeps in-memory throttle but opens flag `tech-location-rate-limit-not-distributed`; redis-backed alternative documented. |
| P1-08 | Fire-and-forget start_inspection | Session 5 awaits with a snackbar on failure; orchestrator idempotency makes "already INSPECTING" a no-op. |
| P1-09 | Modal endpoint dispatch via `endsWith` fragile | Sessions 5+6 use a `MODAL_ENDPOINT_KEYS` Dart constant; backend exports the same set; CI test asserts parity. |
| P1-10 | Image upload size unbounded | Session 2 serializer adds `validate_photo` with 5MB cap. |
| P1-11 | `pending` and `unknown` folded silently | Session 3 logs warning when `BookingStatus.pending` reaches `UnknownBodyStub`. |
| P1-12 | `reviews-deferred` flag missing in §20 | Already implicit; explicit `reviews-deferred` opening added to §20 session 1 row. |
| P1-13 | URL ordering in `bookings/api/urls.py` | Session 2 §4.7 shows full ordered urls.py. |
| P1-14 | `dispute_opened` admin half | Dropped; admin sees disputes via Django Admin only. §16 updated. |

### P2 / P3 / CSC

P2 items either fixed in their sessions or have flags opened. P3 nits batched with the relevant edit. CSC consistency items: `bookingDetailNotifierProvider` is the canonical name (CSC-01); use `ref.invalidate(...)` (CSC-02); `BookingStatus.fromWire(String?)` stays nullable (CSC-03).

See `AUDIT.md` for full per-item detail.
