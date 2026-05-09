# Session 5 — Quote Flow + Cash Collection

> Fifth session of the Booking Orchestrator sprint. Replaces session 3's stub bodies for `INSPECTING`, `QUOTED`, `IN_PROGRESS`, `COMPLETED`, and `COMPLETED_INSPECTION_ONLY` with rich UIs: tech-side quote builder (chip stack of skills + sub-service picker for in-category browsing), customer-side approval card (3-action: Approve / Decline / Bargain in person), and the combined cash-collection button (single tap → COMPLETED per §14 rule 2). Hard-blocks cash collection when offline.
>
> **Out of scope**: cancellation / no-show / dispute / reschedule UIs (session 6), real wallet operations (finance sprint), AI chatbot intake (future sprint), iOS push (flag #10 deferred).

---

## §0 Sprint context

This is **session 5 of 6**. Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–2 shipped backend; session 3 shipped frontend skeleton with stub bodies; session 4 lit up live tracking. This session lights up the quote and cash flows — the heart of the customer experience.

Session 1+2+3+4 invariants this session relies on:
- Backend transition endpoints `submit_quote`, `approve_quote`, `decline_quote`, `request_revision`, `confirm_cash_received` (session 2 §4.2, §4.3).
- Backend `start_inspection` endpoint (session 2 §4.1) for the auto-flip ARRIVED → INSPECTING when tech opens the builder.
- Backend booking-detail response (session 2 §4.6) shape includes `active_quote`, `booking_items`, `pricing.final_cash_to_collect`, `available_transitions`, `ui` block.
- Frontend `BookingOrchestratorScreen` + 5 slot widgets + 13 stub bodies (session 3).
- `BookingActionExecutor` from session 3 — extended this session to support `NAVIGATE` and `MODAL` action methods.
- `bookingDetailNotifierProvider` family + `bookingOrchestratorEventsNotifier` — already triggers refresh on quote events (session 3 §4.9).
- Connectivity sensing capability (`connectivity_plus` package or equivalent in pubspec) — session 5 introduces it if not already present.

What session 6 will add on top:
- **Session 6** — Cancellation flows (with timing-aware copy), reschedule (child booking), no-show (single tap), dispute (form intake), admin resolve dispute UI polish, SLA countdown polish for AWAITING; flag #26 closure.

This session's deliverables make a **demo-runnable happy path** end-to-end: customer creates booking → tech accepts → tech-on-the-way (session 4) → tech arrives → tech builds quote → customer approves → tech does work → tech collects cash → COMPLETED. Plus the bargain loop and the inspection-fee-only outcome.

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions in sprint meta §4. Session-local decisions:

1. **Quote builder is a separate full-screen route** at `/booking/:job_id/quote-builder`, not a modal sheet. Reason: chip-stack UX needs vertical space, and the UI may be on screen for several minutes while tech enters line items. A modal sheet would cramp the experience.
2. **Builder mounts → fires `start_inspection` in `initState`** (fire-and-forget) per §14 rule 1 (auto-transition on quote-builder open). No explicit "Start inspection" button. If the call fails (tech is not in ARRIVED state — e.g., already INSPECTING), the orchestrator's idempotency makes it a no-op.
3. **`BookingActionExecutor` extended** to support 3 action methods (audit C2-P1-05):
   - `POST` / `GET` / etc. — HTTP request via `package:http` per the canonical pattern in `BOOKING_ORCHESTRATOR_SPRINT.md` §24 (executor was rewritten to `http` in cycle-1 P0-03 fix; see session 3 §4.10).
   - `NAVIGATE` — `GoRouter.of(context).push(action.endpoint)`.
   - `MODAL` — opens a feature-side modal sheet keyed by `action.endpoint` (a route-shaped string, e.g., `'/booking/:job_id/cash-collection-confirm'`).
   The extension keeps the dumb-UI principle: server still tells client what to do; client interprets `method` to dispatch.
4. **Customer-side QUOTED is body-rich, action-slot-empty**. The `QuotedBodyStub` for customer renders the full approval card inline: line items, bargain-ceiling indicators on labor lines, and 3 inline buttons (Approve / Decline / Bargain in person). Server's `ui.primary_action` is null for `QUOTED` + customer (the action lives in the body widget). Server's `ui.body_text` is the prose ("Approve this quote to begin work, or bargain in person with the technician.").
5. **Decline and Bargain open small confirmation modals** (not full screens). Modal collects an optional reason text field; submits to the backend.
6. **Cash collection is a body-embedded card on `IN_PROGRESS` for tech**, not a full screen. Tap the "Cash Collected: Rs.X" button → confirmation modal → POST → status flips to COMPLETED. Single combined tap per §14 rule 2.
7. **Hard-block cash collection on offline**: button disabled when no network; banner reads "Connect to network to confirm cash collection." Re-enables when connectivity restored. Implemented via a `connectivityStatusProvider` (Riverpod-wrapped `connectivity_plus`).
8. **Mid-job upsell**: from the orchestrator screen at `IN_PROGRESS`, tech viewer sees a small "+ Add work" link in the cash-collection card that re-opens the quote builder with `is_upsell=True`. The builder's UI is identical except the title says "Add to existing quote" and the existing `BookingItem` rows are visible (read-only) above the new line item form. On submit, status flips back to `QUOTED` and the customer reviews the additional work.
9. **No editable cash amount in v1**: tech taps "Confirm: Rs. X cash received" with the server-derived `final_cash_to_collect` value pre-filled. Tech cannot enter a partial amount. If customer can't pay full, tech either waits (status stays `IN_PROGRESS`) or escalates via dispute (session 6).
10. **Quote builder's chip stack** shows tech's `TechnicianSkill` rows filtered to the booking's `Service` category. Tech's skills come from cached profile (already loaded at login). The "+" button opens a `SubServicePickerSheet` that fetches all sub-services in the booking's service via a catalog endpoint (added if not present — see §4.7).
11. **Catalog endpoint** `GET /api/catalog/services/<id>/sub-services/` — if not already present, ship a thin endpoint this session. Single-purpose, no auth changes.
12. **Skill chips show pre-filled labor rate** equal to the tech's `TechnicianSkill.labor_rate` (their standing default). Tech can adjust per-line via the editable price field next to each chip-tap. Backend's band validation (per session 1 §6) rejects out-of-band; frontend validates client-side too for instant feedback.
13. **Quote builder is exhaustively tested** with the chip-stack + line-item edit flow. Notifier tests, screen widget tests, mocked datasource. The chip-stack add/remove logic is the most error-prone part.
14. **Bargain navigation per §14 rule 4 is automatic**: when tech receives a `quote_revision_requested` event for the active booking, the orchestrator's body re-renders to `INSPECTING` (server flips status), and the BodySlot's `InspectingBodyStub` for tech contains a "Continue building quote" button → NAVIGATE to the builder pre-loaded with the previous (now SUPERSEDED) quote. No banner, no interstitial.
15. **`CompletedBodyStub` and `CompletedInspectionOnlyBodyStub`** become receipt cards: line items + total + cash collected confirmation + technician profile chip. Same layout for both, with copy difference: COMPLETED says "Job complete — payment received"; COMPLETED_INSPECTION_ONLY says "Inspection only — Rs.500 collected; no work performed."
16. **Network connectivity provider** lives in `core/network/connectivity_status_provider.dart` (new), reusable by future features. Wraps `connectivity_plus`.

17. **Audit-cycle-1 fixes shipped this session** (see [`AUDIT.md`](./AUDIT.md) and sprint meta §25):
    - **P0-03 / §24 transport**: every "Dio impl" code block in this session is illustrative only. Real implementation uses `package:http` per the canonical pattern in `BOOKING_ORCHESTRATOR_SPRINT.md §24`. Substitute Dio symbols mentally throughout. Multipart isn't needed in this session (no file uploads — those land in session 6 for dispute photos).
    - **P1-08 await start_inspection**: drop the fire-and-forget pattern. The quote builder screen `await`s the start_inspection call; on failure, shows a snackbar with retry. Orchestrator's idempotency makes "already INSPECTING" a no-op so the await doesn't penalize the legitimate path.
    - **P1-09 modal endpoint registry**: the v0.9 `endpoint.endsWith(...)` chain is too fragile. Define `MODAL_ENDPOINT_KEYS` as a Dart constant set; backend selector exports the same set; CI test asserts parity. Modal dispatch uses key matching, not string suffix.

---

## §2 Files this session touches

### Backend (small additions, mostly to support the chip stack's "+" browse)

| File | Status | Purpose |
|---|---|---|
| `backend/catalog/api/sub_services_by_service/views.py` | **new** | `GET /api/catalog/services/<service_id>/sub-services/`. |
| `backend/catalog/api/sub_services_by_service/serializers.py` | **new** | List serializer with id, name, base_price, max_price, is_fixed_price, icon_name. |
| `backend/catalog/api/urls.py` | **modified** | Wire the new endpoint. |
| `backend/catalog/api/SEARCH_API.md` (or new file) | **modified or new** | Document the new endpoint. |
| `backend/tests/catalog/test_api_sub_services_by_service.py` | **new** | Auth + happy + 404 (service not found) tests. |

### Frontend feature folder extensions (`frontend/lib/features/orchestrator/`)

#### Domain (new)

| File | Purpose |
|---|---|
| `domain/entities/sub_service_catalog_entry.dart` | Freezed entity for catalog browse results. |
| `domain/entities/quote_draft.dart` | In-progress quote being built (line items + total + is_upsell flag). |
| `domain/entities/quote_draft_line_item.dart` | A single in-progress line item (sub_service ref + qty + priced_at). |
| `domain/failures/quote_builder_failure.dart` | Sealed failures for builder operations. |
| `domain/failures/quote_decision_failure.dart` | Sealed failures for approve/decline/bargain. |
| `domain/failures/cash_collection_failure.dart` | Sealed failures for cash collection. |
| `domain/repositories/quote_repository.dart` | Repository interface (submit_quote, approve, decline, request_revision). |
| `domain/repositories/cash_collection_repository.dart` | Repository interface (confirm_cash_received). |
| `domain/repositories/sub_service_catalog_repository.dart` | Repository interface (list sub_services for service). |
| `domain/use_cases/submit_quote_use_case.dart` | Wraps repository.submitQuote. |
| `domain/use_cases/approve_quote_use_case.dart` | Wraps repository.approveQuote. |
| `domain/use_cases/decline_quote_use_case.dart` | Wraps repository.declineQuote. |
| `domain/use_cases/request_revision_use_case.dart` | Wraps repository.requestRevision. |
| `domain/use_cases/confirm_cash_received_use_case.dart` | Wraps repository.confirmCashReceived. |
| `domain/use_cases/list_sub_services_use_case.dart` | Wraps repository.listSubServices. |

#### Data (new)

| File | Purpose |
|---|---|
| `data/models/quote_draft_request_model.dart` | DTO for `POST /quotes/` body. |
| `data/models/quote_decision_request_model.dart` | DTO for decline / request_revision body (with reason). |
| `data/models/cash_collection_request_model.dart` | DTO for `POST /confirm-cash-received/` body. |
| `data/models/sub_service_catalog_entry_model.dart` | DTO for catalog browse responses. |
| `data/mappers/quote_decision_mapper.dart` | (HttpFailure → sealed). |
| `data/datasources/quote_remote_data_source.dart` | Submit / approve / decline / request_revision HTTP calls. |
| `data/datasources/cash_collection_remote_data_source.dart` | confirm_cash_received HTTP call. |
| `data/datasources/start_inspection_remote_data_source.dart` | Fire-and-forget POST `/start-inspection/`. |
| `data/datasources/sub_service_catalog_remote_data_source.dart` | GET `/api/catalog/services/<id>/sub-services/`. |
| `data/repositories/quote_repository_impl.dart` | Maps datasource exceptions to sealed failures. |
| `data/repositories/cash_collection_repository_impl.dart` | Same. |
| `data/repositories/sub_service_catalog_repository_impl.dart` | Same. |

#### Presentation — providers (new)

| File | Purpose |
|---|---|
| `presentation/providers/dependency_injection.dart` | **modified** — register all new providers. |
| `presentation/providers/quote_builder_notifier.dart` | Holds `QuoteDraft` state; add/remove/edit line items; submit. |
| `presentation/providers/sub_service_catalog_provider.dart` | `family<int>` (serviceId) — fetches catalog browse list. |
| `presentation/providers/cash_collection_notifier.dart` | Submits cash collection, surfaces async state. |
| `presentation/providers/quote_decision_notifier.dart` | Submits approve / decline / request_revision. |

#### Presentation — screens (new)

| File | Purpose |
|---|---|
| `presentation/screens/quote_builder_screen.dart` | Full screen at `/booking/:job_id/quote-builder`. |

#### Presentation — widgets (new + modified)

| File | Purpose |
|---|---|
| `presentation/widgets/quote_builder/skill_chip_stack.dart` | Horizontal scroll of skill chips with default rate; tap to add line item. |
| `presentation/widgets/quote_builder/line_item_row.dart` | Editable line item row (name + qty stepper + price field + remove button). |
| `presentation/widgets/quote_builder/sub_service_picker_sheet.dart` | Modal bottom sheet with full catalog list. |
| `presentation/widgets/quote_builder/quote_total_summary.dart` | Sticky-bottom total + "Submit quote" button. |
| `presentation/widgets/quote_builder/upsell_existing_items_section.dart` | Read-only section showing already-accepted `BookingItem` rows (only visible when `is_upsell=True`). |
| `presentation/widgets/quote_approval/quote_approval_card.dart` | Customer-side line item display + 3 inline action buttons. |
| `presentation/widgets/quote_approval/decline_quote_modal.dart` | Confirmation modal with optional reason field. |
| `presentation/widgets/quote_approval/bargain_in_person_modal.dart` | Confirmation modal with optional reason field. |
| `presentation/widgets/quote_approval/bargain_ceiling_indicator.dart` | Small chip on labor lines: "Negotiable up to Rs. 2000". |
| `presentation/widgets/cash_collection/cash_collection_card.dart` | Body-embedded card with the combined "Cash Collected" button + offline banner. |
| `presentation/widgets/cash_collection/cash_collection_confirm_modal.dart` | "Confirm: Rs. X cash received" → POST → spinner → snackbar. |
| `presentation/widgets/cash_collection/upsell_link.dart` | Small "+ Add more work" link inside the cash-collection card; opens quote builder with `is_upsell=true`. |
| `presentation/widgets/receipts/receipt_card.dart` | Receipt UI for COMPLETED + COMPLETED_INSPECTION_ONLY (shared). |
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** — replace `InspectingBodyStub`, `QuotedBodyStub`, `InProgressBodyStub`, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub` bodies. |
| `presentation/widgets/booking_orchestrator_action_button.dart` | **modified** — handle `NAVIGATE` and `MODAL` action methods. |

#### Routing (modified)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/routing/app_router.dart` | **modified** | Add `/booking/:job_id/quote-builder` route. |

#### Connectivity (new)

| File | Purpose |
|---|---|
| `frontend/lib/core/network/connectivity_status_provider.dart` | Riverpod stream provider wrapping `connectivity_plus`. |
| `frontend/pubspec.yaml` | **modified** | Add `connectivity_plus: ^6.x` if not already present. |

#### Documentation (modified)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Add quote flow section, cash collection section, mark sessions 6 stubs still pending. |

#### Tests (all new)

| File | Purpose |
|---|---|
| `frontend/test/features/orchestrator/data/repositories/quote_repository_impl_test.dart` | All 4 quote operations × failure branches. |
| `frontend/test/features/orchestrator/data/repositories/cash_collection_repository_impl_test.dart` | Cash collection happy + failure branches. |
| `frontend/test/features/orchestrator/data/repositories/sub_service_catalog_repository_impl_test.dart` | Catalog browse happy + failure. |
| `frontend/test/features/orchestrator/presentation/providers/quote_builder_notifier_test.dart` | Add/remove/edit line items; total recompute; band validation; submit success/failure. |
| `frontend/test/features/orchestrator/presentation/providers/quote_decision_notifier_test.dart` | Approve/decline/request_revision. |
| `frontend/test/features/orchestrator/presentation/providers/cash_collection_notifier_test.dart` | Confirm cash; offline rejection. |
| `frontend/test/features/orchestrator/presentation/screens/quote_builder_screen_test.dart` | Full-screen widget test: chip tap → row added; total updates; submit fires datasource. |
| `frontend/test/features/orchestrator/presentation/widgets/quote_approval/quote_approval_card_test.dart` | 3 inline buttons render; tap routes to correct modal/datasource. |
| `frontend/test/features/orchestrator/presentation/widgets/cash_collection/cash_collection_card_test.dart` | Button enabled when online; disabled with banner when offline. |
| `frontend/test/features/orchestrator/presentation/widgets/receipts/receipt_card_test.dart` | Renders correctly for both terminal statuses. |
| `frontend/test/core/network/connectivity_status_provider_test.dart` | Stream emits correctly. |
| `frontend/test/features/orchestrator/presentation/widgets/booking_orchestrator_action_button_test.dart` | **modified** — covers NAVIGATE + MODAL methods. |

### Files NOT touched

- All session 1–4 work that's already shipped.
- Address picker (still uses existing OSM `LocationPicker`).
- Cancel / no-show / dispute / reschedule UIs (session 6).
- iOS code (flag #10 deferred).

---

## §3 Pre-flight

```bash
# 1. Repo + branch
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# 2. Confirm sessions 1–4 landed
ls backend/bookings/api/quotes/views.py
ls backend/bookings/api/completion/views.py
ls frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart
ls frontend/lib/core/widgets/map/live_tracking_map.dart

# 3. Backend baseline
cd backend && source venv/bin/activate
pytest -q                               # green baseline
python manage.py check
python manage.py runserver &
sleep 2
# Smoke: confirm submit_quote endpoint reachable
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8000/api/bookings/1/quotes/   # 401 expected
kill %1
cd ..

# 4. Frontend baseline
cd frontend
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs

# 5. Confirm connectivity_plus already in pubspec OR plan to add it
grep -n "connectivity_plus" pubspec.yaml || echo "Will add this session"

# 6. Confirm session 4 widgets compile (sanity)
flutter test test/features/orchestrator/presentation/screens/

# 7. Confirm GoRouter is the navigator (not legacy NavigatorKey)
grep -n "GoRouter" lib/core/routing/app_router.dart | head -3
```

---

## §4 Per-file detailed changes

### §4.0 Action button method extension + modal endpoint registry (touches session 3 work)

**Audit P1-09**: replace the fragile `endpoint.endsWith(...)` chain with an explicit registry. Server emits a well-known **key** (last path segment). Frontend matches against the key set. Mismatches surface at CI time via a parity test.

#### `presentation/providers/modal_endpoint_keys.dart` (new)

**Audit C2-P1-04**: the registry is **split into two sets** to encode the asymmetry between server-emitted modals and client-only modals (e.g. `tech-cancel-confirm` is invoked from the AppBar overflow menu and is never emitted by `orchestrator_ui.py`):

- `serverEmitted` — keys that backend emits in `ui.primary_action` / `ui.secondary_actions`. Must equal backend `ALL_KEYS` exactly. Parity test verifies set equality.
- `all` = `serverEmitted ∪ {client-only}`. Used by the frontend test that asserts every registered key has a `_openModal` handler.

```dart
/// Canonical set of MODAL endpoint keys. Backend's UI selector emits actions
/// whose endpoint ends with `/<key>`; frontend matches against this set.
///
/// **Contract**: when adding a new modal:
///   1. Add the key here.
///   2. Add the case in [_openModal] below.
///   3. If server-emitted: add the same key to backend `modal_endpoints.py`
///      AND include it in [serverEmitted]. CI parity test enforces equality
///      between [serverEmitted] and backend `ALL_KEYS`.
///   4. If client-only (e.g. invoked from overflow): add to [all] only.
abstract class ModalEndpointKeys {
  static const cashCollectionConfirm = 'cash-collection-confirm';
  static const quoteDecline = 'decline';        // matched as endpoint segment after /quotes/<id>/
  static const quoteBargain = 'bargain';
  // Session 6 adds: cancelConfirm, reschedule, noShowConfirm (server-emitted)
  // + techCancelConfirm (client-only).

  /// Server-emitted keys. Must equal backend `ALL_KEYS` exactly.
  /// Used by the bidirectional parity test.
  static const serverEmitted = <String>{
    cashCollectionConfirm,
    quoteDecline,
    quoteBargain,
    // session 6 server-emitted keys appended here.
  };

  /// All keys (server-emitted + client-only). Used by the frontend test that
  /// asserts every registered key has a `_openModal` handler.
  static const all = <String>{
    ...serverEmitted,
    // session 6 client-only keys appended here.
  };
}
```

Helper to extract the key from a server-emitted endpoint string:

```dart
String? extractModalKey(String endpoint) {
  // endpoint is like '/booking/123/cash-collection-confirm' or
  // '/booking/123/quotes/45/decline'. Strip trailing slash, take last segment.
  final clean = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;
  final lastSlash = clean.lastIndexOf('/');
  if (lastSlash < 0) return null;
  return clean.substring(lastSlash + 1);
}
```

#### `presentation/widgets/booking_orchestrator_action_button.dart` (modified)

Extend `_execute` to dispatch on `action.method`. **Audit coupling note**: this widget mixes 3 concerns (HTTP / NAVIGATE / MODAL). The HTTP concern is delegated to `BookingActionExecutor` from session 3; NAVIGATE goes to GoRouter; MODAL goes to the registry below. Three small dispatch arms in one place — readable; splitting into 3 separate widgets would just shuffle the switch.

```dart
Future<void> _execute() async {
  setState(() => _busy = true);
  try {
    switch (widget.action.method.toUpperCase()) {
      case 'NAVIGATE':
        if (mounted) {
          await GoRouter.of(context).push(widget.action.endpoint);
        }
        break;
      case 'MODAL':
        if (mounted) {
          await _openModal(widget.action.endpoint, widget.bookingId);
        }
        break;
      default:
        // HTTP path (POST/GET/PATCH/etc).
        await ref.read(bookingActionExecutorProvider).execute(widget.action);
        if (mounted) {
          // Audit CSC-02: invalidate (event-driven would also fire, but explicit
          // invalidate ensures freshness even if the action's resulting event is
          // delayed or dropped).
          ref.invalidate(bookingDetailNotifierProvider(widget.bookingId));
        }
        break;
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    }
  } finally {
    if (mounted) setState(() => _busy = false);
  }
}

Future<void> _openModal(String endpoint, int bookingId) async {
  final key = extractModalKey(endpoint);
  if (key == null) {
    developer.log('Unparseable MODAL endpoint: $endpoint',
        name: 'orchestrator', level: 1000 /* SEVERE */);
    return;
  }

  // Audit P1-09: explicit key matching, not endsWith chains. Adding a modal
  // means adding a case here AND a key in ModalEndpointKeys; the parity test
  // catches any forgetfulness.
  switch (key) {
    case ModalEndpointKeys.cashCollectionConfirm:
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CashCollectionConfirmModal(bookingId: bookingId),
      );
      break;
    case ModalEndpointKeys.quoteDecline:
      // Endpoint format: /booking/<bid>/quotes/<qid>/decline
      // Extract quoteId from the path.
      final quoteId = _parseQuoteIdFromEndpoint(endpoint);
      if (quoteId == null) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DeclineQuoteModal(bookingId: bookingId, quoteId: quoteId),
      );
      break;
    case ModalEndpointKeys.quoteBargain:
      final quoteId = _parseQuoteIdFromEndpoint(endpoint);
      if (quoteId == null) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => BargainInPersonModal(bookingId: bookingId, quoteId: quoteId),
      );
      break;
    // Session 6 adds more cases.
    default:
      developer.log('Unknown MODAL key "$key" (endpoint=$endpoint). '
                    'Did you forget to add it to ModalEndpointKeys?',
          name: 'orchestrator', level: 900 /* WARNING */);
      return;
  }

  // Refresh after modal closes (modal may have submitted state-changing action).
  if (mounted) {
    ref.invalidate(bookingDetailNotifierProvider(bookingId));
  }
}

int? _parseQuoteIdFromEndpoint(String endpoint) {
  // /booking/<bid>/quotes/<qid>/<key>
  final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
  final quotesIdx = parts.indexOf('quotes');
  if (quotesIdx < 0 || quotesIdx + 1 >= parts.length) return null;
  return int.tryParse(parts[quotesIdx + 1]);
}
```

#### Backend mirror: `backend/bookings/api/modal_endpoints.py` (new)

```python
"""Canonical MODAL endpoint keys. The booking-orchestrator-screen uses
server-emitted MODAL actions whose endpoint string ends with one of these keys.
Frontend dispatches based on the key (see frontend ModalEndpointKeys).
Drift between this file and the frontend ModalEndpointKeys breaks the dispatch
silently — CI parity test enforces both sides agree."""

CASH_COLLECTION_CONFIRM = 'cash-collection-confirm'
QUOTE_DECLINE = 'decline'
QUOTE_BARGAIN = 'bargain'
# Session 6 adds: cancel-confirm, reschedule, no-show-confirm, tech-cancel-confirm.

ALL_KEYS = frozenset({
    CASH_COLLECTION_CONFIRM,
    QUOTE_DECLINE,
    QUOTE_BARGAIN,
})

def cash_collection_endpoint(booking_id: int) -> str:
    return f'/booking/{booking_id}/{CASH_COLLECTION_CONFIRM}'

def quote_decline_endpoint(booking_id: int, quote_id: int) -> str:
    return f'/booking/{booking_id}/quotes/{quote_id}/{QUOTE_DECLINE}'

def quote_bargain_endpoint(booking_id: int, quote_id: int) -> str:
    return f'/booking/{booking_id}/quotes/{quote_id}/{QUOTE_BARGAIN}'
```

`bookings/selectors/orchestrator_ui.py` imports from this module and uses the helper functions when emitting MODAL actions; no string-literal endpoints inside handlers.

#### Parity tests (audit C2-P1-04 — three contracts, ship this session)

**Three** small tests, each enforcing one direction of the contract. Together they catch every drift mode without requiring strict set-equality across the two languages.

1. **Frontend handler-coverage** — `test/features/orchestrator/modal_handler_coverage_test.dart`:

   ```dart
   // Asserts every key in ModalEndpointKeys.all has a handler in _openModal.
   // Drives each key as a synthetic MODAL action through the button widget;
   // asserts no SEVERE log line appears (default branch logs SEVERE on miss).
   ```

2. **Backend emission-coverage** — `tests/bookings/test_modal_endpoints_emission.py`:

   ```python
   # Enumerate every (status, role) handler in orchestrator_ui.py, capture every
   # emitted MODAL endpoint, parse trailing key. Assert each key is in ALL_KEYS.
   # (Catches: a handler emits a typo'd key that isn't registered.)
   ```

3. **Cross-language server-emitted equality** — fixture-based:

   - Backend test `tests/bookings/test_modal_endpoints_export.py` writes `ALL_KEYS` to a JSON fixture (`backend/bookings/api/_modal_keys_export.json`) at test time.
   - Frontend test `test/features/orchestrator/modal_server_emitted_parity_test.dart` reads that fixture and asserts `ModalEndpointKeys.serverEmitted == loaded_set`. (Catches: backend adds a key without frontend, or vice versa.)
   - The fixture is committed; CI fails if the test rewrites it without a corresponding frontend update.

`techCancelConfirm` (session 6) is in `ModalEndpointKeys.all` but NOT in `serverEmitted`, so test #3 doesn't see it; test #1 still verifies it has a handler.

### §4.1 Domain entities

#### `domain/entities/sub_service_catalog_entry.dart`

```dart
@freezed
class SubServiceCatalogEntry with _$SubServiceCatalogEntry {
  const factory SubServiceCatalogEntry({
    required int id,
    required String name,
    required String iconName,
    required bool isFixedPrice,
    required int basePrice,
    int? maxPrice,
  }) = _SubServiceCatalogEntry;
}
```

#### `domain/entities/quote_draft.dart`

```dart
@freezed
class QuoteDraft with _$QuoteDraft {
  const factory QuoteDraft({
    @Default([]) List<QuoteDraftLineItem> lineItems,
    @Default(false) bool isUpsell,
  }) = _QuoteDraft;

  const QuoteDraft._();

  int get totalAmount => lineItems.fold(0, (sum, li) => sum + li.lineTotal);

  bool get isEmpty => lineItems.isEmpty;
}
```

#### `domain/entities/quote_draft_line_item.dart`

```dart
@freezed
class QuoteDraftLineItem with _$QuoteDraftLineItem {
  const factory QuoteDraftLineItem({
    required int subServiceId,
    required String subServiceName,
    required bool isFixedPrice,
    required int basePrice,            // band floor (or fixed price)
    int? maxPrice,                      // band ceiling, null for fixed
    required int quantity,
    required int pricedAt,
  }) = _QuoteDraftLineItem;

  const QuoteDraftLineItem._();

  int get lineTotal => quantity * pricedAt;

  /// True if [pricedAt] is within the catalog band for this sub-service.
  bool get isPriceValid {
    if (isFixedPrice) return pricedAt == basePrice;
    if (maxPrice == null) return pricedAt >= basePrice;
    return pricedAt >= basePrice && pricedAt <= maxPrice!;
  }
}
```

#### `domain/failures/quote_builder_failure.dart`

```dart
sealed class QuoteBuilderFailure implements Exception {
  const QuoteBuilderFailure();
}

class QuoteBandViolation extends QuoteBuilderFailure {
  final int subServiceId;
  final String subServiceName;
  const QuoteBandViolation({required this.subServiceId, required this.subServiceName});
}

class QuoteEmptyRejection extends QuoteBuilderFailure {
  const QuoteEmptyRejection();
}

class QuoteSubmitInvalidTransition extends QuoteBuilderFailure {
  final String currentStatus;
  const QuoteSubmitInvalidTransition({required this.currentStatus});
}

class QuoteSubmitNetworkFailure extends QuoteBuilderFailure {
  const QuoteSubmitNetworkFailure();
}

class QuoteSubmitServerFailure extends QuoteBuilderFailure {
  const QuoteSubmitServerFailure();
}

class UnknownQuoteBuilderFailure extends QuoteBuilderFailure {
  final String message;
  const UnknownQuoteBuilderFailure(this.message);
}
```

(Similar sealed hierarchies for `QuoteDecisionFailure` and `CashCollectionFailure` — each with `…NotAuthorized`, `…InvalidTransition`, `…NetworkFailure`, `…ServerFailure`, `Unknown…`. Keep shape consistent.)

### §4.2 Data models + datasources + repositories

(Sketches — implement following session 3's data-layer pattern.)

#### `data/models/quote_draft_request_model.dart`

```dart
@freezed
class QuoteDraftRequestModel with _$QuoteDraftRequestModel {
  const factory QuoteDraftRequestModel({
    @JsonKey(name: 'is_upsell') required bool isUpsell,
    @JsonKey(name: 'line_items') required List<QuoteLineItemInputModel> lineItems,
  }) = _QuoteDraftRequestModel;
  factory QuoteDraftRequestModel.fromJson(Map<String, dynamic> json) =>
      _$QuoteDraftRequestModelFromJson(json);
}

@freezed
class QuoteLineItemInputModel with _$QuoteLineItemInputModel {
  const factory QuoteLineItemInputModel({
    @JsonKey(name: 'sub_service_id') required int subServiceId,
    required int quantity,
    @JsonKey(name: 'priced_at') required String pricedAt,   // string-decimal per backend §4.2
  }) = _QuoteLineItemInputModel;
  factory QuoteLineItemInputModel.fromJson(Map<String, dynamic> json) =>
      _$QuoteLineItemInputModelFromJson(json);
}
```

Mapper from `QuoteDraft` → `QuoteDraftRequestModel`: trivial; converts `pricedAt: int` → `pricedAt: priceInt.toString()`.

#### `data/datasources/quote_remote_data_source.dart`

**Audit C2-P0-04 + C2-P0-01**: rewritten as `package:http` per §24; URLs drop `/api/`.

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/quote_draft_request_model.dart';

class QuoteRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  QuoteRemoteDataSource(this._client, this._secureStorage);

  Future<int> submitQuote(int bookingId, QuoteDraftRequestModel body) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/quotes/'),
      headers: _headers(token),
      body: jsonEncode(body.toJson()),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['id'] as num).toInt();
  }

  Future<void> approveQuote(int bookingId, int quoteId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/quotes/$quoteId/approve/'),
      headers: _headers(token),
    );
    _ensureOk(response);
  }

  Future<void> declineQuote(int bookingId, int quoteId, String reason) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/quotes/$quoteId/decline/'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    _ensureOk(response);
  }

  Future<void> requestRevision(int bookingId, int quoteId, String reason) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/quotes/$quoteId/request-revision/'),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );
    _ensureOk(response);
  }

  Map<String, String> _headers(String? token) => {
    if (token != null) 'Authorization': 'Token $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? envelope;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) envelope = decoded;
    } catch (_) {}
    throw HttpFailure(
      statusCode: response.statusCode,
      code: envelope?['code'] as String? ?? 'unknown',
      message: envelope?['message'] as String? ?? 'Quote request failed (${response.statusCode}).',
      errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
```

#### `data/datasources/cash_collection_remote_data_source.dart`

**Audit C2-P0-04 + C2-P0-01**: same `http` rewrite + URL fix.

```dart
class CashCollectionRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  CashCollectionRemoteDataSource(this._client, this._secureStorage);

  Future<void> confirmCashReceived(int bookingId, int amount, String method) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/confirm-cash-received/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'amount': amount.toString(), 'method': method}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic>? envelope;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) envelope = decoded;
      } catch (_) {}
      throw HttpFailure(
        statusCode: response.statusCode,
        code: envelope?['code'] as String? ?? 'unknown',
        message: envelope?['message'] as String? ?? 'Cash collection failed.',
        errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
      );
    }
  }
}
```

#### `data/datasources/start_inspection_remote_data_source.dart`

**Audit P0-03**: uses `package:http` per §24. **Audit P1-08**: no longer fire-and-forget — propagates failures so the screen can show a snackbar.

```dart
class StartInspectionRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  StartInspectionRemoteDataSource(this._client, this._secureStorage);

  /// Throws [HttpFailure] on non-2xx; SocketException bubbles. Caller decides
  /// whether to surface a snackbar (audit P1-08; v0.9 swallowed silently).
  Future<void> startInspection(int bookingId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    // Audit C2-P0-01: AppConstants.baseUrl already includes /api.
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/start-inspection/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    // Idempotent endpoint — 200 even when already INSPECTING. Only non-2xx is real failure.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'start_inspection_failed',
        message: 'Could not auto-start inspection.',
      );
    }
  }
}
```

#### `data/datasources/sub_service_catalog_remote_data_source.dart`

**Audit C2-P0-04 + C2-P0-01**: `package:http` + URL fix.

```dart
class SubServiceCatalogRemoteDataSource {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  SubServiceCatalogRemoteDataSource(this._client, this._secureStorage);

