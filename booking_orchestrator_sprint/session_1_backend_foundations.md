# Session 1 — Backend Foundations

> First session of the Booking Orchestrator sprint (6 sessions total). Lays the data layer + service layer that every other session builds on.
>
> **Out of scope for this session:** HTTP endpoints, realtime publishers, WebSocket consumer changes, all frontend work, real wallet/commission writes. Those land in sessions 2–6 and the future finance sprint.

---

## §0 Sprint context

This is **session 1 of 6** in the booking orchestrator sprint. Cross-cutting architectural decisions live in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md) (this folder). Before opening this session file, read sprint meta §1, §3 (mandatory pre-reads), §4 (the 16 architectural decisions), and skim §5–§17 so the schema additions and orchestrator shape feel intentional rather than arbitrary.

What sessions 2–6 will add on top of this session:
- **Session 2** — HTTP endpoints + realtime publishers + `tech_gps` stream + WS consumer subgroup mechanism + auto-transition ingress.
- **Session 3** — Frontend `BookingOrchestratorScreen` skeleton + per-event notifiers.
- **Session 4** — Dual-provider live-tracking maps + Android foreground GPS service.
- **Session 5** — Quote builder + customer approval + cash collection.
- **Session 6** — Cancellation, no-show, dispute, polish, flag closure.

This session touches **only** the backend: models, migrations, services, selectors, adapters, admin registrations, factories, tests. **No `views.py`, no `urls.py`, no Flutter.**

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions are in sprint meta §4. Decisions specific to this session:

1. **Single migration file** — `0008_booking_orchestrator_foundations.py` for all new bookings-app columns and models, atomic apply/rollback. `catalog` gets its own one-line migration `0009_subservice_max_price.py`.
2. **`bookings/services/orchestrator.py` is the single transition module.** Replaces the "one file per transition" approach. Each transition is a top-level function (matches existing `instant_book_service.py` / `job_request_action.py` shape — top-level functions, not a class). Existing services stay untouched (already shipped + tested).
3. **Every orchestrator function is structurally identical** (canonical shape, no exceptions):
   1. Load booking with `select_for_update` inside `transaction.atomic`.
   2. Validate from-state and actor permission (raise `BookingTransitionError` with code if invalid).
   3. Mutate `JobBooking` columns + create related rows (Quote / QuoteLineItem / BookingItem / SupportTicket as needed).
   4. `transaction.on_commit(...)` to broadcast the realtime event via `EventDispatchService.broadcast_event`.
   5. Inside the same atomic block, call the relevant `FinancePort` method (null-adapter no-ops this sprint).
4. **`finance_ports.py` is one file, one Protocol** (`FinancePort` with 5 methods) — not 5 separate Protocols. The null adapter and the future real adapter both implement the same single Protocol.
5. **`auto_transition.py` is its own module**, not folded into `orchestrator.py`. Reason: separation of concerns — auto_transition is the *trigger* layer (geofence check), orchestrator is the *execution* layer (status mutation). Session 2's `tech-location` ingress invokes `auto_transition.evaluate_on_location` which then calls `orchestrator.en_route` or `orchestrator.arrived`.
6. **5 new event types added to the realtime enum** (`quote_revision_requested`, `quote_declined`, `booking_cancelled`, `booking_no_show`, `booking_rescheduled`). **Audit P0-08**: `tech_reliability_penalty` from the v0.9 plan is dropped; `EventLog.target_role` doesn't allow `admin` values (only `customer`/`technician`), so the broadcast would fail at save. Replaced by writing to a new `TechReliabilityIncident` model (sprint meta §11.5). The orchestrator broadcasts events from session 1; the HTTP endpoints that *trigger* the orchestrator land in session 2. Existing event types declared but never broadcast (`tech_en_route`, `tech_arrived`, `quote_generated`, `quote_approved`, `job_completed`, `payment_received`, `dispute_opened`, `dispute_resolved`) get their first wired publishers here.
7. **Legacy `PENDING` status is retained** (`STATUS_PENDING = 'PENDING'`) but never used for new bookings — existing rows untouched, new orchestrator transitions never produce or consume it. No data migration.
8. **No data backfill** for new `JobBooking` columns — all are nullable or have defaults. Existing bookings render correctly because the orchestrator's UI hints (next session) read column-or-default.
9. **`BookingAttachment` is schema-only this session** — no admin inline, no upload endpoint, no UI. Reserved for chatbot-intake feature in a future sprint per sprint meta §11.
10. **Test factories live in two files** — `tests/factories/bookings.py` extended with `QuoteFactory`, `QuoteLineItemFactory`, `BookingItemFactory`, plus status-specific JobBookingFactory subclasses (`JobBookingInProgressFactory`, etc.); new file `tests/factories/support.py` for `SupportTicketFactory`, `TicketEvidenceFactory`, `BookingAttachmentFactory`.
11. **Validation errors use a new `bookings.exceptions.BookingValidationError` class** (per CLAUDE.md error contract). Audit P0-01 caught that v0.9 claimed this class already existed — it does not. Session adds the class alongside new error codes (`invalid_transition`, `invalid_quote_empty`, `quote_band_violation`, `cancellation_not_allowed`, `dispute_not_disputable_status`, `reschedule_not_allowed`, `not_assigned_to_you`, `no_show_too_early`).
12. **`Quote.total_amount` is server-derived and stored** — recomputed on every line-item mutation. Asserted in service-layer tests; not enforced by DB constraint (rely on service correctness).

---

## §2 Files this session touches

### Backend models + migrations

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/models.py` | **modified** | New status constants + `JobBooking` columns + 6 new model classes. |
| `backend/bookings/migrations/0008_booking_orchestrator_foundations.py` | **new** | Single migration for all bookings-app additions. |
| `backend/catalog/models.py` | **modified** | Add `SubService.max_price`. |
| `backend/catalog/migrations/0008_subservice_max_price.py` | **new** | Single AddField migration. (Audit P0-05: catalog is at 0007 today, next is 0008. v0.9 plan said 0009 — typo.) |

### Backend services (all new)

| File | Purpose |
|---|---|
| `backend/bookings/services/orchestrator.py` | Transition gateway with all post-CONFIRMED transition functions. |
| `backend/bookings/services/finance_ports.py` | `FinancePort` Protocol (5 methods). |
| `backend/bookings/services/auto_transition.py` | Geofence-driven trigger layer (calls orchestrator). |

### Backend adapters

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/adapters/null_finance.py` | **new** | `NullFinanceAdapter` (no-ops). |
| `backend/bookings/adapters/__init__.py` | **modified** | Add `get_default_finance_service()` lazy factory. |

### Backend selectors (all new)

| File | Purpose |
|---|---|
| `backend/bookings/selectors/quote_selector.py` | Read-only `Quote` / `QuoteLineItem` / `BookingItem` access. |
| `backend/bookings/selectors/dispute_selector.py` | Read-only `SupportTicket` / `TicketEvidence` access. |

### Backend exceptions

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/exceptions.py` | **modified** | **Add** `BookingValidationError` class (audit P0-01) + new error code constants. |

### Backend realtime (event enum extension)

| File | Status | Purpose |
|---|---|---|
| `backend/realtime/constants/event_types.py` | **modified** | 5 new event types + registry metadata. |

### Backend admin

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/admin.py` | **modified** | Register `Quote` (inline), `BookingItem` (inline), `SupportTicket` (top-level + `TicketEvidence` inline). `BookingAttachment` deliberately NOT registered this session. |

### Backend tests (all new files except factory extensions)

| File | Status | Purpose |
|---|---|---|
| `backend/tests/factories/bookings.py` | **modified** | Add `QuoteFactory`, `QuoteLineItemFactory`, `BookingItemFactory`, status subclasses of `JobBookingFactory`. |
| `backend/tests/factories/support.py` | **new** | `SupportTicketFactory`, `TicketEvidenceFactory`, `BookingAttachmentFactory`. |
| `backend/tests/factories/catalog.py` | **modified** | Extend `SubServiceFactory` with `max_price`. |
| `backend/tests/bookings/test_models.py` | **new** | DB constraint + status enum tests. |
| `backend/tests/bookings/test_services_orchestrator.py` | **new** | Per-transition tests (happy / wrong-from / idempotent / finance-port-called). |
| `backend/tests/bookings/test_services_auto_transition.py` | **new** | Geofence threshold tests. |
| `backend/tests/bookings/test_finance_ports.py` | **new** | NullFinanceAdapter behavioral tests + Protocol-conformance test. |
| `backend/tests/bookings/test_selectors_quote.py` | **new** | Query-count assertions on quote selectors. |
| `backend/tests/bookings/test_selectors_dispute.py` | **new** | Query-count assertions on dispute selectors. |

### Files NOT touched

- All `views.py`, all `urls.py`, all `serializers.py` — session 2.
- All `frontend/` — sessions 3–6.
- `backend/realtime/events/services/event_dispatch_service.py`, `backend/realtime/streams/dispatch.py` — used as-is (no changes).
- `backend/bookings/services/job_request_action.py`, `backend/bookings/services/job_request_dispatch.py`, `backend/bookings/tasks.py` — already shipped, untouched.

