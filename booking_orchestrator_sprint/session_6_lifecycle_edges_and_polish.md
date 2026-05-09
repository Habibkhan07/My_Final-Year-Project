# Session 6 — Lifecycle Edges and Polish

> Final session of the Booking Orchestrator sprint. Ships the cancellation flow (customer-side modal + tech-side overflow per §14 rule 6), reschedule (customer-only with date/time picker + child-booking creation), no-show buttons (single tap per §14 rule 7), dispute open form (customer-only per §14 rule 5; tech sees read-only banner), Django Admin resolve action polish, SLA countdown for AWAITING, tech-offline banner integration verification, polished terminal-status stub bodies. Closes flag #26. Opens the final two deferred flags.
>
> **Out of scope**: AI chatbot intake (deferred), reviews/ratings (deferred), real wallet operations (finance sprint), iOS work (flag #10).

---

## §0 Sprint context

This is **session 6 of 6** — the last session of the Booking Orchestrator sprint. Cross-cutting decisions live in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md).

Sessions 1–5 invariants this session relies on:
- Backend transition endpoints `customer_cancel`, `tech_cancel`, `mark_no_show`, `open_dispute`, `reschedule`, `admin_resolve_dispute` (session 2 §4.4).
- Frontend `BookingOrchestratorScreen`, slot architecture, per-event notifiers, action button with `NAVIGATE` + `MODAL` methods (sessions 3 + 5).
- Live tracking + offline banner already wired into LiveTrackingMap (session 4).
- 5 of 13 stub bodies already replaced with rich UIs (session 5: Inspecting / Quoted / InProgress / Completed / CompletedInspectionOnly).
- Django Admin SupportTicket resolve view scaffolded in session 2 §4.11; this session polishes + tests it.

What lands at sprint completion:
- Full lifecycle end-to-end demoable on Android with OSM provider.
- All 14 transition endpoints wired to UI buttons or auto-flips.
- All 13 stub bodies replaced with status-appropriate UI (the remaining 8 from this session: Awaiting / Confirmed / EnRoute / Arrived / Cancelled / Rejected / NoShow / Disputed; sessions 4–5 covered the other 5).
- flag #26 (booking detail screen) closes.
- Two new flags open: `auto-no-show-detection-deferred`, `ai-chatbot-intake-future-sprint`.

