# Session 6a — Cancellation + Reschedule + No-show

> **Supersedes the first half of [`session_6_lifecycle_edges_and_polish.md`](./session_6_lifecycle_edges_and_polish.md).** Session 6 was split to keep human-in-the-loop decision density manageable. The parent spec is preserved as historical reference; this file is authoritative for what 6a ships, and [`session_6b_dispute_admin_polish.md`](./session_6b_dispute_admin_polish.md) is authoritative for what 6b ships.
>
> **6a scope (this file):** the three "termination of an active booking" flows — customer cancel (timing-aware modal), tech cancel (overflow menu + reliability-penalty modal), reschedule (date+time picker + child booking), no-show (single-tap confirm). Plus the `SlaCountdown` reusable widget (driven by `AwaitingBodyStub`), modal registry extension for the four new keys, and 5 of the 7 polished stubs (`Awaiting`, `Confirmed`, `Cancelled`, `Rejected`, `NoShow`).
>
> **6b scope (sibling):** dispute open flow + Django Admin resolve polish + sprint-end CLAUDE.md amendments + flag.md closure of #26 + opening of #29 (chatbot) and `eventlog-retention-policy-tbd` + the final two stubs (`Disputed`, `Unknown`) + folder rename `stub_bodies/` → `status_bodies/` + sprint-end integration acceptance tests.

---

## §0 Sprint context

This is **session 6a of the post-split 8-session plan** (1, 2, 3, 4, 5a, 5b, 6a, 6b). Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–5b invariants this sub-session relies on:

- All session 1–5 invariants from the parent spec §0.
- Backend transition endpoints `customer_cancel`, `tech_cancel`, `mark_no_show`, `reschedule` (session 2 §4.4).
- 5b's modal endpoint registry (`ModalEndpointKeys`, `modal_endpoints.py`, parity tests, `_openModal` switch). 6a extends both halves with 4 new keys.
- 5b's `BookingOrchestratorActionButton._openModal` already supports the helper invocation pattern. 6a appends 4 cases.
- `bookingRescheduledNotifier` (session 3 §4.9) handles automatic navigation to the child booking on `booking_rescheduled` event arrival; 6a's `RescheduleModal` only needs to fire the request and pop.

What 6a ends on: a customer or tech can cancel a booking with the right phase-aware UX; customer can reschedule from AWAITING/CONFIRMED into a new child booking; either party can mark no-show when the server-driven button surfaces. AWAITING shows a live SLA countdown. End-to-end happy path remains 5b's; 6b ships the dispute flow + sprint wrap.

---

## §1 Decisions taken (subset of parent §1; numbers preserved)

Carried over from parent session 6 §1, scoped to 6a:

1. **Customer cancel uses the existing secondary-action slot.** Server emits `customer_cancel` in `ui.secondary_actions` for AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED with `method='MODAL'` + `endpoint='/booking/:job_id/cancel-confirm'`. (Parent §1.1.)
2. **Tech cancel is NOT in secondary-action slot per §14 rule 6.** Lives in a 3-dot AppBar overflow menu. Server still emits `available_transitions: ['cancel_by_tech']` so the menu knows to render. (Parent §1.2.)
3. **Reschedule is customer-only**, in secondary-action slot for AWAITING / CONFIRMED only. Modal opens date+time picker; submit creates the child booking; `bookingRescheduledNotifier` (session 3) handles auto-nav. (Parent §1.3.)
4. **No-show buttons are server-driven**: `available_transitions` includes `mark_no_show` only when the time threshold has passed. Single tap → confirm modal → POST. (Parent §1.4.)
9. **SLA countdown for AWAITING**: `AwaitingBodyStub` shows live ticking timer derived from `bookingDetail.scheduledStart` + the SLA window. (Parent §1.9.)
10. **`SlaCountdown` widget is reusable** in `core/widgets/timing/sla_countdown.dart`. (Parent §1.10.)
11. **Polished terminal stubs (6a portion):** `Cancelled`, `Rejected`, `NoShow` — lean on `ReceiptCard`-style chrome with reason / actor / fee / "Book again" CTA. `Disputed` and `Unknown` are 6b. (Parent §1.11 — 6a portion.)
12. **`ConfirmedBodyStub`** stays minimal — tech name + accepted timestamp + ETA + map placeholder. (Parent §1.12.)
14. **flag.md (6a portion):** open `auto-no-show-detection-deferred`. **Numbering**: at spec-write time `flag.md`'s latest entry is **#33** (`tech_location` ingress throttle), so this opens as **#34**. Verify by `tail flag.md` at execution time — if new flags landed since, pick the next-highest. The chatbot-flag update (already filed as #28 — see 6b's note), the eventlog-retention flag (audit P2-03), and the `✅ Resolved` for #26 are 6b's wrap. (Parent §1.14 — 6a portion.)