### Backend services (1 file extended for audit P1-03)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/services/instant_book_service.py` | **modified** | Add promo snapshot writes (audit P1-03). After `_resolve_promotion(promotion_id)` returns the `Promotion`, write `promo_code_snapshot=promotion.code, promo_discount_snapshot=<computed_discount>` onto the new booking before save. v0.9 added the columns but never wrote them — every new booking would have null snapshots, defeating the purpose. |

---

## §3 Pre-flight

```bash
# 1. Repo baseline
cd /home/hamayon-khan/Development/my_fyp_project
git status                              # working tree clean (or stash)
git pull origin main

# 2. Backend env
cd backend
source venv/bin/activate                # or your venv path

# 3. Confirm clean migration baseline
python manage.py migrate --check        # no pending migrations
python manage.py showmigrations bookings catalog
# Expect: bookings highest = 0007_drop_accepted_at_add_awaiting_status; catalog highest = 0007_add_duration_minutes
# This sprint adds bookings/0008_* and catalog/0008_* (both new heads).

# 4. Confirm green baseline
pytest -q                               # all currently-passing tests stay green

# 5. Confirm realtime layer alive (existing primitives we'll call)
python manage.py shell -c "from realtime.events.services.event_dispatch_service import EventDispatchService; print('events OK')"
python manage.py shell -c "from realtime.streams.dispatch import publish_stream; print('streams OK')"
python manage.py shell -c "from realtime.constants.event_types import EventType; print('events:', len(list(EventType)))"

# 6. Confirm catalog seed exists (need at least one labor SubService for tests)
python manage.py shell -c "from catalog.models import SubService; print('subservices:', SubService.objects.count())"

# 7. Confirm Daphne alive (per flag #13 resolution)
python manage.py runserver &
sleep 2
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/api/bookings/   # expect 401
kill %1
```

If any pre-flight step fails, stop and fix before proceeding. Migration drift on the baseline will cascade.

---

## §4 Per-file detailed changes

### File 1: `backend/bookings/models.py` (modified)

#### 4.1.a Status constants

Existing constants (keep):

```python
class JobBooking(models.Model):
    STATUS_PENDING = 'PENDING'                      # legacy, pre-migration 0007
    STATUS_AWAITING_TECH_ACCEPT = 'AWAITING'
    STATUS_CONFIRMED = 'CONFIRMED'
    STATUS_COMPLETED = 'COMPLETED'
    STATUS_CANCELLED = 'CANCELLED'
    STATUS_REJECTED = 'REJECTED'
```

Add:

```python
    # Booking orchestrator v1 — sprint 0008
    STATUS_EN_ROUTE = 'EN_ROUTE'
    STATUS_ARRIVED = 'ARRIVED'
    STATUS_INSPECTING = 'INSPECTING'
    STATUS_QUOTED = 'QUOTED'
    STATUS_IN_PROGRESS = 'IN_PROGRESS'
    STATUS_COMPLETED_INSPECTION_ONLY = 'COMPLETED_INSPECTION_ONLY'
    STATUS_NO_SHOW = 'NO_SHOW'
    STATUS_DISPUTED = 'DISPUTED'

    STATUS_CHOICES = [
        (STATUS_AWAITING_TECH_ACCEPT, 'Awaiting tech accept'),
        (STATUS_CONFIRMED, 'Confirmed'),
        (STATUS_EN_ROUTE, 'En route'),
        (STATUS_ARRIVED, 'Arrived'),
        (STATUS_INSPECTING, 'Inspecting'),
        (STATUS_QUOTED, 'Quoted'),
        (STATUS_IN_PROGRESS, 'In progress'),
        (STATUS_COMPLETED, 'Completed'),
        (STATUS_COMPLETED_INSPECTION_ONLY, 'Completed (inspection only)'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_REJECTED, 'Rejected'),
        (STATUS_NO_SHOW, 'No show'),
        (STATUS_DISPUTED, 'Disputed'),
        (STATUS_PENDING, 'Pending (legacy, do not use for new bookings)'),
    ]

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
        STATUS_IN_PROGRESS,
    })
```

Update the `status` field declaration: `max_length` from `10` → `32` (longest value `COMPLETED_INSPECTION_ONLY` is 26 chars), `choices=STATUS_CHOICES`, `default=STATUS_AWAITING_TECH_ACCEPT`.

#### 4.1.b New columns on `JobBooking`

Append to the field list:

```python
    # Phase timestamps
    accepted_at = models.DateTimeField(null=True, blank=True)
    en_route_started_at = models.DateTimeField(null=True, blank=True)
    arrived_at = models.DateTimeField(null=True, blank=True)
    inspection_started_at = models.DateTimeField(null=True, blank=True)
    quote_first_submitted_at = models.DateTimeField(null=True, blank=True)
    work_started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    # Cash collection (sprint meta §16)
    final_cash_to_collect = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    cash_collected_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    cash_collected_at = models.DateTimeField(null=True, blank=True)
    cash_collection_method = models.CharField(max_length=16, default='cash')

    # Pricing breakdown
    inspection_fee = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    base_services_total = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    discount_applied = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # Promotion snapshot (denormalized; survives promo deletion)
    promo_code_snapshot = models.CharField(max_length=64, null=True, blank=True)
    promo_discount_snapshot = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # Address snapshot (denormalized; survives customer-side address deletion)
    actual_address_snapshot = models.TextField(blank=True, default='')

    # Reschedule chain (sprint meta §12)
    parent_booking = models.ForeignKey(
        'self', null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name='child_bookings',
    )

    # Cancellation audit
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancelled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name='cancelled_bookings',
    )
    cancel_reason = models.CharField(max_length=64, null=True, blank=True)

    # No-show audit
    no_show_at = models.DateTimeField(null=True, blank=True)
    no_show_actor = models.CharField(max_length=16, null=True, blank=True)  # 'tech' | 'customer'

    # Dispute audit
    dispute_opened_at = models.DateTimeField(null=True, blank=True)
```

`cancel_reason` allowed values (validated at service layer, not in DB):
- `customer_cancelled_pre_accept`
- `customer_cancelled_post_accept`
- `customer_cancelled_post_arrival`
- `customer_rescheduled`
- `technician_cancelled`

#### 4.1.c New model `Quote`

```python
class Quote(models.Model):
    STATUS_DRAFT = 'DRAFT'
    STATUS_SUBMITTED = 'SUBMITTED'
    STATUS_APPROVED = 'APPROVED'
    STATUS_DECLINED = 'DECLINED'
    STATUS_SUPERSEDED = 'SUPERSEDED'

    STATUS_CHOICES = [
        (STATUS_DRAFT, 'Draft'),
        (STATUS_SUBMITTED, 'Submitted'),
        (STATUS_APPROVED, 'Approved'),
        (STATUS_DECLINED, 'Declined'),
        (STATUS_SUPERSEDED, 'Superseded (replaced by next revision)'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='quotes')
    revision_number = models.PositiveIntegerField()
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_upsell = models.BooleanField(default=False)        # True if submitted during IN_PROGRESS
    decision_reason = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField(null=True, blank=True)
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['booking_id', 'revision_number']
        constraints = [
            models.UniqueConstraint(
                fields=['booking', 'revision_number'],
                name='unique_quote_revision_per_booking',
            ),
        ]

    def __str__(self):
        return f"Quote #{self.id} (booking {self.booking_id}, rev {self.revision_number}, {self.status})"
```

#### 4.1.d New model `QuoteLineItem`

```python
class QuoteLineItem(models.Model):
    quote = models.ForeignKey(Quote, on_delete=models.CASCADE, related_name='line_items')
    sub_service = models.ForeignKey('catalog.SubService', on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    priced_at = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ['quote_id', 'id']

    def save(self, *args, **kwargs):
        # Defensive: keep line_total in sync if computed at the call site
        if self.quantity and self.priced_at is not None:
            self.line_total = self.quantity * self.priced_at
        super().save(*args, **kwargs)
```

#### 4.1.e New model `BookingItem` (final accepted snapshot)

```python
class BookingItem(models.Model):
    """Snapshot of accepted line items. Populated only when a Quote is APPROVED.
    Source of truth for 'what work was actually performed.' Finance sprint reads here for reconciliation."""

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='items')
    sub_service = models.ForeignKey('catalog.SubService', on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)
    line_total = models.DecimalField(max_digits=10, decimal_places=2)
    sourced_quote = models.ForeignKey(
        Quote, null=True, on_delete=models.PROTECT,
        related_name='snapshotted_into_items',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['booking_id', 'id']
```

#### 4.1.f New model `SupportTicket`