What does **not** ship:
- Real money writes (finance sprint).
- AI chatbot dispute intake (form-intake stub here; chatbot adapter is its own sprint).
- Auto-detected no-show via Celery (manual buttons only).
- Reviews/ratings (separate small sprint).
- iOS push (flag #10).

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions in sprint meta §4. Session-local decisions:

1. **Customer cancel uses the existing secondary-action slot.** Server's `ui.secondary_actions` includes a `customer_cancel` entry on AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED. The action's `method = 'MODAL'` and `endpoint = '/booking/:job_id/cancel-confirm'` opens `CustomerCancelModal`. Per the modal-endpoint registry from session 5.
2. **Tech cancel is NOT in the secondary-action slot per §14 rule 6.** It lives in a 3-dot overflow menu in the orchestrator screen's AppBar, visible only to tech viewers. Server still emits `available_transitions: ['cancel_by_tech']` so the menu knows to render the item; but the server's `ui.secondary_actions` does NOT include it for tech viewers.
3. **Reschedule is customer-only**, in the secondary-action slot for AWAITING / CONFIRMED only (server enforces). Modal opens a date+time picker; submit creates the child booking; `bookingRescheduledNotifier` (session 3 §4.9) handles nav to the child booking's screen automatically.
4. **No-show buttons are server-driven**: server's `available_transitions` includes `mark_no_show` only when the time threshold has passed (`arrived_at + 15min` for tech, `scheduled_start + 15min` without arrival for customer). Frontend just renders the secondary-action button when the server says so. Single tap → confirmation modal → POST.
5. **Dispute open form is customer-only per §14 rule 5.** For tech viewers, `DisputedBodyStub` shows a read-only banner ("Customer has reported an issue. Admin will contact you.") with no buttons. For customer viewers on disputable statuses (IN_PROGRESS, COMPLETED, COMPLETED_INSPECTION_ONLY) without an active OPEN ticket, server emits `open_dispute` in `secondary_actions`; tap opens `DisputeOpenForm`.
6. **`DisputeOpenForm` is full-screen route at `/booking/:job_id/dispute`**, not a modal. Reason: needs space for the photo upload + reason text + chatbot-style intro paragraph. Modal would cramp the upload UX.
7. **Photo upload uses `image_picker`** (assume in pubspec from prior sprints). Single photo, optional. Multipart POST.
8. **Admin resolve form is in Django Admin** (not a separate React/JS dashboard). Session 2 scaffolded the URL + view; this session polishes the template + adds tests + wires the success message + bookings page redirect.
9. **SLA countdown for AWAITING**: `AwaitingBodyStub` shows a live ticking timer derived from `bookingDetail.scheduledStart` and the SLA window (computed by mapper from server-emitted `expires_at` if present in payload, else falls back to a hardcoded 15min default per existing AWAITING flow). When the countdown hits 0, the SLA-timeout event auto-fires from backend; the orchestrator's events notifier catches `booking_rejected` (reason='sla_timeout') and refreshes detail.
10. **`SlaCountdown` widget is reusable** — lives in `core/widgets/timing/sla_countdown.dart` for future use (could be used in the bookings list, in-app notifications, etc.).
11. **Polished terminal stubs** (`Cancelled` / `Rejected` / `NoShow` / `Disputed`) lean on the existing `ReceiptCard`-style chrome from session 5, with status-specific copy + actor/reason details + suggested next actions ("Try booking again" link).
12. **`ConfirmedBodyStub`** stays minimal — shows tech name + accepted timestamp + ETA (if scheduled_start is in the future) + the live tracking map placeholder (that lights up on EN_ROUTE).
13. **Tech-offline banner verification**: session 4 built the staleness detection inside `LiveTrackingMap`. This session adds an integration test that simulates network drop and asserts the banner appears, completing the live-tracking acceptance criteria.
14. **flag.md update pattern**: append-only with `✅ Resolved (2026-MM-DD)` + "What changed" block per the existing flag.md schema. Don't delete resolved flags; strike them through. **This session opens** `auto-no-show-detection-deferred`, `chatbot-intake-future-sprint`, and (audit P2-03) `eventlog-retention-policy-tbd`.
15. **CLAUDE.md amendments**: this session is the right place to add the small CLAUDE.md notes for the patterns introduced this sprint (modal endpoint registry, stream consumer pattern, WS upstream subscribe contract). One paragraph each, all together at sprint end.
16. **Sprint-end integration smoke**: this session's §6 includes a comprehensive end-to-end QA script walking the full lifecycle through every edge — happy path, every cancellation phase, reschedule, no-show (both sides), dispute open + admin resolve. Documented as the sprint's acceptance test.

17. **Audit-cycle-1 fixes shipped this session** (see [`AUDIT.md`](./AUDIT.md) and sprint meta §25):
    - **P0-03 / §24 transport**: every "Dio impl" code block in this session is illustrative only. Real implementation uses `package:http` per the canonical pattern in `BOOKING_ORCHESTRATOR_SPRINT.md §24`. **Multipart pattern (for `DisputeOpenForm` photo upload)** uses `http.MultipartRequest` per §24. Substitute Dio symbols mentally throughout.
    - **P1-09 modal endpoint registry**: extends the `ModalEndpointKeys` constant (introduced in session 5 §4.0) with the 4 new keys: `cancel-confirm`, `reschedule`, `no-show-confirm`, `tech-cancel-confirm`. Adds matching cases to the `_openModal` switch. Backend `bookings/api/modal_endpoints.py` extended with the same 4 constants. The CI parity test (also from session 5) catches drift.
    - **flag.md** opens `eventlog-retention-policy-tbd` (audit P2-03) — the realtime EventLog will grow unbounded without a cleanup task; defer to ops sprint but log explicitly so it doesn't get lost.

---

## §2 Files this session touches

### Frontend: cancellation (new under `lib/features/orchestrator/`)

| File | Purpose |
|---|---|
| `data/datasources/cancellation_remote_data_source.dart` | `customerCancel`, `techCancel` HTTP calls. |
| `data/models/cancellation_request_model.dart` | DTO for tech cancel body (optional reason). |
| `domain/failures/cancellation_failure.dart` | Sealed failure hierarchy. |
| `domain/repositories/cancellation_repository.dart` | Interface. |
| `data/repositories/cancellation_repository_impl.dart` | Impl. |
| `domain/use_cases/customer_cancel_use_case.dart` | Wrapper. |
| `domain/use_cases/tech_cancel_use_case.dart` | Wrapper. |
| `presentation/providers/cancellation_notifier.dart` | Submits cancel; surfaces async state. |
| `presentation/widgets/cancellation/customer_cancel_modal.dart` | Modal with timing-aware copy + Rs.500 fee notice (when applicable). |
| `presentation/widgets/cancellation/tech_cancel_overflow_menu.dart` | AppBar overflow menu with "Cancel job" item; opens confirmation modal. |
| `presentation/widgets/cancellation/tech_cancel_confirm_modal.dart` | Confirmation modal explaining reliability penalty. |

### Frontend: reschedule (new)

| File | Purpose |
|---|---|
| `data/datasources/reschedule_remote_data_source.dart` | `POST /reschedule/`. |
| `data/models/reschedule_request_model.dart` | DTO with `new_scheduled_start`, `new_scheduled_end`. |
| `domain/failures/reschedule_failure.dart` | Sealed. |
| `domain/repositories/reschedule_repository.dart` | Interface. |
| `data/repositories/reschedule_repository_impl.dart` | Impl. |
| `domain/use_cases/reschedule_use_case.dart` | Wrapper. |
| `presentation/providers/reschedule_notifier.dart` | Submit + async state. |
| `presentation/widgets/reschedule/reschedule_modal.dart` | Full-screen modal: date picker + time picker + duration display + confirm. |

### Frontend: no-show (new)

| File | Purpose |
|---|---|
| `data/datasources/no_show_remote_data_source.dart` | `POST /no-show/`. |
| `domain/failures/no_show_failure.dart` | Sealed. |
| `domain/repositories/no_show_repository.dart` | Interface. |
| `data/repositories/no_show_repository_impl.dart` | Impl. |
| `domain/use_cases/mark_no_show_use_case.dart` | Wrapper. |
| `presentation/providers/no_show_notifier.dart` | Submit + async state. |
| `presentation/widgets/no_show/no_show_confirm_modal.dart` | Single-tap modal: "Yes, the {counterparty} didn't show". |

### Frontend: dispute (new — customer-only intake)

| File | Purpose |
|---|---|
| `data/datasources/dispute_remote_data_source.dart` | Multipart `POST /disputes/` via `http.MultipartRequest` (audit P0-03 §24 multipart pattern). |
| `data/models/dispute_open_request_model.dart` | DTO with `initial_reason` + optional `photo`. |
| `domain/failures/dispute_failure.dart` | Sealed. |
| `domain/repositories/dispute_repository.dart` | Interface. |
| `data/repositories/dispute_repository_impl.dart` | Impl. |
| `domain/use_cases/open_dispute_use_case.dart` | Wrapper. |
| `presentation/providers/dispute_notifier.dart` | Submit + async state. |
| `presentation/screens/dispute_open_form_screen.dart` | Full-screen form. |
| `presentation/widgets/dispute/dispute_status_banner.dart` | Read-only banner for tech viewer ("Customer has reported an issue. Admin will contact you."). |

### SLA countdown (reusable)

| File | Purpose |
|---|---|
| `frontend/lib/core/widgets/timing/sla_countdown.dart` | Reusable countdown widget. |
| `frontend/test/core/widgets/timing/sla_countdown_test.dart` | Tests with virtual clock. |

### Stub bodies polished (modified)

| File | Status | Purpose |
|---|---|---|
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | Replace 7 of the remaining 8 stubs (`AwaitingBodyStub`, `ConfirmedBodyStub`, `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub`, `DisputedBodyStub`, `UnknownBodyStub`). `EnRouteBodyStub` and `ArrivedBodyStub` already polished in session 4. After this session: all 13 stubs are full bodies; the file's name "stub_bodies" is a misnomer post-sprint — rename to `status_bodies/all_status_bodies.dart` in the same edit (small refactor, requires updating the import in `body_slot.dart`). |

### Routing (modified)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/routing/app_router.dart` | **modified** | Add `/booking/:job_id/dispute` route. |

### Backend: Admin polish (modified)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/admin.py` | **modified** | Polish the SupportTicketAdmin resolve flow: better validation, success messages, related-bookings hyperlinks. |
| `backend/bookings/templates/admin/bookings/supportticket/resolve.html` | **modified** | Polished form template with confirmation step. |

### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Final pass: complete coverage of all 14 transitions, all stubs, all events, all modal endpoints, the SLA countdown widget, dispute flow. Mark sprint as DONE. |
| `CLAUDE.md` | **modified** | Three small additions: modal endpoint pattern, stream consumer pattern, WS upstream subscribe contract. One paragraph each. |
| `flag.md` | **modified** | ✅ Resolved #26 with summary. Open `auto-no-show-detection-deferred`, `ai-chatbot-intake-future-sprint`. |

### Tests (all new)

| File | Purpose |
|---|---|
| `test/features/orchestrator/data/repositories/cancellation_repository_impl_test.dart` | Customer + tech cancel × failure branches. |
| `test/features/orchestrator/data/repositories/reschedule_repository_impl_test.dart` | Reschedule × failures. |
| `test/features/orchestrator/data/repositories/no_show_repository_impl_test.dart` | No-show × failures. |
| `test/features/orchestrator/data/repositories/dispute_repository_impl_test.dart` | Dispute open × failures (multipart edge cases). |
| `test/features/orchestrator/presentation/providers/cancellation_notifier_test.dart` | Submit + async state transitions. |
| `test/features/orchestrator/presentation/providers/reschedule_notifier_test.dart` | Submit + async. |
| `test/features/orchestrator/presentation/providers/no_show_notifier_test.dart` | Submit + async. |
| `test/features/orchestrator/presentation/providers/dispute_notifier_test.dart` | Submit + async (with mocked photo). |
| `test/features/orchestrator/presentation/widgets/cancellation/customer_cancel_modal_test.dart` | Timing-aware copy renders correctly per status; fee notice appears at right phases. |
| `test/features/orchestrator/presentation/widgets/cancellation/tech_cancel_overflow_menu_test.dart` | Menu visible only when status allows + viewer is tech. |
| `test/features/orchestrator/presentation/widgets/reschedule/reschedule_modal_test.dart` | Date picker + validation. |
| `test/features/orchestrator/presentation/widgets/no_show/no_show_confirm_modal_test.dart` | Single tap fires notifier. |
| `test/features/orchestrator/presentation/screens/dispute_open_form_screen_test.dart` | Form submit with + without photo. |
| `test/features/orchestrator/presentation/widgets/dispute/dispute_status_banner_test.dart` | Tech-viewer banner renders read-only. |
| `test/features/orchestrator/presentation/widgets/stub_bodies/polished_stubs_test.dart` | All 8 polished stubs render correctly with hardcoded BookingDetail per status. |
| `test/core/widgets/timing/sla_countdown_test.dart` | Countdown ticks correctly with virtual clock; surfaces "expired" callback. |
| `backend/tests/bookings/test_admin_resolve_dispute_polish.py` | End-to-end Django Admin form → orchestrator service → state mutation. |

### Files NOT touched

- All session 1–5 work (orchestrator/quote/cash flows, live tracking, etc.).
- iOS-related code (flag #10 deferred).
- Reviews/ratings (out of sprint).

---

## §3 Pre-flight

```bash
# 1. Repo + sessions 1–5 confirmed
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main
ls booking_orchestrator_sprint/session_5_quote_flow_and_cash_collection.md

# 2. Backend baseline
cd backend && source venv/bin/activate
pytest -q
python manage.py check

# 3. Confirm session 2 admin scaffolding
grep -n "SupportTicketAdmin" bookings/admin.py
ls bookings/templates/admin/bookings/supportticket/resolve.html

# 4. Frontend baseline
cd ../frontend
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs

# 5. Confirm session 4 + 5 widgets compile
flutter test test/features/orchestrator/
flutter test test/core/widgets/map/

# 6. Confirm image_picker is in pubspec (if not already, plan to add)
grep -n "image_picker" pubspec.yaml || echo "Will add this session"

# 7. Confirm flag.md schema (latest entry conventions)
tail -50 ../flag.md
```

---

## §4 Per-file detailed changes

### §4.0 Modal endpoint registry extension (audit P1-09)

Sessions 3+5 introduced the modal-endpoint contract: server emits `ui.primary_action` or `ui.secondary_actions` entries with `method='MODAL'` and `endpoint='/booking/:job_id/<key>'`. Session 5 §4.0 replaced the v0.9 fragile `endsWith()` chain with an explicit `ModalEndpointKeys` registry + a CI parity test against the backend's `modal_endpoints.py`.

This session adds **4** new modal endpoints (the dispute screen is NAVIGATE, not MODAL — full-screen route per §1 decision 6):

| Modal key | Modal builder | Notes |
|---|---|---|
| `cancel-confirm` | `CustomerCancelModal` | Customer-only; emitted by server in `secondary_actions`. |
| `reschedule` | `RescheduleModal` | Customer-only; AWAITING/CONFIRMED only. |
| `no-show-confirm` | `NoShowConfirmModal` | Server emits when time-threshold passed. |
| `tech-cancel-confirm` | `TechCancelConfirmModal` | **Invoked from AppBar overflow, NOT server-emitted** — there's no MODAL action for this in `ui.secondary_actions`. The overflow menu calls the modal directly. |

The dispute opening uses `method='NAVIGATE'` with `endpoint='/booking/:job_id/dispute'` — the action button's NAVIGATE branch pushes the route via GoRouter; the screen is a full route registered in `app_router.dart`.

#### Frontend `ModalEndpointKeys` extension

```dart
// frontend/lib/features/orchestrator/presentation/providers/modal_endpoint_keys.dart
abstract class ModalEndpointKeys {
  // Session 5 (server-emitted)
  static const cashCollectionConfirm = 'cash-collection-confirm';
  static const quoteDecline = 'decline';
  static const quoteBargain = 'bargain';

  // Session 6 server-emitted (audit P1-09)
  static const cancelConfirm = 'cancel-confirm';
  static const reschedule = 'reschedule';
  static const noShowConfirm = 'no-show-confirm';

  // Session 6 client-only (audit C2-P1-04)
  // Invoked from the AppBar overflow menu; orchestrator_ui.py never emits this.
  static const techCancelConfirm = 'tech-cancel-confirm';

  /// Server-emitted keys. Must equal backend `ALL_KEYS` exactly (parity test).
  static const serverEmitted = <String>{
    cashCollectionConfirm,
    quoteDecline,
    quoteBargain,
    cancelConfirm,
    reschedule,
    noShowConfirm,
  };

  /// All keys (server-emitted + client-only). Every key here must have a
  /// `_openModal` handler (frontend coverage test).
  static const all = <String>{
    ...serverEmitted,
    techCancelConfirm,
  };
}
```

#### Backend `modal_endpoints.py` extension

```python
# backend/bookings/api/modal_endpoints.py — session 6 additions
CANCEL_CONFIRM = 'cancel-confirm'
RESCHEDULE = 'reschedule'
NO_SHOW_CONFIRM = 'no-show-confirm'
# tech-cancel-confirm is NOT here — it's frontend-only (invoked from overflow,
# never emitted by orchestrator_ui.py).

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

`bookings/selectors/orchestrator_ui.py` per-status handlers use these helper functions when emitting MODAL actions (no string-literal endpoints).

#### `_openModal` extension

Add cases to the existing switch (session 5 §4.0). The parity test catches both directions of drift.

```dart
Future<void> _openModal(String endpoint, int bookingId) async {
  final key = extractModalKey(endpoint);
  if (key == null) return;

  switch (key) {
    // Session 5 cases (cashCollectionConfirm, quoteDecline, quoteBargain) ...

    // Session 6 additions
    case ModalEndpointKeys.cancelConfirm:
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => CustomerCancelModal(bookingId: bookingId),
      );
      break;
    case ModalEndpointKeys.reschedule:
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RescheduleModal(bookingId: bookingId),
      );
      break;
    case ModalEndpointKeys.noShowConfirm:
      await showModalBottomSheet(
        context: context,
        builder: (_) => NoShowConfirmModal(bookingId: bookingId),
      );
      break;
    case ModalEndpointKeys.techCancelConfirm:
      // Audit C2-P1-04: client-only key. The AppBar overflow menu invokes this
      // case via a synthetic MODAL endpoint string `/booking/<id>/tech-cancel-confirm`
      // that it constructs locally. Backend never emits this — it's NOT in
      // backend ALL_KEYS, only in frontend ModalEndpointKeys.all. The
      // bidirectional parity test (modal_server_emitted_parity_test) compares
      // ONLY serverEmitted (which excludes this), so the asymmetry is fine.
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => TechCancelConfirmModal(bookingId: bookingId),
      );
      break;

    default:
      developer.log('Unknown MODAL key "$key"', name: 'orchestrator', level: 900);
      return;
  }

  if (mounted) {
    ref.invalidate(bookingDetailNotifierProvider(bookingId));
  }
}
```

### §4.1 Customer cancel

#### `presentation/widgets/cancellation/customer_cancel_modal.dart`

Timing-aware copy. Reads booking from provider; switches copy per status.

```dart
class CustomerCancelModal extends ConsumerStatefulWidget {
  final int bookingId;
  const CustomerCancelModal({super.key, required this.bookingId});
  @override
  ConsumerState<CustomerCancelModal> createState() => _CustomerCancelModalState();
}

