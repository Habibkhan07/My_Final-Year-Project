# Session 5a — Quote Authoring (Tech Side)

> **Supersedes the first half of [`session_5_quote_flow_and_cash_collection.md`](./session_5_quote_flow_and_cash_collection.md).** Session 5 was split into two sub-sessions to keep human-in-the-loop decision density manageable. The parent spec is preserved as historical reference; this file is authoritative for what 5a ships, and [`session_5b_customer_approval_and_cash.md`](./session_5b_customer_approval_and_cash.md) is authoritative for what 5b ships.
>
> **5a scope (this file):** the tech-facing half of the quote flow — quote builder screen, chip-stack, line-item editing, sub-service catalog browse, `start_inspection` auto-flip on builder mount, submit. Stops at status `QUOTED`. The customer never sees the approval card in 5a — `QuotedBodyStub` keeps the v0 placeholder for the customer path until 5b.
>
> **5b scope (sibling):** customer-side approval (3 actions), cash collection (single-tap + offline hard-block), receipt cards for both terminal statuses, mid-job upsell, modal endpoint registry.

---

## §0 Sprint context

This is **session 5a of the post-split 8-session plan** (1, 2, 3, 4, 5a, 5b, 6a, 6b). Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–4 invariants are carried over from the parent spec §0 verbatim — read them there.

What 5a ends on: tech can build a quote and submit it. Backend creates a `Quote` row, status flips `INSPECTING → QUOTED`, both screens observe the new status. Customer sees a placeholder `QuotedBodyStub`; tech sees an "awaiting customer decision" tech-path body. End-to-end approval/cash/receipt is 5b's job.

What 5a does NOT ship that the parent session 5 promised:
- Customer's `QuoteApprovalCard` (5b)
- Cash collection card + confirm modal (5b)
- Receipt cards (5b)
- Mid-job upsell link in cash card (5b)
- Connectivity provider + offline hard-block on cash (5b)
- Modal endpoint registry foundation + parity tests (5b — moved here from parent §4.0 because 5a has zero MODAL features; NAVIGATE is enough for the quote-builder route)
- `quote_decision_notifier`, `cash_collection_notifier` (5b)

---

## §1 Decisions taken (subset of parent §1; numbers preserved)

Carried over from parent session 5 §1, scoped to 5a:

1. **Quote builder is a separate full-screen route** at `/booking/:job_id/quote-builder`, not a modal sheet. (Parent §1.1.)
2. **Builder mounts → `await`s `start_inspection`** per audit P1-08 (parent §1.17 / §1.2). On failure shows a soft snackbar but lets the builder open — orchestrator's idempotency makes "already INSPECTING" a no-op so the await is cheap on the legitimate path.
3. **`BookingActionExecutor` extended for NAVIGATE method only in 5a.** MODAL support deferred to 5b along with the registry. (Parent §1.3 — split across 5a/5b.)
10. **Quote builder's chip stack** shows tech's `TechnicianSkill` rows filtered to the booking's `Service`. (Parent §1.10.)
11. **Catalog endpoint** `GET /api/catalog/services/<id>/sub-services/`. (Parent §1.11.)
12. **Skill chips show pre-filled labor rate** equal to `TechnicianSkill.labor_rate`. Tech can adjust per-line. Backend's band validation (session 1 §6) is the source of truth; frontend mirrors for instant feedback. (Parent §1.12.)
13. **Quote builder is exhaustively tested** — chip-stack, line-item edit, validation, submit. (Parent §1.13.)
14. **Bargain return navigation (tech side)**: when `quote_revision_requested` event arrives, server flips `INSPECTING`; the `InspectingBodyStub` for tech (shipped here) renders a "Continue building quote" button → NAVIGATE to the builder. The customer-side modal that *fires* the event is 5b's deliverable. (Parent §1.14 — split across 5a/5b.)