17. **Audit-cycle-1 fixes (6a portion):**
    - **P0-03 / §24 transport**: `package:http` for cancel / reschedule / no-show data sources. URLs do not include `/api/` (it's already in `AppConstants.baseUrl`).
    - **P1-09 modal endpoint registry extension**: 4 new keys (3 server-emitted + 1 client-only). Frontend `ModalEndpointKeys` + backend `modal_endpoints.py` extended; `orchestrator_ui.py` emission updated to use new helper functions; CI parity test catches drift.
    - Multipart pattern (P0-03 multipart) — DEFERRED to 6b (only relevant for dispute photo upload).
    - flag.md `eventlog-retention-policy-tbd` (P2-03) — DEFERRED to 6b.

Decisions deferred to 6b: 5, 6, 7, 8, 13, 15, 16, the 6b portions of 11 and 14.

---

## §2 Files this session touches

### Cancellation (frontend, 11 files; all from parent §2)

| File | Purpose |
|---|---|
| `data/datasources/cancellation_remote_data_source.dart` | `customerCancel`, `techCancel` HTTP calls. |
| `data/models/cancellation_request_model.dart` | DTO for tech cancel body (optional reason). |
| `domain/failures/cancellation_failure.dart` | Sealed: `CancellationNotAllowed`, `CancellationNetworkFailure`, `CancellationServerFailure`, `UnknownCancellationFailure`. |
| `domain/repositories/cancellation_repository.dart` | Interface (`customerCancel`, `techCancel`). |
| `data/repositories/cancellation_repository_impl.dart` | Maps datasource exceptions to sealed failures. |
| `domain/use_cases/customer_cancel_use_case.dart` | Wraps `repository.customerCancel`. |
| `domain/use_cases/tech_cancel_use_case.dart` | Wraps `repository.techCancel`. |
| `presentation/providers/cancellation_notifier.dart` | Submits cancel; surfaces async state. |
| `presentation/widgets/cancellation/customer_cancel_modal.dart` | Phase-aware copy + Rs.500 fee notice when applicable. |
| `presentation/widgets/cancellation/tech_cancel_overflow_menu.dart` | AppBar overflow with "Cancel job" item. |
| `presentation/widgets/cancellation/tech_cancel_confirm_modal.dart` | Reliability-penalty messaging. |

### Reschedule (frontend, 8 files)

| File | Purpose |
|---|---|
| `data/datasources/reschedule_remote_data_source.dart` | `POST /reschedule/`. |
| `data/models/reschedule_request_model.dart` | DTO (`new_scheduled_start`, `new_scheduled_end`). |
| `domain/failures/reschedule_failure.dart` | Sealed: `RescheduleNotAllowed`, `RescheduleNetworkFailure`, `RescheduleServerFailure`, `UnknownRescheduleFailure`. |
| `domain/repositories/reschedule_repository.dart` | Interface. |
| `data/repositories/reschedule_repository_impl.dart` | Impl. |
| `domain/use_cases/reschedule_use_case.dart` | Wrapper. |
| `presentation/providers/reschedule_notifier.dart` | Submit + async state. |
| `presentation/widgets/reschedule/reschedule_modal.dart` | Date picker + time picker + duration display. |

### No-show (frontend, 7 files)

| File | Purpose |
|---|---|
| `data/datasources/no_show_remote_data_source.dart` | `POST /no-show/`. |
| `domain/failures/no_show_failure.dart` | Sealed. |
| `domain/repositories/no_show_repository.dart` | Interface. |
| `data/repositories/no_show_repository_impl.dart` | Impl. |
| `domain/use_cases/mark_no_show_use_case.dart` | Wrapper. |
| `presentation/providers/no_show_notifier.dart` | Submit + async state. |
| `presentation/widgets/no_show/no_show_confirm_modal.dart` | Single-tap modal: "Yes, the {counterparty} didn't show". |

### SLA countdown (reusable, 2 files)

| File | Purpose |
|---|---|
| `frontend/lib/core/widgets/timing/sla_countdown.dart` | Reusable countdown widget. |
| `frontend/test/core/widgets/timing/sla_countdown_test.dart` | Tests with virtual clock + `onExpired` callback. |

### Stub bodies (modified, 5 of 7)

| File | Status | Purpose |
|---|---|---|
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | Replace `AwaitingBodyStub` (uses `SlaCountdown`), `ConfirmedBodyStub`, `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub`. The other two stubs (`Disputed`, `Unknown`) and the folder rename to `status_bodies/` are 6b. |

### AppBar wiring

| File | Status | Purpose |
|---|---|---|
| `presentation/screens/booking_orchestrator_screen.dart` | **modified** | Add `TechCancelOverflowMenu(bookingId: widget.jobId)` to AppBar `actions`. Widget renders nothing for non-tech viewers and disallowed statuses, so it's safe to always include. |

### Modal endpoint registry extension

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/presentation/providers/modal_endpoint_keys.dart` | **modified** | Add `cancelConfirm`, `reschedule`, `noShowConfirm` to `serverEmitted`; add `techCancelConfirm` to `all` (client-only). |
| `frontend/lib/features/orchestrator/presentation/widgets/booking_orchestrator_action_button.dart` | **modified** | Append 4 cases to `_openModal` switch (per parent §4.0). |
| `backend/bookings/api/modal_endpoints.py` | **modified** | Add `CANCEL_CONFIRM`, `RESCHEDULE`, `NO_SHOW_CONFIRM` constants + helper functions; update `ALL_KEYS`. **`tech-cancel-confirm` is NOT here** — frontend-only key. |
| `backend/bookings/selectors/orchestrator_ui.py` | **modified** | Per-status handlers use `cancel_confirm_endpoint(...)`, `reschedule_endpoint(...)`, `no_show_confirm_endpoint(...)` helpers when emitting MODAL actions for the affected statuses. |
| `backend/bookings/api/_modal_keys_export.json` | **regenerated** | Re-exported by the test fixture; committed. |

### Routing

(No new routes in 6a — reschedule + cancel + no-show are all modal-based; dispute's full-screen route is 6b.)

### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Add cancellation, reschedule, no-show, SLA countdown sections. |
| `flag.md` | **modified** | Open new flag `auto-no-show-detection-deferred` at **#34** (next available; latest at spec-write was #33). Verify `tail flag.md` first. |

### Tests (11 files)

| File | Status | Purpose |
|---|---|---|
| `test/features/orchestrator/data/repositories/cancellation_repository_impl_test.dart` | **new** | Customer + tech cancel × failure branches. |
| `test/features/orchestrator/data/repositories/reschedule_repository_impl_test.dart` | **new** | Reschedule × failures. |
| `test/features/orchestrator/data/repositories/no_show_repository_impl_test.dart` | **new** | No-show × failures. |
| `test/features/orchestrator/presentation/providers/cancellation_notifier_test.dart` | **new** | Submit + async transitions. |
| `test/features/orchestrator/presentation/providers/reschedule_notifier_test.dart` | **new** | Submit + async. |
| `test/features/orchestrator/presentation/providers/no_show_notifier_test.dart` | **new** | Submit + async. |
| `test/features/orchestrator/presentation/widgets/cancellation/customer_cancel_modal_test.dart` | **new** | Phase-aware copy renders correctly per status; fee notice appears at right phases. |
| `test/features/orchestrator/presentation/widgets/cancellation/tech_cancel_overflow_menu_test.dart` | **new** | Menu visible only when status allows + viewer is tech. |
| `test/features/orchestrator/presentation/widgets/reschedule/reschedule_modal_test.dart` | **new** | Date picker + validation. |
| `test/features/orchestrator/presentation/widgets/no_show/no_show_confirm_modal_test.dart` | **new** | Single tap fires notifier; copy adapts to viewer role. |
| `test/core/widgets/timing/sla_countdown_test.dart` | **new** | Virtual-clock tickdown; `onExpired` fires once. |
| `test/features/orchestrator/presentation/widgets/stub_bodies/polished_stubs_test.dart` | **new** | Asserts the 5 polished stubs from 6a (`AwaitingBodyStub`, `ConfirmedBodyStub`, `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub`) render correctly with hardcoded `BookingDetail` fixtures (one fixture per terminal-status / phase variant). 6b extends this file with `DisputedBodyStub` and `UnknownBodyStub`. |
| `test/features/orchestrator/modal_handler_coverage_test.dart` | **modified** | Extended for the 4 new keys (3 server-emitted + 1 client-only). |
| `test/features/orchestrator/modal_server_emitted_parity_test.dart` | **modified** | Re-runs against regenerated fixture. |

### Files NOT touched in 6a

- All session 1–5 work + already-shipped stubs.
- Dispute frontend, dispute backend admin polish, `Disputed` + `Unknown` stubs, folder rename, `/booking/:job_id/dispute` route, CLAUDE.md amendments, sprint-end integration tests, flag.md resolution / chatbot / retention entries (all 6b).
- iOS code (flag #10).

---

## §3 Pre-flight

```bash
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# Confirm sessions 1–5b landed
ls frontend/lib/features/orchestrator/presentation/widgets/cash_collection/cash_collection_card.dart
ls frontend/lib/features/orchestrator/presentation/providers/modal_endpoint_keys.dart
ls backend/bookings/api/modal_endpoints.py

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

# Confirm parity tests pass on 5b's empty-extension baseline
flutter test test/features/orchestrator/modal_server_emitted_parity_test.dart
pytest backend/tests/bookings/test_modal_endpoints_emission.py
```

---

## §4 Per-file detailed changes

For full code blocks, see the parent spec [`session_6_lifecycle_edges_and_polish.md`](./session_6_lifecycle_edges_and_polish.md). Sub-sections that apply to 6a:

- **Parent §4.0** — modal registry extension. Apply ONLY the 4 new keys belonging to 6a (`cancelConfirm`, `reschedule`, `noShowConfirm` + frontend-only `techCancelConfirm`). The dispute is NAVIGATE, not MODAL — no key for it.
- **Parent §4.1** — `CustomerCancelModal` in full (phase computation matches backend `cancel_by_customer` phase logic from session 1 §5).
- **Parent §4.2** — `TechCancelOverflowMenu`, `TechCancelConfirmModal`, AppBar wiring in `BookingOrchestratorScreen` (one-line `actions: [TechCancelOverflowMenu(bookingId: widget.jobId)]` addition).
- **Parent §4.3** — `RescheduleModal` in full (date + time picker, duration preservation, calls notifier, `bookingRescheduledNotifier` handles nav).
- **Parent §4.4** — `NoShowConfirmModal` in full.
- **Parent §4.6** — `SlaCountdown` reusable widget in full.
- **Parent §4.7** — polished stubs (5a portion: `AwaitingBodyStub` with SLA, `ConfirmedBodyStub`, `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub`). The `DisputedBodyStub` and `UnknownBodyStub` are 6b. The folder rename `stub_bodies/` → `status_bodies/` is held for 6b (do it when the LAST stub is replaced — partial rename mid-stream would break imports).
- **Parent §4.11** — flag.md updates (6a portion only): open `auto-no-show-detection-deferred` at **#34** (next available number; verify by `tail flag.md`, latest at spec-write was #33). DO NOT resolve flag #26 yet (held for 6b's sprint wrap). The chatbot flag is already at #28 — 6b updates that entry rather than opening a new one.

### Modal registry extension — 6a's contribution to `ModalEndpointKeys`

```dart
// frontend/lib/features/orchestrator/presentation/providers/modal_endpoint_keys.dart
abstract class ModalEndpointKeys {
  // Session 5b (server-emitted)
  static const cashCollectionConfirm = 'cash-collection-confirm';
  static const quoteDecline = 'decline';
  static const quoteBargain = 'bargain';

  // Session 6a server-emitted (audit P1-09)
  static const cancelConfirm = 'cancel-confirm';
  static const reschedule = 'reschedule';
  static const noShowConfirm = 'no-show-confirm';

  // Session 6a client-only (audit C2-P1-04)
  // Invoked from the AppBar overflow menu; orchestrator_ui.py never emits this.
  static const techCancelConfirm = 'tech-cancel-confirm';

  static const serverEmitted = <String>{
    cashCollectionConfirm,
    quoteDecline,
    quoteBargain,
    cancelConfirm,
    reschedule,
    noShowConfirm,
  };

  static const all = <String>{
    ...serverEmitted,
    techCancelConfirm,
  };
}
```

```python
# backend/bookings/api/modal_endpoints.py — 6a additions
CANCEL_CONFIRM = 'cancel-confirm'
RESCHEDULE = 'reschedule'
NO_SHOW_CONFIRM = 'no-show-confirm'
# tech-cancel-confirm is NOT here — frontend-only.

ALL_KEYS = frozenset({
    CASH_COLLECTION_CONFIRM,
    QUOTE_DECLINE,
    QUOTE_BARGAIN,
    CANCEL_CONFIRM,
    RESCHEDULE,
    NO_SHOW_CONFIRM,
    # tech-cancel-confirm intentionally excluded
})

def cancel_confirm_endpoint(booking_id: int) -> str:
    return f'/booking/{booking_id}/{CANCEL_CONFIRM}'
def reschedule_endpoint(booking_id: int) -> str:
    return f'/booking/{booking_id}/{RESCHEDULE}'
def no_show_confirm_endpoint(booking_id: int) -> str:
    return f'/booking/{booking_id}/{NO_SHOW_CONFIRM}'
```

`_openModal` switch additions (parent §4.0 in full): `cancelConfirm` → `CustomerCancelModal`, `reschedule` → `RescheduleModal`, `noShowConfirm` → `NoShowConfirmModal`, `techCancelConfirm` → `TechCancelConfirmModal` (with the comment about the frontend-only asymmetry).

---

## §5 Gotchas (subset of parent §5)

Parent gotchas that apply to 6a (numbers preserved):

2. **`CustomerCancelModal`'s phase computation must match backend's `cancel_by_customer` phase logic exactly** (session 1 §5 transition table). Mismatches mean the UI promises a fee that backend doesn't charge or vice versa.
3. **`TechCancelOverflowMenu` queries `availableTransitions.contains('cancel_by_tech')`** — server's transition validator (session 2 §4.10) is the source of truth. Test the matrix.
4. **Reschedule modal `lastDate` is +60 days** per UX choice. Document if your demo window needs longer.
5. **`bookingRescheduledNotifier` handles `pushReplacementNamed`** automatically on the rescheduled event. `RescheduleModal._onSubmit` just pops the modal — the screen replacement happens via the event. Brief flash if both fire is acceptable.
6. **No-show modal's `actor_role`** is derived from `booking.viewerRole` (session 3 mapper). Button visible only when `available_transitions` includes `mark_no_show` (server enforces threshold).
9. **`SlaCountdown.expiresAt`** is computed from `scheduledStart + 15min` as a fallback. Backend should ideally emit `expiresAt` in the booking-detail response; otherwise UI countdown drifts. Future enhancement.
10. **`SlaCountdown.onExpired`** fires once at zero. Use to trigger `bookingDetailNotifier.refresh()` so the UI catches up if the SLA-timeout event was missed during a brief WS drop.
11. **`CancelledBodyStub.feeOwed`** reading: `pricing.finalCashToCollect` set by backend's `cancel_by_customer` for post-accept phases; null on rescheduled cancellations.
12. **`RejectedBodyStub` reason discriminator** — backend stamps `cancel_reason` for cancellations but not for rejections. For rejections, source of truth is the EventLog entry's `payload.reason`. Either re-fetch the event OR backend extends the detail serializer with `reject_reason`. Open a small task in flag.md if not done.
18. **flag.md numbering**: pick the next available flag number. Verify by `tail flag.md` before assigning. At spec-write time the latest entry is **#33**, so 6a opens **#34** (auto-no-show); 6b will *update* the existing chatbot entry at **#28** (rather than opening a new one — re-audit caught a pre-existing duplicate) and open **#35** for the eventlog-retention flag.

Gotchas deferred to 6b: 1 (folder rename), 7 (image_picker), 8 (multipart), 13 (tech-side dispute banner read-only), 14 (`UnknownBodyStub`), 15 (admin form `final_status` validation), 16 (admin success redirect), 17 (CLAUDE.md placement), 19 (CLAUDE.md amendments not optional), 20 (`DisputeStatusBanner` count text).

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

### Manual checks — 6a flows (subset of parent §6 acceptance tests)

These three are the 6a-relevant subset of parent §6. The full sprint-end run (acceptance tests 1–9) is held for 6b's wrap.

#### Acceptance test 4 (Cancellation matrix)

For each phase (AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED), customer cancels:
- AWAITING → CANCELLED, no fee.
- CONFIRMED, EN_ROUTE → CANCELLED, Rs.500 owed.
- ARRIVED, INSPECTING, QUOTED → CANCELLED, Rs.500 owed.

Each: `CancelledBodyStub` shows reason + fee correctly.

Tech cancels (from any non-terminal except IN_PROGRESS): from overflow menu → confirmation → CANCELLED, no fee, reliability event logged.

#### Acceptance test 5 (Reschedule)

1. Customer at CONFIRMED taps "Reschedule" (secondary action).
2. Date picker → time picker → confirm.
3. Original booking → CANCELLED with reason `customer_rescheduled` (no fee).
4. Child booking created, customer's screen replaces to child via `bookingRescheduledNotifier`.
5. Tech receives a fresh `job_new_request` for the child booking.

#### Acceptance test 6 (No-show)

**Tech reports customer no-show**: after ARRIVED + 15min, server includes `mark_no_show` in `available_transitions`; secondary-action button surfaces. Tap → confirm → NO_SHOW with `actor='tech'`.

**Customer reports tech no-show**: after `scheduled_start + 15min` without ARRIVED, server includes `mark_no_show`; tap → confirm → NO_SHOW with `actor='customer'`.

### SLA countdown manual

1. Create an AWAITING booking. Open it as customer.
2. **Verify**: `AwaitingBodyStub` renders `SlaCountdown` showing `15:00` ticking down.
3. Wait until 0 (or fast-forward via virtual clock in the unit test).
4. **Verify**: countdown reads "expired"; backend's SLA-timeout fires `booking_rejected`; `RejectedBodyStub` appears.

### Constraint checks

```bash
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/   # 1 hit (body_slot.dart)
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/  # empty
grep -rn "cancel_by_tech" frontend/lib/features/orchestrator/  # at least one hit (overflow menu gating)
flutter test test/features/orchestrator/modal_handler_coverage_test.dart   # 4 new keys covered
```

---

## §7 What this session does NOT fix

Defer to 6b:
- Dispute open form, customer-only navigate to `/booking/:job_id/dispute`, multipart photo upload.
- `DisputeStatusBanner`, `DisputedBodyStub`, `UnknownBodyStub`.
- Folder rename `stub_bodies/` → `status_bodies/` and import update.
- Backend admin polish for SupportTicket resolve.
- Sprint-end CLAUDE.md amendments (3 patterns).
- `ORCHESTRATOR_FEATURE.md` final pass.
- flag.md: ✅ Resolve #26, open #29 (chatbot), open `eventlog-retention-policy-tbd`.
- Sprint-end integration smoke (9 acceptance tests).
- Tech-offline banner verification integration test.
- Multipart audit fix.

Defer to future sprints: AI chatbot dispute intake, auto no-show detection (the flag opened in 6a), reviews/ratings, real wallet writes, iOS foreground location, per-tech / per-service threshold config, receipt PDF/share/export, polished animation transitions, design-system pass.

---

## §8 Definition of done

### Code

- [ ] Cancellation (11 files) created.
- [ ] Reschedule (8 files) created.
- [ ] No-show (7 files) created.
- [ ] `SlaCountdown` widget + test created.
- [ ] AppBar wires `TechCancelOverflowMenu` in `BookingOrchestratorScreen`.
- [ ] Modal registry extended on both sides (frontend + backend) with the 4 new keys.
- [ ] `_openModal` switch extended with 4 cases (3 server-emitted + 1 client-only).
- [ ] `orchestrator_ui.py` emission updated to use new helper functions.
- [ ] 5 polished stubs replaced (`Awaiting`, `Confirmed`, `Cancelled`, `Rejected`, `NoShow`).
- [ ] `dependency_injection.dart` registers cancellation, reschedule, no-show notifiers + repositories.
- [ ] `ORCHESTRATOR_FEATURE.md` updated with cancel + reschedule + no-show + SLA sections.

### Tests

- [ ] `flutter test` green.
- [ ] `pytest -q` (backend) green.
- [ ] All new repository / notifier / widget tests pass.
- [ ] `SlaCountdown` test uses virtual clock and verifies tickdown + `onExpired`.
- [ ] `polished_stubs_test.dart` covers all 5 of 6a's polished stubs (`Awaiting` with SLA fixture, `Confirmed`, `Cancelled` with reason+fee permutations, `Rejected` with reject-reason fixture, `NoShow` with both `actor` variants). 6b extends this same file with the final 2 stubs.
- [ ] Modal parity test (`test_modal_endpoints_emission.py`, `modal_server_emitted_parity_test.dart`) passes after 4-key extension.
- [ ] Modal handler-coverage test asserts the 4 new keys have handlers (incl. the client-only `techCancelConfirm`).

### Constraints

- [ ] Single `switch (booking.status)` (in `body_slot.dart`).
- [ ] No `/api/` URL strings in widgets.
- [ ] No `package:dio` imports anywhere.
- [ ] Tech-cancel only in overflow menu (per §14 rule 6).
- [ ] No-show is single-tap with single confirmation (per §14 rule 7).
- [ ] Server is authoritative on `available_transitions`; frontend doesn't pre-validate.

### flag.md

- [ ] New flag `auto-no-show-detection-deferred` opened (next available number; **#34** at spec-write time — verify with `tail flag.md`).
- [ ] Flag #26 NOT yet resolved (held for 6b sprint wrap).
- [ ] Existing flag #28 (chatbot) NOT touched in 6a (6b updates it).

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): cancel + reschedule + no-show + SLA countdown (sprint v1, session 6a)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] `git status` clean after commit.

---

*End of 6a. The three "termination of an active booking" flows are shipped; dispute + admin polish + sprint-end consolidation move to 6b.*