  Future<List<SubServiceCatalogEntryModel>> listForService(int serviceId) async {
    final token = await _secureStorage.read(key: 'auth_token');
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/catalog/services/$serviceId/sub-services/'),
      headers: {
        if (token != null) 'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'catalog_fetch_failed',
        message: 'Failed to load sub-services (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['items'] as List)
        .map((e) => SubServiceCatalogEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

#### Repository impls

Standard pattern from session 3: try datasource → catch HttpFailure → map to sealed; catch SocketException → NetworkFailure; catch any → Unknown. Implementation per file.

### §4.3 `quote_builder_notifier.dart`

```dart
@Riverpod(keepAlive: false)
class QuoteBuilderNotifier extends _$QuoteBuilderNotifier {
  @override
  QuoteDraft build({
    required int jobId,
    bool isUpsell = false,
    List<QuoteDraftLineItem> initialLineItems = const [],
  }) {
    return QuoteDraft(lineItems: initialLineItems, isUpsell: isUpsell);
  }

  void addLineItemFromCatalog(SubServiceCatalogEntry entry, {int? defaultRate}) {
    final newLine = QuoteDraftLineItem(
      subServiceId: entry.id,
      subServiceName: entry.name,
      isFixedPrice: entry.isFixedPrice,
      basePrice: entry.basePrice,
      maxPrice: entry.maxPrice,
      quantity: 1,
      pricedAt: defaultRate ?? entry.basePrice,
    );
    state = state.copyWith(lineItems: [...state.lineItems, newLine]);
  }

  void removeLineItem(int subServiceId) {
    state = state.copyWith(
      lineItems: state.lineItems.where((li) => li.subServiceId != subServiceId).toList(),
    );
  }

  void updateLineItemQuantity(int subServiceId, int newQuantity) {
    state = state.copyWith(
      lineItems: state.lineItems.map((li) =>
          li.subServiceId == subServiceId ? li.copyWith(quantity: newQuantity) : li).toList(),
    );
  }

  void updateLineItemPrice(int subServiceId, int newPrice) {
    state = state.copyWith(
      lineItems: state.lineItems.map((li) =>
          li.subServiceId == subServiceId ? li.copyWith(pricedAt: newPrice) : li).toList(),
    );
  }

  /// Returns the sub_service IDs of any line items that violate the price band.
  /// Empty list means OK to submit.
  List<int> validateAllLines() {
    return state.lineItems.where((li) => !li.isPriceValid).map((li) => li.subServiceId).toList();
  }

  /// Submits the quote. Throws QuoteBuilderFailure subtypes on failure.
  /// Returns the new server-issued Quote.id on success.
  Future<int> submit() async {
    if (state.isEmpty) throw const QuoteEmptyRejection();
    final invalid = validateAllLines();
    if (invalid.isNotEmpty) {
      // First violation surfaces; UI should highlight all invalid.
      final first = state.lineItems.firstWhere((li) => li.subServiceId == invalid.first);
      throw QuoteBandViolation(
        subServiceId: first.subServiceId,
        subServiceName: first.subServiceName,
      );
    }
    final repo = ref.read(quoteRepositoryProvider);
    final quoteId = await repo.submitQuote(jobId, state);
    return quoteId;
  }
}
```

### §4.4 `quote_builder_screen.dart`

```dart
class QuoteBuilderScreen extends ConsumerStatefulWidget {
  final int jobId;
  final bool isUpsell;
  const QuoteBuilderScreen({super.key, required this.jobId, this.isUpsell = false});

  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  @override
  void initState() {
    super.initState();
    // Per §14 rule 1: open quote builder = auto ARRIVED → INSPECTING.
    // Audit P1-08: the v0.9 plan was fire-and-forget which silently swallowed
    // real failures (stale booking, network down) — tech sees the builder open,
    // enters line items, then submit_quote 400s with confusing error.
    // Now we await the call and surface failures via snackbar. Orchestrator's
    // idempotency makes "already INSPECTING" a no-op so the await is cheap on
    // the legitimate path.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(startInspectionRemoteDataSourceProvider)
            .startInspection(widget.jobId);
      } catch (e) {
        if (!mounted) return;
        // Soft warning — don't block the builder. If the booking really is in
        // a bad state (terminal, etc.) the eventual submit_quote will reject
        // with a clear error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not auto-mark inspection started. You can still build a quote.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(bookingDetailNotifierProvider(widget.jobId));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpsell ? 'Add to existing quote' : 'Build quote'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load booking.')),
        data: (booking) => _BuilderBody(booking: booking, isUpsell: widget.isUpsell),
      ),
    );
  }
}

class _BuilderBody extends ConsumerWidget {
  final BookingDetail booking;
  final bool isUpsell;
  const _BuilderBody({required this.booking, required this.isUpsell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build initial line items for upsell from the existing BookingItem rows
    // ... actually no, upsell APPENDS rather than re-quotes, so existing items
    // are read-only above; the builder starts empty for the new lines.
    final draftNotifier = ref.read(quoteBuilderNotifierProvider(
      jobId: booking.id,
      isUpsell: isUpsell,
      initialLineItems: const [],
    ).notifier);
    final draft = ref.watch(quoteBuilderNotifierProvider(
      jobId: booking.id,
      isUpsell: isUpsell,
      initialLineItems: const [],
    ));

    return Column(
      children: [
        if (isUpsell)
          UpsellExistingItemsSection(items: booking.bookingItems),
        // Skill chip stack (tech's known skills filtered to booking's service)
        SkillChipStack(
          serviceId: booking.service.id,
          onChipTap: (entry) {
            // Default rate: tech's standing TechnicianSkill.labor_rate.
            // Resolved server-side by mapping their TechnicianSkill rows;
            // expose via a tech-skills provider (read from cached profile).
            draftNotifier.addLineItemFromCatalog(entry, defaultRate: entry.basePrice);
          },
        ),
        // Editable line items
        Expanded(
          child: ListView.builder(
            itemCount: draft.lineItems.length,
            itemBuilder: (_, idx) => LineItemRow(
              item: draft.lineItems[idx],
              onQuantityChanged: (q) => draftNotifier.updateLineItemQuantity(
                draft.lineItems[idx].subServiceId, q),
              onPriceChanged: (p) => draftNotifier.updateLineItemPrice(
                draft.lineItems[idx].subServiceId, p),
              onRemove: () => draftNotifier.removeLineItem(
                draft.lineItems[idx].subServiceId),
            ),
          ),
        ),
        // "+ More services" button → opens SubServicePickerSheet
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('More services'),
          onPressed: () async {
            final entry = await showModalBottomSheet<SubServiceCatalogEntry>(
              context: context,
              isScrollControlled: true,
              builder: (_) => SubServicePickerSheet(serviceId: booking.service.id),
            );
            if (entry != null) draftNotifier.addLineItemFromCatalog(entry);
          },
        ),
        // Sticky-bottom total + submit
        QuoteTotalSummary(
          draft: draft,
          onSubmit: () async {
            try {
              await draftNotifier.submit();
              if (context.mounted) {
                Navigator.of(context).pop();
                // bookingDetailProvider auto-refreshes via quote_generated event.
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_friendlyError(e))),
                );
              }
            }
          },
        ),
      ],
    );
  }

  String _friendlyError(Object e) => switch (e) {
    QuoteEmptyRejection() => 'Add at least one line item before submitting.',
    QuoteBandViolation(:final subServiceName) =>
      'Price for "$subServiceName" is outside the platform-allowed range.',
    QuoteSubmitInvalidTransition(:final currentStatus) =>
      'Cannot submit: booking is in $currentStatus.',
    QuoteSubmitNetworkFailure() => 'Network error; check your connection.',
    QuoteSubmitServerFailure() => 'Server error; try again.',
    _ => 'Could not submit quote.',
  };
}
```

### §4.5 Supporting widgets

#### `presentation/widgets/quote_builder/skill_chip_stack.dart`

Reads tech's known skills from the cached technician profile (existing — consumed via `currentTechnicianSkillsProvider`, which filters to skills matching `serviceId`).

```dart
class SkillChipStack extends ConsumerWidget {
  final int serviceId;
  final void Function(SubServiceCatalogEntry) onChipTap;
  const SkillChipStack({super.key, required this.serviceId, required this.onChipTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(techSkillsForServiceProvider(serviceId));
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: skills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, idx) {
          final s = skills[idx];
          return ActionChip(
            label: Text('${s.subServiceName} — Rs.${s.laborRate}'),
            onPressed: () => onChipTap(SubServiceCatalogEntry(
              id: s.subServiceId,
              name: s.subServiceName,
              iconName: s.iconName,
              isFixedPrice: false,
              basePrice: s.laborRate,
              maxPrice: s.maxPrice,    // from catalog mirror; tech's profile cache must have it
            )),
          );
        },
      ),
    );
  }
}
```

`techSkillsForServiceProvider` is a derived provider over the existing tech profile data — implemented in `presentation/providers/dependency_injection.dart`. If the existing tech-profile model doesn't include `maxPrice` for skills, derive it via the catalog or extend the profile DTO (small follow-up).

#### `presentation/widgets/quote_builder/line_item_row.dart`

Standard rows; numeric stepper for quantity, text-field for price with band hint as helper text. Validation: price field shows error when out of band (color shifts to red, helper text shows "Rs. X – Y").

#### `presentation/widgets/quote_builder/sub_service_picker_sheet.dart`

```dart
class SubServicePickerSheet extends ConsumerWidget {
  final int serviceId;
  const SubServicePickerSheet({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(subServiceCatalogProvider(serviceId));
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load.')),
          data: (entries) => ListView.builder(
            controller: scrollController,
            itemCount: entries.length,
            itemBuilder: (_, idx) {
              final e = entries[idx];
              return ListTile(
                title: Text(e.name),
                subtitle: e.isFixedPrice
                    ? Text('Fixed: Rs.${e.basePrice}')
                    : Text('Rs.${e.basePrice} – Rs.${e.maxPrice ?? "?"}'),
                onTap: () => Navigator.of(context).pop(e),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

#### `presentation/widgets/quote_builder/quote_total_summary.dart`

Sticky-bottom card with total + submit button. Disabled when `draft.isEmpty`.

#### `presentation/widgets/quote_builder/upsell_existing_items_section.dart`

Read-only section above the chip-stack when `is_upsell=true`. Lists existing `BookingItem` rows with prices, total, and a small "Already accepted" badge.

### §4.6 Customer-side approval card

#### `presentation/widgets/quote_approval/quote_approval_card.dart`

```dart
class QuoteApprovalCard extends ConsumerWidget {
  final BookingDetail booking;
  const QuoteApprovalCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = booking.activeQuote!;
    final notifier = ref.watch(quoteDecisionNotifierProvider(booking.id).notifier);
    final state = ref.watch(quoteDecisionNotifierProvider(booking.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quote rev #${quote.revisionNumber}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...quote.lineItems.map((li) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text('${li.subServiceName} × ${li.quantity}')),
                  Text('Rs. ${li.lineTotal}'),
                  if (!_isFixedPrice(li, booking))    // mapper provides this hint
                    BargainCeilingIndicator(line: li, booking: booking),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Total: Rs. ${quote.totalAmount}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // 3 inline action buttons
            FilledButton(
              onPressed: state.isLoading ? null : () => notifier.approve(quoteId: quote.id),
              child: state.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Approve quote'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final reason = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => const BargainInPersonModal(),
                      );
                      if (reason != null) await notifier.requestRevision(quoteId: quote.id, reason: reason);
                    },
                    child: const Text('Bargain in person'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () async {
                      final reason = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => const DeclineQuoteModal(),
                      );
                      if (reason != null) await notifier.decline(quoteId: quote.id, reason: reason);
                    },
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `presentation/widgets/quote_approval/decline_quote_modal.dart`

```dart
class DeclineQuoteModal extends StatefulWidget {
  const DeclineQuoteModal({super.key});
  @override
  State<DeclineQuoteModal> createState() => _DeclineQuoteModalState();
}

class _DeclineQuoteModalState extends State<DeclineQuoteModal> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Decline quote?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('You\'ll only pay the Rs. 500 inspection fee in cash. Tech will leave.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, _ctrl.text),
                child: const Text('Confirm decline'),
              )),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

`BargainInPersonModal` is identical shape with copy: "Want to bargain in person? Tech will be notified to revise their quote after talking to you."

#### `presentation/widgets/quote_approval/bargain_ceiling_indicator.dart`

Small chip rendered next to labor-line items: "Bargain up to Rs. {maxPrice}" (read from `BookingDetail.subService.maxPrice` since it's a per-sub-service property; derive on render).

### §4.7 Cash collection card

#### `presentation/widgets/cash_collection/cash_collection_card.dart`

```dart
class CashCollectionCard extends ConsumerWidget {
  final BookingDetail booking;
  const CashCollectionCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = booking.pricing.finalCashToCollect ?? booking.pricing.baseServicesTotal ?? 0;
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOnline = connectivity == ConnectivityStatus.online;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Job complete', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Total: Rs. $amount (cash)'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: !isOnline
                  ? null
                  : () async {
                      await showModalBottomSheet(
                        context: context,
                        builder: (_) => CashCollectionConfirmModal(
                          bookingId: booking.id,
                          amount: amount,
                        ),
                      );
                    },
              child: Text('Cash Collected: Rs. $amount'),
            ),
            if (!isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Connect to network to confirm cash collection.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            UpsellLink(bookingId: booking.id),
          ],
        ),
      ),
    );
  }
}
```

#### `presentation/widgets/cash_collection/cash_collection_confirm_modal.dart`

```dart
class CashCollectionConfirmModal extends ConsumerWidget {
  final int bookingId;
  final int amount;
  const CashCollectionConfirmModal({super.key, required this.bookingId, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashCollectionNotifierProvider(bookingId));
    final notifier = ref.watch(cashCollectionNotifierProvider(bookingId).notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Confirm Rs. $amount cash received',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('This will mark the job complete. Make sure you have the cash before tapping confirm.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextButton(
                onPressed: state.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              Expanded(child: FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        try {
                          await notifier.confirm(amount: amount, method: 'cash');
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not confirm. Try again.')),
                            );
                          }
                        }
                      },
                child: state.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm'),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### `presentation/widgets/cash_collection/upsell_link.dart`

Small text-button "+ Add more work to this job" that pushes the quote builder with `?upsell=true`.

### §4.8 Receipt card (shared by COMPLETED and COMPLETED_INSPECTION_ONLY)

```dart
class ReceiptCard extends StatelessWidget {
  final BookingDetail booking;
  final bool isInspectionOnly;
  const ReceiptCard({super.key, required this.booking, required this.isInspectionOnly});

  @override
  Widget build(BuildContext context) {
    final cash = booking.cashCollection;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isInspectionOnly ? Icons.assignment : Icons.check_circle,
              color: isInspectionOnly
                  ? Theme.of(context).colorScheme.outline
                  : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              isInspectionOnly
                  ? 'Inspection only — Rs. 500 collected; no work performed.'
                  : 'Job complete — payment received.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (!isInspectionOnly) ...[
              const Text('Work performed:'),
              const SizedBox(height: 8),
              ...booking.bookingItems.map((bi) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${bi.subServiceName} × ${bi.quantity} — Rs. ${bi.lineTotal}'),
              )),
              const Divider(),
            ],
            Row(
              children: [
                const Text('Cash collected: '),
                Text('Rs. ${cash.amount ?? 0}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (cash.at != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'At ${cash.at!.toLocal().toString()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### §4.9 Updated stubs (replace 5 of 13)

#### `InspectingBodyStub` (replaced)

```dart
class InspectingBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const InspectingBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomer = booking.viewerRole == BookingOrchestratorRole.customer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCustomer)
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Technician is on-site. Awaiting their assessment.'),
            ))
          else
            // Tech viewer: builder is on a separate route. Body shows status + nav button.
            Column(
              children: [
                const Card(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('You\'re building a quote. Continue from the quote builder screen.'),
                )),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Continue building quote'),
                  onPressed: () {
                    GoRouter.of(context).push('/booking/${booking.id}/quote-builder');
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
```

#### `QuotedBodyStub` (replaced)

```dart
class QuotedBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const QuotedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.viewerRole == BookingOrchestratorRole.customer) {
      // Customer sees the full approval card inline.
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: QuoteApprovalCard(booking: booking)),
      );
    }
    // Tech viewer: shows quote summary + "awaiting decision" indicator.
    final quote = booking.activeQuote;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote != null) Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quote rev #${quote.revisionNumber} — Rs. ${quote.totalAmount}'),
                  const SizedBox(height: 8),
                  ...quote.lineItems.map((li) => Text('• ${li.subServiceName} × ${li.quantity} — Rs. ${li.lineTotal}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Awaiting customer decision…',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
```

#### `InProgressBodyStub` (replaced)

```dart
class InProgressBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const InProgressBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.viewerRole == BookingOrchestratorRole.technician) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: CashCollectionCard(booking: booking)),
      );
    }
    // Customer viewer: status display + quote summary.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(booking.ui.bodyText),
          )),
          const SizedBox(height: 16),
          if (booking.bookingItems.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Work being performed:'),
                    const SizedBox(height: 8),
                    ...booking.bookingItems.map((bi) =>
                        Text('• ${bi.subServiceName} × ${bi.quantity} — Rs. ${bi.lineTotal}')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

#### `CompletedBodyStub` and `CompletedInspectionOnlyBodyStub` (replaced)

```dart
class CompletedBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const CompletedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: ReceiptCard(booking: booking, isInspectionOnly: false),
      ),
    );
  }
}

class CompletedInspectionOnlyBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const CompletedInspectionOnlyBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: ReceiptCard(booking: booking, isInspectionOnly: true),
      ),
    );
  }
}
```

### §4.10 Connectivity provider

#### `core/network/connectivity_status_provider.dart`

```dart
enum ConnectivityStatus { online, offline }

@Riverpod(keepAlive: true)
Stream<ConnectivityStatus> connectivityStatusStream(Ref ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((results) {
    // results is List<ConnectivityResult> in connectivity_plus 6.x
    return results.any((r) =>
        r == ConnectivityResult.wifi
        || r == ConnectivityResult.mobile
        || r == ConnectivityResult.ethernet)
      ? ConnectivityStatus.online
      : ConnectivityStatus.offline;
  });
}

@Riverpod(keepAlive: true)
ConnectivityStatus connectivityStatus(Ref ref) {
  final asyncStatus = ref.watch(connectivityStatusStreamProvider);
  return asyncStatus.maybeWhen(
    data: (status) => status,
    orElse: () => ConnectivityStatus.online,    // optimistic on initial load
  );
}
```

Add `connectivity_plus: ^6.0.0` to `pubspec.yaml`.

### §4.11 Routing

```dart
GoRoute(
  path: '/booking/:job_id/quote-builder',
  name: 'quote_builder',
  builder: (context, state) {
    final jobId = int.parse(state.pathParameters['job_id']!);
    final isUpsell = state.uri.queryParameters['upsell'] == 'true';
    return QuoteBuilderScreen(jobId: jobId, isUpsell: isUpsell);
  },
),
```

### §4.12 Backend: catalog endpoint

#### `backend/catalog/api/sub_services_by_service/views.py`

```python
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from catalog.models import Service, SubService
from .serializers import SubServiceListItemSerializer


class SubServicesByServiceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, service_id: int):
        try:
            Service.objects.only('id').get(id=service_id)
        except Service.DoesNotExist:
            return Response({'status': 404, 'code': 'not_found', 'message': 'Service not found.'}, status=404)
        items = SubService.objects.filter(service_id=service_id, is_active=True).order_by('name')
        return Response({
            'items': SubServiceListItemSerializer(items, many=True).data,
        }, status=200)
```

#### `backend/catalog/api/sub_services_by_service/serializers.py`

```python
class SubServiceListItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubService
        fields = ['id', 'name', 'icon_name', 'is_fixed_price', 'base_price', 'max_price']
```

Add to `catalog/api/urls.py`:

```python
path('services/<int:service_id>/sub-services/', SubServicesByServiceView.as_view(), name='sub-services-by-service'),
```

---

## §5 Gotchas

1. **`BookingActionExecutor.MODAL` endpoint patterns** are an informal contract between server and frontend. Document them in `ORCHESTRATOR_FEATURE.md` so future server changes don't break frontend matching. v1 endpoints: `/booking/:job_id/cash-collection-confirm`, `/booking/:job_id/quotes/:quote_id/decline`, `/booking/:job_id/quotes/:quote_id/bargain`.
2. **Quote builder fires `start-inspection` from `initState`**, not from a button. If the call fails (booking already past ARRIVED — e.g., tech crashed mid-builder and reopens), backend returns 400; client swallows. Don't show an error banner for this case.
3. **`SubService.max_price` is null for fixed-price** items per session 1 §4.2. Frontend's `QuoteDraftLineItem.isPriceValid` handles both branches; frontend's chip-stack and picker-sheet show the band correctly.
4. **`techSkillsForServiceProvider` filters tech's skills to the booking's service category.** If tech has skills in multiple services, only matching ones appear in the chip stack. The "+" button surfaces the rest of the booking's service category.
5. **Quote submission triggers `quote_generated` event** which the orchestrator's events notifier (session 3) catches and refreshes detail. After submitting, navigate the builder back to the orchestrator screen — the screen is already showing QUOTED status by the time the user lands.
6. **Customer's QuoteApprovalCard renders inline in BodySlot.** The orchestrator's `PrimaryActionSlot` is empty for QUOTED + customer (no server-emitted primary action). Verify session 2's `orchestrator_ui` selector emits `primary_action: null` for this state.
7. **Bargain/Decline modals return `String?`** (the optional reason) via `Navigator.pop(context, _ctrl.text)`. Empty string OK; null means user cancelled.
8. **Cash collection's "amount"** is `final_cash_to_collect` if non-null, else `base_services_total` if non-null, else 0. Order matters per session 1's pricing semantics.
9. **`connectivity_plus` v6 returns `List<ConnectivityResult>`** (changed from single value). The provider above handles both old + new; double-check the actual installed version and adjust.
10. **Upsell quote builder's "existing items"** are read-only — tech sees what was already accepted, then adds NEW lines. They cannot edit prior lines (those are settled). Backend's `submit_quote` with `is_upsell=true` appends the new lines on customer approval.
11. **Quote bargain is uncapped** per sprint meta §6 — there's no client-side limit on revisions. After 3+ revisions the UI may feel cluttered for the customer; that's a polish concern for later.
12. **`receipt_card.dart`** for COMPLETED uses `booking.bookingItems` (the snapshotted accepted line items). For COMPLETED_INSPECTION_ONLY, `booking.bookingItems` is empty (no quote was approved); the receipt only shows the inspection fee.
13. **Quote builder's "Submit" button is enabled only when `!draft.isEmpty && allLinesValid`**. The notifier's `validateAllLines()` returns the violating sub_service IDs; the row UI highlights them.
14. **`startInspection` is fire-and-forget** but on Android with poor connectivity it can fail. The orchestrator's `bookingDetailNotifierProvider` re-fetches on quote_generated; if status is still ARRIVED when the quote arrives, backend's `submit_quote` will fail with `invalid_transition`. Frontend surfaces "Submit failed: booking is in ARRIVED" snackbar. Tech can re-submit (which retries `start-inspection` first via the notifier or via reload).
15. **Mid-job upsell while customer is offline**: tech submits the upsell quote → status flips to QUOTED → customer never sees it (no realtime). When customer comes online, eventSync replays missed events, customer's screen rebuilds, approval card appears. Verified by session 3's eventSync logic.
16. **GoRouter pushes vs replaces**: the quote builder is `push`ed (so back button returns to orchestrator screen). On submit success, `Navigator.of(context).pop()` returns. Don't replace — losing the orchestrator screen would force a re-mount when the user returns.
17. **Catalog endpoint pagination**: not implemented this session (sub-services per service are typically <30). If a category exceeds 50, add cursor pagination later. Document.
18. **`SubService.is_active` filter** in the catalog endpoint — tech shouldn't see deactivated sub-services. If session 1's migration didn't set `is_active=True` defaults correctly, catalog queries may return empty. Verify.
19. **Decline reason vs request-revision reason**: both are stored in `Quote.decision_reason` (session 1 §6 schema). Backend distinguishes by the endpoint called, not by the reason text. Frontend should make the modal copy distinct so the user knows what they're triggering.
20. **`UpsellLink`** is small and easy to miss — that's intentional. The primary path is "Cash Collected"; upsell is the rare case. Don't make it a button as prominent as the cash button.

---

## §6 Verification

### Static checks

```bash
cd frontend
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
```

### Backend

```bash
cd backend
pytest tests/catalog/test_api_sub_services_by_service.py -v
pytest -q       # full suite green
```

### Manual end-to-end (happy path with bargain)

1. Backend running, Android device with `--dart-define=MAP_PROVIDER=osm`.
2. Customer logs in, books, tech accepts.
3. Tech walks through EN_ROUTE → ARRIVED (session 4 verified live tracking).
4. Tech taps "Build quote" on ArrivedBodyStub → quote builder opens.
5. **Verify**: status flips to INSPECTING in backend (check Django logs); orchestrator's body for tech now reads "Continue building quote".
6. Tech taps a skill chip (say "AC Wash – Rs.1500") → line item appears at default price.
7. Tech adjusts quantity to 1 (default), price stays Rs. 1500. Total updates.
8. Tap "+ More services" → picker sheet shows other AC sub-services. Tech taps "AC Refill" → second line appears.
9. Tech taps "Submit quote".
10. **Verify**: customer's screen refreshes (quote_generated event); QuotedBodyStub renders QuoteApprovalCard with both line items, total, and 3 buttons.
11. Customer taps "Bargain in person" → modal opens. Customer enters "Can you do it for less?" and confirms.
12. **Verify**: tech's screen refreshes (quote_revision_requested event); body shows "Continue building quote"; tap → builder pre-loaded with previous quote (or empty? — verify behavior matches design choice in §4.3).
13. Tech adjusts AC Wash to Rs. 1300, resubmits.
14. Customer sees the new quote (revision 2). Customer taps "Approve quote".
15. **Verify**: status flips to IN_PROGRESS; tech's screen shows CashCollectionCard with "Cash Collected: Rs. 1700" button.
16. Tech does the work (manual delay).
17. Tech turns OFF wifi/data → CashCollectionCard's button disables, banner appears.
18. Tech turns network back ON → button re-enables.
19. Tech taps "Cash Collected: Rs. 1700" → confirmation modal → tap "Confirm".
20. **Verify**: status flips to COMPLETED; both screens show ReceiptCard with line items + total + cash collected timestamp.

### Edge: decline → COMPLETED_INSPECTION_ONLY

1. From step 11 above, customer taps "Decline" instead of "Bargain in person".
2. Decline modal opens; customer enters "Too expensive" and confirms.
3. **Verify**: status flips to COMPLETED_INSPECTION_ONLY; body shows ReceiptCard with the inspection-only copy and "Cash collected: Rs. 500".

### Edge: upsell during IN_PROGRESS

1. From step 15 above, tech taps the small "+ Add more work" link in CashCollectionCard.
2. Quote builder opens with `?upsell=true`. UpsellExistingItemsSection appears at top showing the already-accepted items.
3. Tech adds "AC Refill +" line, submits.
4. **Verify**: status flips back to QUOTED; customer sees QuoteApprovalCard with the upsell quote.
5. Customer approves; status flips to IN_PROGRESS; tech sees CashCollectionCard with the new total.

### Constraint checks

```bash
# No status branching in widgets except the one in BodySlot (session 3)
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/presentation/
# Expected: 1 hit (body_slot.dart)

# No /api/ URL strings in widgets — endpoints flow from server
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/
# Expected: empty (URLs live in datasources)

# Cash collection is single combined endpoint per §14 rule 2
grep -rn "/mark-complete/" frontend/lib/features/orchestrator/
# Expected: empty (combined into /confirm-cash-received/)
```

---

## §7 What this session does NOT fix

- Cancellation / no-show / dispute / reschedule UIs — session 6.
- SLA countdown polish for AWAITING — session 6.
- AI chatbot intake — future sprint (form-intake stub via session 6).
- Reviews / ratings — future sprint.
- Real wallet writes — finance sprint.
- Editable cash amount (partial payment) — out of v1.
- Bargain revision cap (3 max?) — uncapped per sprint meta §6.
- Quote builder catalog pagination — future sprint when categories exceed 50.
- Upsell quote builder showing PRIOR quote line items as starting point (vs blank slate) — design decision: blank slate this sprint; revisit if confusing.
- Receipt PDF / share — out of v1.
- Tech-side standing-rate edit shortcut from chip stack — future polish.
- iOS UI tweaks for non-Material design — flag #10 deferred.

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All new files under `backend/catalog/api/sub_services_by_service/` created.
- [ ] All new files under `frontend/lib/features/orchestrator/data/` (datasources + models + repositories) created.
- [ ] All new files under `frontend/lib/features/orchestrator/domain/` created.
- [ ] All new presentation files (providers + screens + widgets) created.
- [ ] `BookingActionExecutor` extended for NAVIGATE + MODAL methods.
- [ ] `connectivity_plus` added to `pubspec.yaml`; provider wrapped.
- [ ] 5 stub bodies replaced (`InspectingBodyStub`, `QuotedBodyStub`, `InProgressBodyStub`, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub`).
- [ ] GoRouter route `/booking/:job_id/quote-builder` registered.
- [ ] `ORCHESTRATOR_FEATURE.md` updated with quote flow + cash collection sections + modal endpoint registry.

### Tests

- [ ] `pytest -q` (backend) green.
- [ ] `flutter test` green on the full suite.
- [ ] Quote repository tests cover all 4 operations × failure branches.
- [ ] Cash collection repository tests cover happy + failure branches.
- [ ] Catalog repository tests cover happy + 404.
- [ ] Quote builder notifier tests cover add/remove/edit/validate/submit.
- [ ] Quote builder screen widget test pumps the screen with mocked providers and verifies chip-tap → row added.
- [ ] Quote approval card widget test verifies all 3 buttons present and tappable; modals open.
- [ ] Cash collection card test verifies button enabled/disabled by connectivity.
- [ ] Receipt card test verifies both terminal status renderings.
- [ ] Action button test extended for NAVIGATE + MODAL.

### Constraints

- [ ] Single switch on `BookingStatus` in `BodySlot` (session 3 invariant; verify still single).
- [ ] No widgets construct `/api/` URLs.
- [ ] No widgets import Dio directly (note: codebase uses `package:http`, not Dio — this checklist item is a defensive scan in case stale Dio leaks into a copy-paste).
- [ ] All money values use typed `int` (rupees) in domain; string-decimals only at the wire boundary.
- [ ] All sealed failure types are caught and surfaced with friendly copy in the corresponding widget's error path.
- [ ] No state mutations outside notifiers — widgets are dumb.

### flag.md

- [ ] No new flags from this session (per sprint meta §20 — session 5 row is "—" / "—").

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` includes the modal endpoint registry, the quote flow narrative, the cash collection narrative, and the upsell semantics.
- [ ] CLAUDE.md may need a small note on the modal-endpoint pattern; one-paragraph addition under the per-event feature wiring section.

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): quote builder + customer approval + cash collection (sprint v1, session 5)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] `git status` clean after commit.