17. **Audit-cycle-1 fixes (5a portion)**:
    - **P0-03 / §24 transport**: `package:http` (not Dio) in all 5a data sources; URLs do not include `/api/` (it's already in `AppConstants.baseUrl`).
    - **P1-08 await `start_inspection`**: drop fire-and-forget; await + snackbar on failure.
    - P1-09 modal endpoint registry — DEFERRED to 5b.

Decisions deferred to 5b: 4, 5, 6, 7, 8, 9, 15, 16, the 5b-portion of 3 (MODAL method + `_openModal` helper + modal endpoint registry foundation), and the 5b-portion of 14 (customer-side `BargainInPersonModal` triggering `quote_revision_requested`).

---

## §2 Files this session touches

### Backend (5 files, all from parent §2)

| File | Status | Purpose |
|---|---|---|
| `backend/catalog/api/sub_services_by_service/views.py` | **new** | `GET /api/catalog/services/<service_id>/sub-services/`. |
| `backend/catalog/api/sub_services_by_service/serializers.py` | **new** | List serializer (id, name, base_price, max_price, is_fixed_price, icon_name). |
| `backend/catalog/api/urls.py` | **modified** | Wire the new endpoint. |
| `backend/catalog/api/SEARCH_API.md` | **modified or new** | Document the new endpoint. |
| `backend/tests/catalog/test_api_sub_services_by_service.py` | **new** | Auth + happy + 404 (service not found) tests. |

### Frontend domain (9 files)

| File | Purpose |
|---|---|
| `domain/entities/sub_service_catalog_entry.dart` | Freezed entity for catalog browse results. |
| `domain/entities/quote_draft.dart` | In-progress quote being built. |
| `domain/entities/quote_draft_line_item.dart` | Single in-progress line item. |
| `domain/failures/quote_builder_failure.dart` | Sealed failures: `QuoteBandViolation`, `QuoteEmptyRejection`, `QuoteSubmitInvalidTransition`, `QuoteSubmitNetworkFailure`, `QuoteSubmitServerFailure`, `UnknownQuoteBuilderFailure`. |
| `domain/failures/quote_decision_failure.dart` | Sealed failures for approve / decline / requestRevision: `QuoteDecisionNotAuthorized`, `QuoteDecisionInvalidTransition`, `QuoteDecisionNetworkFailure`, `QuoteDecisionServerFailure`, `UnknownQuoteDecisionFailure`. **Lives in 5a** (not 5b) because 5a's `quote_repository_impl` ships all 4 ops and the decision-path branches must map to a real sealed type — without this file in 5a, the impl wouldn't compile cleanly. 5b consumes this file for its 3 decision use cases. |
| `domain/repositories/quote_repository.dart` | Interface declares ALL FOUR ops (`submitQuote`, `approveQuote`, `declineQuote`, `requestRevision`). 5a consumes only `submitQuote`; 5b consumes the rest. Shipping the full interface keeps 5a's impl file complete. |
| `domain/repositories/sub_service_catalog_repository.dart` | Interface (`listForService`). |
| `domain/use_cases/submit_quote_use_case.dart` | Wraps `repository.submitQuote`. |
| `domain/use_cases/list_sub_services_use_case.dart` | Wraps `repository.listForService`. |

### Frontend data (7 files)

| File | Purpose |
|---|---|
| `data/models/quote_draft_request_model.dart` | DTO for `POST /quotes/` body. Includes `QuoteLineItemInputModel` (string-decimal `priced_at` per backend wire contract). |
| `data/models/sub_service_catalog_entry_model.dart` | DTO for catalog browse responses. |
| `data/datasources/quote_remote_data_source.dart` | Ships with all 4 methods (submit, approve, decline, requestRevision). 5a tests cover submit branches only; 5b adds tests for the others. |
| `data/datasources/sub_service_catalog_remote_data_source.dart` | `GET /catalog/services/<id>/sub-services/`. |
| `data/datasources/start_inspection_remote_data_source.dart` | `POST /bookings/<id>/start-inspection/`; awaitable per audit P1-08. |
| `data/repositories/quote_repository_impl.dart` | Implements all 4 ops. `submitQuote` maps `HttpFailure` → sealed `QuoteBuilderFailure`; `approveQuote` / `declineQuote` / `requestRevision` map `HttpFailure` → sealed `QuoteDecisionFailure`. Both failure types are 5a-shipped (see domain table). Only `submitQuote` is reached via 5a UI; the decision ops are wired by 5b's notifier. |
| `data/repositories/sub_service_catalog_repository_impl.dart` | Same shape. |

(No new mappers in 5a.)

### Frontend presentation

| File | Status | Purpose |
|---|---|---|
| `presentation/providers/dependency_injection.dart` | **modified** | Register `quoteBuilderNotifier`, `subServiceCatalogProvider`, `startInspectionRemoteDataSourceProvider`, `quoteRepositoryProvider`, `subServiceCatalogRepositoryProvider`. (5b will append cash + decision providers.) |
| `presentation/providers/quote_builder_notifier.dart` | **new** | Holds `QuoteDraft` state; add/remove/edit line items; submit. |
| `presentation/providers/sub_service_catalog_provider.dart` | **new** | `family<int>` (serviceId) — catalog browse list. |
| `presentation/screens/quote_builder_screen.dart` | **new** | Full screen at `/booking/:job_id/quote-builder`. |
| `presentation/widgets/quote_builder/skill_chip_stack.dart` | **new** | |
| `presentation/widgets/quote_builder/line_item_row.dart` | **new** | |
| `presentation/widgets/quote_builder/sub_service_picker_sheet.dart` | **new** | |
| `presentation/widgets/quote_builder/quote_total_summary.dart` | **new** | |
| `presentation/widgets/quote_builder/upsell_existing_items_section.dart` | **new** | Read-only section visible when `is_upsell=true` (the `?upsell=true` query param routes here from 5b's `UpsellLink`). |
| `presentation/widgets/booking_orchestrator_action_button.dart` | **modified** | Add `NAVIGATE` case in `_execute` switch. The MODAL case + `_openModal` helper are 5b. |
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | Replace `InspectingBodyStub` (both viewer roles, including the tech "Continue building quote" button per decision 14). Replace `QuotedBodyStub` tech-path only; leave customer-path as the v0 placeholder until 5b. |
| `core/routing/app_router.dart` | **modified** | Add `/booking/:job_id/quote-builder` route (NAVIGATE-routed). |

### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Add quote builder section (data flow, audit fix notes, route). |

### Tests (6 files)

| File | Purpose |
|---|---|
| `test/features/orchestrator/data/repositories/quote_repository_impl_test.dart` | submit branches × failure types (`QuoteBandViolation`, `QuoteEmptyRejection`, `QuoteSubmitInvalidTransition`, `QuoteSubmitNetworkFailure`, `QuoteSubmitServerFailure`). 5b appends the decision-path branches. |
| `test/features/orchestrator/data/repositories/sub_service_catalog_repository_impl_test.dart` | Happy + 404 + network failure. |
| `test/features/orchestrator/presentation/providers/quote_builder_notifier_test.dart` | Add/remove/edit line items; total recompute; band validation; submit success; submit empty rejection; submit band violation. |
| `test/features/orchestrator/presentation/screens/quote_builder_screen_test.dart` | Pumps screen with mocked providers; chip-tap → row added; total updates; submit fires datasource. Verifies `start_inspection` is awaited from `initState` and a snackbar appears on failure (audit P1-08 regression). |
| `test/features/orchestrator/presentation/widgets/booking_orchestrator_action_button_test.dart` | **modified** | Adds NAVIGATE-method test. MODAL coverage tests are 5b's responsibility. |
| `backend/tests/catalog/test_api_sub_services_by_service.py` | (already listed above.) |

### Files NOT touched in 5a

- All session 1–4 work.
- `quote_decision_*`, `cash_collection_*`, `connectivity_*`, `receipt_*`, `quote_approval/*`, `cash_collection/*`, `receipts/*` (5b).
- Modal registry foundation + parity tests (5b).
- Cancellation / reschedule / no-show / dispute (sessions 6a/6b).
- iOS code (flag #10).

---

## §3 Pre-flight

```bash
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# Sessions 1–4 confirmed
ls backend/bookings/api/quotes/views.py
ls frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart
ls frontend/lib/core/widgets/map/live_tracking_map.dart

# Backend baseline
cd backend && source venv/bin/activate
pytest -q
python manage.py check
cd ..

# Frontend baseline
cd frontend
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs

# GoRouter sanity
grep -n "GoRouter" lib/core/routing/app_router.dart | head -3
```

---

## §4 Per-file detailed changes

For full code blocks, see the parent spec [`session_5_quote_flow_and_cash_collection.md`](./session_5_quote_flow_and_cash_collection.md). The sub-sections that apply to 5a:

- **Parent §4.1** — domain entities (`sub_service_catalog_entry`, `quote_draft`, `quote_draft_line_item`) **and BOTH the `QuoteBuilderFailure` and `QuoteDecisionFailure` sealed hierarchies** (the latter follows the `…NotAuthorized` / `…InvalidTransition` / `…NetworkFailure` / `…ServerFailure` / `Unknown…` shape described in parent §4.1). The `CashCollectionFailure` hierarchy in the same parent section is 5b.
- **Parent §4.2** — data layer for `quote_draft_request_model`, `sub_service_catalog_entry_model`, `quote_remote_data_source` (the file ships with all 4 methods — 5a's tests cover only `submitQuote`), `start_inspection_remote_data_source`, `sub_service_catalog_remote_data_source`, `quote_repository_impl` (impl has all 4 ops; only submit consumed by 5a UI), `sub_service_catalog_repository_impl`. Skip the cash + decision DTOs/datasources (5b).
- **Parent §4.3** — `quote_builder_notifier.dart` in full.
- **Parent §4.4** — `quote_builder_screen.dart` in full. Note the `WidgetsBinding.instance.addPostFrameCallback` block that `await`s `startInspection` and surfaces the soft snackbar (audit P1-08).
- **Parent §4.5** — supporting widgets (`skill_chip_stack`, `line_item_row`, `sub_service_picker_sheet`, `quote_total_summary`, `upsell_existing_items_section`) in full.
- **Parent §4.9** — `InspectingBodyStub` in full (both viewer paths). `QuotedBodyStub` tech-path only — keep the customer-path placeholder from session 3.
- **Parent §4.11** — routing entry for `/booking/:job_id/quote-builder`.
- **Parent §4.12** — backend catalog endpoint in full.

### 5a's `BookingOrchestratorActionButton._execute` — NAVIGATE only

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
      // 5b adds: case 'MODAL': await _openModal(...);
      default:
        // HTTP path (POST/GET/PATCH/etc).
        await ref.read(bookingActionExecutorProvider).execute(widget.action);
        if (mounted) {
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
```

5b's edit appends the `MODAL` case + the `_openModal` helper + the `_parseQuoteIdFromEndpoint` helper.

---

## §5 Gotchas (subset of parent §5)

Parent gotchas that apply to 5a (numbers preserved):

2. Quote builder fires `start-inspection` from `initState` and `await`s it (audit P1-08). Don't show a hard error banner — soft snackbar so the builder still opens.
3. `SubService.max_price` is null for fixed-price items. `QuoteDraftLineItem.isPriceValid` handles both branches.
4. `techSkillsForServiceProvider` filters tech's skills to the booking's `Service` category. The "+" button surfaces the rest of the catalog.
5. Quote submission triggers `quote_generated` event; the orchestrator's events notifier (session 3) catches it and refreshes detail. After submit, `Navigator.of(context).pop()` returns to the orchestrator screen.
10. Upsell quote builder's "existing items" are read-only — tech sees what was already accepted, then adds NEW lines. They cannot edit prior lines. (The link that gets you here is in 5b; 5a wires the receiving builder.)
13. Quote builder's "Submit" button is enabled only when `!draft.isEmpty && allLinesValid`. The notifier's `validateAllLines()` returns the violating sub_service IDs; the row UI highlights them.
14. `startInspection` failure is non-blocking. If status is still `ARRIVED` when the quote arrives, backend's `submit_quote` rejects with `invalid_transition` and the snackbar surfaces.
16. GoRouter pushes vs replaces: builder is `push`ed (back button returns to orchestrator). On submit success, `Navigator.of(context).pop()` returns. Don't replace.
17. Catalog endpoint pagination not implemented (sub-services per service typically <30).
18. `SubService.is_active` filter — tech shouldn't see deactivated sub-services.

Gotchas deferred to 5b: 1 (modal endpoint patterns), 6 (customer QUOTED inline), 7 (modal pop returning `String?`), 8 (cash amount fallback), 9 (`connectivity_plus` v6), 11 (bargain uncapped), 12 (`receipt_card` items), 15 (mid-job upsell while customer offline), 19 (decline vs revision reason), 20 (`UpsellLink` discoverability).

---

## §6 Verification

### Static checks

```bash
cd frontend
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
cd ../backend
pytest tests/catalog/test_api_sub_services_by_service.py -v
pytest -q
```

### Manual smoke — 5a tech-side flow

1. Backend running, customer + tech logged in.
2. Walk through CONFIRMED → EN_ROUTE → ARRIVED via session 4.
3. Tech taps the action button on `ArrivedBodyStub` that NAVIGATEs to `/booking/<id>/quote-builder`.
4. **Verify**: builder opens; backend log shows `start_inspection` fired; status flips to `INSPECTING`. (Tech is on the builder screen at this point, NOT the orchestrator screen — the "Continue building quote" prose only appears on the orchestrator's `InspectingBodyStub` for tech if you back out, which is the next step's verification path.)
5. Tech taps a skill chip → line item appears at default rate. Adjust quantity / price; total updates.
6. Tap "+ More services" → picker sheet shows other sub-services; pick one → second line appears.
7. Tap "Submit quote".
8. **Verify**: backend creates `Quote` row; status flips to `QUOTED`; both screens refresh via `quote_generated`. Tech sees the "awaiting customer decision" body. Customer sees the v0 placeholder for `QuotedBodyStub` (will become `QuoteApprovalCard` in 5b).
9. End of 5a demo.

### Constraint checks

```bash
# Single switch on BookingStatus across the orchestrator
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/presentation/
# Expected: 1 hit (body_slot.dart)

# No /api/ URL strings in widgets — endpoints flow from server / data sources
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/
# Expected: empty

# No Dio leaks
grep -rn "package:dio" frontend/lib/features/orchestrator/data/datasources/
# Expected: empty (audit P0-03)
```

---

## §7 What this session does NOT fix

Defer to 5b:
- Customer's `QuoteApprovalCard` and the 3-action approve/decline/bargain flow.
- `DeclineQuoteModal`, `BargainInPersonModal`, `BargainCeilingIndicator`.
- `CashCollectionCard`, `CashCollectionConfirmModal`, `UpsellLink`.
- `ReceiptCard` for both terminal statuses.
- Connectivity provider + offline hard-block on cash collection.
- Modal endpoint registry foundation + parity tests + `_openModal` switch.
- `quote_decision_notifier`, `cash_collection_notifier`.
- Stubs: `QuotedBodyStub` customer-path, `InProgressBodyStub`, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub`.

Defer to sessions 6a/6b: cancellation, reschedule, no-show, dispute, SLA countdown polish, terminal stubs.

Defer to future sprints: AI chatbot intake, reviews/ratings, real wallet writes, editable cash, bargain cap, catalog pagination, tech-side standing-rate edit shortcut, iOS UI tweaks.

---

## §8 Definition of done

### Code

- [ ] All new files under `backend/catalog/api/sub_services_by_service/` created and tested.
- [ ] Quote authoring domain (8 files) created.
- [ ] Quote authoring data (8 files) created.
- [ ] `quote_builder_notifier`, `sub_service_catalog_provider`, `quote_builder_screen` created.
- [ ] 5 builder widgets created.
- [ ] `BookingOrchestratorActionButton` extended for NAVIGATE method.
- [ ] `app_router.dart` route `/booking/:job_id/quote-builder` registered.
- [ ] `InspectingBodyStub` replaced (both viewer roles).
- [ ] `QuotedBodyStub` tech-path replaced (customer-path remains v0 placeholder).
- [ ] `dependency_injection.dart` registers all 5a providers.
- [ ] `ORCHESTRATOR_FEATURE.md` quote-builder section drafted.

### Tests

- [ ] `pytest -q` (backend) green.
- [ ] `flutter test` green.
- [ ] `quote_repository_impl_test.dart` covers submit branches.
- [ ] `sub_service_catalog_repository_impl_test.dart` covers happy + 404 + network.
- [ ] `quote_builder_notifier_test.dart` covers add/remove/edit/validate/submit.
- [ ] `quote_builder_screen_test.dart` verifies chip-tap → row added; submit fires datasource; `start_inspection` await + snackbar on failure (audit P1-08 regression).
- [ ] Action button NAVIGATE test passes.

### Constraints

- [ ] Single `switch (booking.status)` (in `body_slot.dart`).
- [ ] No `/api/` URL strings in widgets.
- [ ] No `package:dio` imports anywhere (audit P0-03).
- [ ] All money values typed `int` (rupees) in domain; string-decimals only at the wire boundary.

### flag.md

- [ ] No new flags from 5a.

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): quote builder + tech-side authoring (sprint v1, session 5a)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] `git status` clean after commit.

---

*End of 5a. The quote authoring half is shipped; customer approval, cash, and receipts are 5b's job.*
