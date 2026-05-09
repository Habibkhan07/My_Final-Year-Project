# Session 5b — Customer Approval + Cash Collection + Receipts

> **Supersedes the second half of [`session_5_quote_flow_and_cash_collection.md`](./session_5_quote_flow_and_cash_collection.md).** Session 5 was split to keep human-in-the-loop decision density manageable. The parent spec is preserved as historical reference; [`session_5a_quote_authoring.md`](./session_5a_quote_authoring.md) is authoritative for what 5a ships, and this file is authoritative for what 5b ships.
>
> **5b scope (this file):** customer-side approval card with 3 inline actions (Approve / Decline / Bargain in person), cash collection card with offline hard-block, mid-job upsell link, receipt cards for both terminal statuses, modal endpoint registry foundation + parity tests, and the rest of the stub bodies session 5 was supposed to replace.
>
> **5a scope (sibling, ships first):** tech-facing quote builder, sub-service catalog endpoint, `start_inspection` auto-flip, `InspectingBodyStub`, `QuotedBodyStub` tech-path.

---

## §0 Sprint context

This is **session 5b of the post-split 8-session plan** (1, 2, 3, 4, 5a, 5b, 6a, 6b). Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–4 + 5a invariants this sub-session relies on:

- All session 1–4 invariants from parent §0.
- 5a's quote authoring stack: `quote_repository` interface (declares all 4 ops; only `submitQuote` was consumed by 5a — the other 3 are wired up by 5b's notifier), `quote_repository_impl` (already implements all 4 ops; submit→`QuoteBuilderFailure`, decision ops→`QuoteDecisionFailure`), `quote_remote_data_source.dart` (already has all 4 methods), `QuoteBuilderFailure` and `QuoteDecisionFailure` sealed hierarchies (both shipped by 5a so the impl compiles; 5b consumes `QuoteDecisionFailure` in its decision use cases). 5b adds only `CashCollectionFailure`.
- 5a's `BookingOrchestratorActionButton` already supports the NAVIGATE method. 5b adds the MODAL method and the `_openModal` helper.
- 5a's `InspectingBodyStub` replaced. 5a's `QuotedBodyStub` has the tech path real and the customer path as a v0 placeholder — 5b replaces just the customer path.
- 5a's `dependency_injection.dart` registers quote builder + catalog providers; 5b appends cash + decision providers.

After 5b: end-to-end happy path demo-runnable — customer approves a quote, tech collects cash, both screens see the receipt. Bargain loop and inspection-fee-only outcome also working.

What 5b explicitly does NOT ship: cancellation / reschedule / no-show / dispute (sessions 6a/6b).

---

## §1 Decisions taken (subset of parent §1; numbers preserved)

Carried over from parent session 5 §1, scoped to 5b:

3. **`BookingActionExecutor` extended for MODAL method** (5b portion of parent §1.3): `_openModal` helper, `_parseQuoteIdFromEndpoint`, switch over `ModalEndpointKeys`. NAVIGATE was already added by 5a.
4. **Customer-side QUOTED is body-rich, action-slot-empty.** The `QuotedBodyStub` for customer renders `QuoteApprovalCard` inline with line items, bargain-ceiling indicators, and 3 inline buttons. Server's `ui.primary_action` is null for `QUOTED + customer`. (Parent §1.4.)
5. **Decline and Bargain open small confirmation modals** with optional reason text; submits to backend. (Parent §1.5.)
6. **Cash collection is a body-embedded card on `IN_PROGRESS` for tech**, single combined tap → confirm modal → POST → COMPLETED. (Parent §1.6.)
7. **Hard-block cash collection on offline**: button disabled + banner ("Connect to network to confirm cash collection."). Implemented via `connectivityStatusProvider` (Riverpod-wrapped `connectivity_plus`). (Parent §1.7.)
8. **Mid-job upsell**: small "+ Add work" link in `CashCollectionCard` re-opens quote builder with `?upsell=true`. (Parent §1.8.)
9. **No editable cash amount in v1**: tech taps "Confirm: Rs. X cash received" with the server-derived `final_cash_to_collect` value pre-filled. (Parent §1.9.)
14. **Bargain return navigation (customer side)**: customer's `BargainInPersonModal` triggers `quote_revision_requested`. The tech-side reroute back to the builder (the InspectingBodyStub button + the auto-flip back to INSPECTING) is 5a's deliverable; the trigger is 5b's. (Parent §1.14 — 5b portion.)
15. **`CompletedBodyStub` and `CompletedInspectionOnlyBodyStub` become receipt cards** sharing one widget with copy variation. (Parent §1.15.)
16. **Network connectivity provider** in `core/network/connectivity_status_provider.dart`; reusable. (Parent §1.16.)

