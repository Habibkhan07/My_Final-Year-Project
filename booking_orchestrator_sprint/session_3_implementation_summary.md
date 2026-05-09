# Session 3 — Implementation Summary (state of the world)

> Companion to `session_3_orchestrator_frontend_skeleton.md` (the original spec). This document captures **what actually shipped vs. what the spec asked for**, the audit history (pre-impl + impl-time), every patch made, the full test inventory, and what Session 4 inherits. Written 2026-05-09 against the live working tree.
>
> **Read this before starting Session 4.** The spec describes intent; this describes reality. Companion to `session_2_implementation_summary.md` (which Session 3 inherits from).

---

## §0 TL;DR for future-me

1. **The orchestrator screen is real.** `frontend/lib/features/orchestrator/` is a complete Domain → Data → Presentation feature stack (52 source files; 17 test files). It mounts at `/booking/:job_id`, hydrates from `GET /api/bookings/<id>/`, renders a status-driven slot architecture (header / timeline / body / secondary actions / primary action), and reacts to 12 realtime events via two screen-scoped notifiers. **Closes flag #26** (the placeholder `CustomerBookingDetailScreen` is deleted; the route is renamed to `/booking/:job_id` audience-neutral).
2. **It is the audience-shared detail surface.** Both customer and technician land on the same screen — viewer role is derived in the data-layer mapper from `customer.id == currentUserId`. The server's role-aware `ui` block (sprint session 2) drives every label, button, and slot toggle. Frontend never branches on `status` for copy.
3. **Body widgets are stubs for sessions 4–6.** Each of the 14 `BookingStatus` values has a dedicated stub widget (e.g. `EnRouteBodyStub`, `QuotedBodyStub`). Today they render `booking.ui.bodyText` verbatim. Sessions 4 / 5 / 6 swap them for the live tracking map, quote builder + cash collection, and rich termination flows respectively. The exhaustive-switch contract — adding a new `BookingStatus` is a compile error here — is pinned by `body_slot_test.dart`.
4. **Three backend patches landed alongside the frontend.** `orchestrator_ui.py` had its endpoint strings stripped of the `/api/` prefix and the literal `<id>` placeholder substituted with the live `active_quote.id` (cycle-2 P0-01 + P1 fix). `booking_detail/views.py` started surfacing `child_booking_id` for the reschedule lineage. `booking_detail/serializers.py` got a purpose-built `_BookingItemResponseSerializer` (the BookingItem ≠ QuoteLineItem column-name divergence would have raised `AttributeError` at runtime).
5. **5 new event types + router rewiring.** `quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled` joined the `SystemEventType` enum (now 18 + unknown). `event_urgency.dart` maps all five to `lowUrgency`. `event_urgency_router.dart` was rewritten end-to-end so all orchestrator-relevant routes (high-urgency and low-urgency tap targets) converge on `/booking/:job_id`; `bookingRescheduled` uniquely targets `/booking/:child_booking_id`. `_resolveTemplatedPath` is now a generic `:<token>` substituter.
6. **Tests pin every cycle-1 + cycle-2 audit finding (23 total).** Phase C of the impl wrote ~130 frontend tests + 15 backend tests; the full suites pass with zero regressions (frontend `02:02 +967: All tests passed`; backend `874 passed in 12.15s`). The screen-level smoke test is the load-bearing one — if anyone reverts `ref.watch` → `ref.read` in `booking_orchestrator_screen.dart`, the events notifier auto-disposes and the realtime refresh chain dies silently. The smoke test catches that exact regression vector.
7. **Everything in this session is uncommitted.** The session 2 surface is also still uncommitted (per `session_2_implementation_summary.md` §11). Together they form one large coherent change to be staged + committed in a single feature-branch flow.
8. **No new flags were opened.** flag #26 closed in lockstep with this session (see flag.md). No flag.md additions were warranted — the deferred work (rich body widgets in sessions 4–6, real cash collection sheet, dispute multipart upload) is sprint-internal scope, not "shortcut shipped now, fix later."

---

## §1 What Session 3 was supposed to deliver (per spec)

Source: `booking_orchestrator_sprint/session_3_orchestrator_frontend_skeleton.md` (1924 lines, post-cycle-2 patches).

The Flutter feature that fronts the orchestrator HTTP/WS surface:

- **Domain layer**: a top-level `BookingDetail` entity + 8 nested entities, sealed `BookingDetailFailure` hierarchy, repository interface, single-purpose use case.
- **Data layer**: freezed DTOs mirroring the wire shape (booking_detail, booking_quote, booking_item, booking_ui_block, plus the per-event payloads), DTO → domain mapper, event payload extractor, http remote data source, SharedPreferences local data source, offline-first repository implementation.
- **Presentation layer**: per-feature DI, an `AsyncNotifier` that hydrates from `GET /api/bookings/<id>/`, two screen-scoped event notifiers (one for refresh-trigger events, one for the reschedule nav side-effect), an action-dispatch executor, the screen + 5 slot widgets, 14 stub body widgets, a placeholder pending-action sheet for sessions 5/6 modals.
- **Realtime touch-ups**: 5 new `SystemEventType` enum cases, 5 new `EventUrgency` mappings, comprehensive `EventUrgencyRouter` rewiring so booking events all converge on `/booking/:job_id`.
- **Routing**: GoRoute for `/booking/:job_id` (named `booking_orchestrator`), invalid-link surface for malformed deep-links, removal of the placeholder route.
- **Bookings list lockstep**: list-side patch mappers for the 5 new events so the customer's My Bookings list updates in lockstep with the orchestrator state, plus the list notifier's event switch extension.
- **Backend Phase A**: three small backend tweaks required for the frontend to function (URL prefix drop, child_booking_id forward-pointer, BookingItem serializer split).
- **Tests**: comprehensive coverage of every audit finding, every drift seam, every backwards-compat default, the Riverpod `ref.watch` contract, and the full domain → data → presentation pipeline.

---

## §2 What's actually in the working tree (file inventory)

### 2.1 New frontend feature folder (untracked) — `frontend/lib/features/orchestrator/`

```
domain/
├── entities/
│   ├── booking_detail.dart                       (+ .freezed.dart)
│   ├── booking_orchestrator_role.dart            — enum: customer | technician
│   ├── booking_quote.dart                        (+ .freezed.dart)  Quote + LineItem + Status enum
│   ├── booking_item.dart                         (+ .freezed.dart)  Snapshot of accepted line
│   ├── booking_ui_block.dart                     (+ .freezed.dart)  ui.* + action + style enum
│   ├── booking_phase_timestamps.dart             (+ .freezed.dart)  7 nullable lifecycle anchors
│   ├── booking_pricing.dart                      (+ .freezed.dart)  Rupees-as-int snapshot
│   └── booking_cash_collection.dart              (+ .freezed.dart)
├── failures/
│   └── booking_detail_failure.dart               — sealed: NotFound, NotParticipant, OfflineNoCache, NetworkFailure, ServerFailure, Unknown
├── repositories/
│   └── booking_detail_repository.dart            — IBookingDetailRepository.getBookingDetail(int)
└── use_cases/
    └── get_booking_detail_use_case.dart          — thin wrapper

data/
├── models/                                       — freezed + json_serializable
│   ├── booking_detail_model.dart                 (+ .freezed.dart, .g.dart)
│   ├── booking_quote_model.dart                  (+ .freezed.dart, .g.dart)
│   ├── booking_item_model.dart                   (+ .freezed.dart, .g.dart)
│   ├── booking_ui_block_model.dart               (+ .freezed.dart, .g.dart)
│   └── booking_event_payloads.dart               (+ .freezed.dart, .g.dart)
│       — JobIdPayload, QuoteGeneratedPayload, BookingRescheduledPayload
├── mappers/
│   ├── booking_detail_mapper.dart                — DTO → domain; viewer-role derivation; Decimal-string → int rupees
│   └── booking_event_payload_mapper.dart         — extractJobId, extractChildBookingId
├── datasources/
│   ├── booking_detail_remote_data_source.dart    — package:http; baseUrl + /bookings/<id>/
│   └── booking_detail_local_data_source.dart     — SharedPrefs; key prefix orchestrator_booking_detail_v1_
└── repositories/
    └── booking_detail_repository_impl.dart       — offline-first: remote → cache → local fallback

presentation/
├── providers/
│   ├── dependency_injection.dart                 (+ .g.dart)  per-feature secure storage + repo wiring
│   ├── booking_detail_provider.dart              (+ .g.dart)  AsyncNotifier family<int>; keepAlive: false
│   ├── booking_orchestrator_events_notifier.dart (+ .g.dart)  family<int>; 12-event filter + invalidate
│   ├── booking_rescheduled_notifier.dart         (+ .g.dart)  family<int>; pushReplacement on match
│   └── booking_action_executor.dart              (+ .g.dart)  HTTP dispatch (POST/GET/PATCH/PUT/DELETE)
├── screens/
│   └── booking_orchestrator_screen.dart          — Scaffold + AppBar + when(loading/error/data)
└── widgets/
    ├── booking_orchestrator_action_button.dart   — endpoint-suffix classifier + busy state
    ├── sheets/
    │   └── booking_action_pending_sheet.dart     — placeholder for session 5/6 modals
    ├── slots/
    │   ├── header_slot.dart                      — tone-tinted: status + counterparty + lineage callouts
    │   ├── timeline_slot.dart                    — 5-dot phase progression
    │   ├── body_slot.dart                        — exhaustive switch on BookingStatus → stub class
    │   ├── secondary_actions_slot.dart           — Wrap of text buttons + dispute toggle
    │   └── primary_action_slot.dart              — full-width FilledButton
    └── stub_bodies/
        └── all_status_stubs.dart                 — 14 stub widgets (one per status)
```