class _CustomerCancelModalState extends ConsumerState<CustomerCancelModal> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(bookingDetailNotifierProvider(widget.bookingId));
    final notifierState = ref.watch(cancellationNotifierProvider(widget.bookingId));
    final notifier = ref.watch(cancellationNotifierProvider(widget.bookingId).notifier);

    return detailAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 200, child: Center(child: Text('Could not load.'))),
      data: (booking) {
        final phase = _phaseFor(booking.status);
        final feeOwed = phase != _CancelPhase.preAccept;
        final feeAmount = booking.pricing.inspectionFee ?? 500;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_titleFor(phase), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_bodyFor(phase, feeAmount)),
              if (feeOwed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text('You\'ll owe Rs. $feeAmount in cash to the technician.')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextButton(
                    onPressed: notifierState.isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Keep booking'),
                  )),
                  Expanded(child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: notifierState.isLoading ? null : () async {
                      try {
                        await notifier.customerCancel();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        }
                      }
                    },
                    child: notifierState.isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(feeOwed ? 'Cancel & owe Rs. $feeAmount' : 'Cancel booking'),
                  )),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  _CancelPhase _phaseFor(BookingStatus s) => switch (s) {
    BookingStatus.awaiting => _CancelPhase.preAccept,
    BookingStatus.confirmed || BookingStatus.enRoute => _CancelPhase.preArrival,
    BookingStatus.arrived || BookingStatus.inspecting || BookingStatus.quoted => _CancelPhase.postArrival,
    _ => _CancelPhase.preAccept,    // shouldn't reach for terminal statuses (button hidden)
  };

  String _titleFor(_CancelPhase p) => switch (p) {
    _CancelPhase.preAccept => 'Cancel this booking?',
    _CancelPhase.preArrival => 'Cancel after technician accepted?',
    _CancelPhase.postArrival => 'Cancel after technician arrived?',
  };

  String _bodyFor(_CancelPhase p, int fee) => switch (p) {
    _CancelPhase.preAccept => 'No fee. Booking will be cancelled immediately.',
    _CancelPhase.preArrival => 'Technician already accepted and may be on the way. Inspection fee applies.',
    _CancelPhase.postArrival => 'Technician is at your location. Inspection fee applies.',
  };

  String _friendlyError(Object e) => switch (e) {
    CancellationNotAllowed() => 'Cancellation is not allowed at this stage.',
    CancellationNetworkFailure() => 'Network error; check your connection.',
    _ => 'Could not cancel.',
  };
}

