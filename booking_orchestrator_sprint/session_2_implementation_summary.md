# Session 2 — Implementation Summary (state of the world)

> Companion to `session_2_backend_transitions.md` (the original spec). This document captures **what actually shipped vs. what the spec asked for**, the audit history, every patch made, and what the next session inherits. Written 2026-05-08 against the live working tree.
>
> **Read this before starting Session 3.** The spec describes intent; this describes reality.

---

## §0 TL;DR for future-me

1. **Every Session 2 endpoint, selector, and test is in the working tree but UNCOMMITTED.** Twelve `??` (untracked) directories/files plus thirteen `M ` (modified-not-staged) files. `git status --short` is the source of truth — see §11.
2. The orchestrator service layer (Session 1's deliverable) **was committed** as eight "audit phase" commits (`cf69c40`…`88701ed`) on top of Session 1's feature commits. Those phases are done.
3. The HTTP/WS surface that Session 2 adds **on top** of that orchestrator is what's sitting uncommitted. It works (826 passing tests, `manage.py check` clean, no pending migrations) but has not yet been turned into a commit.
4. **Two audit passes (Pass 1 + Pass 2)** were performed in this conversation. Pass 1 shipped C1/H1/H5; Pass 2 shipped C2/C4/C5/H4. Tier 2 deferred. See §7.
5. **Two findings the audit agents claimed were critical were FALSE POSITIVES**: R3 (`unsubscribe_tracking` silent-kick) and O3 (reschedule discarded `select_for_update`). Both verified against channels source + the existing `instant_book_service` pattern. See §7.4.
6. The Session 2 spec said "no new migrations" but **two migrations did land** (`0009_supportticket_resolved_by`, `0010_quote_unique_submitted_quote_per_booking_flavour`) via the audit phases. They are committed.

---

## §1 What Session 2 was supposed to deliver (per spec)

Source: `booking_orchestrator_sprint/session_2_backend_transitions.md` (1581 lines).

The HTTP, WebSocket, admin, and docs surface that wires Session 1's `bookings/services/orchestrator.py` (14 transition functions) to clients:

- **16 HTTP endpoints** across 6 feature folders (transitions ×3, quotes ×4, completion ×1, terminations ×5, tech_location ×1, booking_detail ×1).
- **2 new selectors** (`orchestrator_ui.py`, `transition_validator.py`) — pure projections of orchestrator rules for UI hints.
- **WS consumer extension** — accept `subscribe_tracking` / `unsubscribe_tracking` upstream messages for booking-scoped tracking subgroups.
- **`tech_gps` stream** — published from `tech_location` ingress to `tracking_job_<booking_id>` subgroup.
- **Django Admin "Resolve dispute" custom action** on `SupportTicketAdmin`.
- **Docs** — extend `BOOKINGS_API.md`, create `STREAMS_TECH_GPS.md`, add new event types to `EVENT_DISPATCH_API.md`.
- **`BOOKING_GEOFENCE_STRICT` env var** — toggles strict-mode geofence rejection on the manual `arrived` endpoint.

---

## §2 What's actually in the working tree (file inventory)

### 2.1 New endpoint folders (all untracked)

```
backend/bookings/api/
├── booking_detail/        ?? (untracked)
│   ├── __init__.py
│   ├── serializers.py     # BookingDetailResponseSerializer + nested role-aware blocks
│   └── views.py           # GET /api/bookings/<id>/  (BookingDetailView)
├── completion/            ?? (untracked)
│   ├── serializers.py     # ConfirmCashReceivedRequestSerializer / Response
│   └── views.py           # POST /api/bookings/<id>/confirm-cash-received/
├── quotes/                ?? (untracked)
│   ├── serializers.py     # QuoteLineItemInputSerializer (+max_value=999 per Pass 2/C5)
│   └── views.py           # 4 endpoints: SubmitQuote, ApproveQuote, DeclineQuote, RequestRevision
├── tech_location/         ?? (untracked)
│   ├── serializers.py     # TechLocationRequestSerializer / Response
│   └── views.py           # POST /api/bookings/<id>/tech-location/  (with 4-sec throttle, Pass 2/H4 lock)
├── terminations/          ?? (untracked)
│   ├── serializers.py     # 5 (request, response) pairs (RescheduleRequest has Pass 2/C4 time bounds)
│   └── views.py           # CustomerCancel, TechCancel, MarkNoShow, OpenDispute, Reschedule
└── transitions/           ?? (untracked)
    ├── serializers.py     # ArrivedRequestSerializer / 3 response shapes
    └── views.py           # StartInspection, EnRoute, Arrived
```

### 2.2 Modified files (staged in working tree, not committed)

| File | Why it changed |
|---|---|
| `backend/bookings/admin.py` | Added `SupportTicketAdmin.resolve_view` + URL injection + `resolve_link` column. Plus `resolved_by` audit-trail (audit phase 6, committed). |
| `backend/bookings/api/urls.py` | Wired all 16 new routes (see §3). Literal-prefix routes ordered before `<int:>` catch-all. |
| `backend/bookings/services/orchestrator.py` | Pass 2 / C2 patch: `mark_complete_with_cash` now refuses any `cash_amount != booking.final_cash_to_collect`. |
| `backend/bookings/api/BOOKINGS_API.md` | Extended with §3–§13 covering all 16 endpoints, sample payloads, error envelopes. |
| `backend/realtime/api/EVENT_DISPATCH_API.md` | One line per new event type added to registry table. |
| `backend/realtime/constants/groups.py` | `TRACKING_JOB_GROUP_TEMPLATE = "tracking_job_{booking_id}"` added beside `USER_GROUP_TEMPLATE`. |
| `backend/realtime/events/consumers.py` | `subscribe_tracking` / `unsubscribe_tracking` upstream message handling + `_can_subscribe` authz (booking participant + non-terminal). |
| `backend/realtime/streams/dispatch.py` | `publish_stream` accepts `group=` parameter (additive — single-user `user=` path still works). |
| `backend/core/settings.py` | `BOOKING_GEOFENCE_STRICT = env.bool('BOOKING_GEOFENCE_STRICT', default=False)`. |
| `backend/tests/bookings/services/test_orchestrator.py` | Pass 2 / C2 regression tests on `mark_complete_with_cash`. |
| `CLAUDE.md` (repo root) | Documented WS subscribe/unsubscribe upstream messages contract. |
| `flag.md` (repo root) | New flags opened by this session — see §10. |

### 2.3 New selectors (untracked)

| File | Public API |
|---|---|
| `backend/bookings/selectors/orchestrator_ui.py` | `resolve_orchestrator_ui(booking, *, viewer, role) -> dict` — produces the `ui` dict (button text, pricing tag) that the booking-detail serializer embeds verbatim. Role-aware (`customer` / `technician`). |
| `backend/bookings/selectors/transition_validator.py` | `available_transitions(booking, *, viewer, role) -> list[str]` — projection of orchestrator validation for UI hints. Test-asserted to stay in sync with the orchestrator's actual validity rules. |

### 2.4 New tests (untracked)

| File | Tests |
|---|---|
| `tests/bookings/api/test_booking_detail_api.py` | 8 |
| `tests/bookings/api/test_transitions_api.py` | 13 |
| `tests/bookings/api/test_quotes_api.py` | 15 (incl. dual-role + quantity-overflow regressions) |
| `tests/bookings/api/test_completion_api.py` | 11 (incl. C2 regressions) |
| `tests/bookings/api/test_terminations_api.py` | 17 (incl. C4 reschedule-time regressions) |
| `tests/bookings/api/test_tech_location_api.py` | 13 (incl. H5 IDOR-before-throttle + H4 terminal-flip race) |
| `tests/bookings/api/test_admin_resolve_dispute.py` | 4 |
| `tests/realtime/test_consumer_tracking_subscribe.py` | 6 |
| `tests/bookings/selectors/test_orchestrator_ui_selector.py` | (untracked) |
| `tests/bookings/selectors/test_transition_validator_selector.py` | (untracked) |
| `tests/bookings/conftest.py` | Shared fixtures (`fake_finance`, `captured_broadcasts`) |

**Total Session 2-specific test functions: ~92** (excluding shared `test_orchestrator.py` which is Session 1).

### 2.5 New docs (untracked)

| File | Content |
|---|---|
| `backend/realtime/api/STREAMS_TECH_GPS.md` | Stream contract for the `tech_gps` topic — payload shape, group naming, subscribe/unsubscribe lifecycle, authorization model. |

### 2.6 New env / config (untracked)

| File | Purpose |
|---|---|
| `backend/.env.example` | Example env (committed); real `.env` is gitignored. `BOOKING_GEOFENCE_STRICT=False` default documented here. |

---

## §3 The 16 endpoints (URL → handler → orchestrator function → broadcast)

All routes mounted under `/api/bookings/`. URL ordering matters: literal-prefix (`counts/`, `instant-book/`) before typed `<int:booking_id>/` catch-all. The detail `GET <int:>/` doesn't shadow the verb-suffixed POSTs because Django picks longest-match.

| URL (POST unless noted) | Handler | Orchestrator function | Auth gate | Broadcasts (target_role) |
|---|---|---|---|---|
| **Read** | | | | |
| `GET <id>/` | `BookingDetailView` | (selectors only) | participant (customer or assigned tech) | — |
| **Phase markers (tech-only manual override)** | | | | |
| `<id>/start-inspection/` | `StartInspectionView` | `start_inspection` | `hasattr(tech_profile)` | — |
| `<id>/en-route/` | `EnRouteView` | `en_route(source='manual')` | `hasattr(tech_profile)` | `tech_en_route` (customer) |
| `<id>/arrived/` | `ArrivedView` | `arrived(source='manual')` | `hasattr(tech_profile)` + optional geofence | `tech_arrived` (customer) |
| **Quotes** | | | | |
| `<id>/quotes/` | `SubmitQuoteView` | `submit_quote` | `hasattr(tech_profile)` | `quote_generated` (customer) |
| `<id>/quotes/<qid>/approve/` | `ApproveQuoteView` | `approve_quote` | `_reject_if_not_customer` (booking_id-scoped, dual-role safe) | `quote_approved` (technician) |
| `<id>/quotes/<qid>/decline/` | `DeclineQuoteView` | `decline_quote` | `_reject_if_not_customer` | `quote_declined` (technician) |
| `<id>/quotes/<qid>/request-revision/` | `RequestRevisionView` | `request_revision` | `_reject_if_not_customer` | `quote_revision_requested` (technician) |
| **Completion** | | | | |
| `<id>/confirm-cash-received/` | `ConfirmCashReceivedView` | `mark_complete_with_cash` | `hasattr(tech_profile)` | `payment_received` + `job_completed` (customer) |
| **Terminations** | | | | |
| `<id>/cancel/` | `CustomerCancelView` | `cancel_by_customer` | `_reject_if_not_customer` | `booking_cancelled` (technician) |
| `<id>/tech-cancel/` | `TechCancelView` | `cancel_by_tech` | `hasattr(tech_profile)` | `booking_cancelled` (customer) |
| `<id>/no-show/` | `MarkNoShowView` | `mark_no_show` | participant; actor_role derived from auth (NOT body) | `booking_no_show` (other party) |
| `<id>/disputes/` | `OpenDisputeView` | `open_dispute` | participant (orchestrator validates) | `dispute_opened` (other party) |
| `<id>/reschedule/` | `RescheduleView` | `reschedule` | `_reject_if_not_customer` | (tech receives child as a fresh `job_new_request`) |
| **GPS ingress (publishes stream + auto-transition)** | | | | |
| `<id>/tech-location/` | `TechLocationIngressView` | `auto_transition.evaluate_on_location` | `hasattr(tech_profile)` + assigned-tech IDOR + 4-sec throttle | `tech_gps` STREAM to `tracking_job_<id>` |

### 3.1 Wire-code error catalog

| Wire code | When | HTTP | Source |
|---|---|---|---|
| `not_a_technician` | hasattr(tech_profile) gate fails | 403 | view layer |
| `not_a_customer` | `_reject_if_not_customer` mismatch | 403 | view layer |
| `not_a_participant` | booking_detail: caller is neither customer nor tech | 403 | view layer |
| `booking_not_found` | booking_id doesn't exist | 404 | view layer (and orchestrator) |
| `not_assigned_to_you` | orchestrator IDOR (tech) | 400 | orchestrator (`_require_assigned_tech`) |
| `invalid_transition` | from-state check fails | 400 | orchestrator (`_reject_invalid_from_state`) |
| `invalid_input` | shape OK, semantics wrong (e.g. cash mismatch per Pass 2/C2) | 400 | orchestrator |
| `invalid_quote_empty` | submit_quote with no line items | 400 | orchestrator |
| `quote_band_violation` | priced_at outside [base_price, max_price] | 400 | orchestrator |
| `cancellation_not_allowed` | post-arrival cancel rules | 400 | orchestrator |
| `dispute_not_disputable_status` | open_dispute on terminal/awaiting | 400 | orchestrator |
| `reschedule_not_allowed` | reschedule from EN_ROUTE+ or slot conflict | 400 | orchestrator |
| `no_show_too_early` | <15 min after arrival anchor | 400 | orchestrator |
| `quote_not_found` | quote_id doesn't belong to booking | 404 | orchestrator |
| `ticket_not_found` | dispute resolve target missing | 404 | orchestrator |
| `not_at_customer_location` | arrived strict-mode geofence fail | 400 | view (only if `BOOKING_GEOFENCE_STRICT=True`) |
| `too_many_requests` | tech_location 4-sec throttle | 429 | view layer |
| `validation_error` | DRF serializer field errors | 400 | DRF (canonical envelope via custom handler) |

### 3.2 Canonical error envelope

Every error path emits `{status, code, message, errors}` via `core/common/failures/exception.py::custom_exception_handler`. `BookingValidationError` matches FIRST so the orchestrator's stable codes survive DRF's default flow.

```json
{
  "status": 400,
  "code": "quote_band_violation",
  "message": "Quote line item priced outside the catalog band.",
  "errors": {"line_items[0].priced_at": ["expected within 1000.00–2000.00, got 9999.00"]}
}
```

---

## §4 Orchestrator public surface (Session 1, used by Session 2)

`bookings/services/orchestrator.py` — 14 public transition functions + admin one. Every function follows the canonical 5-step shape: resolve finance port → `transaction.atomic()` → `_lock_booking` + IDOR/from-state guard → mutate → `transaction.on_commit(broadcast)`.

| Function | From → To | Invoked by |
|---|---|---|
| `en_route` | CONFIRMED → EN_ROUTE | `EnRouteView` (manual) + `auto_transition` |
| `arrived` | EN_ROUTE → ARRIVED | `ArrivedView` (manual) + `auto_transition` |
| `start_inspection` | ARRIVED → INSPECTING | `StartInspectionView` |
| `submit_quote` | INSPECTING → QUOTED (or IN_PROGRESS upsell) | `SubmitQuoteView` |
| `request_revision` | QUOTED → INSPECTING (supersede prior quote) | `RequestRevisionView` |
| `approve_quote` | QUOTED → IN_PROGRESS (snapshot to BookingItem) | `ApproveQuoteView` |
| `decline_quote` | QUOTED → COMPLETED_INSPECTION_ONLY | `DeclineQuoteView` |
| `mark_complete_with_cash` | IN_PROGRESS → COMPLETED + cash stamp | `ConfirmCashReceivedView` |
| `cancel_by_customer` | {AWAITING, CONFIRMED, EN_ROUTE, ARRIVED, INSPECTING, QUOTED} → CANCELLED | `CustomerCancelView` |
| `cancel_by_tech` | {CONFIRMED, EN_ROUTE, ARRIVED} → CANCELLED + `TechReliabilityIncident` | `TechCancelView` |
| `mark_no_show` | {ARRIVED, INSPECTING, QUOTED} → NO_SHOW (15-min anchor) | `MarkNoShowView` |
| `open_dispute` | non-terminal → DISPUTED + `SupportTicket` | `OpenDisputeView` |
| `reschedule` | {AWAITING, CONFIRMED} → original CANCELLED + child AWAITING | `RescheduleView` |
| `admin_resolve_dispute` | DISPUTED → {CANCELLED, COMPLETED, COMPLETED_INSPECTION_ONLY} + ticket RESOLVED | Django Admin custom action |

### 4.1 Idempotency contract

Every transition that has a deterministic target state is idempotent: a duplicate call with the booking already in the target state returns the booking silently without re-firing broadcasts or finance hooks.

**Known gap (Pass 2/H2-new, deferred):** `approve_quote` does NOT short-circuit on already-APPROVED — a duplicate call raises `invalid_transition`. Inconsistent with `mark_complete_with_cash` which DOES short-circuit. See §7.5.

### 4.2 Broadcast contract

Every broadcast is wrapped in `transaction.on_commit` so a rolled-back atomic block never produces a phantom WS frame or FCM push. Lazy-imported `EventDispatchService` to avoid a module cycle (orchestrator → realtime).

---

## §5 Realtime layer (modified by Session 2)

### 5.1 WS consumer (`realtime/events/consumers.py::SystemEventConsumer`)

- `connect()` — auth via `get_user_from_scope`; reject anonymous with code 4001; join per-user group `user_<id>_events`.
- `receive()` — accepts ONLY two upstream actions (everything else silently ignored):
  - `{"action": "subscribe_tracking", "booking_id": <int>}` → `_can_subscribe` authz → `group_add` to `tracking_job_<booking_id>`.
  - `{"action": "unsubscribe_tracking", "booking_id": <int>}` → `group_discard` from `tracking_job_<booking_id>`.
- `_can_subscribe(user_id, booking_id)` — booking-scoped DB authz: caller must be the booking's customer OR `booking.technician.user_id`, AND `booking.status not in TERMINAL_STATUSES`. Failures silently drop (no error frame; warn-log only — to avoid leaking booking existence).
- `disconnect()` — leaves all `tracking_job_<id>` subgroups in `_tracking_subscriptions` BEFORE leaving the user group (order is load-bearing: prevents in-flight tracking frames fanning out to a half-disconnected socket).

### 5.2 Streams (`realtime/streams/dispatch.py::publish_stream`)

- New keyword arg: `group=` (mutually exclusive with `user=`). Used by `tech_location` ingress to publish to `tracking_job_<booking_id>`.
- No `EventLog` write, no FCM fallback, no ACK contract. Strict per CLAUDE.md realtime rules.
- Try/except is narrow — wraps only the `group_send` call.

### 5.3 Group naming (`realtime/constants/groups.py`)

```python
USER_GROUP_TEMPLATE      = "user_{user_id}_events"          # pre-existing
TRACKING_JOB_GROUP_TEMPLATE = "tracking_job_{booking_id}"   # added Session 2
```

The `_events` suffix on the user group is historical (predates streams support) and intentionally retained — renaming would force a coordinated frontend churn.

### 5.4 New event types in `EVENT_REGISTRY`

| Event | `is_critical` | display_name |
|---|---|---|
| `quote_revision_requested` | False | Customer wants to bargain |
| `quote_declined` | False | Quote declined |
| `booking_cancelled` | False | Booking cancelled |
| `booking_no_show` | False | No-show reported |
| `booking_rescheduled` | False | Booking rescheduled |

(Pre-existing critical events: `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`, `job_new_request`.)

---

## §6 Selectors

| File | Purpose | Used by |
|---|---|---|
| `bookings/selectors/orchestrator_ui.py` | `resolve_orchestrator_ui(booking, viewer, role)` — returns `ui` block (button text, pricing tag) for the booking-detail response. Pure function; no DB beyond what's pre-fetched. | `BookingDetailView` |
| `bookings/selectors/transition_validator.py` | `available_transitions(booking, viewer, role)` — projection of orchestrator validity for UI. Test-asserted to stay in sync with orchestrator. | `BookingDetailView` |
| `bookings/selectors/quote_selector.py` | `get_active_quote(booking)`, `list_booking_items(booking)` — multi-revision quote chain handling. | `BookingDetailView`, orchestrator |
| `bookings/selectors/dispute_selector.py` | `list_open_tickets(booking)` — for the `open_tickets_count` in detail response. | `BookingDetailView` |

**Known gap (Pass 2/H6-new, H7-new, deferred):** `available_transitions` runs an unguarded `booking.tickets.filter(...).exists()` per call. The booking_detail endpoint makes 5 separate selector calls without `prefetch_related` chaining → estimated 6–8 DB queries per detail load. ZERO uses of `django_assert_num_queries` in `tests/bookings/api/` — this drift is invisible to the suite. See §7.5.

---

## §7 Audit history

### 7.1 Pre-Session-2 audits (committed as orchestrator hardening phases 1–8)

These are pre-existing audits applied to the orchestrator before this conversation began. All committed.

| Commit | Phase | What changed |
|---|---|---|
| `cf69c40` | 1 | Populate cash columns at booking creation time |
| `9ed9d05` | 2 | Defensive hardening (input coercion, error codes) |
| `748ba2a` | 3 | Design tightening |
| `2fba203` | 5 | Reschedule race + cash carry to child |
| `3af827b` | 6 | Admin-resolve audit trail (`SupportTicket.resolved_by`, migration 0009) |
| `08001e6` | 7 | Code semantics + payload completeness |
| `88701ed` | 8 | DB-enforced quote uniqueness (migration 0010 — partial unique index on `Quote(booking, is_upsell) WHERE status='SUBMITTED'`) |

### 7.2 Audit Pass 1 (this conversation, patched + uncommitted)

Spawned by user request: "aggressively audit your whole implementation, is it bulletproof?"

Three load-bearing patches landed:

| ID | File | Fix |
|---|---|---|
| **C1** | `bookings/api/booking_detail/views.py` | GET emits full no-cache header stack (`Cache-Control: no-store, no-cache, must-revalidate, private` + `Pragma: no-cache` + `Expires: 0`) — docstring claimed it but headers were absent. |
| **H1** | `bookings/api/quotes/views.py` (Approve/Decline/Revision), `bookings/api/terminations/views.py` (CustomerCancel/Reschedule) | Replaced `if hasattr(request.user, "tech_profile")` with `_reject_if_not_customer(request, booking_id)` helper that does `booking.customer_id == request.user.id`. Unblocks dual-role users (customer who is also an APPROVED tech) on their own bookings. Preserves `403 not_a_customer` wire code via pre-fetch. Adds clean `404 booking_not_found` path for missing bookings. |
| **H5** | `bookings/api/tech_location/views.py` | Reordered IDOR check BEFORE throttle. Pre-fix a non-assigned tech could populate `_LAST_PUBLISH_TS` with junk (tech_user_id, random_booking_id) keys until the cap-eviction sweep evicted legitimate entries. |

Deferred Pass 1 findings: H4 structural (subscribe→group_add race), H2/H3/H6/H7 (admin form retention, dispute N+1, tech_cancel reason discarded).

### 7.3 Audit Pass 2 (this conversation, patched + uncommitted)

Five parallel agents (endpoints, orchestrator, realtime, selectors, test-coverage) + my own dual-role verification. **31 net-new findings.**

Tier 1 patches landed:

| ID | File | Fix |
|---|---|---|
| **C2** | `bookings/services/orchestrator.py` (`mark_complete_with_cash`) | Validates `cash_amount == booking.final_cash_to_collect` exactly. Rejects under-payment (revenue loss) AND over-payment (client tampering). Missing `final_cash_to_collect` surfaces `400 invalid_transition` (server-side invariant break, not 500). |
| **C4-new** | `bookings/api/terminations/serializers.py` (`RescheduleRequestSerializer`) | Adds `validate(self, attrs)` enforcing `new_scheduled_start > now() - 60s grace` and `new_scheduled_start <= now() + 90 days`. Closes past-time + far-future capacity-pollution attacks. |
| **C5-new** | `bookings/api/quotes/serializers.py` (`QuoteLineItemInputSerializer`) | `quantity` now `IntegerField(min_value=1, max_value=999)`. Prevents `priced_at * quantity` arithmetic overflow of `Decimal(max_digits=10)` ceiling. |
| **H4** | `bookings/api/tech_location/views.py` | Wraps terminal-status check + `publish_stream` in `transaction.atomic()` with `select_for_update()` re-read. Closes the race where a concurrent terminal flip between unlocked check and publish leaks tech GPS post-completion. `auto_transition.evaluate_on_location` runs OUTSIDE the lock by design (it has its own atomic). |

### 7.4 Pass 2 false positives — DROPPED from Tier 1 (be aware)

Two findings the audit agents called CRITICAL turned out to be misdiagnosed. Verified against source before patching.

- **R3 — `unsubscribe_tracking` "silent kick attack":** **FALSE.** `channels.layers.InMemoryChannelLayer.group_discard(group, channel)` (and `channels_redis`) removes only the *named channel*, not the group. User B's unsubscribe runs `group_discard(group, B_channel)`; B's channel was never in the group → no-op. User A stays subscribed. There is no kick attack. (Defense-in-depth tightening — only allow unsubscribe of bookings in `_tracking_subscriptions` — is LOW priority.)
- **O3 — Reschedule `select_for_update` discarded result:** **FALSE.** `orchestrator.py:1506` uses `TechnicianProfile.objects.select_for_update().get(pk=...)` with no variable assignment. This is the SAME intentional pattern used at `instant_book_service.py:217`. The lock side-effect is what matters; Postgres holds the row lock until `transaction.atomic()` exits. Reschedule + instant_book serialize via that shared row. Working as intended.

### 7.5 Tier 2 (deferred — your call when to ship)

Defense-in-depth + operational hygiene. NOT critical, but should land before Session 6 closes.

| ID | What | Why deferred |
|---|---|---|
| D1/E4 | `hasattr(tech_profile)` gate doesn't check `status='APPROVED'` on 6 tech-only endpoints | Defense-in-depth; matchmaking won't assign non-APPROVED, but gate should be tightened. |
| H1-new | `finance.apply_inspection_fee_decision()` and `finance.record_commission()` called inside atomic but not in `transaction.on_commit()` | Null adapter masks; bites when real finance adapter lands in finance sprint. |
| H2-new | `approve_quote` not idempotent | Inconsistent with `mark_complete_with_cash`. Duplicate POST → `invalid_transition` instead of clean return. |
| H5-new | No scheduled job to prune `EventLog` (UNACKNOWLEDGED_WINDOW=24h documented but no Celery Beat task) | DB grows unbounded over time. |
| H6-new | `available_transitions` does unguarded `tickets.filter().exists()` per booking_detail load | N+1 on every detail screen. |
| H7-new | booking_detail makes 5 selector calls without `prefetch_related` (~6–8 queries per request) | Compounds H6-new; fix together. |
| H8-new | `cancel_reason` exposed as raw enum string to both roles | Currently safe values; future internal codes need role-conditional masking. |
| H3-new | Subscribe-tracking auth → group_add race window | Structural — needs design (subscription confirm frame vs server-side last-frame replay vs Redis-backed publish queue). Probably flag.md material. |
| T1 | dual-role test exists for `approve_quote` only | Decline / RequestRevision / CustomerCancel / Reschedule have NO dual-role regression. The H1 patch is undertested. |
| T9 | ZERO `django_assert_num_queries` in `tests/bookings/api/` | Direct violation of CLAUDE.md "Mandatory django_assert_num_queries on every test fetching nested data." This is why H6/H7 went undetected. |

Plus: D2 wire-code inconsistency (`_require_customer` raises `not_assigned_to_you`), M1–M7, L1–L4 (8 medium + 4 low).

---

## §8 Migrations

| Migration | Purpose | Committed? |
|---|---|---|
| `bookings/0008_booking_orchestrator_foundations.py` | Quote / QuoteLineItem / BookingItem / SupportTicket / TicketEvidence / BookingAttachment / TechReliabilityIncident + JobBooking column extensions + SubService.max_price | yes (Session 1) |
| `bookings/0009_supportticket_resolved_by.py` | `SupportTicket.resolved_by` FK + `resolved_at` audit columns (audit phase 6) | yes |
| `bookings/0010_quote_unique_submitted_quote_per_booking_flavour.py` | Partial unique index `Quote(booking, is_upsell) WHERE status='SUBMITTED'` (audit phase 8) | yes |
| `realtime/0002_eventlog_expires_at.py` | `EventLog.expires_at` + `recipient_user_id` (flag #19, pre-Session-2) | yes |

**Session 2 spec said "no new migrations expected." That held for the endpoint surface itself; 0009 and 0010 came from the audit phases that wrapped Session 1's orchestrator hardening. No further migrations added by Pass 1 or Pass 2 patches.**

---

## §9 Test state

**Full suite: 826 passing in ~12s** (was 814 baseline pre-Pass-1, +9 regression tests from Pass 2, +3 from Pass 1).

```
826 passed in 11.93s        # immediately before this summary
```

`manage.py check` clean. `makemigrations --dry-run` reports no changes.

### 9.1 Per-area test counts (Session 2 surface)

| File | Tests |
|---|---|
| `test_booking_detail_api.py` | 8 |
| `test_transitions_api.py` | 13 |
| `test_quotes_api.py` | 15 |
| `test_completion_api.py` | 11 |
| `test_terminations_api.py` | 17 |
| `test_tech_location_api.py` | 13 |
| `test_admin_resolve_dispute.py` | 4 |
| `test_consumer_tracking_subscribe.py` | 6 |
| `test_stream_dispatch.py` | 5 |
| (selector tests, conftest fixtures) | — |
| **Session 2 surface subtotal** | **~92** |
| `test_orchestrator.py` (Session 1 carryover, lightly extended) | 97 |

### 9.2 Fixtures in `tests/bookings/conftest.py`

- `fake_finance` — MagicMock-based stand-in for the FinancePort. All orchestrator tests inject it; the null adapter is exercised separately in `tests/bookings/services/test_finance_ports.py`.
- `captured_broadcasts` — patches `EventDispatchService.broadcast_event` so tests assert event_type + target_role + payload structure without a real channel layer.

### 9.3 Test gaps (per Pass 2 audit, deferred)

- No dual-role tests on Decline / Revision / CustomerCancel / Reschedule.
- No `django_assert_num_queries` anywhere in `tests/bookings/api/`.
- No file-upload security tests on `OpenDispute` (>5 MB rejected, but no MIME-type / path-injection / multi-file tests).
- No idempotency tests on Decline / Revision / NoShow.
- No terminal-state-guard tests on Transitions / Decline / Revision / NoShow / Dispute.

---

## §10 flag.md additions / interactions

The original spec called for opening 3 flags. State as of this summary:

| Flag | State | Notes |
|---|---|---|
| `geofence-strictness-config-tbd` | open | env-level only; per-tech / per-service config deferred. (flag #32) |
| `wallet-commission-deferred-to-finance-sprint` | open | Null adapter shape correct; real implementation = finance sprint. |
| `tech-location-rate-limit-not-distributed` | open (flag #33) | per-process throttle; multi-Daphne deployments allow N×4s effective rate. Redis-backed token-bucket is the proper fix. |

Pre-existing flags Session 2 work touches (no state change):
- #25 (customer-side `job_accepted`), #22 (rejection notify), #19 (envelope contract), #14/#20 (accept/decline) — all closed.
- #28 (AI chatbot dispute intake) — schema seam present, module deferred. The `OpenDispute` form is intake_method='FORM'; the chatbot path is intake_method='CHATBOT' + `chat_log` JSONField.
- #31 (admin realtime channel) — `tech_reliability_penalty` event deferred; the `TechReliabilityIncident` audit row is the source of truth for now.

Pass 2 audit findings are NOT yet logged as flags — they are tracked in this doc's §7.5. If Tier 2 isn't shipped before the next session boundary, the H1-new / H2-new / H5-new / H6-new / H7-new findings should be promoted to flag.md entries with the standard "where / what's wrong / why we shipped it / proper fix" schema.

---

## §11 What's actually committed vs uncommitted (the most important section)

```
On branch main
Your branch is ahead of 'origin/main' by 18 commits.

Changes not staged for commit:
  M  CLAUDE.md
  M  backend/bookings/admin.py
  M  backend/bookings/api/BOOKINGS_API.md
  M  backend/bookings/api/urls.py
  M  backend/bookings/services/orchestrator.py
  M  backend/core/settings.py
  M  backend/realtime/api/EVENT_DISPATCH_API.md
  M  backend/realtime/constants/groups.py
  M  backend/realtime/events/consumers.py
  M  backend/realtime/streams/dispatch.py
  M  backend/tests/bookings/services/test_orchestrator.py
  M  flag.md
  M  main.pdf

Untracked:
  ?? backend/.env.example
  ?? backend/bookings/api/booking_detail/
  ?? backend/bookings/api/completion/
  ?? backend/bookings/api/quotes/
  ?? backend/bookings/api/tech_location/
  ?? backend/bookings/api/terminations/
  ?? backend/bookings/api/transitions/
  ?? backend/bookings/selectors/orchestrator_ui.py
  ?? backend/bookings/selectors/transition_validator.py
  ?? backend/bookings/templates/
  ?? backend/dev_send_push.py
  ?? backend/realtime/api/STREAMS_TECH_GPS.md
  ?? backend/tests/bookings/api/test_admin_resolve_dispute.py
  ?? backend/tests/bookings/api/test_booking_detail_api.py
  ?? backend/tests/bookings/api/test_completion_api.py
  ?? backend/tests/bookings/api/test_quotes_api.py
  ?? backend/tests/bookings/api/test_tech_location_api.py
  ?? backend/tests/bookings/api/test_terminations_api.py
  ?? backend/tests/bookings/api/test_transitions_api.py
  ?? backend/tests/bookings/conftest.py
  ?? backend/tests/bookings/selectors/test_orchestrator_ui_selector.py
  ?? backend/tests/bookings/selectors/test_transition_validator_selector.py
  ?? backend/tests/realtime/test_consumer_tracking_subscribe.py
  ?? booking_orchestrator_sprint/
  ?? frontend/android/.kotlin/
  ?? session_1_wire_main_isolate.md
  ?? session_2_auth_bridge.md
  ?? session_3_android_native_and_finalize.md
  ?? session_4_customer_bookings_list_ui.md
  ?? Test_Cases.docx
```

**Action item before Session 3 starts:** stage and commit Session 2 as a single coherent commit (or a small chain). Suggested message structure:

```
feat(bookings): orchestrator HTTP/WS surface (sprint v1, session 2)

- 16 transition endpoints across 6 feature folders
- WS subscribe_tracking / unsubscribe_tracking + tracking_job_<id> subgroup
- tech_gps stream publisher
- Django Admin "Resolve dispute" custom action
- BOOKING_GEOFENCE_STRICT env toggle (default False)
- BOOKINGS_API.md / EVENT_DISPATCH_API.md / STREAMS_TECH_GPS.md
- Audit Pass 1 (C1, H1, H5) + Pass 2 (C2, C4-new, C5-new, H4)
- 826 passing tests; manage.py check clean; no new migrations
```

Do NOT commit `main.pdf` (binary), `Test_Cases.docx` (binary, may be sensitive), `frontend/android/.kotlin/` (build cache), or the four root-level `session_*.md` files unless they are intentional deliverables (they appear to be Flutter session notes, not part of this sprint).

---

## §12 What Session 3 inherits (preconditions for orchestrator screen)

Session 3 (`session_3_orchestrator_frontend_skeleton.md`) builds the Flutter `BookingOrchestratorScreen` skeleton + per-event notifiers + booking-detail provider hydration. It depends on:

1. **`GET /api/bookings/<id>/` returning the role-aware payload.** ✅ Implemented (in working tree).
2. **`available_transitions` reflecting orchestrator validity.** ✅ Implemented (test-asserted).
3. **All 5 new event types broadcast on the right transitions.** ✅ Implemented; broadcasts wired in orchestrator under `transaction.on_commit`.
4. **Wire codes from §3.1 stable for Flutter sealed-class mapping.** ✅ Stable; documented in `BOOKINGS_API.md`.
5. **Cache-Control suppressed on the detail GET.** ✅ Patched (Pass 1 / C1).

Frontend will need to handle:
- `not_a_customer` 403 / `not_a_technician` 403 → role-gated UI rebuild.
- `not_assigned_to_you` 400 → orchestrator-level IDOR (rare; surfaces if a booking gets reassigned mid-flow).
- `invalid_transition` 400 → state-machine race; trigger booking-detail re-fetch.
- `quote_not_found` 404 → quote was superseded; re-fetch.
- `booking_not_found` 404 → detail screen back-pop with toast.
- `too_many_requests` 429 (tech_location only) → tech-side foreground service backoff.

Session 4 (live tracking) depends on:
- WS `subscribe_tracking` upstream message path. ✅ Implemented.
- `tech_gps` stream payload shape (lat/lng/accuracy_meters/heading/booking_id). ✅ Implemented; documented in `STREAMS_TECH_GPS.md`.
- `tech_location` ingress 4-sec throttle behavior + 429 envelope. ✅ Implemented + tested.

---

## §13 Glossary of internal terms

| Term | Meaning |
|---|---|
| **Orchestrator** | `bookings/services/orchestrator.py` — the only writer of `JobBooking.status`. 14 public transition functions. Every view delegates here. |
| **FinancePort** | `bookings/services/finance_ports.py::FinancePort` Protocol. The orchestrator calls it for cash collection / commission / inspection-fee decisions. Production has `NullFinanceAdapter`; the real adapter lands in the finance sprint. |
| **Stream vs Event** | Streams = transient state values (GPS, balance display, typing) — no DB write, no FCM, no ACK. Events = facts that happened (job_accepted, payment_received) — DB-persisted via EventLog, FCM fallback when offline, ACK contract for `is_critical=True`. |
| **`tracking_job_<id>` subgroup** | Per-booking channel-layer group joined via WS `subscribe_tracking`. Receives `tech_gps` stream frames. |
| **`user_<id>_events` group** | Per-user channel-layer group joined on WS connect. Receives both events and per-user streams. The `_events` suffix is historical (predates streams support). |
| **`_reject_if_not_customer` helper** | View-layer customer-side IDOR gate (Pass 1 / H1). Pre-fetches booking by id, returns 404 if missing or 403 `not_a_customer` if mismatch. Replaces the broken `hasattr(tech_profile)` early-out which locked dual-role users out of customer-side actions on their own bookings. |
| **`final_cash_to_collect`** | Server-derived field on `JobBooking`. Set on quote-decision (approve = base − inspection fee; decline = inspection fee). The tech's cash button surfaces this exact figure. Pass 2 / C2 enforces strict equality at completion. |
| **`accepted_at`** | Timestamp on `JobBooking` set when tech accepts the AWAITING booking. Stop-gap — proper end-state is the AWAITING → CONFIRMED transition itself (flag #1, closed). |

---

*End of summary. Next session reads this first; the spec second.*