```python
class SupportTicket(models.Model):
    INTAKE_FORM = 'FORM'
    INTAKE_CHATBOT = 'CHATBOT'
    INTAKE_CHOICES = [
        (INTAKE_FORM, 'Form'),
        (INTAKE_CHATBOT, 'Chatbot'),
    ]

    STATUS_OPEN = 'OPEN'
    STATUS_RESOLVED = 'RESOLVED'
    STATUS_CHOICES = [
        (STATUS_OPEN, 'Open'),
        (STATUS_RESOLVED, 'Resolved'),
    ]

    OUTCOME_NONE = 'NONE'
    OUTCOME_REFUND_CUSTOMER = 'REFUND_CUSTOMER'
    OUTCOME_PENALIZE_TECH = 'PENALIZE_TECH'
    OUTCOME_DISMISS = 'DISMISS'
    OUTCOME_CHOICES = [
        (OUTCOME_NONE, 'None'),
        (OUTCOME_REFUND_CUSTOMER, 'Refund customer'),
        (OUTCOME_PENALIZE_TECH, 'Penalize tech'),
        (OUTCOME_DISMISS, 'Dismiss'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='tickets')
    opened_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT,
        related_name='opened_tickets',
    )
    dispute_intake_method = models.CharField(max_length=16, choices=INTAKE_CHOICES, default=INTAKE_FORM)
    initial_reason = models.TextField()
    chat_log = models.JSONField(null=True, blank=True)              # reserved for chatbot intake (future sprint)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_OPEN)
    resolution_outcome = models.CharField(max_length=32, choices=OUTCOME_CHOICES, default=OUTCOME_NONE)
    resolution_notes = models.TextField(blank=True, default='')
    opened_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-opened_at']
```

#### 4.1.g New model `TicketEvidence`

```python
class TicketEvidence(models.Model):
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='evidence')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    image = models.ImageField(upload_to='dispute_evidence/')
    caption = models.TextField(blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['ticket_id', 'uploaded_at']
```

#### 4.1.h New model `BookingAttachment` (schema-only this session)

```python
class BookingAttachment(models.Model):
    """Reserved schema for booking-lifecycle photos (edge case #14). 
    No upload UI this sprint; reserved for chatbot intake feature."""

    KIND_BEFORE = 'BEFORE'
    KIND_AFTER = 'AFTER'
    KIND_QUOTE = 'QUOTE'
    KIND_OTHER = 'OTHER'
    KIND_CHOICES = [
        (KIND_BEFORE, 'Before'),
        (KIND_AFTER, 'After'),
        (KIND_QUOTE, 'Quote evidence'),
        (KIND_OTHER, 'Other'),
    ]

    booking = models.ForeignKey(JobBooking, on_delete=models.CASCADE, related_name='attachments')
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    kind = models.CharField(max_length=16, choices=KIND_CHOICES, default=KIND_OTHER)
    image = models.ImageField(upload_to='booking_attachments/')
    caption = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['booking_id', 'created_at']
```

---

### File 2: `backend/catalog/models.py` (modified)

Add to `SubService`:

```python
    max_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
```

Semantics:
- Labor sub-services (`is_fixed_price=False`): `base_price` = floor, `max_price` = ceiling. Per-quote `priced_at` must satisfy `base_price <= priced_at <= max_price`.
- Fixed-price sub-services (`is_fixed_price=True`): `base_price` = the price, `max_price` is null. Per-quote `priced_at` must equal `base_price`.

Validation lives in `bookings/services/orchestrator.py::submit_quote`, not on the model.

---

### File 3: `backend/bookings/migrations/0008_booking_orchestrator_foundations.py` (new)

Generated by:

```bash
python manage.py makemigrations bookings --name booking_orchestrator_foundations
```

Should produce a single migration with operations roughly:
- `AlterField` on `JobBooking.status` (max_length 10 → 32, choices updated, default updated).
- `AddField` × 22 (all new `JobBooking` columns).
- `CreateModel` × 6 (Quote, QuoteLineItem, BookingItem, SupportTicket, TicketEvidence, BookingAttachment).
- `AddConstraint` × 1 (Quote unique_quote_revision_per_booking).

**Verify the generated file before committing:**
- All `AddField` calls have `null=True` or a `default=` (no breakage on existing rows).
- The migration's `dependencies` list points to the previous bookings migration (`0007_*`) AND to `catalog.0009_subservice_max_price` (Quote/QuoteLineItem reference SubService) AND to the auth user migration AND to whatever `customers` migration owns the address FK referenced by `parent_booking_id` change semantics (no FK change here, but check).

If `makemigrations` produces multiple migration files, manually merge them into `0008_booking_orchestrator_foundations.py`. Single-file atomicity is the goal.

---

### File 4: `backend/catalog/migrations/0008_subservice_max_price.py` (new)

(Audit P0-05: was 0009 in v0.9 plan; catalog is at 0007 today so next is 0008.)

Generated by:

```bash
python manage.py makemigrations catalog --name subservice_max_price
```

Single `AddField` operation. Trivial.

---

### File 5: `backend/bookings/services/finance_ports.py` (new)

```python
"""Finance ports (sprint meta §9).

The booking orchestrator must NOT import the wallet/commission/JazzCash machinery
directly — that machinery doesn't exist yet (deferred to the finance sprint).
Instead, the orchestrator depends on the FinancePort Protocol below, and a
NullFinanceAdapter (in adapters/null_finance.py) provides no-op implementations
for this sprint. Finance sprint will swap in a real adapter without touching
orchestrator code.

Contract: every method here is called inside the same atomic block as the
status mutation it accompanies. Real adapters MAY raise (e.g. wallet lockout
on accept); orchestrator must let exceptions propagate so the transaction rolls
back. Null adapter never raises.
"""

from typing import Protocol, Literal
from decimal import Decimal


class FinancePort(Protocol):
    def can_accept_job(
        self, *, technician, payout_amount: Decimal,
    ) -> tuple[bool, str | None]:
        """Lockout check before tech accepts a job.

        Returns (allowed, reason_code_or_None). When allowed=False, reason_code is
        a machine-readable string (e.g. 'wallet_below_threshold') that the caller
        surfaces in the error envelope.
        Null adapter: always (True, None).
        """
        ...

    def record_commission(self, *, booking, amount: Decimal) -> None:
        """Called on IN_PROGRESS → COMPLETED transition.

        Will create JobCommission + WalletTransaction rows in the finance sprint.
        Null adapter: no-op.
        """
        ...

    def apply_inspection_fee_decision(
        self, *, booking, decision: Literal['accepted', 'declined'],
    ) -> None:
        """Called on QUOTED → IN_PROGRESS (decision='accepted')
        or QUOTED → COMPLETED_INSPECTION_ONLY (decision='declined').

        Inspection-fee accounting (Rs.500 deducted from final bill on accept,
        owed as cash on decline) is computed by the orchestrator regardless;
        this port hook lets finance sprint also create wallet entries.
        Null adapter: no-op.
        """
        ...

    def apply_cancellation_charge(
        self, *, booking,
        actor: Literal['customer', 'tech'],
        phase: Literal['pre_accept', 'pre_arrival', 'post_arrival'],
    ) -> None:
        """Called on any → CANCELLED transition.

        Penalty/fee column writes happen on the booking row regardless;
        this hook lets finance sprint also log a wallet entry for the
        Rs.500 owed (customer-cancel post-accept) or reliability event
        (tech-cancel).
        Null adapter: no-op.
        """
        ...

    def record_cash_collected(
        self, *, booking, amount: Decimal, method: str,
    ) -> None:
        """Called on IN_PROGRESS → COMPLETED transition after the tech taps
        the combined 'Cash Collected: Rs.X' button (per sprint meta §14 rule 2).

        Booking columns (cash_collected_amount, cash_collected_at, etc.) are
        already stamped by the orchestrator. Finance sprint will additionally
        write a WalletTransaction here.
        Null adapter: no-op.
        """
        ...
```

---

### File 6: `backend/bookings/adapters/null_finance.py` (new)

```python
"""NullFinanceAdapter — no-op implementation of FinancePort.

In use during the booking orchestrator sprint and for any test that doesn't
need real money behavior. Finance sprint will introduce WalletAdapter alongside
this file; selection happens in adapters/__init__.py::get_default_finance_service.
"""

from decimal import Decimal
from typing import Literal


class NullFinanceAdapter:
    def can_accept_job(self, *, technician, payout_amount: Decimal) -> tuple[bool, str | None]:
        return (True, None)

    def record_commission(self, *, booking, amount: Decimal) -> None:
        return None

    def apply_inspection_fee_decision(
        self, *, booking, decision: Literal['accepted', 'declined'],
    ) -> None:
        return None

    def apply_cancellation_charge(
        self, *, booking,
        actor: Literal['customer', 'tech'],
        phase: Literal['pre_accept', 'pre_arrival', 'post_arrival'],
    ) -> None:
        return None

    def record_cash_collected(self, *, booking, amount: Decimal, method: str) -> None:
        return None
```

---

### File 7: `backend/bookings/adapters/__init__.py` (modified)

Existing file has `get_default_scheduler()`. Add at the bottom:

```python
def get_default_finance_service():
    """Lazy import of NullFinanceAdapter; finance sprint will swap to a real adapter
    by changing only this function's body. Service code stays unchanged.
    """
    from .null_finance import NullFinanceAdapter
    return NullFinanceAdapter()
```

Per CLAUDE.md port-and-adapter pattern: this lazy import keeps `bookings.services.*` modules free of finance imports at module-load time.

---

### File 8: `backend/bookings/services/orchestrator.py` (new)