enum _CancelPhase { preAccept, preArrival, postArrival }
```

### §4.2 Tech cancel (overflow menu)

#### `presentation/widgets/cancellation/tech_cancel_overflow_menu.dart`

Renders an `IconButton` with `Icons.more_vert` in the AppBar; opens a popup menu.

```dart
class TechCancelOverflowMenu extends ConsumerWidget {
  final int bookingId;
  const TechCancelOverflowMenu({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(bookingDetailNotifierProvider(bookingId));
    return detailAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (booking) {
        if (booking.viewerRole != BookingOrchestratorRole.technician) return const SizedBox.shrink();
        if (!booking.availableTransitions.contains('cancel_by_tech')) return const SizedBox.shrink();
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'cancel') {
              final confirmed = await showModalBottomSheet<bool>(
                context: context,
                builder: (_) => const TechCancelConfirmModal(),
              );
              if (confirmed == true) {
                await ref.read(cancellationNotifierProvider(bookingId).notifier).techCancel();
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'cancel', child: Text('Cancel job')),
          ],
        );
      },
    );
  }
}
```

#### `presentation/widgets/cancellation/tech_cancel_confirm_modal.dart`

```dart
class TechCancelConfirmModal extends StatelessWidget {
  const TechCancelConfirmModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cancel this job?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Your reliability score will take a small hit. Repeated cancellations may '
            'result in temporary suspension. Use only if necessary.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep job'),
              )),
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel job'),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### Wire into `booking_orchestrator_screen.dart`

Update the AppBar's `actions`:

```dart
appBar: AppBar(
  title: const Text('Booking'),
  actions: [TechCancelOverflowMenu(bookingId: widget.jobId)],
),
```

The widget renders nothing for non-tech viewers and disallowed statuses, so it's safe to always include.

### §4.3 Reschedule

#### `presentation/widgets/reschedule/reschedule_modal.dart`

Date + time picker; preserves the original booking's duration (`scheduledEnd - scheduledStart`).

```dart
class RescheduleModal extends ConsumerStatefulWidget {
  final int bookingId;
  const RescheduleModal({super.key, required this.bookingId});
  @override
  ConsumerState<RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends ConsumerState<RescheduleModal> {
  DateTime? _newStart;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(bookingDetailNotifierProvider(widget.bookingId));
    final notifierState = ref.watch(rescheduleNotifierProvider(widget.bookingId));
    final notifier = ref.watch(rescheduleNotifierProvider(widget.bookingId).notifier);

    return detailAsync.when(
      loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 250, child: Center(child: Text('Could not load.'))),
      data: (booking) {
        final duration = booking.scheduledEnd.difference(booking.scheduledStart);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reschedule booking',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Current: ${_fmt(booking.scheduledStart)} — ${_fmt(booking.scheduledEnd)}'),
              const SizedBox(height: 12),
              const Text('No fee since this is a reschedule. Technician will be re-notified.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_newStart == null
                    ? 'Pick new date & time'
                    : 'New: ${_fmt(_newStart!)} — ${_fmt(_newStart!.add(duration))}'),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: booking.scheduledStart.add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(booking.scheduledStart),
                  );
                  if (time == null) return;
                  setState(() {
                    _newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  )),
                  Expanded(child: FilledButton(
                    onPressed: _newStart == null || notifierState.isLoading
                        ? null
                        : () async {
                            try {
                              await notifier.reschedule(
                                newScheduledStart: _newStart!,
                                newScheduledEnd: _newStart!.add(duration),
                              );
                              if (context.mounted) Navigator.pop(context);
                              // bookingRescheduledNotifier (session 3 §4.9) handles
                              // pushReplacementNamed to the child booking on event arrival.
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_friendlyError(e))),
                                );
                              }
                            }
                          },
                    child: notifierState.isLoading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirm reschedule'),
                  )),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _friendlyError(Object e) => switch (e) {
    RescheduleNotAllowed() => 'Reschedule is no longer possible at this stage.',
    RescheduleNetworkFailure() => 'Network error.',
    _ => 'Could not reschedule.',
  };
}
```

### §4.4 No-show

#### `presentation/widgets/no_show/no_show_confirm_modal.dart`

Single-tap modal — no reason picker per §14 rule 7.

```dart
class NoShowConfirmModal extends ConsumerWidget {
  final int bookingId;
  const NoShowConfirmModal({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookingDetailNotifierProvider(bookingId)).requireValue;
    final isCustomer = detail.viewerRole == BookingOrchestratorRole.customer;
    final actorTitle = isCustomer ? 'Technician didn\'t show' : 'Customer didn\'t show';
    final notifier = ref.watch(noShowNotifierProvider(bookingId).notifier);
    final state = ref.watch(noShowNotifierProvider(bookingId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(actorTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(isCustomer
              ? 'Confirm that the technician hasn\'t arrived after waiting.'
              : 'Confirm that the customer hasn\'t shown up at the scheduled location.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextButton(
                onPressed: state.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              Expanded(child: FilledButton(
                onPressed: state.isLoading ? null : () async {
                  try {
                    await notifier.markNoShow();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not mark no-show.')),
                      );
                    }
                  }
                },
                child: state.isLoading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Yes, $actorTitle'.toLowerCase()),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
```

### §4.5 Dispute

#### `presentation/screens/dispute_open_form_screen.dart`

Full-screen form with text + optional photo. Chatbot-shaped data — schema reserves `chat_log` for future chatbot adapter.

```dart
class DisputeOpenFormScreen extends ConsumerStatefulWidget {
  final int bookingId;
  const DisputeOpenFormScreen({super.key, required this.bookingId});
  @override
  ConsumerState<DisputeOpenFormScreen> createState() => _DisputeOpenFormScreenState();
}

class _DisputeOpenFormScreenState extends ConsumerState<DisputeOpenFormScreen> {
  final _reasonCtrl = TextEditingController();
  XFile? _photo;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disputeNotifierProvider(widget.bookingId));
    final notifier = ref.watch(disputeNotifierProvider(widget.bookingId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us what went wrong. An admin will review your case and contact '
              'you within 1–2 business days.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'What happened? (required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
              minLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_photo == null ? 'Add a photo (optional)' : 'Photo attached'),
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
                if (picked != null) setState(() => _photo = picked);
              },
            ),
            if (_photo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(File(_photo!.path), height: 120, fit: BoxFit.cover),
              ),
            const Spacer(),
            FilledButton(
              onPressed: state.isLoading || _reasonCtrl.text.trim().length < 10
                  ? null
                  : () async {
                      try {
                        await notifier.openDispute(
                          initialReason: _reasonCtrl.text.trim(),
                          photoFile: _photo == null ? null : File(_photo!.path),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dispute opened. Admin will review.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_friendlyError(e))),
                          );
                        }
                      }
                    },
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(Object e) => switch (e) {
    DisputeNotDisputableStatus() => 'Dispute can\'t be opened on this booking.',
    DisputeNetworkFailure() => 'Network error.',
    _ => 'Could not open dispute.',
  };
}
```

