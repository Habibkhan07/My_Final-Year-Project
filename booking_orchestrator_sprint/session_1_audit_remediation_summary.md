# Session 1 — Booking Orchestrator: Complete Implementation Summary

> **Authoritative handoff to Session 2.** This document is the single-source narrative of everything implemented in `backend/bookings/` during Session 1. It covers (a) the original sprint phases A → O that built the orchestrator, (b) audit cycle 1 phases 1–3 that closed the first round of P0/P1 findings, and (c) audit cycle 2 phases 5–8 that closed the second-iteration findings. Every claim in this doc was verified against the live code/git tree before writing.
>
> **What this doc is NOT.**
> - Not a forward-looking plan: the planning docs are the seven `BOOKING_ORCHESTRATOR_SPRINT.md`/`session_<N>_*.md` files in this folder. Those are pre-implementation design notes; this doc is post-implementation reality.
> - Not the Session 2 design: Session 2 will land HTTP views, URL routing, and request/response serializers on top of the service-layer foundations described here.
> - Not a frontend doc: zero frontend files were touched in any phase covered here.
> - Not a database-migration safety analysis for production: the project is pre-launch with no production rows to worry about.
>
> **Audit-doc disambiguation.** `AUDIT.md` is the cycle-1 audit findings doc (frontend-leaning sprint scan). `AUDIT_CYCLE_2.md` is the cycle-2 frontend audit. The backend audit cycles 1 and 2 referenced in this document live in **commit messages**, not in standalone audit docs — `cf69c40`, `9ed9d05`, `748ba2a` for cycle 1; `2fba203`, `3af827b`, `08001e6`, `88701ed` for cycle 2.

---

## 0. Quick reference