The transition gateway. ~14 top-level functions. All structurally identical (per §1 decision 3). Below is the canonical shape demonstrated on `start_inspection`; every other transition follows the same pattern.

#### 4.8.a Module preamble + canonical example

```python
"""Booking orchestrator — single transition gateway for all post-CONFIRMED status flips.

Every function here:
1. Loads the booking with select_for_update inside transaction.atomic.
2. Validates from-state and actor permission.
3. Mutates JobBooking columns + creates related rows.
4. Registers event broadcast in transaction.on_commit.
5. Calls the relevant FinancePort method (null-adapter no-ops this sprint).

Return value is the updated JobBooking instance (post-mutation, post-save).
On any validation failure, raises BookingValidationError with a code recognized
by the standard DRF exception handler.

Reference: BOOKING_ORCHESTRATOR_SPRINT.md §5 transition table, §9 finance ports.
"""

from __future__ import annotations
from decimal import Decimal
from typing import Iterable, Optional

from django.db import transaction
from django.utils import timezone

from bookings.models import (
    JobBooking, Quote, QuoteLineItem, BookingItem, SupportTicket, TicketEvidence,
)
from bookings.exceptions import BookingValidationError
from bookings.adapters import get_default_finance_service
from realtime.events.services.event_dispatch_service import EventDispatchService
from realtime.constants.event_types import EventType


# ---- Canonical example: start_inspection ----

def start_inspection(*, booking_id: int, technician_user, finance=None) -> JobBooking:
    """ARRIVED → INSPECTING. Triggered when tech opens the quote builder
    (§14 rule 1) — the navigation IS the trigger; no explicit button.
    """
    finance = finance or get_default_finance_service()

    with transaction.atomic():
        booking = (
            JobBooking.objects
            .select_for_update()
            .select_related('technician__user', 'customer')
            .get(id=booking_id)
        )

        # Authorization (IDOR + role check)
        if booking.technician.user_id != technician_user.id:
            raise BookingValidationError(
                code='not_assigned_to_you',
                message='You are not the technician on this booking.',
            )

        # Idempotency: same actor, same target state → no-op success
        if booking.status == JobBooking.STATUS_INSPECTING:
            return booking

        # State-machine guard
        if booking.status != JobBooking.STATUS_ARRIVED:
            raise BookingValidationError(
                code='invalid_transition',
                message='Booking is not in ARRIVED state.',
                errors={'current_status': [booking.status]},
            )

        # Mutation
        booking.status = JobBooking.STATUS_INSPECTING
        booking.inspection_started_at = timezone.now()
        booking.save(update_fields=['status', 'inspection_started_at'])

        # No finance port for this transition (no money moves on inspection start).
        # No event broadcast either — this is a UI-flip-only transition (§5).

    return booking
```

#### 4.8.b Function signatures (rest of module)

Implement each following the canonical shape above. Notes per function:

```python
def en_route(*, booking_id, technician_user, source: str = 'manual', finance=None) -> JobBooking:
    """CONFIRMED → EN_ROUTE. Auto path (source='auto') from auto_transition.py;
    manual path (source='manual') for fallback overrides.
    Stamps en_route_started_at. Fires tech_en_route event to customer.
    No finance port (no money moves)."""

def arrived(*, booking_id, technician_user, source: str = 'manual', finance=None) -> JobBooking:
    """EN_ROUTE → ARRIVED. Same auto/manual distinction. Stamps arrived_at.
    Fires tech_arrived event to customer.
    No finance port."""

def submit_quote(
    *, booking_id, technician_user,
    line_items: Iterable[dict],   # [{sub_service_id, quantity, priced_at}, ...]
    is_upsell: bool = False,
    finance=None,
) -> Quote:
    """INSPECTING → QUOTED (or IN_PROGRESS → QUOTED if is_upsell=True).
    Validates each line item's priced_at against SubService band:
      labor: base_price <= priced_at <= max_price
      fixed: priced_at == base_price
    Empty line_items rejected with BookingValidationError(code='invalid_quote_empty').
    Creates Quote (revision_number = max(prev) + 1, status=SUBMITTED) +
    QuoteLineItem rows. Stamps quote_first_submitted_at if first revision.
    Fires quote_generated event to customer.
    No finance port."""

def request_revision(*, booking_id, customer_user, quote_id: int, reason: str, finance=None) -> JobBooking:
    """QUOTED → INSPECTING (customer wants face-to-face bargain).
    Marks Quote.status = SUPERSEDED, decision_reason = reason, decided_at = now.
    Fires quote_revision_requested event to tech.
    No finance port. Booking returns to INSPECTING; tech revises and resubmits."""

def approve_quote(*, booking_id, customer_user, quote_id: int, finance=None) -> JobBooking:
    """QUOTED → IN_PROGRESS.
    Marks Quote.status = APPROVED. Snapshots QuoteLineItem rows into BookingItem 
    (quantity, price_charged, line_total, sourced_quote=quote). For mid-job upsell:
    appends to existing BookingItem rows; does not delete prior items.
    Stamps work_started_at if first approval.
    Recomputes JobBooking.base_services_total = sum(BookingItem.line_total).
    Fires quote_approved event to tech.
    Calls finance.apply_inspection_fee_decision(decision='accepted')."""

def decline_quote(*, booking_id, customer_user, quote_id: int, reason: str, finance=None) -> JobBooking:
    """QUOTED → COMPLETED_INSPECTION_ONLY (terminal).
    Marks Quote.status = DECLINED. Stamps completed_at. 
    Sets final_cash_to_collect = inspection_fee (Rs.500 for INSPECTION bookings; 
    0 for FIXED_GIG/LABOR_GIG since they didn't pay an inspection fee upfront).
    Fires quote_declined event to tech.
    Calls finance.apply_inspection_fee_decision(decision='declined')."""

def mark_complete_with_cash(
    *, booking_id, technician_user,
    cash_amount: Decimal, method: str = 'cash',
    finance=None,
) -> JobBooking:
    """IN_PROGRESS → COMPLETED. Combined complete + cash collection (§14 rule 2).
    Stamps completed_at, cash_collected_at, cash_collected_amount, cash_collection_method.
    Fires payment_received event to customer + job_completed event to customer.
    Calls finance.record_cash_collected(...) and finance.record_commission(...)."""

def cancel_by_customer(*, booking_id, customer_user, finance=None) -> JobBooking:
    """Any of {AWAITING, CONFIRMED, EN_ROUTE, ARRIVED, INSPECTING, QUOTED} → CANCELLED.
    Computes phase from current status:
      AWAITING → 'pre_accept' (no fee)
      CONFIRMED, EN_ROUTE → 'pre_arrival' (Rs.500 owed; sets final_cash_to_collect)
      ARRIVED, INSPECTING, QUOTED → 'post_arrival' (Rs.500 owed)
    IN_PROGRESS not allowed (must use dispute flow).
    Stamps cancelled_at, cancelled_by=customer_user, cancel_reason='customer_cancelled_<phase>'.
    Fires booking_cancelled event to tech.
    Calls finance.apply_cancellation_charge(actor='customer', phase=phase)."""

def cancel_by_tech(*, booking_id, technician_user, finance=None) -> JobBooking:
    """Any non-terminal → CANCELLED. No customer-facing fee but a reliability incident
    is recorded for admin review.
    Stamps cancelled_at, cancelled_by=technician_user, cancel_reason='technician_cancelled'.
    Fires booking_cancelled event to customer.
    Writes a TechReliabilityIncident row (incident_type='TECH_CANCEL', phase=<computed>).
    NOTE (audit P0-08): v0.9 plan also broadcast `tech_reliability_penalty` realtime event
    with target_role='admin', but EventLog only supports customer/technician roles.
    The DB row replaces the broadcast; admin reads via Django Admin.
    Calls finance.apply_cancellation_charge(actor='tech', phase=<computed>)."""

def mark_no_show(
    *, booking_id, actor_user, actor_role: str,  # 'tech' | 'customer'
    finance=None,
) -> JobBooking:
    """Tech path: ARRIVED/INSPECTING/QUOTED → NO_SHOW (after arrived_at + 15min, enforced at view).
    Customer path: CONFIRMED/EN_ROUTE/ARRIVED → NO_SHOW (after scheduled_start + 15min, enforced at view).
    Stamps no_show_at, no_show_actor.
    Fires booking_no_show event to the OTHER party (audit P1-14: admin half dropped same as
    dispute_opened; admin reliability tracking via DB query, not realtime).
    When actor_role='customer' (customer reports tech no-show), also writes a
    TechReliabilityIncident row (incident_type='TECH_NO_SHOW') for admin review.
    No finance port this sprint (penalty/fee math deferred to finance sprint)."""

def open_dispute(
    *, booking_id, opener_user,
    initial_reason: str,
    photo_file=None,  # ImageField-compatible
    finance=None,
) -> SupportTicket:
    """Any status (including post-completion) → DISPUTED if not already.
    Creates SupportTicket(dispute_intake_method='FORM', initial_reason, opener),
    optionally creates one TicketEvidence row.
    Flips booking.status to DISPUTED only if not already there (multiple tickets allowed
    per booking; status flip is one-shot — see edge case #7).
    Stamps dispute_opened_at on first ticket.
    Fires dispute_opened event to counterparty (audit P1-14: admin half dropped;
    EventLog target_role doesn't support 'admin'; admin sees disputes via Django Admin).
    No finance port."""

def admin_resolve_dispute(
    *, ticket_id: int, admin_user,
    outcome: str,  # 'REFUND_CUSTOMER' | 'PENALIZE_TECH' | 'DISMISS'
    notes: str,
    final_status: str,  # one of {COMPLETED, COMPLETED_INSPECTION_ONLY, CANCELLED}
    finance=None,
) -> SupportTicket:
    """DISPUTED → final terminal (admin chooses).
    Marks ticket.status=RESOLVED, resolution_outcome, resolution_notes, resolved_at=now.
    Updates booking.status = final_status.
    Fires dispute_resolved event to both parties.
    No finance port this sprint (refund money flow is finance-sprint work)."""

def reschedule(
    *, original_booking_id, customer_user,
    new_scheduled_start, new_scheduled_end,
    finance=None,
) -> JobBooking:
    """AWAITING/CONFIRMED → CANCELLED on original; create child JobBooking (AWAITING)
    with parent_booking=original. Copies tech_id, address, service, sub_service,
    promotion snapshot. Original cancel_reason='customer_rescheduled' (no fee).
    Fires booking_rescheduled event to tech (with new booking id).
    Then dispatches the new booking via existing dispatch_job_new_request_event.
    Reschedule blocked from EN_ROUTE onwards (raises BookingValidationError).
    No finance port for the cancellation half (rescheduling is fee-exempt)."""
```