17. **Audit-cycle-1 fixes (5b portion)**:
    - **P0-03 / §24 transport**: `package:http` (not Dio) in 5b's data sources (`cash_collection_remote_data_source`); URLs do not include `/api/`.
    - **P1-09 modal endpoint registry**: ship the foundation in 5b. Empty until this session adds `cashCollectionConfirm`, `quoteDecline`, `quoteBargain`. The CI parity test enforces frontend `serverEmitted ⇔ backend ALL_KEYS`.

Decisions already shipped by 5a: 1, 2, 10, 11, 12, 13, plus the 5a-portion of 14 and the 5a-portion of 17.

---

## §2 Files this session touches

### Frontend domain (6 files, all from parent §2)

| File | Purpose |
|---|---|
| `domain/failures/cash_collection_failure.dart` | Sealed: `CashCollectionNotAuthorized`, `CashCollectionInvalidTransition`, `CashCollectionNetworkFailure`, `CashCollectionServerFailure`, `UnknownCashCollectionFailure`. (`QuoteDecisionFailure` was shipped by 5a — see 5a domain table.) |
| `domain/repositories/cash_collection_repository.dart` | Interface (`confirmCashReceived`). |
| `domain/use_cases/approve_quote_use_case.dart` | Wraps `repository.approveQuote`. Throws `QuoteDecisionFailure` (5a-shipped). |
| `domain/use_cases/decline_quote_use_case.dart` | Wraps `repository.declineQuote`. Throws `QuoteDecisionFailure`. |
| `domain/use_cases/request_revision_use_case.dart` | Wraps `repository.requestRevision`. Throws `QuoteDecisionFailure`. |
| `domain/use_cases/confirm_cash_received_use_case.dart` | Wraps `repository.confirmCashReceived`. Throws `CashCollectionFailure`. |

### Frontend data (5 files)

| File | Purpose |
|---|---|
| `data/models/quote_decision_request_model.dart` | DTO for decline / request_revision (with reason). |
| `data/models/cash_collection_request_model.dart` | DTO for `POST /confirm-cash-received/`. |
| `data/mappers/quote_decision_mapper.dart` | `HttpFailure` → sealed `QuoteDecisionFailure`. |
| `data/datasources/cash_collection_remote_data_source.dart` | `confirm_cash_received` HTTP call. |
| `data/repositories/cash_collection_repository_impl.dart` | Maps datasource exceptions to sealed failures. |