#### `presentation/widgets/dispute/dispute_status_banner.dart`

Read-only banner for tech viewers (per §14 rule 5):

```dart
class DisputeStatusBanner extends StatelessWidget {
  final int openTicketsCount;
  const DisputeStatusBanner({super.key, required this.openTicketsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.report_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  openTicketsCount == 1
                      ? 'Customer has reported an issue.'
                      : 'Customer has reported $openTicketsCount issues.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text('Admin will contact you to resolve.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### §4.6 SLA countdown

#### `core/widgets/timing/sla_countdown.dart`

```dart
class SlaCountdown extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback? onExpired;
  final TextStyle? textStyle;

  const SlaCountdown({
    super.key,
    required this.expiresAt,
    this.onExpired,
    this.textStyle,
  });

  @override
  State<SlaCountdown> createState() => _SlaCountdownState();
}

class _SlaCountdownState extends State<SlaCountdown> {
  Timer? _ticker;
  late Duration _remaining;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_recompute);
    });
  }

  void _recompute() {
    final now = DateTime.now();
    _remaining = widget.expiresAt.isAfter(now)
        ? widget.expiresAt.difference(now)
        : Duration.zero;
    if (_remaining == Duration.zero && !_expiredFired) {
      _expiredFired = true;
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _remaining.inMinutes;
    final secs = _remaining.inSeconds % 60;
    final label = _remaining == Duration.zero
        ? 'expired'
        : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    return Text(label, style: widget.textStyle);
  }
}
```

### §4.7 Polished stub bodies

#### `AwaitingBodyStub` (replaced)

```dart
class AwaitingBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const AwaitingBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SLA expiry: scheduledStart is the SLA anchor; backend's two-tier dispatch
    // typically arms 60s for ASAP, 15min for scheduled. v1: read from
    // ui.body_text or fallback to a 15min default from scheduledStart.
    final expiresAt = booking.scheduledStart.add(const Duration(minutes: 15));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.schedule, size: 64),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16),
                const SizedBox(width: 6),
                SlaCountdown(
                  expiresAt: expiresAt,
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### `ConfirmedBodyStub` (polished)

```dart
class ConfirmedBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const ConfirmedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final acceptedAt = booking.phaseTimestamps.acceptedAt;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(booking.ui.bodyText,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (acceptedAt != null) ...[
                    const SizedBox(height: 4),
                    Text('Accepted at ${_fmt(acceptedAt)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text('Scheduled: ${_fmt(booking.scheduledStart)}'),
              subtitle: Text(booking.addressSnapshot),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
```

#### `CancelledBodyStub`, `RejectedBodyStub`, `NoShowBodyStub` (polished)

Each shows the terminal status with reason, actor, fee owed (if any), and a "Book again" call-to-action that pops back to the bookings list (or pushes the discovery flow).

```dart
class CancelledBodyStub extends StatelessWidget {
  final BookingDetail booking;
  const CancelledBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final reason = booking.cancelReason ?? 'unknown';
    final feeOwed = booking.pricing.finalCashToCollect ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(booking.ui.bodyText, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Reason: ${_friendlyReason(reason)}'),
                  if (feeOwed > 0) ...[
                    const SizedBox(height: 8),
                    Text('Cash owed to technician: Rs. $feeOwed',
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Book a similar service'),
            onPressed: () => GoRouter.of(context).go('/discovery'),
          ),
        ],
      ),
    );
  }

  String _friendlyReason(String raw) => switch (raw) {
    'customer_cancelled_pre_accept' => 'You cancelled before tech accepted',
    'customer_cancelled_post_accept' => 'You cancelled after tech accepted',
    'customer_cancelled_post_arrival' => 'You cancelled after tech arrived',
    'technician_cancelled' => 'Technician cancelled',
    'customer_rescheduled' => 'You rescheduled to a new time',
    _ => raw,
  };
}

// RejectedBodyStub and NoShowBodyStub follow the same structure with status-specific
// copy + reasons (rejected: 'tech_declined' vs 'sla_timeout'; no-show: actor='tech' vs 'customer').
```

#### `DisputedBodyStub` (polished)

```dart
class DisputedBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const DisputedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomer = booking.viewerRole == BookingOrchestratorRole.customer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DisputeStatusBanner(openTicketsCount: booking.openTicketsCount),
          const SizedBox(height: 16),
          if (isCustomer)
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('We\'ve received your report. An admin is reviewing.'),
            ))
          else
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Don\'t take any further action. An admin will contact you.'),
            )),
        ],
      ),
    );
  }
}
```

`UnknownBodyStub` shows a generic message with a "Reload" button. Used as a defensive fallback for forward-compat (server adds a new status string the frontend hasn't recognized yet).

### §4.8 GoRouter route

Add to `app_router.dart`:

```dart
GoRoute(
  path: '/booking/:job_id/dispute',
  name: 'open_dispute',
  builder: (context, state) {
    final jobId = int.parse(state.pathParameters['job_id']!);
    return DisputeOpenFormScreen(bookingId: jobId);
  },
),
```

Also: file rename `stub_bodies/all_status_stubs.dart` → `status_bodies/all_status_bodies.dart`. Update import in `body_slot.dart`. Folder rename + import update — small refactor that should be done in this session as it's the "polish" session.

### §4.9 Backend Admin polish

#### `bookings/admin.py` (modified)

Polish the `SupportTicketAdmin` resolve view from session 2:

```dart
def resolve_view(self, request, ticket_id: int):
    try:
        ticket = SupportTicket.objects.select_related('booking', 'opened_by').get(id=ticket_id)
    except SupportTicket.DoesNotExist:
        return redirect('admin:bookings_supportticket_changelist')

    if ticket.status == SupportTicket.STATUS_RESOLVED:
        self.message_user(request, 'Ticket already resolved.', messages.WARNING)
        return redirect(f'../../{ticket_id}/change/')

    if request.method == 'POST':
        outcome = request.POST.get('outcome')
        notes = request.POST.get('notes', '').strip()
        final_status = request.POST.get('final_status')
        if not (outcome and final_status and notes):
            self.message_user(request, 'All fields required.', messages.ERROR)
            return self._render(request, ticket)
        try:
            updated_ticket = orchestrator.admin_resolve_dispute(
                ticket_id=ticket.id,
                admin_user=request.user,
                outcome=outcome,
                notes=notes,
                final_status=final_status,
            )
            self.message_user(
                request,
                f'Ticket #{ticket.id} resolved. Booking #{ticket.booking_id} now {final_status}.',
                messages.SUCCESS,
            )
        except BookingValidationError as exc:
            self.message_user(request, f'Failed: {exc.message}', messages.ERROR)
            return self._render(request, ticket)
        return redirect(f'/admin/bookings/jobbooking/{ticket.booking_id}/change/')
    return self._render(request, ticket)

def _render(self, request, ticket):
    return render(request, 'admin/bookings/supportticket/resolve.html', {
        'ticket': ticket,
        'evidence': ticket.evidence.all(),
        'outcomes': SupportTicket.OUTCOME_CHOICES,
        'final_statuses': [
            (JobBooking.STATUS_COMPLETED, 'Completed (full)'),
            (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, 'Completed (inspection only)'),
            (JobBooking.STATUS_CANCELLED, 'Cancelled'),
        ],
    })
```

#### `bookings/templates/admin/bookings/supportticket/resolve.html` (polished)

```html
{% extends "admin/base_site.html" %}
{% block content %}
<h1>Resolve dispute ticket #{{ ticket.id }}</h1>

<table>
  <tr><th>Booking:</th><td><a href="/admin/bookings/jobbooking/{{ ticket.booking_id }}/change/">#{{ ticket.booking_id }}</a></td></tr>
  <tr><th>Opened by:</th><td>{{ ticket.opened_by }}</td></tr>
  <tr><th>Opened at:</th><td>{{ ticket.opened_at }}</td></tr>
  <tr><th>Reason:</th><td>{{ ticket.initial_reason|linebreaks }}</td></tr>
</table>

{% if evidence %}
<h3>Evidence</h3>
<div style="display: flex; gap: 8px; flex-wrap: wrap;">
  {% for ev in evidence %}
    <div>
      <a href="{{ ev.image.url }}" target="_blank">
        <img src="{{ ev.image.url }}" style="max-width: 200px; max-height: 200px; border: 1px solid #ccc;" />
      </a>
      {% if ev.caption %}<div style="font-size: 12px;">{{ ev.caption }}</div>{% endif %}
    </div>
  {% endfor %}
</div>
{% endif %}

<form method="post">
  {% csrf_token %}
  <p>
    <label>Outcome:</label><br>
    <select name="outcome" required style="min-width: 300px;">
      {% for value, label in outcomes %}<option value="{{ value }}">{{ label }}</option>{% endfor %}
    </select>
  </p>
  <p>
    <label>Final booking status:</label><br>
    <select name="final_status" required style="min-width: 300px;">
      {% for value, label in final_statuses %}<option value="{{ value }}">{{ label }}</option>{% endfor %}
    </select>
  </p>
  <p>
    <label>Resolution notes (required):</label><br>
    <textarea name="notes" rows="6" cols="80" required></textarea>
  </p>
  <p>
    <input type="submit" value="Resolve ticket" class="default" />
    <a href="/admin/bookings/supportticket/">Cancel</a>
  </p>
</form>
{% endblock %}
```

### §4.10 CLAUDE.md amendments

Three small additions at sprint end. Each goes under the relevant existing section.

#### Under "REALTIME PIPELINE — Events vs Streams"

> **Stream consumer pattern (added during booking orchestrator sprint)**: features that subscribe to a stream type register a handler with `WsFrameDispatcher.register(streamType, handler)` from a feature-side notifier. Handlers receive raw payload maps and feed them into a feature-scoped state notifier. The first reference impl is `frontend/lib/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart`. Mirror the per-event template — keep payload models in the feature's `data/models/`, never in `core/realtime/`.

#### Under "REALTIME PIPELINE" (add to the strict rules)

> **WS upstream for booking-tracking subscription** (added during booking orchestrator sprint): the WS consumer accepts exactly two upstream message types — `subscribe_tracking` and `unsubscribe_tracking`. All other client → server messages are still ignored. The amendment exists because tracking subgroups are job-scoped (multiple watchers per booking); per-user groups are insufficient. Subscription requests are authorized at the consumer (subscriber must be the booking's customer or technician); non-participants silently dropped.

#### Under "FRONTEND" → "Dumb UI Principle" (extend)

> **Modal endpoint registry (added during booking orchestrator sprint)**: server can emit `BookingUiAction.method = 'MODAL'` with `endpoint` matching a known frontend modal pattern. The action button extracts the trailing path segment to dispatch to the correct modal builder. Patterns are documented in `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` under "Modal endpoint registry." Server adds new modal patterns by emitting them; frontend adds new modal builders by extending the dispatcher. No coupling between server and frontend code beyond the endpoint string.

### §4.11 flag.md updates

Resolve flag #26:

```markdown
~~### Flag #26: Customer booking detail screen is placeholder~~

✅ **Resolved (2026-MM-DD)**

**What changed**: Booking orchestrator sprint shipped the full `BookingOrchestratorScreen` at `/booking/:job_id` covering the entire lifecycle for both customer and technician viewers. Replaces the placeholder stub from session_4 of the prior sprint. See `booking_orchestrator_sprint/` for the 6-session sprint that landed this.
```

Add new flags at bottom:

```markdown
### Flag #28: Auto no-show detection deferred

**Where**: `backend/bookings/services/orchestrator.py` (mark_no_show) + (would-be) `backend/bookings/tasks.py` (auto-detection task).

**What's wrong**: No-show detection is manual-only. Either party must tap a button. A tech who silently leaves a customer waiting can't be auto-flagged; a customer who fails to show up doesn't trigger a no-show until the tech reports it.

**Why we shipped it**: Manual is simpler and avoids GPS-jitter false positives in v1. Real-world no-show rates are low; manual coverage is acceptable for demo and early production.

**The proper fix**: Add a Celery task `auto_detect_no_show(booking_id)` armed at `arrived_at + 30min` for tech-side and `scheduled_start + 30min` for customer-side. Task checks geofence (tech's last GPS frame within 100m of customer address?) and only flips if criteria are met (tech is gone vs. has been parked there). Per-tech / per-service threshold configuration also deferred.

### Flag #29: AI Chatbot dispute intake (future sprint)

**Where**: `backend/bookings/models.py::SupportTicket.dispute_intake_method` (currently always 'FORM') + `frontend/lib/features/orchestrator/presentation/screens/dispute_open_form_screen.dart`.

**What's wrong**: The project's identity is "Smart Technician Booking Application With AI Chatbot Assistant," but dispute intake is a static form. SupportTicket schema reserves `chat_log` JSON field + `dispute_intake_method='CHATBOT'` enum value for future chatbot adapter, but no chatbot infra exists yet.

**Why we shipped it**: Chatbot integration (Claude API, conversation persistence, photo-during-chat upload) is a significant adapter; deferred to its own sprint to keep this orchestrator sprint scoped.

**The proper fix**: Build a chatbot adapter sprint:
- Wire `anthropic` SDK or equivalent.
- Add `chat_log` writes to SupportTicket (one row per turn).
- Frontend: chat-style interface for dispute intake instead of the static form.
- Auto-decide when to escalate: chatbot transitions chat_log → ticket when user requests human OR when conversation reaches a "needs admin" classifier threshold.
- The form-intake path stays alive as a fallback (e.g., when chatbot rate-limited).
```

---

## §5 Gotchas

1. **The `stub_bodies/` folder rename to `status_bodies/`** is small but breaks the import in `body_slot.dart`. Do both edits in the same commit. Search-and-replace the import + delete the old folder name from disk.
2. **`CustomerCancelModal`'s phase computation** must match backend's `cancel_by_customer` phase logic exactly (session 1 §5 transition table). Mismatches mean the UI promises a fee that backend doesn't charge (or vice versa).
3. **`TechCancelOverflowMenu` queries `availableTransitions.contains('cancel_by_tech')`** — server's transition validator (session 2 §4.10) is the source of truth. If session 2's validator is wrong for a particular status, the menu surfaces or hides incorrectly. Test this matrix.
4. **Reschedule modal's date picker `lastDate`** is +60 days from now per UX choice; if your demo window needs to schedule farther out, bump it. Document.
5. **`bookingRescheduledNotifier` (session 3) handles `pushReplacementNamed`** automatically on the rescheduled event. So `RescheduleModal._onSubmit` just pops the modal — the screen replacement happens via the event, not via direct routing. If both fire (modal pops + event arrives), the user sees a brief flash; acceptable.
6. **No-show modal's `actor_role`** is derived from `booking.viewerRole` (session 3 mapper). The button is visible only when `available_transitions` includes `mark_no_show` AND the viewer's threshold has passed (session 2 view enforces). Frontend doesn't double-check the threshold.
7. **`DisputeOpenFormScreen` requires `image_picker`** in pubspec. If not present from prior sprints, add it and request the right permissions in AndroidManifest (`READ_EXTERNAL_STORAGE` / scoped storage on Android 13+).
8. **The dispute multipart POST** uses `http.MultipartRequest` per §24's multipart pattern (audit C2-P0-04 — Dio isn't in pubspec). The data source builds the request, sets `request.fields['initial_reason'] = reason`, optionally appends `await http.MultipartFile.fromPath('photo', photo.path)`, sends via `_client.send(request)`, then converts to `http.Response.fromStream(...)` for the standard `_ensureOk` path. Endpoint URL: `${AppConstants.baseUrl}/bookings/$bookingId/disputes/` (no `/api/` prefix — audit C2-P0-01).
9. **`SlaCountdown.expiresAt`** is computed from `scheduledStart + 15min` as a fallback. If the server's actual SLA differs (the two-tier 60s/15min logic from session 1), backend should ideally emit `expiresAt` in the booking-detail response; otherwise the UI's countdown drifts from reality. Future enhancement: include `slaExpiresAt` in the detail serializer.
10. **`SlaCountdown.onExpired`** fires once when the countdown hits zero. Use it to trigger a `bookingDetailNotifier.refresh()` so the UI updates if the SLA-timeout event has already arrived (catches up if event was missed during a brief WS drop).
11. **`CancelledBodyStub.feeOwed` reading** — `pricing.finalCashToCollect` is set by backend's `cancel_by_customer` for post-accept phases. On rescheduled cancellations the field stays null since no fee is owed.
12. **`RejectedBodyStub` reason discriminator** — backend stamps `cancel_reason` for cancellations but not for rejections. For rejections, the source of truth is the EventLog entry's `payload.reason` (the original `booking_rejected` event from session 1). Frontend can either (a) re-fetch the original event OR (b) backend can include `reject_reason` on the booking detail response. Option (b) is simpler — extend session 2's serializer to include it. Open a small task in flag.md if not done.
13. **Tech-side dispute banner is always read-only** per §14 rule 5. Don't accidentally render an open-dispute button for tech viewers.
14. **`UnknownBodyStub`** is a defensive fallback for when the server emits a status string the frontend's `BookingStatus.fromWire` doesn't recognize. Renders prose + a refresh button. Forward-compat for v2 statuses.
15. **Django Admin resolve form** must validate that `final_status` is one of the three allowed (COMPLETED / COMPLETED_INSPECTION_ONLY / CANCELLED). Backend's orchestrator service validates too, but the form should pre-filter to avoid form-validation errors.
16. **Admin resolve success redirect** goes to the JobBooking change page (not the ticket changelist) — admin's mental model is "I resolved this booking's dispute, now show me the booking." If you keep the redirect to the ticket changelist, admin has to click through more.
17. **CLAUDE.md amendments** should be appended in the right sections (not at the bottom). Read the existing structure and place each amendment near the related rule.
18. **flag.md numbering**: pick the next available flag number (likely #28 / #29 if flag #27 is the most recent). Verify by `tail flag.md` before assigning numbers.
19. **Sprint-end CLAUDE.md amendments are not optional** — they document patterns introduced this sprint that future contributors (especially future-Claude) will reference. Skipping them creates the same memory-vs-session-file problem the user warned about earlier.
20. **`DisputeStatusBanner` count text** uses singular/plural based on `openTicketsCount`. Default 0 should not render the banner — defensive guard at the consumer.

---

## §6 Verification — sprint-end integration smoke

This is the **acceptance test** for the entire booking orchestrator sprint. Walks every transition end-to-end on a real device.

### Setup

```bash
# Backend
cd backend
source venv/bin/activate
python manage.py migrate
python manage.py runserver 0.0.0.0:8000 &

# Frontend
cd ../frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=MAP_PROVIDER=osm
```

Two physical Android devices (or one device + emulator) — one as customer, one as technician. Backend running. OTP `123456` (DEBUG=True).

### Acceptance test 1: Happy path

1. Customer creates a booking via existing flow.
2. Tech receives offer (incoming-job sheet).
3. Tech accepts — both screens navigate to orchestrator at CONFIRMED.
4. **CONFIRMED**: customer sees `ConfirmedBodyStub` with timestamp + scheduled time. Tech sees same.
5. Tech taps "Start journey" (manual override; auto would fire if GPS moves >200m).
6. **EN_ROUTE**: customer sees `EnRouteBodyStub` (live tracking map, polyline appears). Tech's foreground service starts (notification visible).
7. Tech taps "Mark Arrived" or auto-fires when within 100m of customer.
8. **ARRIVED**: customer sees `ArrivedBodyStub` (map smaller, "tech arrived" emphasized). Tech sees primary action "Build quote".
9. Tech taps "Build quote" — quote builder opens. `start_inspection` fires in background → status → INSPECTING.
10. Tech taps a skill chip → line item appears. Tech taps "Submit quote".
11. **QUOTED**: customer sees `QuoteApprovalCard` with line items + 3 buttons. Tech sees "Awaiting customer decision".
12. Customer taps "Approve quote".
13. **IN_PROGRESS**: customer sees status. Tech sees `CashCollectionCard` with combined "Cash Collected: Rs. X" button.
14. Tech taps the cash button → confirmation modal → tap Confirm.
15. **COMPLETED**: both see `ReceiptCard` with line items + total + cash collected timestamp.

### Acceptance test 2: Bargain loop (3 revisions)

From step 11 above:
- Customer taps "Bargain in person" → modal → enter "Can you do it for less?" → confirm.
- Tech sees status flip back to INSPECTING + nav back to quote builder pre-loaded with previous quote (or empty per design choice).
- Tech adjusts price, submits revision 2.
- Customer sees rev #2 → taps Bargain again.
- Tech submits rev #3.
- Customer taps Approve.
- Continue from step 13.

### Acceptance test 3: Decline → COMPLETED_INSPECTION_ONLY

From step 11:
- Customer taps "Decline" → modal → "Too expensive" → confirm.
- **COMPLETED_INSPECTION_ONLY**: both see `ReceiptCard` with inspection-only copy + "Cash collected: Rs. 500".

### Acceptance test 4: Cancellation matrix

For each phase (AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED), customer cancels:
- AWAITING → CANCELLED, no fee.
- CONFIRMED, EN_ROUTE → CANCELLED, Rs.500 owed.
- ARRIVED, INSPECTING, QUOTED → CANCELLED, Rs.500 owed.

Each: `CancelledBodyStub` shows reason + fee correctly.

Tech cancels (from any non-terminal except IN_PROGRESS): from overflow menu → confirmation → CANCELLED, no fee, reliability event logged (admin-visible only).

### Acceptance test 5: Reschedule

1. Customer at CONFIRMED taps "Reschedule" (secondary action).
2. Date picker → time picker → confirm.
3. Original booking → CANCELLED with reason `customer_rescheduled` (no fee).
4. Child booking created, customer's screen replaces to child booking's orchestrator screen at AWAITING.
5. Tech receives a fresh `job_new_request` for the child booking.

### Acceptance test 6: No-show

#### Tech reports customer no-show
1. After ARRIVED + 15min with no progress, tech sees "Customer didn't show" button (server-driven).
2. Tap → confirmation modal → confirm.
3. **NO_SHOW** with `actor='tech'`: both see `NoShowBodyStub` with reason.

#### Customer reports tech no-show
1. After scheduled_start + 15min without ARRIVED, customer sees "Tech didn't show" button.
2. Tap → confirm → **NO_SHOW** with `actor='customer'`.

### Acceptance test 7: Dispute flow

1. From COMPLETED status, customer taps "Report an issue" (secondary action) → navigate to `/booking/:job_id/dispute`.
2. Customer enters reason "Tap is leaking again", attaches a photo, submits.
3. **DISPUTED**: customer's screen shows `DisputedBodyStub` with banner + "admin reviewing" message. Tech's screen shows the same `DisputedBodyStub` with the read-only banner per §14 rule 5.
4. Admin opens Django Admin → SupportTicket changelist → click "Resolve" link.
5. Admin chooses outcome (e.g., REFUND_CUSTOMER), final status (COMPLETED), notes, submits.
6. Both customer and tech receive `dispute_resolved` event; orchestrator screens refresh.
7. Booking is now in the chosen final terminal status.

### Acceptance test 8: Live-tracking edge cases

- Tech moves out of network range → after 60s, customer sees "Technician offline" banner.
- Tech reconnects → banner disappears within next frame (~5s).
- Tech kills the foreground service notification (swipe away) → service stops; banner appears 60s later.
- Tech reopens the orchestrator screen → service restarts (controller's lifecycle).

### Acceptance test 9: Mid-job upsell

1. From IN_PROGRESS, tech taps "+ Add more work" link in CashCollectionCard.
2. Quote builder opens with `?upsell=true`. Existing items visible read-only.
3. Tech adds new line item, submits.
4. Status → QUOTED. Customer sees QuoteApprovalCard for the new (additional) quote.
5. Customer approves → IN_PROGRESS. CashCollectionCard amount updated.
6. Tech taps "Cash Collected" with new total → COMPLETED.

### Static / unit checks

```bash
cd frontend
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib/ test/
cd ../backend
pytest -q
python manage.py check
```

### Constraint final checks

```bash
# Single switch on BookingStatus across the entire frontend
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/
# Expected: 1 hit (body_slot.dart)

# No /api/ URL strings in widgets
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/
# Expected: empty

# Orchestrator service is the only mutator of JobBooking.status (plus the existing 3)
grep -rn "\\.status =" backend/bookings/
# Expected: orchestrator.py + instant_book_service.py + job_request_action.py + tasks.py only

# All new event types in enum (frontend)
grep -E "quoteRevisionRequested|quoteDeclined|bookingCancelled|bookingNoShow|bookingRescheduled" frontend/lib/core/realtime/domain/entities/system_event_type.dart

# Modal endpoint registry documented
grep -n "Modal endpoint registry" frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md
```

### flag.md final state

```bash
grep -n "Flag #26" flag.md           # should show ✅ Resolved
grep -n "Flag #28\|Flag #29" flag.md  # should show new opens
```

---

## §7 What this session does NOT fix

- AI chatbot dispute intake — flag #29 future sprint.
- Auto no-show detection — flag #28 future sprint.
- Reviews / ratings — separate sprint.
- Real wallet writes — finance sprint.
- iOS foreground location service — flag #10.
- Per-tech / per-service geofence radius config — env-level only.
- Per-tech / per-service no-show threshold config — hardcoded 15min for now.
- Receipt PDF / share / export — out of v1.
- Polished animation transitions between status changes — micro-polish, not in v1.
- Stitch design tokens applied to orchestrator — planned UI cleanup pass per memory.

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All new files under `lib/features/orchestrator/{data,domain,presentation}/` created (cancellation, reschedule, no-show, dispute).
- [ ] `core/widgets/timing/sla_countdown.dart` created.
- [ ] `core/routing/app_router.dart` updated with `/booking/:job_id/dispute` route.
- [ ] `BookingOrchestratorActionButton._openModal` extended for new modal endpoints.
- [ ] `BookingOrchestratorScreen` AppBar wires `TechCancelOverflowMenu`.
- [ ] 7 polished stub bodies replace placeholders (`Awaiting`, `Confirmed`, `Cancelled`, `Rejected`, `NoShow`, `Disputed`, `Unknown`).
- [ ] Folder rename `stub_bodies/` → `status_bodies/`; import in `body_slot.dart` updated.
- [ ] `bookings/admin.py` resolve view polished (validation, success messages, redirect).
- [ ] `bookings/templates/admin/bookings/supportticket/resolve.html` polished.

### Tests

- [ ] `flutter test` green on the full suite.
- [ ] `pytest -q` (backend) green.
- [ ] All new repository / notifier / widget tests pass.
- [ ] `SlaCountdown` test uses virtual clock and verifies tickdown + onExpired callback.
- [ ] `test_admin_resolve_dispute_polish.py` covers: form submit happy path, missing-field rejection, already-resolved rejection, redirect target.

### Acceptance test (manual)

- [ ] All 9 acceptance tests in §6 pass on a physical Android device.

### Constraints (per CLAUDE.md + sprint meta)

- [ ] Single status switch in `BodySlot` only (grep-confirmed).
- [ ] No `/api/` URL strings in widgets.
- [ ] Tech sees no dispute or reschedule buttons (per §14 rule 5).
- [ ] Tech-cancel only in overflow menu (per §14 rule 6).
- [ ] No-show is single-tap with single confirmation (per §14 rule 7).
- [ ] Server is authoritative on `available_transitions`; frontend doesn't pre-validate.

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` final pass: complete coverage of all 14 transitions, all 13 statuses, all event types, all modal endpoints, the SLA countdown widget, the dispute flow, the admin resolve flow.
- [ ] CLAUDE.md amendments added in the right sections (not appended at bottom).

### flag.md

- [ ] Flag #26 resolved with strikethrough + ✅ + date + "What changed" block.
- [ ] Flag #28 (`auto-no-show-detection-deferred`) opened with full schema.
- [ ] Flag #29 (`ai-chatbot-intake-future-sprint`) opened with full schema.

### Sprint completion

- [ ] All 6 session files exist in `booking_orchestrator_sprint/`.
- [ ] `BOOKING_ORCHESTRATOR_SPRINT.md` reflects sprint completion (no outstanding `[TBD]` markers).
- [ ] `git status` clean.
- [ ] Final commit message: `feat(orchestrator): lifecycle edges + polish + sprint completion (sprint v1, session 6)`.
- [ ] Sprint demo recorded (optional but recommended) — video walking through happy path + bargain + dispute on a physical device.

---

## §9 Sprint wrap-up note (this is the last session)

Six sessions delivered the full booking orchestrator end-to-end:

- **Session 1**: backend foundations — status enum, models, finance ports, central orchestrator service.
- **Session 2**: backend HTTP + WS — every transition endpoint, `tech_gps` stream, dynamic subgroup subscription, admin resolve action.
- **Session 3**: frontend skeleton — one screen, slot architecture, per-event notifiers, stubs for every status.
- **Session 4**: live tracking — dual-provider maps (Google + OSM), Android foreground GPS service, customer-side stream consumer, polyline + ETA, offline banner.
- **Session 5**: quote flow + cash collection — chip-stack quote builder with bargain loop, customer approval card with 3-action, single-tap cash collection.
- **Session 6**: lifecycle edges + polish — cancellation/reschedule/no-show/dispute flows, SLA countdown, admin resolve form, polished terminal stubs, sprint-end CLAUDE.md amendments, flag #26 closure.

**What's next** (post-sprint):
- Finance sprint — `WalletTransaction`, `JobCommission`, JazzCash top-up, real adapter for the finance ports.
- AI chatbot adapter sprint — replaces dispute form intake; `dispute_intake_method='CHATBOT'` becomes live.
- iOS foreground location — flag #10 (requires Mac).
- Reviews / ratings — separate small sprint.
- Production hardening — self-hosted OSRM (or Mapbox), Google Maps API key provisioning, distributed `tech_location` throttling.

The architecture should support all of these as additive sessions — no orchestrator code needs to change.