Plus `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` — the canonical feature doc (updated 2026-05-09 to reflect Tests ✅).

### 2.2 Modified frontend files (unstaged)

| File | Why it changed |
|---|---|
| `lib/core/realtime/domain/entities/system_event_type.dart` | +5 enum cases (`quoteRevisionRequested`, `quoteDeclined`, `bookingCancelled`, `bookingNoShow`, `bookingRescheduled`) + matching `_lookup` entries. |
| `lib/core/realtime/domain/entities/event_urgency.dart` | All 5 new types mapped to `lowUrgency`. None critical. |
| `lib/core/realtime/presentation/router/event_urgency_router.dart` | All orchestrator-relevant routes converge on `/booking/:job_id`; nav-guard switched to `'job_id'`; `_resolveTemplatedPath` generic; `bookingRescheduled` uniquely uses `:child_booking_id`. Banner copy + icons + titles for all 5 new types. |
| `lib/core/routing/app_router.dart` | New `/booking/:job_id` GoRoute (`name: 'booking_orchestrator'`); `_InvalidBookingLinkScreen` for malformed deep-links; old `/customer/booking/:job_id` route removed. |
| `lib/features/customer/bookings/domain/entities/booking_status.dart` | +8 lifecycle enum values (`enRoute`, `arrived`, `inspecting`, `quoted`, `inProgress`, `completedInspectionOnly`, `noShow`, `disputed`); wire-lookup table extended in lockstep with backend `JobBooking.STATUS_*`. |
| `lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` | +5 static patch methods (`applyBookingCancelled`, `applyBookingNoShow`, `applyQuoteDeclined`, `applyJobCompleted`, `applyBookingRescheduled`). |
| `lib/features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart` | Event switch extended for the 5 new types; `bookingRescheduled` additionally fires `refresh()` so the child booking shows up on Upcoming. |
| `lib/features/customer/bookings/presentation/widgets/booking_card.dart` | Tap → `/booking/<id>` (audience-neutral). |
| `lib/features/customer/bookings/CUSTOMER_BOOKINGS_FEATURE.md` | Updated header to reference `lib/features/orchestrator/` for the detail screen. |
| `lib/features/technician/incoming_job_requests/INCOMING_JOB_REQUESTS_FEATURE.md` | Updated "Known limitations" to reference orchestrator screen and `bookingOrchestratorEventsNotifier`. |
| `lib/core/realtime/REALTIME_EVENTS_FEATURE.md` | §3 enum count bumped from 12 → 18 with a parenthetical naming the 5 new types. |
| `frontend/test/core/realtime/presentation/router/event_urgency_router_test.dart` | Extended with banner copy + tap-target substitution tests for the 5 new events. |
| `frontend/test/features/customer/bookings/presentation/widgets/booking_card_test.dart` | Tap path is `/booking/<id>` not `/customer/booking/<id>`. |

### 2.3 DELETED frontend file