(Note: `quote_remote_data_source.dart` and `quote_repository_impl.dart` already ship in 5a — both with all 4 methods AND with the correct failure mapping per op (submit→`QuoteBuilderFailure`, decision ops→`QuoteDecisionFailure`). 5b appends unit tests for the decision-path branches; **no source-code edit to the impl or datasource is required** — the C1 audit fix moved `QuoteDecisionFailure` into 5a precisely so 5b doesn't need to refactor the impl. If the impl was shipped without the per-op failure split, fix that in 5a, not here.)

### Frontend presentation

| File | Status | Purpose |
|---|---|---|
| `presentation/providers/dependency_injection.dart` | **modified** | Append `cashCollectionNotifier`, `quoteDecisionNotifier`, `cashCollectionRepositoryProvider`, `connectivityStatusProvider`. |
| `presentation/providers/cash_collection_notifier.dart` | **new** | Submits cash collection; surfaces async state. |
| `presentation/providers/quote_decision_notifier.dart` | **new** | Submits approve / decline / request_revision. |
| `presentation/providers/modal_endpoint_keys.dart` | **new** | Registry per audit P1-09. Ships with `cashCollectionConfirm`, `quoteDecline`, `quoteBargain` keys + `extractModalKey` helper. |
| `presentation/widgets/booking_orchestrator_action_button.dart` | **modified** | Add `MODAL` case in `_execute` switch + `_openModal` helper + `_parseQuoteIdFromEndpoint` per parent §4.0. |
| `presentation/widgets/quote_approval/quote_approval_card.dart` | **new** | Customer-side line-item display + 3 inline action buttons. |
| `presentation/widgets/quote_approval/decline_quote_modal.dart` | **new** | Modal with optional reason, returns `String?`. |
| `presentation/widgets/quote_approval/bargain_in_person_modal.dart` | **new** | Modal shape identical to decline; copy differs. |
| `presentation/widgets/quote_approval/bargain_ceiling_indicator.dart` | **new** | Chip on labor lines: "Bargain up to Rs. {maxPrice}". |
| `presentation/widgets/cash_collection/cash_collection_card.dart` | **new** | Tech-side card with combined "Cash Collected: Rs. X" button + offline banner. |
| `presentation/widgets/cash_collection/cash_collection_confirm_modal.dart` | **new** | Confirm → POST → spinner → snackbar. |
| `presentation/widgets/cash_collection/upsell_link.dart` | **new** | Small "+ Add more work" link inside cash card; pushes `/booking/<id>/quote-builder?upsell=true`. |
| `presentation/widgets/receipts/receipt_card.dart` | **new** | Shared receipt UI for COMPLETED + COMPLETED_INSPECTION_ONLY. |
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | Replace `QuotedBodyStub` customer-path (renders `QuoteApprovalCard`); replace `InProgressBodyStub` (both paths — tech → `CashCollectionCard`); replace `CompletedBodyStub` and `CompletedInspectionOnlyBodyStub` to render `ReceiptCard`. |

### Frontend core (new)

| File | Purpose |
|---|---|
| `frontend/lib/core/network/connectivity_status_provider.dart` | Riverpod stream provider wrapping `connectivity_plus`. |
| `frontend/pubspec.yaml` | **modified** | Add `connectivity_plus: ^6.0.0` if not already present. |

### Backend (new + modified)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/api/modal_endpoints.py` | **new** | Constants `CASH_COLLECTION_CONFIRM`, `QUOTE_DECLINE`, `QUOTE_BARGAIN` + endpoint helpers + `ALL_KEYS` frozenset. |
| `backend/bookings/selectors/orchestrator_ui.py` | **modified** | Replace string-literal MODAL endpoints with helper-function calls from `modal_endpoints.py`. |
| `backend/bookings/api/_modal_keys_export.json` | **new** (committed fixture) | Cross-language parity test exports `ALL_KEYS` here; frontend test reads it. |

### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Add quote-approval section, cash-collection section, receipt section, modal-endpoint registry section. |

### Tests (10+ files)

| File | Status | Purpose |
|---|---|---|
| `test/features/orchestrator/data/repositories/quote_repository_impl_test.dart` | **modified** | Append decision-path branches (`approveQuote`, `declineQuote`, `requestRevision`). |
| `test/features/orchestrator/data/repositories/cash_collection_repository_impl_test.dart` | **new** | Happy + failure branches. |
| `test/features/orchestrator/presentation/providers/quote_decision_notifier_test.dart` | **new** | Approve/decline/request_revision; async state transitions. |
| `test/features/orchestrator/presentation/providers/cash_collection_notifier_test.dart` | **new** | Confirm cash; offline rejection. |
| `test/features/orchestrator/presentation/widgets/quote_approval/quote_approval_card_test.dart` | **new** | 3 buttons present and tappable; modals open; correct datasource call. |
| `test/features/orchestrator/presentation/widgets/cash_collection/cash_collection_card_test.dart` | **new** | Button enabled when online; disabled with banner when offline. |
| `test/features/orchestrator/presentation/widgets/receipts/receipt_card_test.dart` | **new** | Renders correctly for both terminal statuses. |
| `test/core/network/connectivity_status_provider_test.dart` | **new** | Stream emits correctly across status transitions. |
| `test/features/orchestrator/presentation/widgets/booking_orchestrator_action_button_test.dart` | **modified** | Append MODAL-method tests for cash, decline, bargain handlers. |
| `test/features/orchestrator/modal_handler_coverage_test.dart` | **new** | Asserts every key in `ModalEndpointKeys.all` has a `_openModal` handler (synthetic-event drive; no SEVERE log line). |
| `test/features/orchestrator/modal_server_emitted_parity_test.dart` | **new** | Reads `_modal_keys_export.json`; asserts `ModalEndpointKeys.serverEmitted == loaded_set`. |
| `backend/tests/bookings/test_modal_endpoints_emission.py` | **new** | Enumerates orchestrator_ui.py handlers; asserts every emitted MODAL endpoint's trailing key is in `ALL_KEYS`. |
| `backend/tests/bookings/test_modal_endpoints_export.py` | **new** | Writes `ALL_KEYS` to `_modal_keys_export.json` as a fixture. |

### Files NOT touched in 5b

- All session 1–4 work + 5a's quote authoring stack (already shipped).
- Cancellation / reschedule / no-show / dispute (6a/6b).
- iOS code (flag #10).

---

## §3 Pre-flight

```bash
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# Confirm 5a landed
ls frontend/lib/features/orchestrator/presentation/screens/quote_builder_screen.dart
ls backend/catalog/api/sub_services_by_service/views.py

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

# Confirm connectivity_plus availability or plan to add
grep -n "connectivity_plus" pubspec.yaml || echo "Will add this session"
```

---

## §4 Per-file detailed changes

For full code blocks, see the parent spec [`session_5_quote_flow_and_cash_collection.md`](./session_5_quote_flow_and_cash_collection.md). The sub-sections that apply to 5b:

- **Parent §4.0** — modal endpoint registry foundation (frontend `modal_endpoint_keys.dart`, backend `modal_endpoints.py`, parity tests, the `_openModal` helper, `_parseQuoteIdFromEndpoint`). Ship in full.
- **Parent §4.1** — the `CashCollectionFailure` sealed hierarchy only (the parent describes it as "similar to `QuoteBuilderFailure`" — mirror the shape). `QuoteBuilderFailure` AND `QuoteDecisionFailure` were both shipped by 5a (per C1 audit fix); 5b only adds `CashCollectionFailure`.
- **Parent §4.2** — data-layer additions for decision + cash: `quote_decision_request_model`, `cash_collection_request_model`, `quote_decision_mapper`, `cash_collection_remote_data_source`, `cash_collection_repository_impl`.
- **Parent §4.6** — customer-side approval card (`QuoteApprovalCard`, `DeclineQuoteModal`, `BargainInPersonModal`, `BargainCeilingIndicator`) in full.
- **Parent §4.7** — cash collection (`CashCollectionCard`, `CashCollectionConfirmModal`, `UpsellLink`) in full.
- **Parent §4.8** — `ReceiptCard` (shared by both terminal statuses) in full.
- **Parent §4.9** — `QuotedBodyStub` customer-path replacement, `InProgressBodyStub` (both paths), `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub`.
- **Parent §4.10** — connectivity provider (`core/network/connectivity_status_provider.dart`) + pubspec entry.
- **Parent §4.11** — routing already added in 5a; nothing new in 5b for routes.

Notifiers (§4 sub-bullets in parent are concise; explicit shape per parent):

```dart
// quote_decision_notifier — summary shape
@Riverpod(keepAlive: false)
class QuoteDecisionNotifier extends _$QuoteDecisionNotifier {
  @override
  AsyncValue<void> build(int bookingId) => const AsyncValue.data(null);

  Future<void> approve({required int quoteId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(quoteRepositoryProvider).approveQuote(bookingId, quoteId));
  }

  Future<void> decline({required int quoteId, required String reason}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(quoteRepositoryProvider).declineQuote(bookingId, quoteId, reason));
  }

  Future<void> requestRevision({required int quoteId, required String reason}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(quoteRepositoryProvider).requestRevision(bookingId, quoteId, reason));
  }
}

// cash_collection_notifier — summary shape
@Riverpod(keepAlive: false)
class CashCollectionNotifier extends _$CashCollectionNotifier {
  @override
  AsyncValue<void> build(int bookingId) => const AsyncValue.data(null);

  Future<void> confirm({required int amount, required String method}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(cashCollectionRepositoryProvider).confirmCashReceived(bookingId, amount, method));
  }
}
```

(CLAUDE.md Riverpod rules apply: `@riverpod` codegen, `AsyncValue.guard`, no manual try/catch with `AsyncError`.)

---

## §5 Gotchas (subset of parent §5)

Parent gotchas that apply to 5b (numbers preserved):

1. **`BookingActionExecutor.MODAL` endpoint patterns** are an informal contract between server and frontend. Document in `ORCHESTRATOR_FEATURE.md` and rely on the parity test for drift detection.
6. **Customer's `QuoteApprovalCard` renders inline in BodySlot.** Server's `PrimaryActionSlot` is empty for `QUOTED + customer`. Verify session 2's `orchestrator_ui` selector emits `primary_action: null` for this state.
7. **Bargain/Decline modals return `String?`** via `Navigator.pop(context, _ctrl.text)`. Empty string OK; null means user cancelled.
8. **Cash collection's `amount`** is `final_cash_to_collect` if non-null, else `base_services_total`, else 0.
9. **`connectivity_plus` v6 returns `List<ConnectivityResult>`** — handle both old and new return shapes; double-check installed version.
11. **Quote bargain is uncapped** per sprint meta §6. Polish concern only.
12. **`receipt_card.dart`** for COMPLETED uses `booking.bookingItems`. For COMPLETED_INSPECTION_ONLY, `bookingItems` is empty; receipt only shows the inspection fee.
15. **Mid-job upsell while customer is offline**: tech submits → status flips to QUOTED → customer never sees it (no realtime). When customer comes online, eventSync replays missed events and the approval card appears.
17. (Carried, also 5a) catalog endpoint pagination not implemented.
19. **Decline reason vs request-revision reason**: both stored in `Quote.decision_reason`. Backend distinguishes by endpoint, not text. Modal copy must make the user's intent clear.
20. **`UpsellLink`** is small and easy to miss — that's intentional. Don't make it as prominent as the cash button.

---

## §6 Verification

### Static checks

```bash
cd frontend
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
cd ../backend
pytest -q
```

### Manual end-to-end (parent §6 happy path with bargain) — full 20-step happy path

1. Backend running, Android device with `--dart-define=MAP_PROVIDER=osm`.
2. Customer logs in, books, tech accepts.
3. Tech walks through EN_ROUTE → ARRIVED.
4. Tech taps "Build quote" on `ArrivedBodyStub` → builder opens (5a deliverable).
5. **Verify**: status flips to INSPECTING.
6. Tech taps a skill chip → line item added.
7. Tech adjusts qty/price; total updates.
8. Tap "+ More services" → picker → add second line.
9. Tap "Submit quote".
10. **Verify**: customer's screen refreshes (`quote_generated`); customer sees `QuoteApprovalCard` with line items, total, 3 buttons. Tech sees "Awaiting customer decision".
11. Customer taps "Bargain in person" → modal → "Can you do it for less?" → confirm.
12. **Verify**: tech's screen refreshes (`quote_revision_requested`); tech body shows "Continue building quote"; tap → builder pre-loaded.
13. Tech adjusts price, resubmits.
14. Customer sees rev #2; taps "Approve quote".
15. **Verify**: status flips to IN_PROGRESS; tech sees `CashCollectionCard` with combined "Cash Collected: Rs. X" button.
16. Tech does the work (manual delay).
17. Tech turns OFF wifi/data → cash button disables; banner appears.
18. Tech turns network back ON → button re-enables.
19. Tech taps "Cash Collected: Rs. X" → confirmation modal → tap "Confirm".
20. **Verify**: status flips to COMPLETED; both screens show `ReceiptCard`.

### Edge: decline → COMPLETED_INSPECTION_ONLY

From step 11, customer taps "Decline" instead → modal → "Too expensive" → confirm. Status flips to COMPLETED_INSPECTION_ONLY; receipt shows inspection-only copy + Rs. 500.

### Edge: upsell during IN_PROGRESS

From step 15, tech taps "+ Add more work" → builder opens with `?upsell=true`; existing items visible read-only above. Tech adds line, submits → status flips back to QUOTED → customer approves → IN_PROGRESS with new total → tech taps cash button.

### Constraint checks

```bash
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/presentation/    # 1 hit (body_slot.dart)
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/              # empty
grep -rn "/mark-complete/" frontend/lib/features/orchestrator/                         # empty (combined)
```

### Modal parity

```bash
flutter test test/features/orchestrator/modal_server_emitted_parity_test.dart
flutter test test/features/orchestrator/modal_handler_coverage_test.dart
pytest backend/tests/bookings/test_modal_endpoints_emission.py
pytest backend/tests/bookings/test_modal_endpoints_export.py
```

---

## §7 What this session does NOT fix

Defer to 6a/6b: cancellation, reschedule, no-show, dispute UIs, SLA countdown polish for AWAITING, terminal-stub polish (Cancelled / Rejected / NoShow / Disputed / Unknown), Django Admin resolve UI polish, sprint-end CLAUDE.md amendments.

Defer to future sprints: AI chatbot intake, reviews/ratings, real wallet writes, editable cash, bargain cap, catalog pagination, receipt PDF/share, tech-side standing-rate edit, iOS UI tweaks.

---

## §8 Definition of done

### Code

- [ ] Decision + cash domain (7 files) created.
- [ ] Decision + cash data (5 files) created.
- [ ] `quote_decision_notifier`, `cash_collection_notifier`, `modal_endpoint_keys.dart` created.
- [ ] `BookingOrchestratorActionButton._openModal` extended (parent §4.0 in full).
- [ ] 4 quote-approval widgets + 3 cash-collection widgets + 1 receipt widget created.
- [ ] `connectivity_plus` added to pubspec; provider wrapped.
- [ ] 4 stub bodies replaced (`QuotedBodyStub` customer-path, `InProgressBodyStub` both paths, `CompletedBodyStub`, `CompletedInspectionOnlyBodyStub`).
- [ ] Backend `modal_endpoints.py` + `_modal_keys_export.json` fixture created.
- [ ] `bookings/selectors/orchestrator_ui.py` uses helper functions for MODAL endpoints.
- [ ] `ORCHESTRATOR_FEATURE.md` extended with approval + cash + receipt + modal-registry sections.

### Tests

- [ ] `pytest -q` (backend) green.
- [ ] `flutter test` green.
- [ ] `quote_repository_impl_test` extended with decision-path branches.
- [ ] `cash_collection_repository_impl_test` covers happy + failures.
- [ ] `quote_decision_notifier_test` and `cash_collection_notifier_test` cover async transitions.
- [ ] `quote_approval_card_test` verifies all 3 buttons.
- [ ] `cash_collection_card_test` verifies online/offline gating.
- [ ] `receipt_card_test` verifies both terminal status renderings.
- [ ] `connectivity_status_provider_test` covers stream transitions.
- [ ] `booking_orchestrator_action_button_test` MODAL branch tests pass.
- [ ] `modal_handler_coverage_test` and `modal_server_emitted_parity_test` pass.
- [ ] Backend `test_modal_endpoints_emission.py` and `test_modal_endpoints_export.py` pass.

### Constraints

- [ ] Single `switch (booking.status)` in `body_slot.dart`.
- [ ] No `/api/` URL strings in widgets.
- [ ] No `/mark-complete/` references (combined cash endpoint per §14 rule 2).
- [ ] No `package:dio` imports anywhere.
- [ ] All money values typed `int` (rupees) in domain; string-decimals at wire only.
- [ ] All sealed failures caught and surfaced with friendly copy.
- [ ] No state mutations outside notifiers.

### flag.md

- [ ] No new flags from 5b (per parent §8).

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` includes the modal-endpoint registry, the quote-approval flow, the cash-collection flow, and the upsell semantics.
- [ ] CLAUDE.md note on the modal-endpoint pattern is held until 6b's sprint-end consolidation pass.

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): customer approval + cash collection + receipts (sprint v1, session 5b)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] `git status` clean after commit.

---

*End of 5b. Quote flow + cash + receipts complete; lifecycle edges (cancel / reschedule / no-show / dispute) move to 6a/6b.*