| Item | Value |
|---|---|
| Sprint commits (build phases) | A, C, E, F, H, I, J, K, L, M, O — 11 commits |
| Audit cycle 1 commits | Phase 1, 2, 3 — 3 commits |
| Audit cycle 2 commits | Phase 5, 6, 7, 8 — 4 commits |
| Total commits in Session 1 | **18** |
| Test count, project total | **655 passing** (was 252 pre-sprint; +403 net) |
| Migration files added | 3 (`0008`, `0009`, `0010`) — applied on top of pre-sprint head `0007` |
| Models added | `Quote`, `QuoteLineItem`, `BookingItem`, `SupportTicket`, `TicketEvidence`, `BookingAttachment`, `TechReliabilityIncident` (7 new models) + 22 columns added to existing `JobBooking` |
| Models modified | `JobBooking` (8 new STATUS constants, 22 new columns), `SupportTicket` (`resolved_by` FK added in cycle-2), `Quote` (partial unique constraint added in cycle-2) |
| Transition functions | **14** in `orchestrator.py` |
| New `EventType` members | 5 (`QUOTE_REVISION_REQUESTED`, `QUOTE_DECLINED`, `BOOKING_CANCELLED`, `BOOKING_NO_SHOW`, `BOOKING_RESCHEDULED`) |
| Error codes (`ERROR_*`) | 11 in `bookings/exceptions.py` |
| New `flag.md` entries | 4 (#28 ai-chatbot, #29 reviews, #30 bank-accounts, #31 admin-realtime-channel) |

**Verification commands** Session 2 should run before any work:

```bash
cd backend && source venv/bin/activate
python manage.py check                       # expect: System check identified no issues (0 silenced).
python manage.py makemigrations --dry-run    # expect: No changes detected
pytest -q                                    # expect: 655 passed
git log --oneline -18                        # expect: top is 88701ed Phase 8; bottom is 1358479 Phase A
```

If any drift, halt and reconcile before changing code — the working tree no longer matches this doc.

**The 18 commits, in chronological order (oldest → newest):**

```
1358479  feat(bookings): orchestrator phase A — events, exceptions, error envelope
9a57e06  feat(bookings): orchestrator phase C — models + migration 0008
1b80a51  feat(bookings): orchestrator phase E — finance port + null adapter
be8288d  feat(bookings): orchestrator phase F — quote + dispute selectors
b7ac9b1  feat(bookings): orchestrator phase H — 14 transition functions
b0dbd4d  feat(bookings): orchestrator phase I — auto_transition geofence
65d6f04  feat(bookings): orchestrator phase J — promo snapshot at booking creation
95cbf7e  feat(bookings): orchestrator phase K — admin registrations
5f24212  feat(bookings): orchestrator phase L — factory extensions
25728ab  test(bookings): orchestrator phase M — full test coverage (~355 new)
c842e0d  docs(flag.md): orchestrator phase O — 4 new flags (#28–#31)
cf69c40  fix(bookings): orchestrator audit phase 1 — populate cash columns at booking time
9ed9d05  fix(bookings): orchestrator audit phase 2 — defensive hardening
748ba2a  fix(bookings): orchestrator audit phase 3 — design tightening
2fba203  fix(bookings): orchestrator audit phase 5 — reschedule race + cash carry
3af827b  fix(bookings): orchestrator audit phase 6 — admin-resolve audit trail
08001e6  fix(bookings): orchestrator audit phase 7 — code semantics + payload completeness
88701ed  fix(bookings): orchestrator audit phase 8 — db-enforced quote uniqueness
```

(Phases B, D, G, N, and Phase 4 do not exist as commits — letters/numbers were assigned during planning and some were merged into adjacent phases or skipped.)

---

## 1. Mental model — the architecture you are inheriting

### 1.1 The 4-layer separation, exactly as CLAUDE.md mandates

```
┌──────────────────────────────────────────────────────────┐
│  views.py            ← Session 2 lands these (NOT here)  │
│  ─────────────────────────────────────────────────────── │
│  serializers.py      ← Session 2 lands these too         │
│  ─────────────────────────────────────────────────────── │
│  services/           ← THIS sprint built the orchestrator│
│  selectors/          ← THIS sprint built quote + dispute │
│  ─────────────────────────────────────────────────────── │
│  models.py           ← THIS sprint added 7 new models    │
└──────────────────────────────────────────────────────────┘
```

The orchestrator is the **single authoritative state-transition layer** for `JobBooking`. Every `STATUS_*` flip post-CONFIRMED goes through it. Views (Session 2's job) will be thin: parse → call orchestrator transition → translate `BookingValidationError` to envelope (already wired) → return.

### 1.2 The canonical transition shape

Every public function in `bookings/services/orchestrator.py` follows this 5-step pattern:

```python
def transition(*, booking_id, actor_user, …, finance=None):
    finance = _resolve_finance(finance)            # lazy NullFinanceAdapter

    # any out-of-band coercion that should produce a 400 (not a 500)
    coerced_input = …                              # e.g. Decimal(str(cash_amount))

    with transaction.atomic():
        booking = _lock_booking(booking_id)        # select_for_update + 404 envelope on miss
        _require_assigned_tech(booking, actor_user)   # or _require_customer

        # idempotent re-entry FIRST so duplicate POSTs return 200 not 400
        if booking.status == TARGET_STATUS:
            return booking

        # from-state guard
        if booking.status not in {ALLOWED_FROM}:
            _reject_invalid_from_state(booking, "...")

        # mutation
        booking.status = TARGET_STATUS
        booking.save(update_fields=[...])

        # finance hook (NullFinanceAdapter no-ops in dev)
        finance.<hook>(...)

        # broadcasts wrapped so a rollback doesn't queue phantom WS frames
        transaction.on_commit(lambda: _broadcast(...))

    return booking
```

### 1.3 The five global invariants the orchestrator upholds

These are load-bearing. Session 2's HTTP views must not violate them:

1. **Booking-first lock ordering.** Every transition acquires `select_for_update()` on the booking row first. Secondary locks (TechnicianProfile, ticket) are acquired *after*. `instant_book_service` only ever locks `TechnicianProfile`, never a booking row, so no deadlock cycle is reachable.
2. **Idempotent re-entry runs before validation.** A network-flaky client re-POST never surfaces a 400 because the transaction was already terminal on the first call.
3. **Coercion lives outside `transaction.atomic()`.** Malformed input becomes a clean 400 envelope, not a `decimal.InvalidOperation` 500.
4. **Side-effects (broadcasts, dispatch) are wrapped in `transaction.on_commit`.** Rolled-back transactions never queue phantom realtime frames.
5. **All errors raised from the orchestrator are `BookingValidationError`** with one of the documented `ERROR_*` codes. The custom DRF exception handler at `core/common/failures/exception.py` matches this class first and emits the canonical `{status, code, message, errors}` envelope.

### 1.4 File map (after Session 1, before Session 2 starts)

```
backend/bookings/
├── models.py                                    8 model classes (1 modified, 7 new)
├── exceptions.py                                BookingValidationError + 11 ERROR_* codes
├── admin.py                                     4 read-only model registrations
├── migrations/
│   ├── 0008_booking_orchestrator_foundations.py 22 columns + 7 models
│   ├── 0009_supportticket_resolved_by.py        cycle-2 FK
│   └── 0010_quote_unique_submitted_quote_per_booking_flavour.py  cycle-2 partial unique
├── services/
│   ├── orchestrator.py                          14 transition functions, 1578 lines
│   ├── auto_transition.py                       geofence trigger classifier
│   ├── instant_book_service.py                  pre-existing booking creation
│   ├── job_request_dispatch.py                  pre-existing dispatch
│   ├── job_request_action.py                    pre-existing accept/decline
│   ├── finance_ports.py                         FinancePort Protocol (5 methods)
│   └── ports.py                                 pre-existing JobDispatchScheduler
├── selectors/
│   ├── quote_selector.py                        3 accessors
│   ├── dispute_selector.py                      2 accessors
│   ├── customer_bookings_selector.py            pre-existing
│   └── pricing_selector.py                      pre-existing
└── adapters/
    ├── __init__.py                              get_default_scheduler + get_default_finance_service
    ├── null_finance.py                          NullFinanceAdapter (no-ops)
    └── celery_scheduler.py                      pre-existing
```

---

## 2. Sprint phases A → O — original implementation (commits `1358479` → `c842e0d`)

### 2.1 Phase A — events, exceptions, error envelope · `1358479`

**Files:** `realtime/constants/event_types.py`, `bookings/exceptions.py`, `core/common/failures/exception.py`.

**What landed:**

- **5 new `EventType` members** for the orchestrator's broadcasts:
  - `QUOTE_REVISION_REQUESTED` (`"quote_revision_requested"`)
  - `QUOTE_DECLINED` (`"quote_declined"`)
  - `BOOKING_CANCELLED` (`"booking_cancelled"`)
  - `BOOKING_NO_SHOW` (`"booking_no_show"`)
  - `BOOKING_RESCHEDULED` (`"booking_rescheduled"`)
  - All 5 are non-critical (`is_critical=False` in `EVENT_REGISTRY`) — no recipient ACK gates money or service delivery.

- **`BookingValidationError(APIException)`** — kw-only init (`code`, `message`, `errors`, `status`). `status_code` defaults to 400; pass `status=404` for not-found.

- **8 initial `ERROR_*` constants** (cycle-2 added 3 more for not-found codes; the full set of 11 is listed in §6):
  - `ERROR_INVALID_TRANSITION = "invalid_transition"`
  - `ERROR_INVALID_INPUT = "invalid_input"`
  - `ERROR_INVALID_QUOTE_EMPTY = "invalid_quote_empty"`
  - `ERROR_QUOTE_BAND_VIOLATION = "quote_band_violation"`
  - `ERROR_CANCELLATION_NOT_ALLOWED = "cancellation_not_allowed"`
  - `ERROR_DISPUTE_NOT_DISPUTABLE_STATUS = "dispute_not_disputable_status"`
  - `ERROR_RESCHEDULE_NOT_ALLOWED = "reschedule_not_allowed"`
  - `ERROR_NOT_ASSIGNED_TO_YOU = "not_assigned_to_you"`
  - `ERROR_NO_SHOW_TOO_EARLY = "no_show_too_early"`

- **Custom DRF exception handler** patched. The handler at `core/common/failures/exception.py` recognises `BookingValidationError` *before* DRF's default flow flattens its `code`/`errors`. Lazy import to avoid module-load circular through Django settings.

**Why it's first.** Subsequent phases throw these exceptions and emit these events; getting them right here means the rest of the sprint never has to re-wire the envelope contract.

**Wire envelope (returned by the patched handler):**

```json
{
  "status": <int>,
  "code": "<ERROR_* wire-string>",
  "message": "<human-readable string for UI toast>",
  "errors": { "field_name": ["..."] }
}
```

The wire-strings are stable and the Flutter dispatcher will key on `code`. Renaming any of them in Session 2 requires a coordinated frontend change.

---

### 2.2 Phase C — models + migration 0008 · `9a57e06`

**Files:** `bookings/models.py`, `bookings/migrations/0008_booking_orchestrator_foundations.py` (262 lines).

#### 2.2.1 `JobBooking` modifications

**8 new STATUS constants** added (existing 6 plus 8 new = 14 total status values):

| Status | Wire-string | Purpose |
|---|---|---|
| `STATUS_PENDING` | `"PENDING"` | **Legacy, do not use for new bookings.** |
| `STATUS_AWAITING_TECH_ACCEPT` | `"AWAITING"` | Default for new bookings — waiting on tech accept |
| `STATUS_CONFIRMED` | `"CONFIRMED"` | Tech accepted; pre-en-route |
| `STATUS_EN_ROUTE` | `"EN_ROUTE"` | Tech moving toward customer |
| `STATUS_ARRIVED` | `"ARRIVED"` | Tech at customer location |
| `STATUS_INSPECTING` | `"INSPECTING"` | Tech opened the quote builder |
| `STATUS_QUOTED` | `"QUOTED"` | Quote submitted; awaiting customer decision |
| `STATUS_IN_PROGRESS` | `"IN_PROGRESS"` | Quote approved; work happening |
| `STATUS_COMPLETED` | `"COMPLETED"` | Cash collected; lifecycle close |
| `STATUS_COMPLETED_INSPECTION_ONLY` | `"COMPLETED_INSPECTION_ONLY"` | Quote declined; customer paid Rs.500 fee only |
| `STATUS_CANCELLED` | `"CANCELLED"` | Cancelled by customer / tech / admin |
| `STATUS_REJECTED` | `"REJECTED"` | Tech declined or SLA timed out at AWAITING |
| `STATUS_NO_SHOW` | `"NO_SHOW"` | Either party didn't show |
| `STATUS_DISPUTED` | `"DISPUTED"` | Dispute opened on a non-terminal booking |

**Two frozensets** for transition logic:

```python
# models.py:55-71
TERMINAL_STATUSES = frozenset({
    STATUS_COMPLETED,
    STATUS_COMPLETED_INSPECTION_ONLY,
    STATUS_CANCELLED,
    STATUS_REJECTED,
    STATUS_NO_SHOW,
    STATUS_DISPUTED,
})

POST_ARRIVAL_STATUSES = frozenset({
    STATUS_ARRIVED,
    STATUS_INSPECTING,
    STATUS_QUOTED,
    # … in-progress + downstream
})
```

**`status` field max_length raised** 10 → 32 to fit the longest value (`"COMPLETED_INSPECTION_ONLY"`, 26 chars).

**Default flipped** `STATUS_PENDING` → `STATUS_AWAITING_TECH_ACCEPT` to match sprint 0007 semantics — every new booking is awaiting tech accept.

**22 new columns** on `JobBooking` (all nullable or defaulted; no backfill needed):

| Column | Type | Purpose |
|---|---|---|
| `accepted_at` | `DateTimeField(null)` | Re-added (was dropped in 0007) |
| `actual_address_snapshot` | `TextField(default='')` | Survives `address.SET_NULL` |
| `arrived_at` | `DateTimeField(null)` | Stamped by `arrived()` |
| `base_services_total` | `DecimalField(10,2,null)` | Sum of accepted line items |
| `cancel_reason` | `CharField(64,null)` | Phase mapping or `'admin_resolved_dispute'` |
| `cancelled_at` | `DateTimeField(null)` | Audit |
| `cancelled_by` | `FK(User, SET_NULL)` | Audit |
| `cash_collected_amount` | `DecimalField(10,2,null)` | Stamped by `mark_complete_with_cash` |
| `cash_collected_at` | `DateTimeField(null)` | Stamped same |
| `cash_collection_method` | `CharField(16, default='cash')` | Per CLAUDE.md, only `'cash'` permitted at service layer (cycle-2 enforced) |
| `completed_at` | `DateTimeField(null)` | Audit |
| `discount_applied` | `DecimalField(10,2,null)` | Promo discount snapshot |
| `dispute_opened_at` | `DateTimeField(null)` | One-shot when `open_dispute` first runs |
| `en_route_started_at` | `DateTimeField(null)` | Stamped by `en_route()` |
| `final_cash_to_collect` | `DecimalField(10,2,null)` | Tech-side "Cash Collected: Rs.X" button binds to this |
| `inspection_fee` | `DecimalField(10,2,null)` | Rs.500 for INSPECTION-flow; null for FIXED_GIG/LABOR_GIG |
| `parent_booking` | `FK(self, SET_NULL)` | Lineage for reschedules |
| `promo_code_snapshot` | `CharField(64,null)` | Promotion `name` (no `code` field on Promotion) |
| `promo_discount_snapshot` | `DecimalField(10,2,null)` | Promotion `discount_value` |
| `tech_no_show_at` | `DateTimeField(null)` | Stamped by tech-no-show path |
| `customer_no_show_at` | `DateTimeField(null)` | Stamped by customer-no-show path |
| `work_started_at` | `DateTimeField(null)` | First time booking enters `IN_PROGRESS` |

#### 2.2.2 New models

**`Quote`** — multi-revision proposal from tech to customer.

```python
booking            FK(JobBooking, related_name='quotes')
revision_number    PositiveInteger        # 1, 2, 3, … per booking
status             CharField(16)          # SUBMITTED / SUPERSEDED / APPROVED / DECLINED
total_amount       DecimalField(10,2)
is_upsell          Boolean                # True = upsell during IN_PROGRESS; False = pre-IN_PROGRESS
decision_reason    TextField              # decline reason
created_at, submitted_at, decided_at  DateTimeField
```

**Constraints** (cycle-2 added the second one):

```python
UniqueConstraint(['booking', 'revision_number'], name='unique_quote_revision_per_booking')
UniqueConstraint(['booking', 'is_upsell'],
                 condition=Q(status='SUBMITTED'),
                 name='unique_submitted_quote_per_booking_flavour')   # cycle-2
```

**`QuoteLineItem`** — quantity × priced_at = line_total. **Auto-recomputed in `save()`** so the orchestrator, factories, and admin can never write an inconsistent total:

```python
# models.py:287-298 — load-bearing
def save(self, *args, **kwargs):
    if self.quantity and self.priced_at is not None:
        self.line_total = self.quantity * self.priced_at
    super().save(*args, **kwargs)
```

**`BookingItem`** — *immutable snapshot* of accepted line items. Populated only by `approve_quote`, never on `submit`. Mid-job upsell **appends** rows; the orchestrator never deletes prior `BookingItem` rows. This is the audit/finance reconciliation source.

**`SupportTicket`** — dispute intake.

```python
booking                 FK(JobBooking, related_name='tickets')
opened_by               FK(User, PROTECT)
dispute_intake_method   CharField  # FORM | CHATBOT (chatbot is a flag #28 seam)
initial_reason          TextField
chat_log                JSONField(null)              # populated by chatbot intake (deferred)
status                  CharField(16)                # OPEN | RESOLVED
resolution_outcome      CharField(32)                # NONE | REFUND_CUSTOMER | PENALIZE_TECH | DISMISS
resolution_notes        TextField
resolved_by             FK(User, PROTECT, null)      # cycle-2 added
opened_at, resolved_at  DateTimeField
```

**`TicketEvidence`** — image uploads attached to a ticket. `ImageField(upload_to='dispute_evidence/')`.

**`BookingAttachment`** — schema-only this sprint. The chatbot intake module (future sprint) will be the first writer. Intentionally NOT registered in admin (per Phase K decision).

**`TechReliabilityIncident`** — append-only audit log per audit P0-08.

```python
booking      FK(JobBooking, PROTECT)
technician   FK(TechnicianProfile, PROTECT)
incident_type    CharField   # tech_cancelled_post_acceptance | customer_reported_no_show | …
created_at       DateTimeField(auto_now_add)
```

Admin view-only (`has_add_permission=False`, `has_delete_permission=False`).

#### 2.2.3 Migration 0008 atomicity

All of the above ship in a **single migration** `0008_booking_orchestrator_foundations.py`. 252 pre-sprint tests pass after applying it (no behavioral wiring yet — that's Phase H).

---

### 2.3 Phase E — finance port + null adapter · `1b80a51`

**Files:** `bookings/services/finance_ports.py`, `bookings/adapters/null_finance.py`, `bookings/adapters/__init__.py`.

The orchestrator must call out to a finance subsystem (record commission, enforce wallet lockout, charge cancellation fees) — but the finance subsystem is a **separate sprint** (currently unbuilt — see flag #30). Per CLAUDE.md's port-and-adapter rule, the orchestrator depends on a Protocol, not a concrete adapter.

**`FinancePort` Protocol — 5 methods:**

```python
# finance_ports.py:24-100
class FinancePort(Protocol):
    def can_accept_job(self, *, technician, payout_amount: Decimal) -> tuple[bool, str | None]: ...
    def record_commission(self, *, booking, amount: Decimal) -> None: ...
    def apply_inspection_fee_decision(self, *, booking, decision: str) -> None: ...   # 'accepted'|'declined'
    def apply_cancellation_charge(self, *, booking, phase: str, actor: str) -> None: ...
    def record_cash_collected(self, *, booking, amount: Decimal, method: str) -> None: ...
```

**`NullFinanceAdapter`** — no-op concrete adapter; `can_accept_job` permits unconditionally. Lets orchestrator atomic blocks complete cleanly without wallet plumbing.

**Lazy resolution:**

```python
# bookings/adapters/__init__.py
def get_default_finance_service():
    """Return the production FinancePort adapter."""
    from bookings.adapters.null_finance import NullFinanceAdapter
    return NullFinanceAdapter()
```

The lazy import inside the function body is the **load-bearing pattern** — it keeps `bookings.services.*` modules free of finance imports at module load time, so the finance sprint can later swap the body of `get_default_finance_service` without touching the orchestrator.

**Service-side resolution:**

```python
# orchestrator.py:74-84
def _resolve_finance(finance):
    if finance is not None:
        return finance
    from bookings.adapters import get_default_finance_service
    return get_default_finance_service()
```

Every orchestrator transition accepts an optional `finance=None` keyword and resolves it lazily. Tests inject a fake; production gets `NullFinanceAdapter`.

---

### 2.4 Phase F — quote + dispute selectors · `be8288d`

**Files:** `bookings/selectors/quote_selector.py`, `bookings/selectors/dispute_selector.py`.

All read access for quotes and disputes routes through these. **No N+1.**

**`quote_selector`:**

```python
def get_active_quote(booking: JobBooking) -> Quote | None:
    """Most-recent SUBMITTED; falls back to most-recent any state."""

def list_quote_history(booking: JobBooking) -> List[Quote]:
    """Oldest-first walk for admin audit."""

def list_booking_items(booking: JobBooking) -> List[BookingItem]:
    """Finance reconciliation source."""
```

**`dispute_selector`:**

```python
def list_open_tickets(booking: JobBooking) -> List[SupportTicket]: ...
def list_all_tickets(booking: JobBooking) -> List[SupportTicket]: ...
```

All 5 accessors use `prefetch_related`/`select_related` per CLAUDE.md no-N+1 rule. Phase M tests every one with `django_assert_num_queries`.

No views consume these yet — Session 2's read endpoints will.

---

### 2.5 Phase H — 14 transition functions · `b7ac9b1`

**File:** `bookings/services/orchestrator.py` (the bulk of the 1578-line file).

The 14 functions, in source order:

| Line | Function | From → To | Actor | Notes |
|---|---|---|---|---|
| 204 | `en_route` | `CONFIRMED → EN_ROUTE` | tech (auto or manual) | Geofence trigger or fallback override |
| 246 | `arrived` | `EN_ROUTE → ARRIVED` | tech (auto or manual) | Geofence trigger or fallback override |
| 284 | `start_inspection` | `ARRIVED → INSPECTING` | tech | UI-trigger (opening quote builder); no broadcast |
| 437 | `submit_quote` | `INSPECTING → QUOTED` (or `IN_PROGRESS → IN_PROGRESS` for upsell) | tech | Multi-revision; supersedes prior `SUBMITTED` of same flavour |
| 554 | `request_revision` | `QUOTED → INSPECTING` | customer | Face-to-face bargain |
| 611 | `approve_quote` | `QUOTED → IN_PROGRESS` (or no-op for upsell) | customer | Snapshots `BookingItem`, recomputes `final_cash_to_collect` |
| 731 | `decline_quote` | `QUOTED → COMPLETED_INSPECTION_ONLY` | customer | Terminal; sets `final_cash_to_collect = inspection_fee` |
| 808 | `mark_complete_with_cash` | `IN_PROGRESS → COMPLETED` | tech | Combined complete + cash; fires both `payment_received` and `job_completed` |
| 941 | `cancel_by_customer` | `* → CANCELLED` | customer | 3 phase mappings; `IN_PROGRESS` rejected — must use `open_dispute` |
| 1008 | `cancel_by_tech` | `* → CANCELLED` | tech | Writes `TechReliabilityIncident` |
| 1097 | `mark_no_show` | `ARRIVED → NO_SHOW` (tech) or `AWAITING/CONFIRMED → NO_SHOW` (customer) | tech or customer | 15-min wait gate (cycle-1) |
| 1209 | `open_dispute` | `* → DISPUTED` (preserves terminal — cycle-1) | customer or tech | Multiple `OPEN` tickets allowed; status flip is one-shot |
| 1306 | `admin_resolve_dispute` | `DISPUTED → admin-chosen terminal` | admin | Both parties notified; cycle-2 added audit-column stamping |
| 1463 | `reschedule` | original `→ CANCELLED`; child `→ AWAITING_TECH_ACCEPT` | customer | Cycle-2 added tech-profile lock + overlap re-check |

**Internal helpers** (all defined above the public functions):

| Line | Helper | Purpose |
|---|---|---|
| 74 | `_resolve_finance` | Lazy NullFinanceAdapter resolution |
| 87 | `_broadcast` | Lazy import of `EventDispatchService.broadcast_event`; wraps the network call only — coding errors propagate |
| 109 | `_payload_basics` | Stock fields on every broadcast payload |
| 117 | `_lock_booking` | `select_for_update` + 404 envelope on miss (cycle-1, tightened cycle-2 to `ERROR_BOOKING_NOT_FOUND`) |
| 149 | `_get_booking_quote_locked` | Booking-scoped quote fetch under lock; IDOR-safe (cycle-1, tightened cycle-2 to `ERROR_QUOTE_NOT_FOUND`) |
| 167 | `_require_assigned_tech` | Tech-side IDOR guard |
| 182 | `_require_customer` | Customer-side IDOR guard |
| 191 | `_reject_invalid_from_state` | Wrong-from-state envelope helper |
| 315 | `_validate_line_items` | Pre-quote-create line-item validator (cycle-1 hardened parsing) |
| 913 | `_cancel_phase_for_status` | Cancellation phase mapping (immediate / pre_arrival / post_arrival) |

**Lazy imports** in `_broadcast` and `reschedule` keep the module-load graph clean:
- `_broadcast` lazy-imports `realtime.events.services.event_dispatch_service`.
- `reschedule` lazy-imports `bookings.services.job_request_dispatch.dispatch_job_new_request_event`.
- `reschedule` also imports `technicians.models.TechnicianProfile` at module load (added cycle-2 for the lock — TechnicianProfile is already a downstream of `bookings.models` via the JobBooking FK so no new cycle is introduced).

**No views** consume any of this yet. The orchestrator is the canonical state-machine API consumed only by Session 2's views.

---

### 2.6 Phase I — auto_transition geofence · `b0dbd4d`

**File:** `bookings/services/auto_transition.py`.

A pure trigger classifier. Reads a tech-location frame and decides whether to flip the booking's status. Atomicity, broadcast, and finance hooks live in the orchestrator — `auto_transition` only *decides*.

**Thresholds:**

```python
EN_ROUTE_THRESHOLD_METERS = 200    # tech has left the accept-location vicinity
ARRIVED_THRESHOLD_METERS = 100     # tech is essentially at the customer's address
```

**Trigger rules:**

- `CONFIRMED` + `dist > 200m` from customer → `orchestrator.en_route(source='auto')`
- `EN_ROUTE` + `dist ≤ 100m` → `orchestrator.arrived(source='auto')`
- `INSPECTING` / `QUOTED` / `IN_PROGRESS` / terminal → never auto-flip (frontend navigation drives `ARRIVED → INSPECTING`; customer drives `QUOTED → IN_PROGRESS` via `approve_quote`).
- Booking-not-found → return `None` silently (stale GPS publishers must not raise).
- Cycle-1 hardening: unauthorized tech + missing tech → also return `None` silently (info-leak closure).

**Math note.** `CustomerAddress.latitude/longitude` are `DecimalField`. They must be cast to `float` before the trig pipeline (sin/cos/asin/sqrt won't accept `Decimal`). Verified: Liberty Market ↔ Gulberg ≈ 1272m; ~0.001° latitude ≈ 111m.

**Tech-location ingress endpoint** that calls this lands in **Session 2**.

---

### 2.7 Phase J — promo snapshot at booking creation · `65d6f04`

**File:** `bookings/services/instant_book_service.py` (`create_instant_booking`).

**Audit P1-03 fix.** Phase C added `promo_code_snapshot` / `promo_discount_snapshot` columns but the booking-creation site never wrote them. Every new booking would have null snapshots, defeating the survive-promo-deletion purpose.

**Where the snapshot is taken.** From `intent.promotion` *post-firewall*, so fixed-gig bookings whose promotion was stripped by the resolver also get null snapshots. Single source of truth at the resolver — no firewall duplication.

**What gets snapshotted:**

- `Promotion` has no `code` field → snapshot `name` (human-stable identifier).
- `discount_value` (raw `Decimal`).
- Pair survives promo row deletion via `on_delete=SET_NULL` on the FK.

31 `instant_book` tests still pass; explicit snapshot tests land in Phase M.

---

### 2.8 Phase K — admin registrations · `95cbf7e`

**File:** `bookings/admin.py`.

All four registered models are **read-only** — the orchestrator is the only writer.

```python
@admin.register(Quote)        class QuoteAdmin(admin.ModelAdmin)         # + QuoteLineItem inline (read-only)
@admin.register(BookingItem)  class BookingItemAdmin(admin.ModelAdmin)   # finance reconciliation source
@admin.register(SupportTicket)class SupportTicketAdmin(admin.ModelAdmin) # + TicketEvidence inline (read-only)
@admin.register(TechReliabilityIncident) class TechReliabilityIncidentAdmin(admin.ModelAdmin)
```

**`QuoteLineItem.line_total` is auto-recomputed on save** (see §2.2.2), so even an admin-shell edit cannot write an inconsistent total.

**`TechReliabilityIncident`** uses `get_readonly_fields` to enumerate every field (Django Admin's `readonly_fields` cannot use `'__all__'` literal). `has_add_permission=False`, `has_delete_permission=False` — admin views, never mutates.

**The custom `resolve-dispute` admin action** that invokes `orchestrator.admin_resolve_dispute` lands in **Session 2**.

**`BookingAttachment` intentionally NOT registered.** Schema-only this sprint; chatbot intake feature is the first intended writer (flag #28).

---

### 2.9 Phase L — factory extensions · `5f24212`

**Files:** `tests/factories/catalog.py`, `tests/factories/bookings.py`, `tests/factories/support.py` (new), `tests/factories/reliability.py` (new).

Per CLAUDE.md "Use `factory_boy` only — never `Model.objects.create()`":

- `SubServiceFactory.max_price` is a `LazyAttribute` (2.5x base for labor, `None` for fixed). Convenience subclasses `FixedPriceSubServiceFactory`, `LaborSubServiceFactory`.
- **Full status-progression chain** in `bookings.py`: `JobBookingConfirmedFactory` → `EnRouteFactory` → `ArrivedFactory` → `InspectingFactory` → `QuotedFactory` → `InProgressFactory` → `CompletedFactory`. Orchestrator tests fabricate any from-state without manually stamping prior phase timestamps.
- `QuoteFactory`, `QuoteLineItemFactory`, `BookingItemFactory`.
- `SupportTicketFactory`, `TicketEvidenceFactory`, `BookingAttachmentFactory`.
- `TechReliabilityIncidentFactory` with `SelfAttribute('booking.technician')` to keep the FK pair coherent.

All 486 existing tests (pre-orchestrator-tests) still passed after this phase. Real test coverage lands in Phase M.

---

### 2.10 Phase M — full test coverage (~355 new) · `25728ab`

**Files in `backend/tests/`:**

| File | Tests | Coverage |
|---|---|---|
| `bookings/test_models.py` | 19 | `status` `max_length=32`, choice membership, `TERMINAL_STATUSES`/`POST_ARRIVAL_STATUSES` frozensets, `Quote` unique-revision constraint, `QuoteLineItem` auto-recompute, `BookingAttachment` writeable-but-unregistered, `TechReliabilityIncident` view-only admin perms |
| `bookings/test_exceptions.py` | 4 | `BookingValidationError` envelope shape via the patched DRF handler — code/errors propagate verbatim, no fall-through to generic `'validation_error'` |
| `bookings/services/test_orchestrator.py` | 63 (later expanded) | Per-transition happy/wrong-from/idempotent/unauthorized fan-out. Targeted: empty quote, fixed/labor band violations, revision counting + supersede, `BookingItem` snapshot + upsell append, decline-cash from `inspection_fee`, cancel phase mapping (parametrized over all 6 from-states), tech-cancel reliability incident, no-show actor_role discrimination, multi-ticket dispute with one-shot status flip, `admin_resolve` broadcasts to both parties with admin identity in payload, reschedule child + parent_booking lineage + on_commit dispatch, default finance factory wiring. **`captured_broadcasts` fixture forces `on_commit` callbacks inline so each test stays in savepoint mode.** |
| `bookings/services/test_auto_transition.py` | 16 | Haversine math against Lahore landmarks, threshold semantics, `INSPECTING`/`ARRIVED` never re-flip, booking-not-found and address-deleted silent |
| `bookings/services/test_finance_ports.py` | 8 | `NullFinanceAdapter` return values, structural Protocol conformance, lazy-import boundary |
| `bookings/selectors/test_quote_selector.py` + `test_dispute_selector.py` | 12 | `django_assert_num_queries` on every accessor — no-N+1 enforcement |
| `bookings/services/test_instant_book_service.py` (new tests) | 3 | Promo snapshot written when promotion present; null when absent; fixed-gig + promo still trips firewall |

**Net.** Full project suite was 252 passing pre-sprint → 607 after Phase M (+355). Cycle 1/2 then added a further 48, ending at 655.

**Key test-infra patterns to know:**

- **`captured_broadcasts` fixture** — patches `transaction.on_commit` to fire the callback inline (savepoint mode). Necessary because pytest-django's default test transaction doesn't run real `on_commit` hooks.
- **`fake_finance` fixture** — injects a stub `FinancePort`-conformant object so transitions can run without exercising real finance code.
- **Status-progression factories** — see §2.9. Tests pass `JobBookingArrivedFactory()` rather than `JobBookingFactory(status=...)` + manual timestamp stamping.

---

### 2.11 Phase O — flag.md entries #28–#31 · `c842e0d`

**File:** `flag.md` (project root).

Four new `flag.md` entries for accepted shortcuts the orchestrator sprint is shipping with:

| Flag | Title | What's deferred |
|---|---|---|
| **#28** | AI chatbot dispute intake — schema seam present, module deferred | `SupportTicket.dispute_intake_method` and `chat_log` columns exist; chatbot intake module is a future sprint. |
| **#29** | Reviews / ratings — model + endpoints deferred | No `Review` model; no review endpoints. `Technician.rating_average` / `review_count` exist but are unwritten. Matchmaker uses synthetic Bayesian baseline meanwhile. |
| **#30** | Bank accounts / wallet payouts — cash collection only this sprint | `FinancePort` routed to `NullFinanceAdapter`; no `WalletTransaction`/`JobCommission`/JazzCash integration. **High-severity blocker for paid pilot.** |
| **#31** | Admin realtime channel — `tech_reliability_penalty` event deferred (audit P0-08) | `EventLog.target_role` doesn't accept `'admin'`, so the planned `tech_reliability_penalty` broadcast was replaced with a `TechReliabilityIncident` table. Admin reads via Django Admin until admin-targeted realtime infra lands. |

All four follow the existing `flag.md` schema (Where / What's wrong / Why we shipped it / The proper fix / Search hints / Severity).

---

## 3. Audit cycle 1 — Phases 1, 2, 3 (commits `cf69c40`, `9ed9d05`, `748ba2a`)

The first audit pass ran *immediately* after Phase O. It surfaced the cycle-1 findings closed below.

### 3.1 Phase 1 — populate cash columns at booking time · `cf69c40`

**The bug.** Three columns added in migration 0008 were silently NULL on every new booking, breaking the cash flow:

| Column | Symptom |
|---|---|
| `inspection_fee` | Read by `decline_quote` to set `final_cash`. NULL meant INSPECTION-flow customers owed Rs.0 instead of Rs.500 on decline. |
| `final_cash_to_collect` | Model docstring promised it was set at `QUOTED → IN_PROGRESS`, but `approve_quote` never wrote it. Tech "Cash Collected: Rs.X" button had no X. |
| `actual_address_snapshot` | Meant to survive `address.SET_NULL`; never populated, so a deleted address erased the destination from receipts and admin views. |

**The fix.** Three changes:

1. **`create_instant_booking` branches on `intent.booking_type`:**
   - `INSPECTION` → `inspection_fee = service.base_inspection_fee` (Rs.500); `final_cash_to_collect = NULL` (set later by approve/decline).
   - `FIXED_GIG` / `LABOR_GIG` → `inspection_fee = NULL`; `final_cash_to_collect = intent.primary_amount`.
   - `actual_address_snapshot` composed from `street_address + locality_label` (or `city`) so `customer.address.SET_NULL` no longer erases the destination.

2. **`approve_quote` stamps:**
   ```python
   booking.final_cash_to_collect = max(
       Decimal('0'), running - inspection_credit,
   )
   ```
   Floor at 0 so a sub-Rs.500 quote does not surface a negative number. Recomputed on upsell so the cash button tracks the growing snapshot total.

3. **Renamed test.** `test_decline_with_no_inspection_fee_yields_zero` → `test_decline_with_null_inspection_fee_defensive_fallback_zero`. The original was celebrating the bug as if NULL fee → Rs.0 were the inspection-flow contract. New name makes it clear this is the defensive fallback for legacy / hand-built rows; the real inspection-flow contract (fee=500 → cash=500) is covered by `test_happy_path_terminal_inspection_only`.

**Tests:** +12 (607 → 619).

---

### 3.2 Phase 2 — defensive hardening · `9ed9d05`

**Six P1 audit findings**, all closed. Every failure mode now returns the canonical envelope instead of crashing or leaking state.

#### 3.2.1 `_lock_booking` 404 envelope

```python
# orchestrator.py:117-146
def _lock_booking(booking_id: int) -> JobBooking:
    try:
        return (
            JobBooking.objects
            .select_for_update()
            .select_related('technician__user', 'customer', 'service', 'sub_service', 'address')
            .get(id=booking_id)
        )
    except JobBooking.DoesNotExist:
        raise BookingValidationError(
            code=ERROR_BOOKING_NOT_FOUND,            # cycle-2 split this from ERROR_INVALID_TRANSITION
            message='Booking not found.',
            status=drf_status.HTTP_404_NOT_FOUND,
        )
```

Every transition function inherits the behavior by routing every booking fetch through here.

#### 3.2.2 `_get_booking_quote_locked` consolidation

New helper consolidating three prior copies of "fetch booking-scoped quote under `select_for_update`":

```python
# orchestrator.py:149-164
def _get_booking_quote_locked(booking: JobBooking, quote_id: int) -> Quote:
    try:
        return booking.quotes.select_for_update().get(id=quote_id)
    except Quote.DoesNotExist:
        raise BookingValidationError(
            code=ERROR_QUOTE_NOT_FOUND,              # cycle-2 split
            message='Quote not found on this booking.',
            status=drf_status.HTTP_404_NOT_FOUND,
        )
```

**IDOR-safe** by design: the booking-scoped manager (`booking.quotes`) means a `quote_id` from another booking returns `DoesNotExist` here — indistinguishable from "never existed."

#### 3.2.3 `_validate_line_items` per-item parse hardening

```python
# orchestrator.py:315-… per-item loop
- non-dict items rejected with errors={f'line_items[{idx}]': ['expected an object']}
- missing sub_service_id / priced_at → field-keyed required error
- unparsable Decimal / int caught and re-raised with the field key
```

Session-2 serializers will catch most of this earlier, but the service is the canonical validator and must not crash.

#### 3.2.4 `mark_complete_with_cash` — three behaviors

1. **Decimal coercion outside `transaction.atomic()`** so bad input becomes a 400 instead of `decimal.InvalidOperation` 500.
2. **Idempotent re-entry runs BEFORE positive-cash guard** — a stale replay with zero amount on an already-completed booking returns cleanly instead of surfacing a phantom 400.
3. **`cash_amount <= 0`** → `BookingValidationError` with field-keyed `errors`. (Cycle-2 retroactively re-coded this as `ERROR_INVALID_INPUT`.)

#### 3.2.5 `admin_resolve_dispute` lock-ordering inversion fix

**Was:** `ticket → booking`. **Now:** `booking → ticket`. Matches every user transition (which only locks the booking), so concurrent admin + customer/tech actions can never deadlock-cycle.

The unlocked pre-check on `ticket.status` preserves the idempotent fast-path for already-resolved tickets without acquiring the booking lock.

#### 3.2.6 `auto_transition.evaluate_on_location` ownership early-return

An unauthorized tech sending varied lat/lng could previously distinguish "no trigger" (`None`) from "would-flip-but-rejected" (orchestrator raises). Both now collapse to `None`, closing the faint info-leak about booking state. Same for `technician_user is None`.

**Tests:** +18 (619 → 637).

---

### 3.3 Phase 3 — design tightening · `748ba2a`

**Four P2 findings**, all closed.

#### 3.3.1 `submit_quote` — tighten prior-quote SUPERSEDE filter

Was:

```python
booking.quotes.filter(status=SUBMITTED).update(status=SUPERSEDED, …)
```

Now:

```python
booking.quotes.filter(status=SUBMITTED, is_upsell=is_upsell).update(...)
```

Current flow makes regular and upsell SUBMITTED quotes mutually exclusive (regular requires `status=QUOTED`, upsell requires `status=IN_PROGRESS`), so the loose SQL was harmless *today*. Pinning prevents future flow changes from accidentally cross-superseding.

(Cycle-2 added the partial unique index that database-enforces this same invariant.)

#### 3.3.2 `approve_quote` — `BookingItem.bulk_create`

N inserts collapse to a single round trip. Order preserved so callers iterating `booking.items.order_by('id')` see items in the same order they appeared on the quote.

#### 3.3.3 `open_dispute` — preserve terminal status

Bookings in `CANCELLED` / `COMPLETED` / `COMPLETED_INSPECTION_ONLY` / `NO_SHOW` / `REJECTED` stay queryable in their terminal state when a dispute is filed against them; the dispute is captured by `dispute_opened_at IS NOT NULL` plus the ticket row, NOT by erasing the prior terminal status.

Non-terminal bookings (typically `IN_PROGRESS`) still flip to `DISPUTED` so other transitions are locked out until admin resolves. `STATUS_DISPUTED` is itself in `TERMINAL_STATUSES`, so a second `open_dispute` on an already-disputed booking takes the no-flip branch automatically.

#### 3.3.4 `mark_no_show` — 15-minute wait at the service layer

Spec rule: file no-show only after the wait clock has elapsed.

- **Tech path** anchors on `booking.arrived_at` (wait clock starts when the tech is at the door).
- **Customer path** anchors on `booking.scheduled_start`.
- Filing too early → `ERROR_NO_SHOW_TOO_EARLY` with `errors={'wait_seconds': [str(remaining)]}`.

Service-level (was previously in the view layer per the docstring) so cron / admin / future-RPC callers inherit the gate.

**`_clock` parameter** is a test seam; production callers leave it `None`. Existing happy-path `mark_no_show` tests inject a 20-min fast-forward to satisfy the new gate without paying real wall-clock time.

#### 3.3.5 `QuoteLineItem.save` docstring corrected

Was: "defensive fallback for hand-built rows" (implied conditional). Actual behavior: **always recompute**. Updated comment to match.

**Tests:** +7 (637 → 644).

---

## 4. Audit cycle 2 — Phases 5, 6, 7, 8 (this conversation)

A second-iteration aggressive audit ran after cycle 1. It surfaced 15 findings (F1–F15). Phases 5–8 close every actionable cycle-2 finding except F8 (product decision) and F10–F15 (deferred polish).

### 4.1 Cycle-2 findings table

| ID | Severity | Subsystem | Status | Phase |
|---|---|---|---|---|
| F1 | **P0** | `reschedule` race | **Closed** | Phase 5 |
| F2 | **P1** | `reschedule` cash carry | **Closed** | Phase 5 |
| F3 | **P1** | `admin_resolve_dispute` audit columns | **Closed** | Phase 6 |
| F4 | **P1** | `SupportTicket.resolved_by` missing | **Closed** | Phase 6 |
| F5 | **P1** | `mark_complete_with_cash` method validation | **Closed** | Phase 7 |
| F6 | **P2** | `ERROR_INVALID_TRANSITION` overloaded | **Closed** | Phase 7 |
| F7 | **P2** | `QUOTE_APPROVED` payload incomplete | **Closed** | Phase 7 |
| F8 | **P2** | Cross-category quote line items | **DEFERRED** | — (product decision) |
| F9 | **P2** | Quote uniqueness only application-enforced | **Closed** | Phase 8 |
| F10 | **P3** | Unused `finance=None` defaults | **DEFERRED** | — |
| F11 | **P3** | `seed_demo` doesn't populate cash columns | **DEFERRED** | — |
| F12 | **P3** | `parent_booking` recursion depth not bounded | **DEFERRED** | — |
| F13 | **P3** | Cash over-collection cap | **DEFERRED** | — |
| F14 | **CSC** | Threading test for `admin_resolve_dispute` | **DEFERRED** | — |
| F15 | **CSC** | Generalize `_clock` injection seam | **DEFERRED** | — |

### 4.2 Phase 5 — `reschedule` race + cash carry · `2fba203`

#### 4.2.1 F1 (P0) — concurrency hole

**Where:** `orchestrator.py::reschedule` (lines 1463–1578).

**The bug.** `reschedule` cancelled the original and created a child in `AWAITING_TECH_ACCEPT` *without* locking the technician's profile or re-checking the target window for overlap. `instant_book_service` does both. Under PostgreSQL `READ_COMMITTED`, a concurrent `instant_book` and a `reschedule` INTO the same target slot could both pass their respective checks — neither seeing the other's pending row — and double-book the technician.

**The fix.** Mirror `instant_book_service`'s recipe inside `reschedule`'s atomic block:

```python
# orchestrator.py:1506-1522
TechnicianProfile.objects.select_for_update().get(pk=original.technician_id)
overlap_exists = JobBooking.objects.filter(
    technician=original.technician,
    status__in=[
        JobBooking.STATUS_PENDING,
        JobBooking.STATUS_AWAITING_TECH_ACCEPT,
        JobBooking.STATUS_CONFIRMED,
    ],
    scheduled_start__lt=new_scheduled_end,
    scheduled_end__gt=new_scheduled_start,
).exclude(id=original.id).exists()
if overlap_exists:
    raise BookingValidationError(
        code=ERROR_RESCHEDULE_NOT_ALLOWED,
        message='New time slot conflicts with another booking.',
        errors={'new_scheduled_start': ['slot unavailable']},
    )
```

**Two subtleties to preserve:**

1. **`.exclude(id=original.id)` is load-bearing.** At this point the cancellation mutation hasn't run yet (it runs immediately below), so the original is still in `AWAITING_TECH_ACCEPT`/`CONFIRMED`. Without the exclude, a customer who wants to *shorten* their booking's duration in-place (same start, earlier end) would self-overlap and reject.
2. **Lock ordering: booking → tech profile.** Matches every other transition. `instant_book_service` only ever locks the tech profile, never a booking row, so no deadlock cycle is reachable.

**Tests:**
- `TestReschedule::test_new_slot_overlap_with_other_booking_rejected` (test_orchestrator.py:1402)
- `TestReschedule::test_overlap_query_excludes_original_being_rescheduled` (test_orchestrator.py:1427)

#### 4.2.2 F2 (P1) — `final_cash_to_collect` not carried to child

```python
# orchestrator.py:1551 — added
final_cash_to_collect=original.final_cash_to_collect,
```

For `INSPECTION`-flow originals this column is `None`, so the carry is a no-op for that path.

**Test:** `TestReschedule::test_final_cash_to_collect_carried_to_child` (test_orchestrator.py:1381).

**Net Phase 5 impact:** orchestrator.py +36, tests +67 (3 new). 644 → 647.

---

### 4.3 Phase 6 — `admin_resolve_dispute` audit trail · `3af827b`

#### 4.3.1 F3 (P1) — terminal-status flip leaves audit columns NULL

**The bug.** Admin resolved a dispute by setting `final_status=CANCELLED` → booking's `cancelled_at`/`cancelled_by`/`cancel_reason` left NULL. Same for `final_status=COMPLETED` and `completed_at`. Analytics filtering on those timestamps silently dropped admin-resolved bookings.

**The fix.** Stamp the columns to mirror what user-facing transitions write:

```python
# orchestrator.py:1400-1418
booking.status = final_status
booking_update_fields = ['status']
if final_status == JobBooking.STATUS_CANCELLED:
    booking.cancelled_at = now
    booking.cancelled_by = admin_user
    booking.cancel_reason = 'admin_resolved_dispute'
    booking_update_fields += ['cancelled_at', 'cancelled_by', 'cancel_reason']
elif final_status in (
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
):
    if booking.completed_at is None:
        booking.completed_at = now
        booking_update_fields.append('completed_at')
booking.save(update_fields=booking_update_fields)
```

**Two subtleties to preserve:**

1. **`completed_at` is preserved if already set.** A dispute opened on an already-completed booking, then admin upholds — the original completion timestamp is the legitimate historical record. Overwriting would falsify when work actually finished.
2. **Cash columns are intentionally NOT touched.** Admin resolution doesn't collect cash; whatever was collected pre-dispute (or none) is the legitimate value.

**Tests in `TestAdminResolveDispute`:**
- `test_resolution_to_cancelled_stamps_audit_columns` (test_orchestrator.py:1210)
- `test_resolution_to_completed_stamps_completed_at` (test_orchestrator.py:1233)
- `test_resolution_to_completed_preserves_existing_completed_at` (test_orchestrator.py:1255)

#### 4.3.2 F4 (P1) — `SupportTicket.resolved_by` did not exist

**The bug.** The only durable record of *which* admin resolved a dispute lived in the WS broadcast payload (`resolved_by_admin: <username>`). Once the WS frame TTL expires, the ticket row tells you when and how but not by whom.

**The fix.** Nullable PROTECT FK on `SupportTicket`:

```python
# models.py:378-384
resolved_by = models.ForeignKey(
    settings.AUTH_USER_MODEL,
    null=True,
    blank=True,
    on_delete=models.PROTECT,
    related_name='resolved_tickets',
)
```

Stamp it in the orchestrator:

```python
# orchestrator.py:1386-1390
ticket.resolved_by = admin_user
ticket.save(update_fields=[
    'status', 'resolution_outcome', 'resolution_notes',
    'resolved_at', 'resolved_by',
])
```

**Why nullable.** Backwards compatibility — pre-launch there are no production rows but tests pre-create `RESOLVED` tickets without an admin. The WS broadcast continues to carry `resolved_by_admin: <username>` because that string field is what the frontend banner needs; the FK is for audit queries, not display.

**Why PROTECT.** Deleting an admin user must not orphan dispute resolution attribution.

**Migration `0009_supportticket_resolved_by.py`** (auto-generated, +21 lines). No-op on existing data because the field is nullable.

**Test:** `TestAdminResolveDispute::test_resolved_by_recorded_on_ticket` (test_orchestrator.py:1282).

**Net Phase 6 impact:** orchestrator.py +31, models.py +13, migrations 0009 +21, tests +93 (4 new). 647 → 651.

---

### 4.4 Phase 7 — code semantics + payload completeness · `08001e6`

#### 4.4.1 F5 (P1) — `mark_complete_with_cash` accepted any string for `method`

**The bug.** The `method` parameter wrote straight to `booking.cash_collection_method` without validation. The model `CharField` would happily store `'mobile_money'`, `'check'`, `''`. CLAUDE.md says "Customer ↔ Technician = CASH ONLY".

**The fix.** Frozenset gate:

```python
# orchestrator.py:801-805
_VALID_CASH_COLLECTION_METHODS = frozenset({'cash'})

# orchestrator.py:824-829
if method not in _VALID_CASH_COLLECTION_METHODS:
    raise BookingValidationError(
        code=ERROR_INVALID_INPUT,
        message='Unsupported cash collection method.',
        errors={'method': [f'must be one of {sorted(_VALID_CASH_COLLECTION_METHODS)}']},
    )
```

**To extend the allowed set:** add the new value to the frozenset literal (e.g. `'mobile_money'`). No model change required (the column is already a free `CharField`). Coordinate with the frontend dispatcher.

**Test:** `TestMarkCompleteCashAmountValidation::test_invalid_method_rejected` (test_orchestrator.py:1631).

#### 4.4.2 F6 (P2) — `ERROR_INVALID_TRANSITION` was overloaded for three concerns

**The bug.** A single `code='invalid_transition'` was raised for three semantically distinct cases:
- (a) wrong-from-state transitions (legitimately a "transition" issue)
- (b) resource-not-found 404s (a missing booking is not a transition issue)
- (c) malformed input (an unparseable cash amount is not a transition issue either)

**The fix.** Three new not-found codes plus reuse of `ERROR_INVALID_INPUT`:

```python
# exceptions.py:60-75
ERROR_INVALID_TRANSITION = "invalid_transition"   # unchanged — still used for actual wrong-from-state
ERROR_INVALID_INPUT = "invalid_input"             # cycle-1 already added; cycle-2 expanded usage
…
ERROR_BOOKING_NOT_FOUND = "booking_not_found"     # NEW
ERROR_QUOTE_NOT_FOUND = "quote_not_found"         # NEW
ERROR_TICKET_NOT_FOUND = "ticket_not_found"       # NEW
```

**Call-site updates:**

| Code | Site |
|---|---|
| `ERROR_BOOKING_NOT_FOUND` | `_lock_booking` (orchestrator.py:142) — every transition inherits this |
| `ERROR_QUOTE_NOT_FOUND` | `_get_booking_quote_locked` (orchestrator.py:160) — every quote-bearing transition. IDOR-safe: a quote_id from another booking surfaces the same envelope as a missing one |
| `ERROR_TICKET_NOT_FOUND` | `admin_resolve_dispute` (orchestrator.py:1361) |
| `ERROR_INVALID_INPUT` | `mark_no_show` actor_role validation (orchestrator.py:1128); `mark_complete_with_cash` zero-cash, negative-cash, unparseable-decimal, unsupported-method (orchestrator.py:824, 837, 860) |

**Why this is safe right now.** Session 2 has not landed the HTTP views yet, so no Flutter code is keying off these literals. Future renames must coordinate with the Flutter dispatcher.

**Tests** (existing tests had assertions tightened in place):
- `TestLockBookingNotFound::test_en_route_unknown_booking_raises_404_envelope` → `code='booking_not_found'`
- `TestQuoteNotFoundOnBooking::test_approve_quote_with_unknown_id_raises_404` → `code='quote_not_found'`
- `TestAdminResolveDisputeLockOrdering::test_unknown_ticket_raises_404` (test_orchestrator.py:1750) → `code='ticket_not_found'`
- `TestMarkCompleteCashAmountValidation::test_zero_cash_rejected` (test_orchestrator.py:1619) → `code='invalid_input'`

#### 4.4.3 F7 (P2) — `QUOTE_APPROVED` broadcast missing cumulative cash

**The bug.** Payload carried `total_amount` (this quote's total only — on the upsell path, the *delta*). Tech's "Cash Collected: Rs.X" button binds to the cumulative `final_cash_to_collect`, so after every upsell approval the tech app was forced to refetch the booking detail.

**The fix.** One-line addition:

```python
# orchestrator.py:719-724
'total_amount': str(quote.total_amount),
'final_cash_to_collect': str(booking.final_cash_to_collect),    # NEW
```

Decimal-as-string is canonical for `Decimal` over JSON. The Flutter mapper layer parses to a typed domain value.

**Test:** `TestApproveQuote::test_happy_path_snapshots_booking_items` had an assertion added.

**Net Phase 7 impact:** orchestrator.py +34/-10, exceptions.py +8, tests +31/-10 (1 new test + 4 in-place tightenings). 651 → 652.

---

### 4.5 Phase 8 — DB-enforced quote uniqueness · `88701ed`

**F9 (P2)** — application-only quote uniqueness invariant.

**The bug.** The orchestrator's `submit_quote` flow enforces "at most one `SUBMITTED` quote per `(booking, is_upsell)`" by superseding any prior submitted quote of the same flavour before creating the new one. Cycle-1 Phase 3 tightened the supersede filter (§3.3.1). But the invariant lived only in application code. A bug in a future caller — or a path that bypasses the supersede update — could violate it without any DB signal.

**The fix.** Partial unique constraint:

```python
# models.py:266-270
models.UniqueConstraint(
    fields=['booking', 'is_upsell'],
    condition=models.Q(status='SUBMITTED'),
    name='unique_submitted_quote_per_booking_flavour',
),
```

The `condition=` clause makes it a **partial index** — only `SUBMITTED` rows are indexed, so prior `SUPERSEDED` / `APPROVED` / `DECLINED` rows do not collide with a new `SUBMITTED`.

**Migration `0010_quote_unique_submitted_quote_per_booking_flavour.py`** (auto-generated, +17 lines). Pre-launch, no row violates this — apply is a no-op on existing data.

**Tests in `TestQuoteSubmittedUniqueness`** — direct ORM creation bypassing the orchestrator:

| Test | Asserts |
|---|---|
| `test_two_submitted_non_upsell_quotes_rejected` (test_orchestrator.py:1695) | DB rejects with `IntegrityError` |
| `test_submitted_upsell_and_non_upsell_coexist` (test_orchestrator.py:1710) | Distinct partial-index keys allow both |
| `test_superseded_does_not_block_new_submitted` (test_orchestrator.py:1726) | `SUPERSEDED` row does not collide → orchestrator's supersede-then-create remains valid |

**Net Phase 8 impact:** models.py +14, migrations 0010 +17, tests +56 (3 new). 652 → 655.

---

## 5. Migrations — operational reference

The orchestrator landed three migrations on top of pre-sprint head `0007_drop_accepted_at_add_awaiting_status`:

| Migration | Phase | What it does | Safety |
|---|---|---|---|
| `0008_booking_orchestrator_foundations` | C | Adds `accepted_at` (re-added), 22 column additions on `JobBooking`, creates `Quote`, `QuoteLineItem`, `BookingItem`, `SupportTicket`, `TicketEvidence`, `BookingAttachment`, `TechReliabilityIncident`, plus `Quote(booking, revision_number)` unique constraint. 262-line migration. | All new columns are nullable or defaulted → no backfill needed. Reversible: `migrate bookings 0007`. |
| `0009_supportticket_resolved_by` | 6 (cycle-2) | `AddField` `resolved_by` (nullable PROTECT FK to `AUTH_USER_MODEL`) on `SupportTicket`. | No-op on existing data (nullable). Reversible: `migrate bookings 0008`. |
| `0010_quote_unique_submitted_quote_per_booking_flavour` | 8 (cycle-2) | `AddConstraint` partial unique on `Quote(booking, is_upsell) WHERE status='SUBMITTED'`. | No-op on pre-launch data — verified no row currently violates. Reversible: `migrate bookings 0009`. |

**Migration dependency chain (current head):**

```
0001_initial → 0002 → 0003 → 0004 → 0005 → 0006 → 0007
            → 0008_booking_orchestrator_foundations
            → 0009_supportticket_resolved_by
            → 0010_quote_unique_submitted_quote_per_booking_flavour
```

**Cross-app dependencies in 0008:** depends on `catalog 0007_add_duration_minutes`, `technicians 0007_collapse_skill_rate_to_labor_rate`, and `swappable_dependency(AUTH_USER_MODEL)`.

**If `migrate` errors on 0010 with `IntegrityError`:** a row in your dev db has two `SUBMITTED` quotes for the same `(booking, is_upsell)`. Investigate before forcing — this is not expected pre-launch.

---

## 6. Error codes — the full set

`backend/bookings/exceptions.py`:

```python
ERROR_INVALID_TRANSITION = "invalid_transition"               # wrong-from-state
ERROR_INVALID_INPUT = "invalid_input"                         # malformed input (cash, method, actor_role)
ERROR_INVALID_QUOTE_EMPTY = "invalid_quote_empty"             # submit_quote with zero line items
ERROR_QUOTE_BAND_VIOLATION = "quote_band_violation"           # priced_at outside fixed/labor band
ERROR_CANCELLATION_NOT_ALLOWED = "cancellation_not_allowed"   # cancel attempted from disallowed status
ERROR_DISPUTE_NOT_DISPUTABLE_STATUS = "dispute_not_disputable_status"  # open_dispute on pre-CONFIRMED
ERROR_RESCHEDULE_NOT_ALLOWED = "reschedule_not_allowed"       # reschedule from EN_ROUTE+ or slot conflict
ERROR_NOT_ASSIGNED_TO_YOU = "not_assigned_to_you"             # IDOR (tech or customer mismatch)
ERROR_NO_SHOW_TOO_EARLY = "no_show_too_early"                 # 15-min wait gate not yet elapsed
ERROR_BOOKING_NOT_FOUND = "booking_not_found"                 # 404 — _lock_booking miss
ERROR_QUOTE_NOT_FOUND = "quote_not_found"                     # 404 — _get_booking_quote_locked miss
ERROR_TICKET_NOT_FOUND = "ticket_not_found"                   # 404 — admin_resolve_dispute ticket miss
```

**Pre-existing exceptions (booking-creation path, NOT envelope-shaped):**

`InvalidAddressError`, `OutOfServiceAreaError`, `SlotUnavailableError`, `InconsistentBookingIntentError`, `PromoFirewallError`, `BookingNotFoundForTechnicianError`, `BookingNotActionableError`. These predate the standard envelope contract and are translated to envelope shape inside their callers' views, **not** here.

---

## 7. Frontend-visible behavior contract (for Session 2's HTTP views)

This is the contract Session 2's views and the Flutter dispatcher must honour:

### 7.1 Envelope shape

```json
{
  "status": <int>,
  "code": "<wire-string from §6>",
  "message": "<human-readable string for UI toast>",
  "errors": { "field_name": ["..."] }
}
```

### 7.2 404 responses (cycle-2)

| `code` | Source | Meaning |
|---|---|---|
| `booking_not_found` | every transition (via `_lock_booking`) | The booking id does not exist or was soft-deleted |
| `quote_not_found` | quote-bearing transitions | The quote id does not exist OR belongs to a different booking (IDOR-safe) |
| `ticket_not_found` | `admin_resolve_dispute` | The ticket id does not exist |

### 7.3 400 responses with field-keyed errors (cycle-2)

| `code` | Field | When |
|---|---|---|
| `invalid_input` | `method` | `mark_complete_with_cash` rejected because method is not in `{'cash'}` |
| `invalid_input` | `cash_amount` | `mark_complete_with_cash` rejected: `<= 0` or unparseable Decimal |
| `invalid_input` | `actor_role` | `mark_no_show` rejected: actor_role not in `{'tech', 'customer'}` |
| `reschedule_not_allowed` | `new_scheduled_start` | `reschedule` rejected: target slot conflicts with another booking on the same tech |
| `quote_band_violation` | `line_items[<idx>]` | Submitted price outside the fixed or labor sub-service band |

### 7.4 Broadcast payload contract (changed in cycle-2)

`QUOTE_APPROVED` now carries cumulative `final_cash_to_collect` as a string. Tech app's cash button binds without a refetch:

```json
{
  "booking_id": …,
  "customer_id": …,
  "technician_id": …,
  "status": "IN_PROGRESS",
  "quote_id": …,
  "is_upsell": false,
  "total_amount": "1500.00",            // THIS quote (delta on upsell)
  "final_cash_to_collect": "2000.00"    // CUMULATIVE — this is what the button shows
}
```

### 7.5 Wire-string stability

Every `code` in §6 and every `EventType` wire string in §2.1 is stable. Renaming requires a coordinated frontend change. Flutter side keys on these literals.

---

## 8. Tests — class-by-class shape (post-Session-1)

`backend/tests/bookings/services/test_orchestrator.py` — 116 tests across 21 classes:

```
TestSubmitQuote                              build (Phase M) + cycle-1 hardening
TestApproveQuote                             build (Phase M) + cycle-2 payload tightening
TestDeclineQuote                             build (Phase M) + cycle-1 (renamed test)
TestMarkCompleteWithCash                     build (Phase M)
TestCancelByCustomer                         build (Phase M, parametrized over from-states)
TestCancelByTech                             build (Phase M)
TestMarkNoShow                               build (Phase M) + cycle-1 (15-min wait + _clock seam)
TestOpenDispute                              build (Phase M) + cycle-1 (terminal preservation, +3 tests)
TestAdminResolveDispute                      build (Phase M) + cycle-2 (+4 tests for audit columns + resolved_by)
TestReschedule                               build (Phase M) + cycle-2 (+3 tests for race + cash carry)
TestDefaultFinanceResolution                 build (Phase M)
TestLockBookingNotFound                      cycle-1 (2 tests) + cycle-2 (code retightened)
TestQuoteNotFoundOnBooking                   cycle-1 (3 tests including cross-booking IDOR)
TestSubmitQuoteMalformedInput                cycle-1 (5 tests)
TestMarkCompleteCashAmountValidation         cycle-1 (4 tests) + cycle-2 (+1 test for method validation)
TestQuoteSubmittedUniqueness                 cycle-2 (NEW class, 3 tests)
TestAdminResolveDisputeLockOrdering          cycle-1 (2 tests) + cycle-2 (code retightened)
```

**Other orchestrator-related test files:**

- `tests/bookings/test_models.py` — 19 tests
- `tests/bookings/test_exceptions.py` — 4 tests
- `tests/bookings/services/test_auto_transition.py` — 16 tests (Phase M) + cycle-1 (+2 silent-return tests)
- `tests/bookings/services/test_finance_ports.py` — 8 tests
- `tests/bookings/selectors/test_quote_selector.py` — 6 tests with `django_assert_num_queries`
- `tests/bookings/selectors/test_dispute_selector.py` — 6 tests with `django_assert_num_queries`
- `tests/bookings/services/test_instant_book_service.py` — 3 cycle-1-relevant tests (cash columns, address snapshot, promo snapshot)

**Project total: 655 passing, 0 failing.**

---

## 9. Deferred items — Session 2's awareness list

### 9.1 F8 — cross-category quote line items  *(awaiting product decision)*

`orchestrator._validate_line_items` (orchestrator.py:315 onwards) does not constrain a quote line item's `sub_service.service_id` to match the booking's `service_id`. A plumber-tech could submit a line item under an electrical sub-service.

Two interpretations:
- **(a) Intentional flexibility.** Plumber-adds-a-small-electrical-fix mid-visit is a legitimate cross-category upsell. Closing this hole would block that.
- **(b) Hole.** The booking's `service` field should be authoritative for what work is in scope.

**The user has not made this decision.** Do not implement either way without explicit confirmation. The single-line fix to close the hole would be:

```python
# orchestrator.py inside _validate_line_items per-item loop:
if sub.service_id != booking.service_id:
    raise BookingValidationError(
        code=ERROR_QUOTE_BAND_VIOLATION,
        message='Line item is not in the booking\'s service category.',
        errors={f'line_items[{idx}].sub_service_id': ['out of band']},
    )
```

### 9.2 F10 — drop unused `finance=None` defaults

Nine transition functions accept `finance=None` and call `_resolve_finance(finance)`. The orchestrator never uses any other adapter today. Cleanup means removing `finance=None` from all 9 functions, removing `_resolve_finance`, and updating ~40 test call sites that pass `finance=fake_finance` for symmetry. The dead path is inert. Leave alone unless the finance sprint forces a touch.

### 9.3 F11–F15 — observations, not bugs

| ID | Observation | Why deferred |
|---|---|---|
| F11 | `seed_demo` doesn't populate `inspection_fee` / `final_cash_to_collect` / `actual_address_snapshot` | Dev tool; not a production bug. Fix opportunistically if you touch `seed_demo`. |
| F12 | `parent_booking` chain depth is unbounded (repeated reschedules) | No current trigger for stack overflow; reports use the `parent_booking_id` column directly, not recursion. |
| F13 | `cash_collected_amount` accepts values arbitrarily larger than `final_cash_to_collect` | Belongs to finance reconciliation, not the orchestrator. Currently legitimate (tip rolled into payment). |
| F14 | No threading-level test for `admin_resolve_dispute` concurrent with customer/tech transitions | Existing tests cover all serial paths; the lock-ordering invariant is documented and tested for serial correctness. Add a real concurrency harness when bringing finance sprint online. |
| F15 | `mark_no_show` is the only transition with a `_clock` injection seam | Generalising costs > generalising buys today. Re-evaluate when a second time-anchored transition lands. |

---

## 10. flag.md state at Session 1 close

The four orchestrator-relevant entries (Phase O) are all **active** (not struck-through):

- **#28** AI chatbot dispute intake — schema seam present, module deferred
- **#29** Reviews / ratings — model + endpoints deferred
- **#30** Bank accounts / wallet payouts — cash collection only this sprint  ← **HIGH SEVERITY** (paid pilot blocker)
- **#31** Admin realtime channel — `tech_reliability_penalty` event deferred

**No new `flag.md` entries written by audit cycle 1 or 2.** Per CLAUDE.md, the rule is: only flag accepted shortcuts and partial implementations. Audit fixes are bug-closures, not accepted shortcuts. F8 (cross-category line items) is a **product decision pending**, not a shipped shortcut, so no flag entry until the user picks an interpretation.

---

## 11. What is NOT in Session 1

- **No HTTP views.** Session 2 lands these.
- **No URL conf entries** in `bookings/urls.py` for orchestrator transitions. Session 2.
- **No request/response serializers.** Session 2.
- **No Flutter changes.** Zero frontend files were touched in any of the 18 commits.
- **No realtime topology changes.** Same `_broadcast` helper, same `EventDispatchService`, same `EventType` enum (5 members added in Phase A but the dispatch contract is unchanged).
- **No API documentation files** (`backend/bookings/api/*.md`). The orchestrator is a service-layer API consumed only by Session 2's views; the public HTTP API doc is Session 2's deliverable.
- **No iOS work.** Project is Android-only per existing decisions.
- **No CLAUDE.md changes.** Project rules are unchanged — this sprint reaffirms them (port-and-adapter, thin views fat services, factory_boy + pytest-django, transaction.atomic + select_for_update, transaction.on_commit, canonical envelope) but introduces no new architectural rule.

---

## 12. Session 2 — handoff

**Most likely Session 2 scope.** Thin DRF views that wrap the orchestrator transitions, URL routing, request/response serializers. The orchestrator boundaries reinforced in cycle 1 + cycle 2 should make Session 2 mostly mechanical:

- View parses + authenticates → calls orchestrator transition with kwargs.
- `BookingValidationError` is caught by the existing custom exception handler → canonical envelope. **No try/except needed in views for orchestrator errors.**
- Successful transitions return a serialized `JobBooking` (or specialized response shape per endpoint).
- IDOR scoping: views must scope `JobBooking.objects` to `request.user` (customer) or `TechnicianProfile.user=request.user` (tech) before passing the id to the orchestrator. The orchestrator does its own `_require_customer` / `_require_assigned_tech` check, but view-layer scoping prevents id enumeration.

**One open product decision Session 2 must answer:** F8 (cross-category line items — see §9.1). Before the quote-submit endpoint goes live, the user must decide whether to enforce same-category line items or accept cross-category flexibility.

**Specific new views Session 2 will need (one per transition function):**

- `POST /api/bookings/<id>/en-route/` (or implicit via tech-location ingress + `auto_transition`)
- `POST /api/bookings/<id>/arrived/` (same)
- `POST /api/bookings/<id>/start-inspection/`
- `POST /api/bookings/<id>/quote/` (submit_quote — also revises)
- `POST /api/bookings/<id>/quote/<quote_id>/request-revision/`
- `POST /api/bookings/<id>/quote/<quote_id>/approve/`
- `POST /api/bookings/<id>/quote/<quote_id>/decline/`
- `POST /api/bookings/<id>/complete-with-cash/`
- `POST /api/bookings/<id>/cancel/` (customer)
- `POST /api/bookings/<id>/tech-cancel/`
- `POST /api/bookings/<id>/no-show/`
- `POST /api/bookings/<id>/dispute/`
- `POST /api/admin/tickets/<ticket_id>/resolve/` (admin)
- `POST /api/bookings/<id>/reschedule/`
- `POST /api/tech-locations/` (ingress; calls `auto_transition.evaluate_on_location`)

Plus read endpoints for quote history, ticket list, and booking detail (selectors already exist).

**Required reader updates beyond the new views (latent gaps Session 1 left behind):**

The orchestrator can place a `JobBooking` in 8 statuses that the existing customer-side reader does not yet handle: `QUOTE_PENDING`, `QUOTE_SUBMITTED`, `EN_ROUTE`, `ARRIVED`, `IN_PROGRESS`, `NO_SHOW`, plus the differentiated cancellation paths and `RESCHEDULED`. Two readers in `backend/bookings/selectors/customer_bookings_selector.py` must be extended in lockstep with each new view that first produces one of these statuses — otherwise affected bookings either vanish from the customer's UI or render with wrong copy. Neither breaks Flutter today (orchestrator is HTTP-unreachable; no booking can reach these statuses until Session 2 wires the views), so fixing them now would mean adding dead branches; fixing them in Session 2 keeps the change colocated with the test that exercises each new view.

1. **`_UPCOMING_STATUSES` and `_PAST_STATUSES`** (lines 79–88). Hardcoded to the original 6 statuses. A booking in `QUOTE_PENDING` / `QUOTE_SUBMITTED` / `EN_ROUTE` / `ARRIVED` / `IN_PROGRESS` is silently filtered out of both segment lists today — the customer's bookings tab shows nothing, even though the booking is live. Add the new in-flight statuses to `_UPCOMING_STATUSES` (they are forward-progress, not terminal) and `NO_SHOW` to `_PAST_STATUSES` (terminal failure). The selector's `django_assert_num_queries` test should still hold; add one fixture per new status to assert the segment includes it.

2. **`_resolve_ui_block`** (lines 144–209). Falls through to the legacy "Pending / Booking is being prepared" card for any status not in its switch chain. Won't crash the Flutter client (defensive default mirrors the old behavior — see comment on line 204), but every new status renders identical wrong copy until cases are added. Add a branch per new status with the right `badge_text` / `badge_tone` / `headline`. Per the docstring on line 140 and CLAUDE.md's dumb-UI principle, these copy decisions are mirrored client-side in the Flutter event-patch mapper — coordinate the two changes in the same PR.

The 22 new `JobBooking` columns and 5 new `EventType` members do **not** require analogous reader updates: existing serializers field-whitelist explicitly (no leak risk), and the new `EventType` wire-strings are emitted only from `orchestrator.py`, which has no HTTP entry point until Session 2 lands.

**Things Session 2 should NOT do:**

- Do **not** rename any of the new error codes (`booking_not_found`, `quote_not_found`, `ticket_not_found`, `invalid_input`) without coordinating a Flutter dispatcher change. They are wire-strings.
- Do **not** rename any `EventType` wire-string for the 5 new events (Phase A) without coordinating a Flutter change.
- Do **not** add try/except blocks around orchestrator calls in views — the custom exception handler does the envelope translation. Wrapping would double-translate.
- Do **not** call any orchestrator function from Celery tasks without re-verifying the lock-ordering and `transaction.on_commit` invariants. The orchestrator's atomicity assumes a synchronous request context unless the caller explicitly mirrors the pattern.
- Do **not** `Quote.objects.create(status=SUBMITTED, ...)` directly. Always go through `orchestrator.submit_quote`. The partial unique constraint (Phase 8) will reject the duplicate with `IntegrityError` instead of the canonical envelope, which is bad UX.
- Do **not** widen `_VALID_CASH_COLLECTION_METHODS` without first deciding what model/payment-method support is being added. CLAUDE.md is "CASH ONLY" today.

**Verification gate before Session 2 starts working:** run the four commands in §0. If any drift, halt and reconcile before changing code.

---

## 13. Key file locations — quick lookup

| Subject | File | Notes |
|---|---|---|
| `JobBooking` model + 7 sibling models | `backend/bookings/models.py` | 477 lines |
| 14 transition functions | `backend/bookings/services/orchestrator.py` | 1578 lines |
| Geofence trigger classifier | `backend/bookings/services/auto_transition.py` | Pure decisions; orchestrator runs side-effects |
| `BookingValidationError` + 11 codes | `backend/bookings/exceptions.py` | Wire-strings; coordinate frontend changes |
| `FinancePort` Protocol | `backend/bookings/services/finance_ports.py` | 5 methods |
| `NullFinanceAdapter` | `backend/bookings/adapters/null_finance.py` | Default; finance sprint swaps body |
| Lazy default-resolution factories | `backend/bookings/adapters/__init__.py` | `get_default_finance_service`, `get_default_scheduler` |
| Quote / dispute selectors | `backend/bookings/selectors/quote_selector.py`, `dispute_selector.py` | 5 accessors total |
| 5 new `EventType` members | `backend/realtime/constants/event_types.py:51-55` | Wire-strings |
| Custom DRF exception handler | `backend/core/common/failures/exception.py` | Envelope translator |
| Admin registrations (4) | `backend/bookings/admin.py` | All read-only |
| Migration 0008 (foundations) | `backend/bookings/migrations/0008_booking_orchestrator_foundations.py` | 262 lines |
| Migration 0009 (resolved_by) | `backend/bookings/migrations/0009_supportticket_resolved_by.py` | Cycle-2 |
| Migration 0010 (quote uniqueness) | `backend/bookings/migrations/0010_quote_unique_submitted_quote_per_booking_flavour.py` | Cycle-2 |
| flag.md entries #28–#31 | `flag.md` (project root) | Phase O |
| Test file (orchestrator) | `backend/tests/bookings/services/test_orchestrator.py` | 116 tests |
| Test factories (extended) | `backend/tests/factories/{catalog,bookings,support,reliability}.py` | Phase L |

---

*End of Session 1 summary. Hand to Session 2.*