Implementation note: keep the canonical 5-step shape. Don't be clever. Don't refactor common code into a "transition decorator" — readability matters more than DRY here.

---

### File 9: `backend/bookings/services/auto_transition.py` (new)

```python
"""Auto-transition layer (sprint meta §14 rule 1).

Geofence-driven status flips invoked by the tech-location ingress endpoint
(landing in session 2). Tech never taps a button for these — the location
update itself is the trigger.

The location ingress endpoint calls evaluate_on_location after recording the
GPS frame. If a transition fires, the orchestrator handles atomicity, event
broadcast, and finance port calls; auto_transition is purely the trigger
classifier.
"""

from __future__ import annotations
from math import radians, sin, cos, sqrt, atan2

from bookings.models import JobBooking
from bookings.services import orchestrator


# §14 rule 1 thresholds
EN_ROUTE_THRESHOLD_METERS = 200    # GPS leaves accept-location radius
ARRIVED_THRESHOLD_METERS = 100     # GPS within customer-address radius


def evaluate_on_location(*, booking_id: int, lat: float, lng: float, technician_user) -> str | None:
    """Check geofence rules for the booking; flip status if criteria met.

    Returns the new status if a transition fired, None otherwise.

    Called once per tech-location ingress frame; idempotent because the
    orchestrator's transition functions short-circuit on already-target state.
    """
    # Cheap fetch (no select_for_update — orchestrator does that)
    try:
        booking = JobBooking.objects.select_related('address').get(id=booking_id)
    except JobBooking.DoesNotExist:
        return None

    if booking.status == JobBooking.STATUS_CONFIRMED:
        # Use the customer's address as a proxy for "starting zone" — if tech
        # is already >200m from there, they've started moving. v2: record the
        # actual accept-location from the first ping after accept.
        accept_lat, accept_lng = booking.address.latitude, booking.address.longitude
        if _haversine_meters(lat, lng, accept_lat, accept_lng) > EN_ROUTE_THRESHOLD_METERS:
            orchestrator.en_route(
                booking_id=booking_id,
                technician_user=technician_user,
                source='auto',
            )
            return JobBooking.STATUS_EN_ROUTE

    elif booking.status == JobBooking.STATUS_EN_ROUTE:
        cust_lat, cust_lng = booking.address.latitude, booking.address.longitude
        if _haversine_meters(lat, lng, cust_lat, cust_lng) <= ARRIVED_THRESHOLD_METERS:
            orchestrator.arrived(
                booking_id=booking_id,
                technician_user=technician_user,
                source='auto',
            )
            return JobBooking.STATUS_ARRIVED

    return None


def _haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in meters."""
    R = 6_371_000  # earth radius m
    phi1, phi2 = radians(lat1), radians(lat2)
    dphi = radians(lat2 - lat1)
    dlambda = radians(lng2 - lng1)
    a = sin(dphi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(dlambda / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return R * c
```

---

### File 10: `backend/bookings/selectors/quote_selector.py` (new)

```python
"""Read-side accessors for Quote / QuoteLineItem / BookingItem.

All queries use select_related/prefetch_related to satisfy the no-N+1 rule
(CLAUDE.md). All callers are session-2 views and session-3 frontend hydration.
"""

from typing import List
from bookings.models import JobBooking, Quote, BookingItem


def get_active_quote(booking: JobBooking) -> Quote | None:
    """The most recent SUBMITTED quote, or the most recent quote of any state if
    no SUBMITTED. Used by orchestrator screen to render the quote-decision card.
    """
    submitted = (
        booking.quotes
        .filter(status=Quote.STATUS_SUBMITTED)
        .order_by('-revision_number')
        .prefetch_related('line_items__sub_service')
        .first()
    )
    if submitted:
        return submitted
    return (
        booking.quotes
        .order_by('-revision_number')
        .prefetch_related('line_items__sub_service')
        .first()
    )


def list_quote_history(booking: JobBooking) -> List[Quote]:
    """All quotes for the booking, oldest revision first. Used by admin and
    debugging tools."""
    return list(
        booking.quotes
        .order_by('revision_number')
        .prefetch_related('line_items__sub_service')
    )


def list_booking_items(booking: JobBooking) -> List[BookingItem]:
    """The accepted-and-performed line items. Source of truth for finance
    sprint reconciliation."""
    return list(
        booking.items
        .order_by('id')
        .select_related('sub_service', 'sourced_quote')
    )
```

---

### File 11: `backend/bookings/selectors/dispute_selector.py` (new)

```python
"""Read-side accessors for SupportTicket / TicketEvidence."""

from typing import List
from bookings.models import JobBooking, SupportTicket


def list_open_tickets(booking: JobBooking) -> List[SupportTicket]:
    """All OPEN tickets on the booking. Multiple allowed (edge case #7)."""
    return list(
        booking.tickets
        .filter(status=SupportTicket.STATUS_OPEN)
        .order_by('-opened_at')
        .prefetch_related('evidence')
        .select_related('opened_by')
    )


def list_all_tickets(booking: JobBooking) -> List[SupportTicket]:
    """All tickets (open + resolved) — admin view."""
    return list(
        booking.tickets
        .order_by('-opened_at')
        .prefetch_related('evidence')
        .select_related('opened_by')
    )
```

---

### File 12: `backend/bookings/exceptions.py` (modified)

**Audit P0-01**: the v0.9 plan said "Existing file has `BookingValidationError`" — verified false. The existing file has `InvalidAddressError`, `OutOfServiceAreaError`, `SlotUnavailableError`, `InconsistentBookingIntentError`, `PromoFirewallError`, `BookingNotFoundForTechnicianError`, `BookingNotActionableError`. **None of those carry the `code/message/errors` envelope shape**. Session 1 must **add** the class.

Add the class **and** the new error code constants:

```python
# backend/bookings/exceptions.py — additions (existing exception classes untouched)

from rest_framework.exceptions import APIException
from rest_framework import status as drf_status


class BookingValidationError(APIException):
    """Raised by orchestrator transitions; serialized by the standard DRF
    exception handler (`backend/core/common/failures/exception.py`) into the
    canonical `{status, code, message, errors}` envelope.

    The handler must recognize this class — verify the handler iteration
    includes a branch for `isinstance(exc, BookingValidationError)` and
    emits `{'status': exc.status_code, 'code': exc.code,
            'message': exc.message, 'errors': exc.errors}`.
    Patch the handler in this session if it doesn't.
    """
    status_code = drf_status.HTTP_400_BAD_REQUEST
    default_detail = 'Booking transition invalid.'
    default_code = 'invalid_transition'

    def __init__(
        self,
        *,
        code: str,
        message: str,
        errors: dict | None = None,
        status: int = 400,
    ):
        self.status_code = status
        self.code = code
        self.message = message
        self.errors = errors or {}
        # APIException expects `detail`; we pass message so DRF logs are useful.
        super().__init__(detail=message, code=code)


# Booking orchestrator v1 — new error codes (sprint 0008)
ERROR_INVALID_TRANSITION = 'invalid_transition'
ERROR_INVALID_QUOTE_EMPTY = 'invalid_quote_empty'
ERROR_QUOTE_BAND_VIOLATION = 'quote_band_violation'
ERROR_CANCELLATION_NOT_ALLOWED = 'cancellation_not_allowed'
ERROR_DISPUTE_NOT_DISPUTABLE_STATUS = 'dispute_not_disputable_status'
ERROR_RESCHEDULE_NOT_ALLOWED = 'reschedule_not_allowed'
ERROR_NOT_ASSIGNED_TO_YOU = 'not_assigned_to_you'
ERROR_NO_SHOW_TOO_EARLY = 'no_show_too_early'  # threshold not yet elapsed
```