| File | Why |
|---|---|
| `lib/features/customer/bookings/presentation/screens/customer_booking_detail_screen.dart` | Pre-orchestrator placeholder (`/customer/booking/:job_id` route's screen). The orchestrator screen at `/booking/:job_id` replaces it audience-neutrally. flag #26 close. |

### 2.4 Modified backend files (unstaged) — Phase A patches

| File | Why it changed |
|---|---|
| `backend/bookings/selectors/orchestrator_ui.py` | Endpoint strings stripped of `/api/` prefix; live `active_quote.id` substituted for `<id>` placeholder in customer-quoted action endpoints; defensive `None` branch in `_customer_quoted` for missing active quote. |
| `backend/bookings/api/booking_detail/views.py` | Added `child_booking_id` lookup (most-recent child via `child_bookings` related_name) to the response payload. |
| `backend/bookings/api/booking_detail/serializers.py` | New `_BookingItemResponseSerializer` (split from `QuoteLineItemResponseSerializer` because `BookingItem.price_charged` ≠ `QuoteLineItem.priced_at`); added `child_booking_id` field to the response. |
| `backend/tests/bookings/api/test_booking_detail_api.py` | +3 tests: profile-picture absolute URL when present + null when absent + `show_dispute_button` matrix across 13 statuses. |
| `backend/tests/bookings/selectors/test_orchestrator_ui_selector.py` | +12 tests on the URL-prefix invariants, `<id>` substitution, and the `_customer_quoted` defensive None branch. |
| `backend/bookings/api/BOOKINGS_API.md` | §8.1 — added `child_booking_id` to sample response, dropped `/api/` prefix from sample endpoint string, added URL convention prose, added BookingItem field semantics table. |

### 2.5 New frontend test directories (untracked)

```
frontend/test/features/orchestrator/                   (17 test files)
├── _helpers/
│   └── booking_detail_fixture.dart                    — shared bookingDetailJson({...}) factory
├── data/
│   ├── mappers/
│   │   ├── booking_detail_mapper_test.dart           — 9 tests
│   │   └── booking_event_payload_mapper_test.dart    — 11 tests
│   ├── datasources/
│   │   ├── booking_detail_remote_data_source_test.dart  — 7 tests
│   │   └── booking_detail_local_data_source_test.dart   — 8 tests
│   └── repositories/
│       └── booking_detail_repository_impl_test.dart  — 12 tests
└── presentation/
    ├── providers/
    │   ├── dependency_injection_test.dart            — 2 tests
    │   ├── booking_action_executor_test.dart         — 6 tests
    │   ├── booking_orchestrator_events_notifier_test.dart  — 5 tests
    │   └── booking_rescheduled_notifier_test.dart    — 5 tests
    ├── screens/
    │   └── booking_orchestrator_screen_test.dart     — 3 tests (smoke + ref.watch contract)
    └── widgets/
        ├── booking_orchestrator_action_button_test.dart  — 8 tests
        ├── sheets/
        │   └── booking_action_pending_sheet_test.dart    — 5 tests
        └── slots/
            ├── header_slot_test.dart                 — 7 tests
            ├── timeline_slot_test.dart               — 16 tests
            ├── body_slot_test.dart                   — 15 tests
            ├── secondary_actions_slot_test.dart      — 4 tests
            └── primary_action_slot_test.dart         — 3 tests

frontend/test/core/routing/                            (1 new test file)
└── app_router_test.dart                              — 4 tests (invalid-link surface + valid id)
```

**Total session-3 frontend test functions: ~130** (excluding the helper file). Plus extended coverage in `event_urgency_router_test.dart` and `booking_card_test.dart`.

### 2.6 New docs (untracked)

| File | Purpose |
|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | Canonical feature doc (Tests row updated to ✅; cross-feature changes section added; Backend Phase A section added; Tests section added). |
| `booking_orchestrator_sprint/session_3_implementation_summary.md` | This file. |

---

## §3 Backend Phase A — three patches

The orchestrator screen depends on three backend behaviors that did not exist in the session-2 surface as committed. These are small, contained, and live in the same uncommitted working tree as the frontend feature. Together they are < 100 lines of source change but each has a non-obvious "why this had to land" story.

### 3.1 `orchestrator_ui.py` — URL convention drop + live quote id

**File**: `backend/bookings/selectors/orchestrator_ui.py`. Modified +46 lines (per `git diff --stat`).

**Before**: every `endpoint=` string in the UI block emitter was `f"/api/bookings/{booking.id}/{verb}/"`. Customer-facing quote-action endpoints used a literal `<id>` placeholder for the quote id (e.g. `f"/api/bookings/{booking.id}/quotes/<id>/approve/"`).

**After**:

```python
# At file top — convention prose:
# Endpoint convention (sprint §24): action ``endpoint`` strings are
# relative paths starting at ``/bookings/...``. The frontend prepends
# ``AppConstants.baseUrl`` (already includes the ``/api`` prefix) before
# dispatching, so embedding ``/api/`` here would produce ``/api/api/...``.
```

- All 12 `endpoint=` strings dropped the leading `/api/`. Verified via grep — zero `/api/bookings/` strings remain in the file.
- `_customer_quoted` imports `get_active_quote` from `bookings.selectors.quote_selector` and substitutes the live `active_quote.id` for the previous `<id>` placeholder in the 3 customer-facing quote endpoints (`approve`, `decline`, `request-revision`).
- `_customer_quoted` gained a defensive `None`-branch:

```python
active_quote = get_active_quote(booking)
if active_quote is None:
    return {
        "status_label": "Quote ready",
        "body_text": "Quote details are unavailable. Refresh in a moment.",
        "primary_action": None,
        "secondary_actions": [_customer_cancel_action(booking, "Cancel")],
        "show_tracking": False,
        "show_quote_card": True,
        "show_dispute_button": False,
        "tone": "warning",
    }
```

**Why this had to land**: cycle-2 P0-01 (the largest blast-radius bug in either audit cycle). `AppConstants.baseUrl` already includes `/api`. Without this drop, every booking-action endpoint URL would render as `http://host/api/api/bookings/...` and 404. The frontend tests would never have caught it because the test http mocks accept any URL — only an integration test against the real Django would surface it.

**Why the live quote id**: the `<id>` literal was a session-2 artifact from when `orchestrator_ui` predated the quote selector wire-up. Pre-fix the wire format was `/bookings/123/quotes/<id>/approve/`; the Flutter executor would have POSTed the literal `<id>` to Django which would 404 on the URL resolver. The fix substitutes the live `active_quote.id` at the moment the UI block is composed.

**Why the defensive None branch**: the orchestrator's submit-quote contract guarantees `get_active_quote` returns a row in the QUOTED state. But a corrupt-row race or a future API change could violate that. Returning the degraded body with `tone: warning` and no actions is strictly safer than a 500.

**Tests**: `tests/bookings/selectors/test_orchestrator_ui_selector.py` got +12 invariant tests asserting (a) no endpoint starts with `/api/`, (b) no endpoint contains literal `<id>`, (c) customer-quoted endpoints interpolate the actual quote id, (d) the defensive None branch produces the warning-tone body.

### 3.2 `booking_detail/views.py` — reschedule lineage forward-pointer

**File**: `backend/bookings/api/booking_detail/views.py`. Modified +11 lines.

**Before**: `BookingDetailView.get` returned `parent_booking_id` (reverse pointer — set on the child of a reschedule) but had no way to navigate **forward** from the cancelled original to the child.

**After**: the view now reads the most-recent child via the `child_bookings` related_name and surfaces `child_booking_id` on the response payload:

```python
# Reschedule-chain forward pointer (audit cycle 2 #B1). When this
# booking is the CANCELLED original, surface the child's id so the
# orchestrator UI can offer a "Continued on #N" link — otherwise a
# user who returns to the original (e.g. via a stale FCM tap) is
# stranded. Most-recent child wins to tolerate chains > 1.
child = (
    booking.child_bookings.order_by('-id').only('id').first()
)
child_booking_id = child.id if child is not None else None
```

The frontend `HeaderSlot` reads `booking.childBookingId` and renders a "Continued on #N" link only when `status == CANCELLED && childBookingId != null`. Tap navigates via `GoRouter.push('/booking/<child>')`.

**Why this had to land**: a reschedule creates a new booking row (the child) and cancels the original. A customer who returns to the cancelled original (typically via a stale FCM tap on a `bookingRescheduled` banner that landed before the in-app `bookingRescheduledNotifier` could redirect) would be stranded with no navigation back to the live booking. This forward pointer makes the recovery path obvious.

**Why most-recent child wins**: the proper-fix from the original audit was "tolerate the (theoretical) case of a chain longer than one." Today the orchestrator's `reschedule` transition produces a single child per parent, but a future "reschedule-the-reschedule" flow is plausible. Picking the most recent child is forward-compatible.

**Tests**: pinned by `test_booking_detail_api.py::test_child_booking_id_set_when_reschedule_chain_exists` and the matching `child_booking_id` field assertion in `booking_detail_mapper_test.dart`.

### 3.3 `booking_detail/serializers.py` — BookingItem ≠ QuoteLineItem

**File**: `backend/bookings/api/booking_detail/serializers.py`. Modified +36 lines.

**Before**: `BookingDetailResponseSerializer` reused `QuoteLineItemResponseSerializer` for the `booking_items` field.

**After**: a new purpose-built `_BookingItemResponseSerializer`:

```python
class _BookingItemResponseSerializer(serializers.Serializer):
    """Wire shape for an accepted ``BookingItem`` row.

    Distinct from ``QuoteLineItemResponseSerializer`` even though the two
    look almost identical: the field names diverge (``BookingItem`` has
    ``price_charged``; ``QuoteLineItem`` has ``priced_at``) and only this
    one carries ``sourced_quote_id``. Reusing the quote-line serializer
    here would raise ``AttributeError: 'BookingItem' object has no
    attribute 'priced_at'`` at runtime — silently undetected because no
    booking-detail test fixture currently includes a BookingItem row.
    """
    id = serializers.IntegerField()
    sub_service_id = serializers.IntegerField()
    sub_service_name = serializers.CharField(source="sub_service.name")
    quantity = serializers.IntegerField()
    price_charged = serializers.DecimalField(max_digits=10, decimal_places=2)
    line_total = serializers.DecimalField(max_digits=10, decimal_places=2)
    sourced_quote_id = serializers.IntegerField(allow_null=True)
```

`BookingDetailResponseSerializer.to_representation` now uses `_BookingItemResponseSerializer` for the `booking_items` field. The frontend's `BookingItemModel` consumes this exact shape.

**Why this had to land**: the divergence was caught at audit time, not at runtime, because no test fixture in the session-2 suite included a BookingItem row in the booking_items field. Reuse of `QuoteLineItemResponseSerializer` would have raised `AttributeError` on the first real production booking that had an approved quote. Bug found in code review, never reached green-path tests.

**Why the column names diverge**: `QuoteLineItem.priced_at` is the price quoted at submission time. `BookingItem.price_charged` is the price locked at approval (post-revision). They are the same number for a single-revision quote but diverge if the technician edits the quote and the customer approves a later revision. The two fields are semantically distinct (one is "what the tech proposed"; the other is "what was agreed"); reusing the same serializer would have hidden the distinction.

**Why this serializer exists in `booking_detail/serializers.py` (not in a shared location)**: only the booking-detail endpoint emits `BookingItem` rows. If a future endpoint also needs them (the admin reliability dashboard, e.g.), promote this to `bookings/api/_shared/serializers.py` at that time.

---

## §4 Frontend Domain layer

This section is intentionally brief — the canonical feature documentation is `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` "Domain Layer". This summary covers only the non-obvious decisions.

### 4.1 Why `BookingStatus` lives in `customer/bookings/`

The orchestrator feature reuses `customer/bookings/domain/entities/booking_status.dart` rather than defining its own. Two reasons:

1. The bookings list and the orchestrator screen MUST share the enum — list rows render the new statuses (via the `ui` block from server) and the orchestrator screen's body slot switches on the same enum. Defining the enum twice would mean the wire-string lookup table is duplicated, and a new backend status would silently fall to `unknown` on whichever side wasn't updated.
2. CLAUDE.md's "no cross-feature import" convention is real but not absolute. Cross-feature imports are acceptable when the imported symbol is **wire-shape contract**, not feature behavior. `BookingStatus` is the wire enum — it's not "the customer's bookings feature owns this"; it's "this is the contract with the backend." Same justification used for `BookingUiTone` (also imported from `customer/bookings`).

A future cleanup might promote `BookingStatus` to `lib/core/domain/booking/booking_status.dart` to make the cross-feature dependency explicit. Not done this session — the scope creep would have invalidated the existing `customer/bookings` test surface.

### 4.2 Why `viewerRole` is derived in the data-layer mapper

The mapper computes `viewerRole = customer.id == currentUserId ? customer : technician` from the wire payload + the auth user id. The else-branch is always `technician` because the server's 403 `not_a_participant` gate runs before the response is composed — by the time the frontend receives a 200, the auth user is guaranteed to be either the customer or the assigned tech.

This single-pass derivation in the mapper means the screen never has to ask "who am I"; the entity already knows.

### 4.3 Sealed failure hierarchy

The 6 sealed subtypes:

```
BookingDetailFailure
  ├── BookingDetailNotFound(int bookingId)        — 404
  ├── BookingDetailNotParticipant                  — 403 not_a_participant
  ├── BookingDetailOfflineNoCache                  — SocketException + no cache
  ├── BookingDetailNetworkFailure                  — generic transport error
  ├── BookingDetailServerFailure                   — 5xx
  └── UnknownBookingDetailFailure(String message)  — catch-all
```

The screen's `error.when(...)` pattern matches on these sealed types — never on the raw `HttpFailure.code` (which would put wire-code knowledge in the UI). The exhaustiveness check fires if a new failure type is added without updating the screen.

The repository's mapping logic:

| Wire | Typed |
|---|---|
| 404 | `BookingDetailNotFound(bookingId)` |
| 403 with code `not_a_participant` | `BookingDetailNotParticipant` |
| 5xx (500, 502, 503, 504) | `BookingDetailServerFailure` |
| anything else with a `code` | `UnknownBookingDetailFailure(message)` |
| `SocketException` + cache hit | returns cached entity silently |
| `SocketException` + no cache | `BookingDetailOfflineNoCache` |

---

## §5 Frontend Data layer

### 5.1 DTO shape — Decimal-as-string preserved on the wire

Every monetary field on the wire is a Decimal-encoded string (e.g. `"500.00"`). The DTOs preserve this — `inspection_fee` is `String`, not `double`. The mapper does the single coercion to `int` rupees (`num.parse(s).toInt()` — `int.parse("500.00")` would throw because `"500.00"` is not a valid int literal).

**Why preserve as string on the DTO**: keeping the wire shape lossless in the DTO means a future migration to a different domain numeric type (BigDecimal? Rational?) only touches the mapper, not the JSON parsing.

### 5.2 Local data source — versioned cache key

The local data source's cache key prefix is `orchestrator_booking_detail_v1_<id>`. The `_v1_` segment is bumped when the response shape changes (a new field that the entity requires non-null, an enum case migration, etc.) — old cache rows from `_v0_` are simply ignored, so a cached entity from a pre-migration version never deserializes incorrectly into the new entity.

### 5.3 Repository — offline-first contract

```
getBookingDetail(bookingId):
  try:
    response = remote.fetch(bookingId)
    cache.write(bookingId, response).ignore()    # best-effort
    return mapper.toDomain(response)
  on HttpFailure(code):
    throw _mapHttpFailure(code, message)
  on SocketException:
    cached = cache.read(bookingId)
    if cached:
      try: return mapper.toDomain(cached)
      on mapper-error: cache.evict(bookingId); throw OfflineNoCache
    throw OfflineNoCache
```

The "mapper-error → evict" branch is the load-bearing one for the cache versioning above. If the cache schema changes (the `_v1_` prefix is bumped) but a stale row still has the `_v0_` prefix in some user's SharedPreferences, the mapper will throw on the deserialization, the cache evicts, and the user sees `OfflineNoCache` instead of a corrupted entity. Pinned by `booking_detail_repository_impl_test.dart::evict_on_mapper_error_*`.

### 5.4 Event payload extractor — defensive job_id parsing

`BookingEventPayloadMapper.extractJobId(event)` accepts:
- `int` directly
- `num` (any numeric — `.toInt()`)
- `String` (parsed via `int.tryParse(...)`)
- and returns `null` for anything else (`bool`, `List`, missing, malformed string).

This forgiving shape is necessary because the wire format documents `job_id` as integer but defensive code is cheap and the alternative (throwing on a malformed event) would let a single bad event from the backend break the entire realtime refresh chain.

`extractChildBookingId` has an additional early-out: it returns `null` if the event type is not `bookingRescheduled`. This guards against a future event type accidentally carrying a `child_booking_id` payload field — the rescheduled notifier should only fire on the dedicated event type.

---

## §6 Frontend Presentation layer

### 6.1 The notifier tree

| Provider | Class | Family | keepAlive | Purpose |
|---|---|---|---|---|
| `bookingDetailProvider(jobId)` | `BookingDetailNotifier` | `<int>` | false | AsyncNotifier hydrating from `GET /api/bookings/<id>/`. Disposed on screen pop; next mount re-fetches. |
| `bookingOrchestratorEventsProvider(jobId)` | `BookingOrchestratorEventsNotifier` | `<int>` | false | Multi-event `ref.listen(systemEventProvider)`. 12 trigger events × matching `payload.job_id` → `ref.invalidate(bookingDetailProvider(jobId))`. |
| `bookingRescheduledProvider(jobId)` | `BookingRescheduledNotifier` | `<int>` | false | Standalone listener for `bookingRescheduled` (nav side effect: `pushReplacement('/booking/<child>')`). |
| `bookingActionExecutorProvider` | `BookingActionExecutor` | — | true | HTTP dispatch for server-emitted `BookingUiAction` (handles GET/POST/PATCH/PUT/DELETE; supports optional body). |

**Why three notifiers and not one**: separation of concerns. `bookingDetailProvider` owns the data fetch. `bookingOrchestratorEventsProvider` owns the refresh-on-event policy (for 12 of the 13 events that affect this booking, just re-fetch). `bookingRescheduledProvider` owns the unique nav side-effect for the one event that re-routes to a different booking. Splitting them means each is small, single-purpose, and easy to test in isolation. Combining them would have produced a single 200-line notifier doing three jobs.

**Why `keepAlive: false`**: each notifier is screen-scoped — when the screen pops, all three should dispose. `keepAlive: true` would leak listeners and prevent garbage collection of disposed bookings. The screen wakes them via `ref.watch(...)` in its `build` — see §6.4.

### 6.2 The 12 refresh-trigger events

`BookingOrchestratorEventsNotifier` filters `systemEventProvider` for these 12 types:

```
techEnRoute, techArrived, quoteGenerated, quoteApproved,
quoteRevisionRequested, quoteDeclined, jobCompleted, paymentReceived,
disputeOpened, disputeResolved, bookingCancelled, bookingNoShow
```

Plus a `payload.job_id == this.jobId` match. On match → `ref.invalidate(bookingDetailProvider(jobId))`. The Riverpod 3 contract preserves the prior value during the rebuild and exposes `isLoading` while the future runs — so the screen renders a thin `LinearProgressIndicator` at the top of the body, never a spinner-flash.

`bookingRescheduled` is **deliberately NOT** in this set. The reschedule isn't a refresh — it's a navigation. The original booking goes to CANCELLED (a state that can be observed by re-fetching) but the user shouldn't stay on the cancelled original; they should be moved to the child. `BookingRescheduledNotifier` owns that side-effect.

### 6.3 `BookingActionExecutor` — the single HTTP dispatcher

The screen's secondary actions, primary action, and tap-from-dispute-button all funnel through one executor. Methods:

- `execute(action, {body})` — primary entry point. Switches on `action.method` (POST/GET/PATCH/PUT/DELETE).
- DELETE has a critical guard: **never** sends a body. Pinned by `booking_action_executor_test.dart::DELETE_without_body` using `verifyNever(client.delete(any(), headers: any(named:'headers'), body: any(named:'body')))`. Some HTTP servers (notably Django's CSRF middleware on dev) reject DELETE with body; some clients silently strip it; the safe contract is "DELETE never has a body." The frontend enforces this even if the backend's `endpoint` string accidentally matched a DELETE-with-body verb.
- POST/PATCH/PUT support optional `body`. When `body != null`, `Content-Type: application/json` is set; the body is `jsonEncode`d.
- All requests carry `Authorization: Token <auth-token>` from the per-feature secure storage.
- Non-2xx → `HttpFailure` from the standard envelope. Non-JSON bodies fall through to a generic `HttpFailure(code: 'unknown_server_error', message: <truncated body>)`.
- Unsupported method → `StateError("BookingActionExecutor: unsupported method '<m>'")`.

### 6.4 The screen's `ref.watch` contract — the most fragile seam in the feature

The screen's `build` MUST `ref.watch` (not `ref.read`) the two screen-scoped event notifiers:

```dart
ref.watch(bookingOrchestratorEventsProvider(widget.jobId));
ref.watch(bookingRescheduledProvider(widget.jobId));
```

Both providers are `keepAlive: false`. A `ref.read` (or an `initState` + `ref.read`) would NOT register a Riverpod subscription. The provider would be constructed (its `build` would run, the `ref.listen(systemEventProvider, ...)` inside would be set up), but with no subscriber it would auto-dispose on the next microtask — canceling the listen, breaking the realtime refresh chain, AND it would all happen silently because the construction succeeded.

**This is the load-bearing regression vector for sessions 4–6.** A well-meaning refactor that "tidies up" the screen by moving `ref.watch` to `ref.read` would compile, would run, and would silently break the entire realtime refresh story — but only on a real device, only for the specific window between two events arriving for the same booking. Untestable in isolation; only the screen-level smoke test catches it.

The smoke test (`booking_orchestrator_screen_test.dart::screen_ref_watch_keeps_event_notifier_alive_refresh_fires`) mounts the screen, observes `_CountingRepo.callCount == 1` (initial fetch), pushes a `tech_en_route` event via the fake `systemEventProvider`, and asserts `callCount == 2`. If the events notifier auto-disposed (the regressed pattern), no second call would fire. The test reason explicitly says "events notifier must be alive — it should have triggered a refresh", so a future engineer who breaks this contract sees a clear, actionable failure.

### 6.5 Slot architecture — one switch in the entire feature

`BodySlot.build` is the **only** place in the feature that switches on `BookingStatus`:

```dart
switch (booking.status) {
  case BookingStatus.awaiting:    return AwaitingBodyStub(booking: booking);
  case BookingStatus.confirmed:   return ConfirmedBodyStub(booking: booking);
  case BookingStatus.enRoute:     return EnRouteBodyStub(booking: booking);
  // ... 11 more arms
  case BookingStatus.pending:     return UnknownBodyStub(booking: booking);
  case BookingStatus.unknown:     return UnknownBodyStub(booking: booking);
}
```

Dart 3 patterns enforce exhaustiveness — adding a new `BookingStatus` enum value is a compile error here. The runtime mapping (each existing status → its dedicated stub class) is pinned by `body_slot_test.dart::status_x_stub_matrix` (15 cases). Catches typos that would compile but be wrong (e.g. `arrived → quoted`).

Sessions 4–6 will replace specific stubs with rich widgets (live tracking map for EN_ROUTE / ARRIVED, quote builder + approval sheet for INSPECTING / QUOTED, cash collection sheet for IN_PROGRESS, etc.). The switch stays put; only the body classes change.

### 6.6 Action button — endpoint suffix classification

`BookingOrchestratorActionButton._classify(endpoint)` parses the endpoint string and returns one of three behaviors:

| Endpoint suffix | Behavior | Auto-body |
|---|---|---|
| `/en-route/`, `/arrived/`, `/start-inspection/`, `/quotes/<id>/approve/`, `/quotes/<id>/decline/` | Direct POST | none |
| `/confirm-cash-received/` | Direct POST | `{cash_amount: pricing.finalCashToCollect}` |
| `/cancel/`, `/tech-cancel/`, `/no-show/` | Pending sheet → POST default reason | reason payload |
| `/reschedule/`, `/disputes/`, `/quotes/`, `/quotes/<id>/request-revision/` | Pending sheet (placeholder for sessions 5/6) | — |

The classifier is intentionally a string-matching switch and not a polymorphic dispatcher because the `endpoint` string is the contract — the backend is free to add a new verb at any time, and the classifier should fail soft (default to "show pending sheet, do nothing") rather than crash on an unrecognized suffix. The frontend's job is to render what the server told it to; the classifier is just a UX hint for the local interaction model.

### 6.7 Stub bodies — `developer.log` on the unknown path

`UnknownBodyStub` logs a warn-level `developer.log` when `booking.status == BookingStatus.pending`. Legacy pre-orchestrator-era rows shouldn't surface in v1 (migration 0007 removed the only persistence path for PENDING), but if one does, the log helps spot rollout-window regressions during dogfooding.

The log uses namespace `'features.orchestrator.unknown_body'` (per the `core.presentation.*` convention noted in cycle-2 P3-04, which was deferred for the planned cleanup pass).

---

## §7 Realtime integration

### 7.1 Five new event types

Added to `core/realtime/domain/entities/system_event_type.dart` enum + `_lookup` map:

| Wire string | Enum case | Urgency | Banner title | Tap target |
|---|---|---|---|---|
| `quote_revision_requested` | `quoteRevisionRequested` | `lowUrgency` | "Customer wants to bargain" | `/booking/:job_id` |
| `quote_declined` | `quoteDeclined` | `lowUrgency` | "Quote declined" | `/booking/:job_id` |
| `booking_cancelled` | `bookingCancelled` | `lowUrgency` | "Booking cancelled" | `/booking/:job_id` |
| `booking_no_show` | `bookingNoShow` | `lowUrgency` | "No-show reported" | `/booking/:job_id` |
| `booking_rescheduled` | `bookingRescheduled` | `lowUrgency` | "Booking rescheduled" | `/booking/:child_booking_id` |

None are critical (no ACK contract). Backend `EVENT_REGISTRY` (session 2) and frontend `event_criticality.dart` agree.

### 7.2 Banner body discriminators

| Event | Body copy |
|---|---|
| `quoteRevisionRequested` | "Customer is asking to revise the quote — tap to view." |
| `quoteDeclined` | "Customer declined the quote — tap to view." |
| `bookingCancelled` | Discriminated by `targetRole`: customer sees "Your technician cancelled — tap to view."; technician sees "The customer cancelled — tap to view." Generic "this booking was cancelled" reads as self-blame; the role-aware copy is more direct. |
| `bookingNoShow` | Discriminated by `payload.actor` + `targetRole`: "Customer did not show" (when actor is customer and recipient is tech), "Your technician did not show" (when actor is tech and recipient is customer). Backend fans the event only to the non-actor side, so we can phrase from the recipient's perspective without ambiguity. |
| `bookingRescheduled` | "Rescheduled — tap to open the new booking." |

All defensive — a missing or unknown payload field falls through to a generic copy, never crashes. Pinned by `event_urgency_router_test.dart`'s extended cases.

### 7.3 Router rewiring — `/booking/:job_id` as the universal sink

Pre-session-3 the high-urgency events targeted entity-specific routes (`/customer/quote/:quote_id`, `/customer/dispute/:dispute_id`, etc.) — except those routes never existed in `app_router.dart`, so every high-urgency event silently no-op'd at the router layer. The session 3 rewiring repoints all of them to the single orchestrator screen at `/booking/:job_id` (the screen adapts its body to the booking's status, so one route absorbs `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved` — the entity-id is `:job_id`, not `:quote_id` / `:dispute_id`).

Low-urgency tap targets converged similarly: `techEnRoute`, `techArrived`, `jobAccepted`, `bookingRejected`, plus the 5 new types — all `/booking/:job_id`.

The exception is `bookingRescheduled`. Its tap target is `/booking/:child_booking_id` (NOT `:job_id`) because the original is now CANCELLED and not actionable. Navigating to the original would leave the user looking at a dead booking; navigating to the child shows them the new live one. The `_navGuardPayloadKeys` entry for this event is `'child_booking_id'` matching the path token — once the user is on the child screen (auto-redirected by `BookingRescheduledNotifier` OR routed there by an earlier tap), a stale banner tap doesn't push a duplicate.

### 7.4 `_resolveTemplatedPath` is generic now

The previous router resolved `:job_id` by looking up `payload['job_id']` directly. Now it parses `:<token>` from the path template and looks up the matching key:

```dart
final regex = RegExp(r':(\w+)');
String resolved = template;
for (final match in regex.allMatches(template)) {
  final key = match.group(1)!;
  final value = event.payload[key]?.toString();
  if (value == null) return null;  // visible failure: skip the push.
  resolved = resolved.replaceFirst(':$key', value);
}
return resolved;
```

This means future events with their own templated routes (a `walletTopUpComplete` event with `/wallet/transactions/:transaction_id`, e.g.) need only a route registration + a payload key — no router-internal change.

### 7.5 Per-event payload models live with the consumer

`booking_event_payloads.dart` defines the 3 freezed payload models (`JobIdPayload`, `QuoteGeneratedPayload`, `BookingRescheduledPayload`) inside `lib/features/orchestrator/data/models/`. Per CLAUDE.md "Per-event feature wiring": payload models live with the receiver, never in `core/realtime`. Putting them in core would invert the dependency graph (core would grow with every new feature event).

The mapper extracts only the fields the orchestrator actually uses — `extractJobId` is shared across 11 events; `extractChildBookingId` is `bookingRescheduled`-only. New payload fields can be added to the mapper without touching the entity unless they affect domain logic (today: none of them do; everything additional is just routing / banner copy).

### 7.6 Pipeline-level guarantees inherited automatically

These apply to every event automatically — DO NOT re-implement per feature:

- **Source tagging** (`ws` / `fcm` / `sync`) — `WsFrameDispatcher`, `FCMHandler`, `EventSyncNotifier` each pass their source.
- **Server-time anchor** — seeded only by `source: ws` frames; FCM and sync are tap-intent / replay channels and could be stale.
- **Recipient filter** — drops frames where `recipientUserId != currentAuthUserId`. Both halves must be non-null.
- **Expiry filter** — drops frames whose `expiresAt` is past the server-anchored now.
- **24-hour windowed dedup** — keys on envelope `id` over a 24h window matching the backend `UNACKNOWLEDGED_WINDOW`.
- **BG-isolate queue cap** (`_kMaxPendingBackgroundEvents = 50`) — coupled across the isolate boundary.
- **Teardown ordering** — `fcmHandler.unregister()` BEFORE `wsConnection.disconnect()`. Reversing this would leak tray notifications to a logged-out device on shared phones.

The orchestrator events ride on these. There is nothing per-feature to wire.

---

## §8 Routing + bookings list integration

### 8.1 `/booking/:job_id` GoRoute

```dart
GoRoute(
  path: '/booking/:job_id',
  name: 'booking_orchestrator',
  builder: (context, state) {
    final raw = state.pathParameters['job_id'];
    final id = raw == null ? null : int.tryParse(raw);
    if (id == null || id <= 0) {
      return const _InvalidBookingLinkScreen();
    }
    return BookingOrchestratorScreen(jobId: id);
  },
),
```

The `id <= 0` guard catches malformed deep-links (`/booking/abc` → `int.tryParse` returns `null`; `/booking/0`, `/booking/-3` → invalid id). `_InvalidBookingLinkScreen` is a dedicated surface (icon + copy + "Go home" button) distinct from the orchestrator's own "Not found" failure UI — it lets the user distinguish "this link is bad" from "this booking vanished from the server."

Pinned by `app_router_test.dart` (4 tests covering the three malformed cases + the valid case).

### 8.2 Bookings list lockstep

The 5 new event types each have a corresponding `apply<EventName>` static method on `BookingEventPatchMapper`:

| Method | Status flip | Badge / headline |
|---|---|---|
| `applyBookingCancelled` | → CANCELLED | "Cancelled" / "This booking was cancelled" |
| `applyBookingNoShow` | → NO_SHOW | "No-show" / actor-discriminated headline |
| `applyQuoteDeclined` | → COMPLETED_INSPECTION_ONLY | "Inspection only" / "You declined the quote" |
| `applyJobCompleted` | → COMPLETED | "Completed" / "<tech> finished the job" |
| `applyBookingRescheduled` | original → CANCELLED | "Rescheduled" / "Moved to a new time slot" |

The list notifier's switch routes events through the appropriate method. `bookingRescheduled` is special — after patching the original to CANCELLED, the notifier additionally fires `refresh()` so the newly-created child booking shows up on the user's Upcoming tab without a manual pull. The other four events don't need a refresh because the patched-row contains all the data the list card needs.

### 8.3 Booking card tap

The customer's `booking_card.dart` previously routed to `/customer/booking/<id>` (the placeholder). It now routes to `/booking/<id>` (audience-neutral). One-line change, but it's the seam through which the customer's primary entry into the orchestrator flows.

Pinned by `booking_card_test.dart`'s extended tap-path assertion.

### 8.4 Why no boot-hook wakeup for the screen-scoped notifiers

`BookingOrchestratorEventsNotifier` and `BookingRescheduledNotifier` are `keepAlive: false` and screen-scoped. They do NOT need to be in `realtimeBootHooksProvider` because:

- The screen's `ref.watch(...)` registers the subscription synchronously when the screen mounts.
- Events that arrive **before** the screen mounts (e.g. an FCM tap landing on `/booking/42` from the cold-start path) flow through the standard `EventUrgencyRouter` push, and by the time the screen finishes building, the notifier is alive and any subsequent event triggers a refresh.
- The events of interest are correlated with the screen being open — there's no "I need to know about this booking even when I'm on a different screen" use case for these notifiers. List-side patches handle that case via the list notifier's keepAlive subscription, which IS in the boot-hook registry.

Contrast with `incomingJobQueueProvider` (technician's offers queue) — that one IS in the boot-hook registry because it must be alive whenever the technician is logged in, regardless of which screen they're on.

---

## §9 Audit history

This section captures the full audit ledger across both the pre-impl and impl-time audits. Two distinct audit traditions ran during this session:

- **Pre-impl audits** (cycles 1 + 2 of `AUDIT.md` / `AUDIT_CYCLE_2.md`) — audited the **sprint plan documents** before any code was written. Findings used IDs `P0-XX`, `P1-XX`, `C2-P0-XX`, `C2-P1-XX`. All P0/P1 findings closed in-document via patches to the sprint files; the patched sprints became what session 3 actually implemented.
- **Impl-time audits** (cycles 1 + 2 of the bulletproof-audit conversation) — audited the **shipped code** after each major impl phase. Findings used IDs `A-XX`, `B-XX`. All findings either landed as code patches or were pinned by Phase C tests.

### 9.1 Pre-impl audit cycle 1 — `AUDIT.md` (1003 lines)

Surfaced 8 P0 + 14 P1 + 11 P2 + 8 P3 + 6 CSC findings against the sprint plan files. All P0/P1 closed in-document by sprint-file patches. The findings specifically relevant to session 3 (frontend) included:

- `BookingValidationError` envelope shape (P0-01) — applied to backend, frontend just consumes the envelope shape.
- `TechReliabilityIncident` model + admin (P0-08) — backend; impacts the absence of `tech_reliability_penalty` event from the orchestrator's broadcast set.
- Customer phone via UserProfile prefetch (P1-XX) — backend selector; frontend receives the prefetch'd phone in the `customer.phone_no` wire field.
- Image upload size cap (P1-10) — backend; frontend respects the cap when uploading dispute photos.
- `BookingDetailView` cache_control drop (P1-04) — applied to backend; frontend benefits because realtime events drive re-fetches.

### 9.2 Pre-impl audit cycle 2 — `AUDIT_CYCLE_2.md` (737 lines)

Surfaced 5 cycle-2 P0 + 7 P1 + 3 P2 + 4 P3 + 3 CSC findings introduced by cycle-1 patches. Of these, the session-3-relevant ones:

| ID | What | Where it landed in session 3 |
|---|---|---|
| **C2-P0-01** | Double `/api/` URL prefix | Backend Phase A (§3.1). All 12 `endpoint=` strings in `orchestrator_ui.py` had the `/api/` prefix dropped. |
| **C2-P0-02** | `wsConnectionNotifierProvider` undefined | Closed in session 4 spec; not session 3 work. |
| **C2-P0-03** | Two contradictory `TrackingSubscriptionController` defs | Closed in session 4 spec. |
| **C2-P0-04** | Stale Dio code blocks remain | Closed in sessions 4/5/6 specs. |
| **C2-P0-05** | Stale `0009` migration reference | Closed in session 1 spec. |
| **C2-P1-01** | Riverpod `dispose()` override won't run | Session 4 spec. |
| **C2-P1-02** | `_connectionEvents.add(...)` shown as comment | Session 4 spec. |
| **C2-P1-03** | `payment_received is_critical=True` wrong in spot-check | Session 1 spec. |
| **C2-P1-04** | Modal-key parity contract asymmetric | Sessions 5/6 spec. |
| **C2-P1-05** | Session 5 dec 3 says "via Dio (existing)" | Session 5 spec. |
| **C2-P1-06** | `flutterSecureStorageProvider` cross-feature coupling | **Applied to session 3 frontend** — `orchestratorSecureStorageProvider` declared in `presentation/providers/dependency_injection.dart` rather than importing from auth. |
| **C2-P1-07** | Two `sendUpstream` defs for WsConnectionNotifier | Session 4 spec. |
| **C2-CSC-03** | `fromWire` nullability rationale undocumented | Applied to session 3 — the `BookingUiTone.fromWire(String)` non-null vs `BookingUiActionStyle.fromWire(String?)` nullable asymmetry is documented as "matches required-vs-optional fields in the serializer." |

The remaining findings (P2 and below) were accepted as defer-OK per cycle-2 §12.

### 9.3 Impl-time audit cycle 1 — bulletproof audit after the first impl pass

User prompted: "aggressively audit your whole implementation, is it bulletproof?" Three load-bearing patches landed (this session's `A-XX` IDs):

| ID | File | Fix |
|---|---|---|
| **A-7** | `presentation/providers/booking_action_executor.dart` | Reorders auth-token read → URL build → headers compose so all three are derived once per request and a token rotation mid-execute doesn't desync the request. |
| **A-8** | `presentation/widgets/booking_orchestrator_action_button.dart` | The `_classify(endpoint)` switch was missing the `/no-show/` arm — would have fallen through to "do nothing", silently breaking the no-show flow. |
| **A-9** | `presentation/widgets/sheets/booking_action_pending_sheet.dart` | Long body text (>3 lines) was clipped because the sheet used a fixed-height container. Wrapped in `SingleChildScrollView` so all body text is reachable. |
| **A-10** | `data/datasources/booking_detail_remote_data_source.dart` + backend serializer | Profile picture URL now built via `request.build_absolute_uri` so the wire format is absolute (`http://api.example.com/media/...`) — `CachedNetworkImage` couldn't resolve relative URLs (`/media/...`) without a host. |
| **A-17** | `backend/bookings/api/booking_detail/serializers.py` (cross-cycle) | The `show_dispute_button` boolean was incorrect for the DISPUTED state (returned True; should be False because the dispute is already open). Pinned by the `show_dispute_button` matrix test in `test_booking_detail_api.py`. |

### 9.4 Impl-time audit cycle 2 — second bulletproof audit

User prompted again: "aggressively audit your whole implementation, is it bulletproof?" Eighteen `B-XX` findings surfaced; all were either patched or directly pinned by Phase C tests.

| ID | What | Where it landed |
|---|---|---|
| **B-4** | Reschedule chain — `child_booking_id` not on the wire | Backend Phase A patch (§3.2). New field surfaced; mapper reads it; HeaderSlot renders "Continued on #N". |
| **B-9** | `extractChildBookingId` had no event-type guard | Mapper now early-returns `null` if event is not `bookingRescheduled`. Pinned by `booking_event_payload_mapper_test.dart`. |
| **B-16/B-17** | Local data source silently swallowed corrupt cache JSON, returning truncated entities | `BookingDetailLocalDataSource.read` now catches the FormatException, evicts the corrupt key, and returns `null`. Pinned by `booking_detail_local_data_source_test.dart`. |
| **B-19** | Repository provider read `currentAuthUserIdProvider` at construction time and StateError'd if auth wasn't ready yet | Repository provider now defers the auth read to first `getBookingDetail` call. Pinned by `dependency_injection_test.dart`'s predicate matcher on the StateError message (Riverpod 3 wraps in ProviderException, so direct `throwsA(isA<StateError>())` doesn't work). |
| **B-29** | `BookingOrchestratorEventsNotifier` was triggering refresh on `bookingRescheduled` | The 12-event filter set explicitly excludes `bookingRescheduled` (the dedicated nav-side-effect notifier owns it). Pinned by `booking_orchestrator_events_notifier_test.dart`. |
| **B-30** | The screen used `ref.read(eventsProvider)` instead of `ref.watch` | Screen now `ref.watch`es both screen-scoped notifiers. Pinned by `booking_orchestrator_screen_test.dart::screen_ref_watch_keeps_event_notifier_alive` (the load-bearing smoke test). |
| **B-40** | Same `ref.watch` issue for `BookingRescheduledNotifier` | Closed in lockstep with B-30. |
| **B-42** | HeaderSlot rendered "Continued on #N" link unconditionally | Now gated on `status == CANCELLED && childBookingId != null`. Pinned by `header_slot_test.dart`. |
| **B-44/B-45** | Malformed deep-links (`/booking/abc`, `/booking/0`, `/booking/-3`) collapsed to id=0 + generic 404 | New `_InvalidBookingLinkScreen` in `app_router.dart`. Pinned by `app_router_test.dart`. |
| **B-51** | HeaderSlot's lineage-callout logic was inline + hard to follow | Extracted to `_lineageCalloutFor(viewer, status, parentId, childId)` private method. No behavior change; refactor only. |
| **B-53** | Timeline's current-dot for INSPECTING + QUOTED diverged (INSPECTING showed "Arrived" current; QUOTED showed "Quote" current) | Both INSPECTING and QUOTED now show "Quote" as current. Pinned by `timeline_slot_test.dart` matrix. |
| **B-55** | `show_dispute_button` rendered the button even when `false` (UI bug) | SecondaryActionsSlot now hides the button when `showDisputeButton == false`. Pinned by `secondary_actions_slot_test.dart`. |
| **B-56** | Wrap of secondary actions had `runSpacing: 0` causing buttons to overlap when wrapped | `runSpacing` set to 8. Pinned by `secondary_actions_slot_test.dart::runSpacing_is_positive`. |
| **B-69** | Pending-sheet body could overflow viewport on small screens | Wrapped in `SingleChildScrollView`. Pinned by `booking_action_pending_sheet_test.dart::long_body_scrolls`. |
| **B-70** | DELETE requests in the executor sent a body | DELETE arm in the switch never sets a body. Pinned by `booking_action_executor_test.dart::DELETE_without_body` using `verifyNever`. |

### 9.5 Phase C — Tests

Wrote the full pinning-regression test suite in 4 sub-phases:

- **C.1 — Critical pinning (cycle-1 + 2 bulletproof fixes)**: 35 tests covering A-7…A-17, B-42…B-70. The "if anyone reverts this fix, this test fails" set.
- **C.2 — Layer completeness**: 50 tests covering domain mapping, payload extractor branches, executor, screen-scoped notifiers, DI provider StateError. The "every layer has a regression net" set.
- **C.3 — Presentation breadth**: 42 tests covering all 5 slot widgets, the action button's classification + busy-state + error-surfacing, all 14 stub bodies via the body-slot matrix. The "screen renders correctly across every status × role" set.
- **C.4 — Smoke**: 3 tests on the screen — including the load-bearing `ref.watch` contract test. The "wire it together end-to-end" set.

Plus 15 backend test additions.

**Final state**: frontend `02:02 +967: All tests passed!`, backend `874 passed in 12.15s`. Zero regressions. The diff against pre-Phase-C baselines: frontend +130, backend +15 = +145 new pinning tests.

---

## §10 Test inventory

(See `ORCHESTRATOR_FEATURE.md` "Tests" section for the full per-file breakdown. The high-priority entries:)

### 10.1 Tests that catch the most-likely regression vectors

| Test | What regression it catches |
|---|---|
| `booking_orchestrator_screen_test.dart::screen_ref_watch_keeps_event_notifier_alive` | A future "tidy up" refactor that swaps `ref.watch` → `ref.read` in the screen's build. The events notifier would auto-dispose silently; realtime refresh chain dies. The smoke test is the only catch. |
| `booking_action_executor_test.dart::DELETE_without_body` | A future endpoint that the backend documents as DELETE-with-body. The backend may parse it; some HTTP servers reject it. Verified via `verifyNever(client.delete(any(), headers: any(named:'headers'), body: any(named:'body')))`. |
| `body_slot_test.dart::status_x_stub_matrix` | A typo'd switch arm (e.g. `arrived → quoted`) that compiles but maps to the wrong stub. Dart 3 exhaustiveness only catches *missing* cases, not *swapped* ones. |
| `timeline_slot_test.dart::*_current_phase_label` | A regression that breaks the INSPECTING → QUOTED phase collapse, or the IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY → "Done" collapse. Heuristic: `FontWeight.w600` on the bolded label is the only observable signal of `_PhaseState.current`. |
| `app_router_test.dart::invalid_link_*` | A future router refactor that drops the `id <= 0` guard and lets malformed deep-links collapse to id=0. Without the test, the `_InvalidBookingLinkScreen` would silently never appear. |
| `booking_detail_repository_impl_test.dart::evict_on_mapper_error_*` | A cache-version migration that bumps `_v1_` to `_v2_` but leaves stale `_v1_` rows in some user's SharedPreferences. Without eviction the user sees a corrupted entity instead of OfflineNoCache. |
| `booking_orchestrator_events_notifier_test.dart::booking_rescheduled_NOT_in_set` | A future engineer who adds `bookingRescheduled` to the events notifier's filter "for symmetry." Would cause a double-fire (the events notifier would refresh; the rescheduled notifier would push-replace). |

### 10.2 Tests that pin invariants that have no obvious failure mode

| Test | What invariant it pins |
|---|---|
| `test_orchestrator_ui_selector.py::no_endpoint_starts_with_api` | URL convention. Adding a new action helper without dropping `/api/` re-introduces the cycle-2 P0-01 regression. |
| `test_orchestrator_ui_selector.py::customer_quoted_endpoints_interpolate_actual_quote_id` | The `<id>` placeholder substitution. Adding a new customer-quote endpoint that forgets to interpolate would resurface the cycle-2 bug. |
| `test_booking_detail_api.py::show_dispute_button_matrix` | The `show_dispute_button` should be False for DISPUTED (already disputed); True for IN_PROGRESS, COMPLETED, COMPLETED_INSPECTION_ONLY, NO_SHOW; False for everything else. A change to the matrix without updating the test would silently allow disputes from terminal states or block them from valid states. |
| `booking_detail_mapper_test.dart::child_booking_id_mapping` | The `child_booking_id` on the wire is mapped to `BookingDetail.childBookingId` and not to `parent_booking_id` (easy typo). |

### 10.3 Tests deliberately not yet written

- **End-to-end realtime → orchestrator refresh**: requires a real WS connection or a sophisticated harness; the screen smoke test + the events notifier unit test together cover the same surface piecewise.
- **Cross-isolate FCM cold-start → orchestrator screen**: requires booting the BG isolate and the main isolate together; the existing FCM tests cover the BG queue contract; the orchestrator screen's deep-link path is covered by `app_router_test.dart`.
- **Pull-to-refresh on the orchestrator screen**: there is no pull-to-refresh today (refresh is event-driven). When session 4's live tracking adds a manual refresh affordance for the map, the test should be added then.

---

## §11 What's actually committed vs uncommitted (the most important section)

```
On branch main
Your branch is ahead of 'origin/main' by 18 commits.

Changes not staged for commit:
  M  backend/bookings/api/booking_detail/serializers.py
  M  backend/bookings/api/booking_detail/views.py
  M  backend/bookings/selectors/orchestrator_ui.py
  M  backend/tests/bookings/api/test_booking_detail_api.py
  M  backend/tests/bookings/selectors/test_orchestrator_ui_selector.py
  M  flag.md
  M  frontend/lib/core/realtime/domain/entities/event_urgency.dart
  M  frontend/lib/core/realtime/domain/entities/system_event_type.dart
  M  frontend/lib/core/realtime/presentation/router/event_urgency_router.dart
  M  frontend/lib/core/routing/app_router.dart
  M  frontend/lib/features/customer/bookings/CUSTOMER_BOOKINGS_FEATURE.md
  M  frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart
  M  frontend/lib/features/customer/bookings/domain/entities/booking_status.dart
  M  frontend/lib/features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart
  D  frontend/lib/features/customer/bookings/presentation/screens/customer_booking_detail_screen.dart
  M  frontend/lib/features/customer/bookings/presentation/widgets/booking_card.dart
  M  frontend/lib/features/technician/incoming_job_requests/INCOMING_JOB_REQUESTS_FEATURE.md
  M  frontend/test/core/realtime/presentation/router/event_urgency_router_test.dart
  M  frontend/test/features/customer/bookings/presentation/widgets/booking_card_test.dart
  M  main.pdf

Untracked:
  ?? booking_orchestrator_sprint/                                (the sprint folder + this summary file)
  ?? frontend/lib/features/orchestrator/                          (the entire feature stack)
  ?? frontend/test/core/routing/                                  (app_router_test.dart)
  ?? frontend/test/features/orchestrator/                         (17 test files)
  ?? session_1_wire_main_isolate.md
  ?? session_2_auth_bridge.md
  ?? session_3_android_native_and_finalize.md
  ?? session_4_customer_bookings_list_ui.md
  ?? Test_Cases.docx
  ?? backend/dev_send_push.py
  ?? frontend/android/.kotlin/                                    (build cache)
```

**Action item before Session 4 starts**: stage and commit Session 3 as a coherent commit (or a small chain). The Session 2 surface (per `session_2_implementation_summary.md` §11) is also still uncommitted — both are part of the same feature-branch flow.

Suggested commit structure for session 3 (one option among many):

```
feat(orchestrator): booking-detail screen + slot architecture (sprint v1, session 3)

- /booking/:job_id audience-shared GoRoute (closes flag #26)
- Domain → Data → Presentation feature stack (52 source files)
- 5 new realtime event types + EventUrgencyRouter rewiring
- Backend Phase A: orchestrator_ui.py URL prefix drop + child_booking_id + BookingItem serializer split
- 130 frontend + 15 backend pinning tests; full suite green; no regressions
- Cumulative coverage of all 23 audit findings (cycles 1 + 2)
```

Do NOT commit `main.pdf` (binary), `Test_Cases.docx` (binary), `frontend/android/.kotlin/` (build cache), or the four root-level `session_*.md` files unless they are intentional deliverables.

---

## §12 What Session 4 inherits

Session 4 (`booking_orchestrator_sprint/session_4_live_tracking_and_dual_maps.md`) replaces `EnRouteBodyStub` and `ArrivedBodyStub` with the live-tracking map + tech foreground GPS. It depends on:

1. **`/booking/:job_id` GoRoute and `BookingOrchestratorScreen`** — ✅ Shipped (session 3).
2. **`bookingDetailProvider(jobId)` AsyncNotifier with `keepAlive: false`** — ✅ Shipped. Session 4's `TrackingSubscriptionController` will `ref.listen(bookingDetailNotifierProvider)` to gate WS subscription on `(status, role)`.
3. **WS `subscribe_tracking` / `unsubscribe_tracking` upstream messages** — ✅ Shipped (session 2).
4. **`tech_gps` stream payload shape** — ✅ Shipped (session 2; documented in `STREAMS_TECH_GPS.md`).
5. **`tech_location` ingress 4-sec throttle + 429 envelope** — ✅ Shipped (session 2).
6. **`SystemEventType.techEnRoute` / `techArrived` event types** — ✅ Shipped (cycles before session 3).
7. **`orchestratorSecureStorageProvider`** — ✅ Shipped (session 3 frontend; closes cycle-2 P1-06).
8. **`HttpFailure` envelope contract for tech-location 429 / 404 / 403** — ✅ Shipped (session 2 contract; session 3 mapper handles).

Session 4 must add:

- A new feature folder `frontend/lib/features/tech_tracking/` (or similar; see session 4 spec §2 for the proposed layout).
- `TrackingSubscriptionController` — listens to bookingDetail status × role + `WsConnectionNotifier.connectionEvents` Stream.
- Foreground service for tech-side GPS publishing (Android only; iOS deferred).
- `EnRouteBody` and `ArrivedBody` real widgets, replacing the stubs.
- Per-event payload models for `tech_en_route` / `tech_arrived` / the `tech_gps` stream consumer.

The orchestrator screen is unchanged — session 4 modifies only the body-slot stub classes, the new feature folder, and the cross-feature DI wiring. The `BodySlot` switch arms for `enRoute` / `arrived` start returning the rich widgets instead of the stubs; everything else stays put.

### 12.1 Cross-cutting things session 4 does NOT inherit

- **No new audit findings to address** — the cycle-2 audit explicitly bounded session 4's deferred items (the deferred ones are sprint-internal scope, not cycle-2 P0/P1 leftovers).
- **No backend changes from session 3 for session 4 to consume** — the three Phase A patches are all session 3-internal (orchestrator screen specific). Session 4's tech-tracking work touches a different backend surface (the WS consumer + tech_location ingress) that's already shipped.

---

## §13 Glossary of internal terms (additions for session 3)

(See `session_2_implementation_summary.md` §13 for session 2 terms — they all carry forward.)

| Term | Meaning |
|---|---|
| **Orchestrator screen** | `frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart`. The audience-shared `/booking/:job_id` surface that drives a single booking through every post-CONFIRMED state. |
| **Slot architecture** | The 5-region layout the orchestrator screen uses: header / timeline / body / secondary actions / primary action. Each slot is a separate widget with a single responsibility; the body is the only one that switches on `BookingStatus`. |
| **Stub body** | A placeholder widget for one `BookingStatus` value. Today all 14 stubs render `booking.ui.bodyText` verbatim with minimal chrome. Sessions 4–6 replace them progressively. |
| **`BookingActionExecutor`** | The single HTTP dispatcher for server-emitted `BookingUiAction`. Handles GET/POST/PATCH/PUT/DELETE; routes through `package:http` + `orchestratorSecureStorageProvider`. |
| **`BookingOrchestratorEventsNotifier`** | The screen-scoped notifier that filters `systemEventProvider` for 12 refresh-trigger event types matching this booking's `job_id` and fires `ref.invalidate(bookingDetailProvider(jobId))`. `keepAlive: false`. |
| **`BookingRescheduledNotifier`** | The screen-scoped notifier that handles the unique nav side-effect of `bookingRescheduled` — calls `pushReplacement('/booking/<child>')` when the user is on the original. `keepAlive: false`. |
| **Viewer role** | `BookingOrchestratorRole.customer` or `.technician`. Derived in the data-layer mapper from `customer.id == currentUserId`. The server's 403 gate makes the else-branch always tech. |
| **Reschedule lineage** | The `parent_booking_id` ↔ `child_booking_id` pointer chain. Parent → reverse pointer (child has it). Child → forward pointer (cancelled original has it). Both surfaced in HeaderSlot for "Continued on #N" / "Rescheduled from #N" callouts. |
| **`_PhaseState`** | Internal enum in `TimelineSlot` (`upcoming` / `current` / `done`). Drives the dot-and-label rendering. The current state's label is the only `Text` widget rendered with `FontWeight.w600` — that's the load-bearing observable signal for the timeline test heuristic. |
| **`_InvalidBookingLinkScreen`** | The dedicated surface for malformed deep-links (`/booking/abc`, `/booking/0`, `/booking/-3`). Distinct from the orchestrator's "Not found" UI so the user can distinguish a typo from a vanished booking. |
| **Cycle-3 / Cycle-4 audits** | The two impl-time bulletproof audits run during this session (after the first impl pass + before Phase C). Surfaced 5 `A-XX` findings + 18 `B-XX` findings. All fixed or pinned. |
| **Phase C** | The dedicated test-writing phase at the end of session 3. Four sub-phases: C.1 (cycle-1 + 2 critical pinning), C.2 (layer completeness), C.3 (presentation breadth), C.4 (smoke). Total: 145 new pinning tests. |

---

## §14 Drift policies + seam maps

These are the load-bearing seams that MUST stay in sync across the codebase. When backend changes any of these, the listed mirror MUST update in lockstep.

| Surface | Authoritative source | Mirror |
|---|---|---|
| `BookingStatus` wire values | `backend/bookings/models.py::JobBooking.STATUS_*` | `frontend/lib/features/customer/bookings/domain/entities/booking_status.dart` `_wireLookup` |
| `ui` block shape | `backend/bookings/selectors/orchestrator_ui.py::resolve_orchestrator_ui` | `BookingDetailMapper._uiBlock` + `BookingUiBlockModel` |
| Action endpoint strings | `orchestrator_ui.py` action helpers (no `/api/` prefix; live quote id substituted) | `BookingActionExecutor` + invariant tests in `test_orchestrator_ui_selector.py` |
| Event types | `backend/realtime/constants/event_types.py` + `EVENT_REGISTRY` | `frontend/lib/core/realtime/domain/entities/system_event_type.dart` |
| Event criticality | `EVENT_REGISTRY[<type>]['is_critical']` | `frontend/lib/core/realtime/domain/entities/event_criticality.dart::criticalTypes` |
| Event urgency | (frontend-only — no backend twin) | `frontend/lib/core/realtime/domain/entities/event_urgency.dart::_urgencyMap` |
| List-card UI patches | `backend/bookings/selectors/customer_bookings_selector._resolve_ui_block` | `frontend/lib/features/customer/bookings/data/mappers/booking_event_patch_mapper.dart` |
| BookingItem wire shape | `backend/bookings/api/booking_detail/serializers.py::_BookingItemResponseSerializer` | `frontend/lib/features/orchestrator/data/models/booking_item_model.dart` |
| Reschedule lineage | `BookingDetailView.get` (forward pointer) + `JobBooking.parent` (reverse pointer) | `BookingDetail.parentBookingId` / `childBookingId` |
| Cache schema version | `_local.read` / `_local.write` key prefix `orchestrator_booking_detail_v1_` | bump `_v1_` → `_v2_` on any wire-shape change requiring re-fetch |

### 14.1 Backwards-compat defaults (wire → entity)

Per the "mapper owns backwards-compat" rule:

| Wire field | Behavior on missing / null |
|---|---|
| `child_booking_id` | Maps to `BookingDetail.childBookingId = null`. HeaderSlot hides the "Continued on #N" callout. |
| `cash_collection.amount` | Maps to `BookingCashCollection.amount = null`. CompletedBodyStub hides the cash-collected line. |
| `active_quote` | Maps to `null`. QuotedBodyStub falls through to a degraded "Quote details unavailable" body. |
| `address` (full object) | Maps to `null`. HeaderSlot uses `address_snapshot` instead. |
| `payload.job_id` on event | Drops the event silently with a `developer.log` warning. |
| `payload.child_booking_id` on `bookingRescheduled` | `BookingRescheduledNotifier` skips the push. |
| `payload.actor` on `bookingNoShow` | Banner falls through to generic "Marked as a no-show — tap to view." copy. |
| `payload.reason` on `bookingRejected` | Banner falls through to generic "Your booking is no longer available — tap to view." |

---

## §15 What this summary does NOT cover

- **Visual design** — planned UI cleanup pass. Today the slot widgets use `AppColors` directly + `Theme.of(context).colorScheme` for accent tones; the global theme stays on `ColorScheme.fromSeed`.
- **iOS native push** — deferred per flag #10.
- **Real production load profiles** — no load test.
- **Internationalization, accessibility** — out of sprint scope.
- **The full Riverpod 3 generator output** (`*.g.dart`, `*.freezed.dart`) — those files are mechanically derived from the source `*.dart` files via `build_runner` and should never be hand-edited.
- **Session 4's tech-tracking implementation** — covered by `session_4_live_tracking_and_dual_maps.md`. This summary only documents what session 4 inherits.

---

*End of summary. Session 4 reads this first; the spec second.*