These are used by `orchestrator.py` calls to `BookingValidationError(code=ERROR_*, ...)` and by session-2 view tests.

**Custom exception handler patch** — verify `backend/core/common/failures/exception.py` already handles `APIException` subclasses correctly (DRF's default handler does). If `BookingValidationError` isn't picked up, add an explicit branch at the top of the custom handler:

```python
# backend/core/common/failures/exception.py — add (after the existing IntegrityError branch)
from bookings.exceptions import BookingValidationError

def custom_exception_handler(exc, context):
    if isinstance(exc, BookingValidationError):
        return Response(
            {
                'status': exc.status_code,
                'code': exc.code,
                'message': exc.message,
                'errors': exc.errors,
            },
            status=exc.status_code,
        )
    # ... existing logic ...
```

Add a unit test asserting the envelope shape: `tests/bookings/test_exceptions.py::test_booking_validation_error_envelope_shape`.

---

### File 13: `backend/realtime/constants/event_types.py` (modified)

Add **4** new event types (was 5 in v0.9; `tech_reliability_penalty` removed per audit P0-08 — see §1 decision 6 amendment below) and their registry metadata.

```python
class EventType(str, Enum):
    # ... existing 13 values ...

    # Booking orchestrator v1
    QUOTE_REVISION_REQUESTED = 'quote_revision_requested'
    QUOTE_DECLINED = 'quote_declined'
    BOOKING_CANCELLED = 'booking_cancelled'
    BOOKING_NO_SHOW = 'booking_no_show'
    BOOKING_RESCHEDULED = 'booking_rescheduled'
    # `tech_reliability_penalty` deliberately NOT added — see audit P0-08;
    # tech-cancel writes to TechReliabilityIncident table instead.
```

Extend `EVENT_REGISTRY` with metadata for each:

```python
EventType.QUOTE_REVISION_REQUESTED: {
    'display_name': 'Customer wants to bargain',
    'is_critical': False,
},
EventType.QUOTE_DECLINED: {
    'display_name': 'Quote declined',
    'is_critical': False,
},
EventType.BOOKING_CANCELLED: {
    'display_name': 'Booking cancelled',
    'is_critical': False,
},
EventType.BOOKING_NO_SHOW: {
    'display_name': 'No-show reported',
    'is_critical': False,
},
EventType.BOOKING_RESCHEDULED: {
    'display_name': 'Booking rescheduled',
    'is_critical': False,
},
```

**Important** (audit C2-P1-03): verify `EVENT_REGISTRY` has `is_critical=True` for `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved` — these are the 5 critical events per sprint meta §16. **`payment_received` is `is_critical=False`** (cash collection confirms via the explicit POST response, not via an ACK on the realtime event); sprint meta §16 line 563 agrees. Do NOT flip `payment_received` to True. Spot-check during this session — sprint meta and registry must agree.

---

### File 14: `backend/bookings/admin.py` (modified)

Register the new models. `BookingAttachment` deliberately NOT registered (schema-only this sprint).

```python
from .models import (
    JobBooking, Quote, QuoteLineItem, BookingItem,
    SupportTicket, TicketEvidence,
    # BookingAttachment intentionally not registered (sprint §1 decision 9)
)


class QuoteLineItemInline(admin.TabularInline):
    model = QuoteLineItem
    extra = 0
    readonly_fields = ['sub_service', 'quantity', 'priced_at', 'line_total']
    can_delete = False


@admin.register(Quote)
class QuoteAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'revision_number', 'status', 'total_amount', 'created_at']
    list_filter = ['status', 'is_upsell']
    inlines = [QuoteLineItemInline]
    readonly_fields = ['booking', 'revision_number', 'total_amount', 'created_at', 'submitted_at', 'decided_at']


@admin.register(BookingItem)
class BookingItemAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'sub_service', 'quantity', 'price_charged', 'line_total']
    readonly_fields = ['booking', 'sub_service', 'quantity', 'price_charged', 'line_total', 'sourced_quote']


class TicketEvidenceInline(admin.TabularInline):
    model = TicketEvidence
    extra = 0


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'opened_by', 'status', 'resolution_outcome', 'opened_at']
    list_filter = ['status', 'resolution_outcome', 'dispute_intake_method']
    readonly_fields = ['booking', 'opened_by', 'dispute_intake_method', 'initial_reason', 'chat_log', 'opened_at']
    inlines = [TicketEvidenceInline]
    # Note: the resolve action wired in session 2 (custom admin button → backend service).
```

---

### File 15: `backend/tests/factories/bookings.py` (modified)

Append:

```python
import factory
from bookings.models import Quote, QuoteLineItem, BookingItem


class JobBookingConfirmedFactory(JobBookingFactory):
    status = JobBooking.STATUS_CONFIRMED
    accepted_at = factory.LazyFunction(timezone.now)


class JobBookingEnRouteFactory(JobBookingConfirmedFactory):
    status = JobBooking.STATUS_EN_ROUTE
    en_route_started_at = factory.LazyFunction(timezone.now)


class JobBookingArrivedFactory(JobBookingEnRouteFactory):
    status = JobBooking.STATUS_ARRIVED
    arrived_at = factory.LazyFunction(timezone.now)


class JobBookingInspectingFactory(JobBookingArrivedFactory):
    status = JobBooking.STATUS_INSPECTING
    inspection_started_at = factory.LazyFunction(timezone.now)


class JobBookingQuotedFactory(JobBookingInspectingFactory):
    status = JobBooking.STATUS_QUOTED


class JobBookingInProgressFactory(JobBookingQuotedFactory):
    status = JobBooking.STATUS_IN_PROGRESS
    work_started_at = factory.LazyFunction(timezone.now)


class JobBookingCompletedFactory(JobBookingInProgressFactory):
    status = JobBooking.STATUS_COMPLETED
    completed_at = factory.LazyFunction(timezone.now)
    cash_collected_at = factory.LazyFunction(timezone.now)
    cash_collected_amount = Decimal('1500.00')


class QuoteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Quote

    booking = factory.SubFactory(JobBookingInspectingFactory)
    revision_number = 1
    status = Quote.STATUS_SUBMITTED
    total_amount = Decimal('0.00')
    is_upsell = False


class QuoteLineItemFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = QuoteLineItem

    quote = factory.SubFactory(QuoteFactory)
    sub_service = factory.SubFactory('tests.factories.catalog.SubServiceFactory')
    quantity = 1
    priced_at = Decimal('500.00')
    line_total = Decimal('500.00')


class BookingItemFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BookingItem

    booking = factory.SubFactory(JobBookingInProgressFactory)
    sub_service = factory.SubFactory('tests.factories.catalog.SubServiceFactory')
    quantity = 1
    price_charged = Decimal('500.00')
    line_total = Decimal('500.00')
```

---

### File 16: `backend/tests/factories/support.py` (new)

```python
import factory
from bookings.models import SupportTicket, TicketEvidence, BookingAttachment


class SupportTicketFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = SupportTicket

    booking = factory.SubFactory('tests.factories.bookings.JobBookingCompletedFactory')
    opened_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    dispute_intake_method = SupportTicket.INTAKE_FORM
    initial_reason = "Tech didn't fix the leak properly."
    status = SupportTicket.STATUS_OPEN


class TicketEvidenceFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = TicketEvidence

    ticket = factory.SubFactory(SupportTicketFactory)
    uploaded_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    image = factory.django.ImageField(width=100, height=100)
    caption = ''


class BookingAttachmentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BookingAttachment

    booking = factory.SubFactory('tests.factories.bookings.JobBookingFactory')
    uploaded_by = factory.SubFactory('tests.factories.accounts.UserFactory')
    kind = BookingAttachment.KIND_OTHER
    image = factory.django.ImageField(width=100, height=100)
    caption = ''
```

---

### File 17: `backend/tests/factories/catalog.py` (modified)

Extend `SubServiceFactory`:

```python
class SubServiceFactory(factory.django.DjangoModelFactory):
    # ... existing fields ...
    max_price = factory.LazyAttribute(
        lambda o: None if o.is_fixed_price else o.base_price * Decimal('2.5')
    )


class FixedPriceSubServiceFactory(SubServiceFactory):
    is_fixed_price = True
    max_price = None


class LaborSubServiceFactory(SubServiceFactory):
    is_fixed_price = False
    base_price = Decimal('500.00')
    max_price = Decimal('1500.00')
```

---

### File 18: `backend/tests/bookings/test_models.py` (new)

Coverage:
- Status field max_length is 32 (not 10).
- All STATUS_* constants are in STATUS_CHOICES.
- TERMINAL_STATUSES set is correct.
- Quote unique_quote_revision_per_booking constraint enforced (IntegrityError on duplicate).
- QuoteLineItem.line_total auto-computed on save.
- BookingAttachment created without admin registration (schema-only verification).

---

### File 19: `backend/tests/bookings/test_services_orchestrator.py` (new)

For each of the 14 transition functions, at least 4 tests:
1. **Happy path** — correct from-state, all columns stamped, event registered (use mock-on-commit), finance port called with right args.
2. **Wrong from-state** — raises `BookingValidationError(code='invalid_transition')`, status unchanged.
3. **Idempotent retry** — same actor, same target state → returns booking unchanged, no duplicate event, no double finance call.
4. **Unauthorized actor** — raises `BookingValidationError(code='not_assigned_to_you')` for tech actions, scoped queries for customer actions.

Special tests:
- `submit_quote`: empty line_items rejected; labor band violation rejected; fixed-price band violation rejected; revision_number increments correctly.
- `approve_quote`: BookingItem rows correctly snapshotted; mid-job upsell appends rather than replaces.
- `decline_quote`: final_cash_to_collect set to inspection_fee.
- `cancel_by_customer`: phase computed correctly across status transitions.
- `cancel_by_tech`: tech_reliability_penalty event fired in addition to booking_cancelled.
- `mark_no_show`: actor_role discrimination works.
- `open_dispute`: multiple tickets on same booking allowed; status flip is one-shot.
- `reschedule`: child booking created with parent_booking link; original cancelled with `customer_rescheduled` reason; tech is re-dispatched (job_new_request fires for the new booking).

Use `pytest-django`'s `transactional_db` fixture for tests that exercise `select_for_update`.

---

### File 20: `backend/tests/bookings/test_services_auto_transition.py` (new)

Coverage:
- Tech within 100m of customer in EN_ROUTE state → flips to ARRIVED.
- Tech within 200m of accept-location in CONFIRMED state → no flip.
- Tech beyond 200m of accept-location in CONFIRMED state → flips to EN_ROUTE.
- Tech in INSPECTING state → no flip (auto-transition only operates on CONFIRMED and EN_ROUTE).
- Booking not found → returns None silently.
- Haversine math on known coordinates (Lahore lat/lng test cases).

---

### File 21: `backend/tests/bookings/test_finance_ports.py` (new)

Coverage:
- `NullFinanceAdapter.can_accept_job` returns `(True, None)` always.
- All other methods return None.
- `NullFinanceAdapter` satisfies the `FinancePort` Protocol structurally (use `typing.runtime_checkable` if needed).
- `get_default_finance_service()` returns a `NullFinanceAdapter` instance.

---

### File 22: `backend/tests/bookings/test_selectors_quote.py` (new)

Coverage:
- `get_active_quote` returns the most recent SUBMITTED quote.
- `get_active_quote` falls back to most recent quote if no SUBMITTED exists.
- `list_quote_history` returns oldest-first.
- `list_booking_items` returns ordered by id with `select_related` (assert via `django_assert_num_queries(2)` — one for items, one for prefetched sub_services).

---

### File 23: `backend/tests/bookings/test_selectors_dispute.py` (new)

Coverage:
- `list_open_tickets` returns only OPEN tickets, newest first.
- `list_all_tickets` returns all tickets (open + resolved).
- Both use prefetched evidence; assert query count.

---

### File 24: `bookings/models.py::TechReliabilityIncident` (new — audit P0-08)

Add to `bookings/models.py` after `TicketEvidence`:

```python
class TechReliabilityIncident(models.Model):
    """Admin log of tech reliability events. Replaces the v0.9-planned realtime
    `tech_reliability_penalty` event (audit P0-08); `EventLog.target_role`
    doesn't support `'admin'` (only `customer`/`technician`), so the broadcast
    would fail at save. The DB row is the source of truth; admin reads via
    Django Admin. Future "reliability score" sprint aggregates over this table.

    Two incident types in v1:
      - TECH_CANCEL: tech voluntarily cancelled a confirmed/post-arrival job.
      - TECH_NO_SHOW: customer reported tech as no-show.
    """
    INCIDENT_TECH_CANCEL = 'TECH_CANCEL'
    INCIDENT_TECH_NO_SHOW = 'TECH_NO_SHOW'
    INCIDENT_CHOICES = [
        (INCIDENT_TECH_CANCEL, 'Tech cancelled job'),
        (INCIDENT_TECH_NO_SHOW, 'Tech reported as no-show by customer'),
    ]

    technician = models.ForeignKey(
        'technicians.TechnicianProfile', on_delete=models.CASCADE,
        related_name='reliability_incidents',
    )
    booking = models.ForeignKey(
        JobBooking, on_delete=models.CASCADE,
        related_name='tech_reliability_incidents',
    )
    incident_type = models.CharField(max_length=32, choices=INCIDENT_CHOICES)
    phase = models.CharField(max_length=32, blank=True, default='')   # 'pre_arrival' | 'post_arrival' | etc.
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['technician', '-created_at'])]
```

Migration `0008_booking_orchestrator_foundations.py` `CreateModel` count: 6 → **7**.

Admin (extend File 14): register with a custom `ModelAdmin`. **Audit C2-P2-01**: Django Admin doesn't accept `'__all__'` as a `readonly_fields` value (no special-cased magic string — it would be looked up as a literal field name and not found). Use the explicit pattern below to make every field readonly AND disable add/delete (audit log; immutable post-write):

```python
@admin.register(TechReliabilityIncident)
class TechReliabilityIncidentAdmin(admin.ModelAdmin):
    list_display = ['id', 'technician', 'booking', 'incident_type', 'created_at']
    list_filter = ['incident_type']

    def get_readonly_fields(self, request, obj=None):
        # Every field is readonly — admin views the audit row but never edits.
        return [f.name for f in self.model._meta.fields]

    def has_add_permission(self, request):
        return False    # rows are written by orchestrator only

    def has_delete_permission(self, request, obj=None):
        return False    # never delete an audit row
```

Test in `tests/bookings/test_models.py`:
- `test_tech_reliability_incident_created_on_tech_cancel` — call `orchestrator.cancel_by_tech`, assert one row exists.
- `test_tech_reliability_incident_created_on_customer_reports_tech_no_show` — call `orchestrator.mark_no_show(actor_role='customer')`, assert one row.

---

### File 25: `backend/bookings/services/instant_book_service.py` (modified — audit P1-03)

**Audit P1-03**: v0.9 added `JobBooking.promo_code_snapshot` and `promo_discount_snapshot` columns but never patched the booking creation site to write them. Result: every new booking would have NULL snapshots, defeating the entire "survive promotion deletion" purpose.

In `create_instant_booking`, after the booking row is constructed (around the existing `JobBooking(...)` instantiation) but before the `.save()` call, add:

```python
# Snapshot promo metadata (sprint v1, audit P1-03).
# These columns are denormalized on JobBooking so that promotion deletion
# or expiry doesn't lose the booking's effective discount audit trail.
if promotion is not None:
    booking.promo_code_snapshot = promotion.code
    # `discount_amount` is the Decimal computed earlier in this function
    # by the pricing resolver; export it here. Variable name will depend
    # on what the existing pricing computation calls it — adapt to local code.
    booking.promo_discount_snapshot = discount_amount
```

Adapt variable names to whatever the existing function uses for the resolved-promotion-discount. The contract:
- `promo_code_snapshot == promotion.code` at booking creation, frozen forever.
- `promo_discount_snapshot == <discount_amount_actually_applied>` (Decimal, in PKR).

Test (`tests/bookings/test_services_instant_book.py`):
- `test_promo_snapshot_written_at_creation_with_promotion` — passes `promotion_id`, asserts both snapshot fields equal the promotion's values.
- `test_promo_snapshot_null_at_creation_without_promotion` — passes no `promotion_id`, asserts both are null.

---

## §5 Gotchas

1. **`max_length` increase from 10 to 32** on `JobBooking.status` — backwards-compatible widening but MySQL InnoDB may rebuild the table on some configs. Verify migration applies cleanly on your dev DB before pushing.
2. **`JobBooking.status` default change** — the field now defaults to `STATUS_AWAITING_TECH_ACCEPT` instead of `STATUS_PENDING`. If anything in fixtures or factories relied on the `STATUS_PENDING` default, update it explicitly. New `JobBookingFactory` inherits the new default.
3. **Promo snapshot fields are nullable for legacy rows** — bookings created BEFORE this migration won't have `promo_code_snapshot` set even if they have a `promotion` FK. Don't assume non-null. The serializer (session 2) will derive a fallback from the live FK if snapshot is null. **New bookings (from File 25 patch onward) always populate the snapshot when a promotion is applied** — audit P1-03 was specifically about ensuring new rows write the snapshot.
4. **`parent_booking` SET_NULL on delete** — never hard-delete a parent booking (you shouldn't, since CANCELLED is the right terminal state). If a hard-delete happens, child loses lineage.
5. **Decimal precision uniformity** — every money field uses `max_digits=10, decimal_places=2` matching existing `JobBooking.price_amount`. Don't introduce new precision values.
6. **`Quote.total_amount` is server-derived but stored.** The orchestrator must keep it in sync with `sum(line_items.line_total)` on every quote mutation. Service-layer assertions catch drift; not enforced by DB constraint.
7. **`auto_transition.py` only fires on CONFIRMED → EN_ROUTE and EN_ROUTE → ARRIVED.** INSPECTING is triggered by frontend (UI navigation = trigger), not GPS. Don't add INSPECTING to auto_transition.
8. **Atomicity boundary** — every orchestrator function is one `transaction.atomic()` block. Event broadcasts go through `transaction.on_commit(...)` per CLAUDE.md (rolled-back transactions never queue phantom events). Finance port calls happen INSIDE the atomic block so a port failure rolls back the status flip. Null adapter never raises, so atomicity isn't tested under failure this sprint — finance sprint will exercise it.
9. **Legacy `STATUS_PENDING` retained but unused.** Don't add new transitions from PENDING; orchestrator's validation rejects PENDING as a from-state for every transition. Existing PENDING rows (if any) are pre-migration 0007 artifacts.
10. **`SubService.max_price` migration** — null for existing rows. Before any quote validation can succeed against labor sub-services, an admin must set `max_price`. Add a Django Admin warning banner if `is_fixed_price=False` and `max_price IS NULL` (in `catalog/admin.py`, separate concern, can defer to session 2).
11. **`BookingAttachment` schema-only** — model exists, NOT registered in admin, no upload UI, no upload endpoint this sprint. Don't accidentally enable in admin during this session.
12. **`select_for_update` requires the queryset to be in a transaction.** The existing pattern in `job_request_action.py` is the template; copy that shape exactly. Outside a transaction, `select_for_update` is a no-op silently.
13. **Event firing inside orchestrator** uses existing `EventDispatchService.broadcast_event(...)`. Wrap the call in a closure passed to `transaction.on_commit(...)`. Add the new event types to the enum BEFORE the orchestrator's broadcasts can resolve them — same migration session, but sequence the file-edit order so the enum lands before the orchestrator imports it.
14. **No new endpoints this session.** If you find yourself reaching for `urls.py` or a new view, stop — that work is session 2.
15. **Test pyramid**: this session is heavy on service-layer tests (the orchestrator IS the contract). Don't write API-shape tests (no APIs yet). Don't write integration-flavored tests against a live realtime channel (that's session 2's job).
16. **Factory inheritance chain depth.** `JobBookingCompletedFactory` inherits through 7 levels. If you add new fields mid-chain, ensure each level explicitly sets what it needs to flip. Trace the chain on each write.

---

## §6 Verification

### Static checks

```bash
cd backend
python manage.py makemigrations --dry-run --check         # no missed migrations
python manage.py migrate                                   # applies bookings 0008 + catalog 0008 (different apps)
python manage.py check                                     # no system check errors
python manage.py shell -c "from bookings.services import orchestrator; print('orch OK')"
python manage.py shell -c "from bookings.services.finance_ports import FinancePort; print('port OK')"
python manage.py shell -c "from bookings.adapters import get_default_finance_service; print(get_default_finance_service())"
```

### Unit tests

```bash
cd backend
pytest tests/bookings/test_models.py -v
pytest tests/bookings/test_services_orchestrator.py -v
pytest tests/bookings/test_services_auto_transition.py -v
pytest tests/bookings/test_finance_ports.py -v
pytest tests/bookings/test_selectors_quote.py -v
pytest tests/bookings/test_selectors_dispute.py -v

# Full suite
pytest -q
```

### Manual smoke (Django shell)

```bash
python manage.py shell
```

```python
from tests.factories.bookings import JobBookingFactory, JobBookingArrivedFactory
from bookings.services import orchestrator

# Walk a booking through INSPECTING
b = JobBookingArrivedFactory()
print(b.status)  # ARRIVED
b = orchestrator.start_inspection(booking_id=b.id, technician_user=b.technician.user)
print(b.status, b.inspection_started_at)  # INSPECTING, <timestamp>

# Try wrong from-state
b2 = JobBookingFactory()
try:
    orchestrator.start_inspection(booking_id=b2.id, technician_user=b2.technician.user)
except Exception as e:
    print("rejected:", e)
```

### Migration round-trip

```bash
python manage.py migrate bookings 0007            # rollback to before this sprint
python manage.py migrate catalog 0007             # rollback catalog one step too (was 0008 in v0.9; audit P0-05 fix)
python manage.py migrate                           # re-apply both
pytest tests/bookings/ -q                          # everything still green
```

### Constraint check (per CLAUDE.md)

```bash
# Confirm services don't import Celery or wallet machinery at module load
grep -rn "from celery import" backend/bookings/services/   # should be empty
grep -rn "from wallet" backend/bookings/services/          # should be empty
grep -rn "import jazzcash" backend/bookings/services/      # should be empty

# Confirm only ONE new module mutates JobBooking.status (orchestrator + the existing 3 services)
grep -rn "\.status =" backend/bookings/services/
# Expected hits: orchestrator.py (many), instant_book_service.py (existing), 
# job_request_action.py (existing). No others.
grep -rn "\.status =" backend/bookings/tasks.py
# Expected: 1 hit (existing SLA expiry task)
```

---

## §7 What this session does NOT fix

- HTTP endpoints — session 2.
- Realtime stream subscription mechanism in WS consumer — session 2.
- `tech_gps` stream + ingress endpoint — session 2.
- Geofence strictness configurability per booking — env-level toggle in session 2; per-tech config later sprint.
- Admin "Resolve dispute" custom action wiring — session 2 (model + service exist now; admin button calls `admin_resolve_dispute` in session 2).
- Reliability score user-facing surface — admin-only event audit this sprint.
- Frontend orchestrator screen — session 3.
- Live tracking UI / dual-provider maps / Android foreground service — session 4.
- Quote builder UI / approval sheet / cash collection screen — session 5.
- Cancellation / no-show / dispute UI — session 6.
- Real `WalletTransaction` and `JobCommission` writes — finance sprint.
- AI chatbot intake — future sprint (`SupportTicket.dispute_intake_method` reserves the seam).
- Reviews / ratings model + API — future sprint.
- iOS foreground location service — deferred per flag #10.
- `BookingAttachment` upload UI / admin registration — schema reserved this sprint, future sprint when chatbot ships.
- Data migration of legacy `PENDING` rows — left as-is; new lifecycle does not produce or consume PENDING.
- `Promotion.funded_by` impact on tech's quote-builder rate floor — pricing computation lands in session 5; service-layer math this session is straight-through.

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All files in §2 created/modified at the listed paths.
- [ ] Migration `0008_booking_orchestrator_foundations` applies cleanly on a fresh dev DB.
- [ ] Migration `0009_subservice_max_price` applies cleanly.
- [ ] `python manage.py makemigrations --dry-run --check` reports no pending migrations.
- [ ] `python manage.py check` returns no errors.
- [ ] All 14 orchestrator transition functions implemented per the canonical shape (§4.8.a).
- [ ] `auto_transition.evaluate_on_location` implemented and tested.
- [ ] `FinancePort` Protocol declared with all 5 methods and full docstrings.
- [ ] `NullFinanceAdapter` satisfies the Protocol.
- [ ] `get_default_finance_service()` returns NullFinanceAdapter via lazy import.
- [ ] All 5 new event types added to `EventType` enum and `EVENT_REGISTRY` metadata.

### Tests

- [ ] `pytest -q` green on the full suite (no regressions on existing tests).
- [ ] Each orchestrator function has at least 4 tests (happy / wrong-from / idempotent / unauthorized).
- [ ] `submit_quote` has additional tests for empty quote, labor band, fixed-price band, revision increment.
- [ ] `approve_quote` has additional tests for BookingItem snapshot + upsell append behavior.
- [ ] `cancel_by_customer` has tests for all 3 phases (pre_accept, pre_arrival, post_arrival).
- [ ] `auto_transition` has Haversine math test cases for known coordinates.
- [ ] `NullFinanceAdapter` Protocol-conformance test passes.
- [ ] Selector tests use `django_assert_num_queries` for no-N+1 enforcement.

### Constraints (per CLAUDE.md)

- [ ] `bookings/services/*.py` does NOT contain `from celery import` or `from realtime.events.services import` at module load. Adapters and event broadcasts are inside function bodies.
- [ ] No new business logic in any view (no new views were added).
- [ ] All status mutations use `transaction.atomic()` + `select_for_update()`.
- [ ] All event broadcasts inside `transaction.on_commit(...)`.
- [ ] All finance port calls inside the atomic block.

### flag.md

- [ ] `flag.md` updated per sprint meta §20:
  - [ ] Opens `ai-chatbot-deferred`
  - [ ] Opens `reviews-deferred`
  - [ ] Opens `bank-accounts-deferred`
  - [ ] Opens `admin-realtime-channel-deferred` (audit P0-08 — needed before re-introducing admin event broadcasts; until then `TechReliabilityIncident` table fills the gap)
- [ ] Each opened flag follows the existing schema (Where / What's wrong / Why we shipped it / The proper fix).

### Documentation

- [ ] This session file (`session_1_backend_foundations.md`) committed alongside `BOOKING_ORCHESTRATOR_SPRINT.md`.
- [ ] Sprint context preamble (§0 of this file) links to the meta-file.
- [ ] No `[TBD]` markers remain in this session file.

### Git

- [ ] Single commit (or small commit chain) with a clear message: `feat(bookings): orchestrator backend foundations (sprint v1, session 1)`.
- [ ] No `--no-verify`, no `--amend` of pushed commits.
- [ ] `git status` clean after commit.
