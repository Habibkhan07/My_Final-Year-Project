import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/common/wallet_lockout.dart' as lockout;
import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../domain/repositories/technician_dashboard_repository.dart';
import '../providers/dependency_injection.dart';
import '../state/technician_dashboard_state.dart';

part 'technician_dashboard_notifier.g.dart';

/// State holder for the technician dashboard screen.
///
/// The notifier deliberately exposes three distinct mutation surfaces so the
/// realtime event pipeline can be wired in later without rewriting the
/// presentation layer:
///
///   1. [refresh]                — full re-fetch from the backend.
///   2. [setOnline]              — user-initiated online toggle (optimistic).
///   3. [onWalletBalanceEvent] / [onForcedOfflineEvent]
///                               — single-field patches the realtime router
///                                 will call when low-urgency events arrive.
///
/// Why patch methods instead of forcing a full refresh on every event:
/// low-urgency events (wallet credited, threshold crossed) arrive frequently
/// and only mutate one field. A whole-screen refetch would burn data and
/// flash the AsyncLoading state across UI that doesn't depend on the changed
/// field.
///
/// **keepAlive: true** so that:
///   * The notifier wakes at boot (via `realtimeTechnicianBootHooksProvider`
///     — the tech-only registry that `bootAfterAuth` iterates only when
///     `isTechnician=true`) and subscribes to `systemEventProvider`
///     BEFORE the first WS frame, so events that arrive while the
///     dashboard tab isn't open still refresh the cached state when
///     the user navigates to it.
///   * The notifier survives bottom-nav tab switches — switching to
///     Jobs / Wallet / Profile and back returns to a still-fresh
///     dashboard rather than re-fetching on every tap.
@Riverpod(keepAlive: true)
class TechnicianDashboardNotifier extends _$TechnicianDashboardNotifier {
  @override
  Future<TechnicianDashboardState> build() async {
    // Subscribe to the realtime event firehose. Any event that can shift
    // the dashboard's denormalised aggregates (up-next, counts, wallet,
    // online-eligibility) triggers a re-fetch. The notifier is
    // keepAlive: true + registered with realtimeTechnicianBootHooksProvider,
    // so events arriving while the tech is on a different tab still hit
    // the listener (registration is gated by `isTechnician=true`, which
    // is always the case if this notifier is being consumed).
    //
    // Reasoning per event:
    //   * jobAccepted → up-next card materialises (tech just accepted).
    //   * jobCompleted → completedToday + payout aggregates change;
    //     up-next may now point at the next job.
    //   * bookingRejected / bookingCancelled / bookingNoShow / quoteDeclined
    //     → up-next may need to scroll forward; counts change.
    //   * paymentReceived → cashCollectedToday + payout change.
    //   * bookingRescheduled → up-next may now be a different booking.
    //   * walletLowBalance → balance + isOnline both must reflect
    //     lockout; safer to refetch than to patch in case the backend
    //     also dropped a job assignment in the same transaction.
    //   * techEnRoute / techArrived / inspectionStarted / quoteGenerated /
    //     quoteApproved / quoteRevisionRequested / disputeOpened → the
    //     row leaves CONFIRMED so the dashboard's `status=CONFIRMED`
    //     filter drops it. Without these, up_next stays stale until
    //     pull-to-refresh while the Schedule tab (which listens to all of
    //     them) shows the truth. The two surfaces must agree.
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      switch (event.eventType) {
        case SystemEventType.jobAccepted:
        case SystemEventType.jobCompleted:
        case SystemEventType.bookingRejected:
        case SystemEventType.bookingCancelled:
        case SystemEventType.bookingNoShow:
        case SystemEventType.quoteDeclined:
        case SystemEventType.paymentReceived:
        case SystemEventType.bookingRescheduled:
        case SystemEventType.walletLowBalance:
        // Mid-job transitions out of CONFIRMED. The BE dashboard selector
        // (`dashboard_selector.get_technician_dashboard`) filters
        // up_next_job / later_today_jobs to `status=CONFIRMED` only — the
        // moment the tech presses "On my way" / "I've arrived" / etc., the
        // row stops qualifying and up_next must promote to the next booking
        // (or null). Without these events the dashboard would lie about
        // up_next until pull-to-refresh — and the Schedule tab (which DOES
        // listen to mid-job events) would silently disagree with the
        // dashboard's denormalised view. Listening here keeps the two
        // surfaces consistent.
        case SystemEventType.techEnRoute:
        case SystemEventType.techArrived:
        case SystemEventType.inspectionStarted:
        case SystemEventType.quoteGenerated:
        case SystemEventType.quoteApproved:
        case SystemEventType.quoteRevisionRequested:
        case SystemEventType.disputeOpened:
          _scheduleRefresh();
          break;
        case SystemEventType.walletBalanceUpdated:
          // Single-field patch — wallet ledger writes broadcast the new
          // balance after every commit. Patch the pill in place so the
          // dashboard doesn't flash a skeleton on every commission row.
          final raw = event.payload['balance'];
          final parsed = raw is String ? double.tryParse(raw) : null;
          if (parsed != null) {
            onWalletBalanceEvent(parsed);
          }
          break;
        // ignore: no_default_cases
        default:
          break;
      }
    });

    final dashboard = await ref
        .read(technicianDashboardRepositoryProvider)
        .getDashboard();
    return TechnicianDashboardState(dashboard: dashboard);
  }

  /// Re-fetches the dashboard from the backend. Used by pull-to-refresh and
  /// by the realtime router for high-urgency events that may have invalidated
  /// multiple fields at once (e.g. a job moving from upcoming → in-progress).
  ///
  /// Uses `.copyWithPrevious(state)` (CLAUDE.md `AsyncValue.guard` pattern)
  /// so the cached value stays visible during the round trip — pull-to-
  /// refresh shows the spinner without flashing a skeleton.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final dashboard = await ref
          .read(technicianDashboardRepositoryProvider)
          .getDashboard();
      return TechnicianDashboardState(dashboard: dashboard);
    });
  }

  /// Fire-and-forget refresh from inside the event listener. Mirrors the
  /// customer_bookings_counts_notifier pattern: the listener is sync; the
  /// awaited state flows through `state =` like any other async mutation.
  void _scheduleRefresh() {
    refresh();
  }

  /// User-initiated online/offline toggle.
  ///
  /// Performs an optimistic flip so the UI feels instant, then awaits the
  /// (future) backend round-trip wrapped in [AsyncValue.guard]. On failure
  /// the optimistic flip is rolled back and [TechnicianDashboardState.toggleStatus]
  /// surfaces the error to the toggle widget without touching the rest of
  /// the screen.
  ///
  /// Backend persistence is currently a no-op stub — `POST /api/technicians/online/`
  /// does not exist yet. Wiring it is a one-line change inside the guard.
  /// The optimistic update is intentionally kept so the seam is exercised by
  /// tests and the UI today; the realtime pipeline's [onForcedOfflineEvent]
  /// already handles the inverse direction (backend forcing offline).
  ///
  /// **Lockout gate.** A tech with ``walletBalance < 0`` cannot flip themselves
  /// online. Mirrors backend B4 ``accept_job_booking`` gate — the would-be
  /// `POST /api/technicians/online/` would refuse with `wallet_lockout`, so
  /// the client refuses up front. Going OFFLINE while locked is still allowed
  /// (always safe to opt out of work). The toggle widget is visually disabled
  /// when locked; this is defense in depth.
  ///
  /// No-op when the dashboard hasn't loaded yet — the toggle widget is
  /// disabled in that state, but the guard makes the contract explicit.
  Future<void> setOnline(bool desired) async {
    if (state is! AsyncData<TechnicianDashboardState>) return;
    final current = state.requireValue;

    final previousIsOnline = current.dashboard.isOnline;
    if (previousIsOnline == desired) return;

    // Lockout gate: locked tech cannot flip themselves ONLINE. Going
    // offline is always allowed. Rule is shared with the banner + wallet
    // entity via ``core/common/wallet_lockout.dart``.
    if (desired && lockout.isWalletLocked(current.dashboard.walletBalance)) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        dashboard: current.dashboard.copyWith(isOnline: desired),
        toggleStatus: const AsyncLoading(),
      ),
    );

    // Persist the toggle to the backend. The response carries the
    // post-commit `is_online` AND the fresh wallet balance — patched
    // back into local state below so a top-up that landed between the
    // dashboard's last refresh and this tap is reconciled in the same
    // round trip (avoids the "tech thinks they're locked but actually
    // topped up two seconds ago" race).
    final result = await AsyncValue.guard<OnlineToggleResult>(() async {
      return ref.read(technicianDashboardRepositoryProvider).setOnline(desired);
    });

    if (state is! AsyncData<TechnicianDashboardState>) return;
    final after = state.requireValue;

    if (result is AsyncError) {
      // Revert optimistic flip on any failure (wallet_lockout, network,
      // permission denied). The error itself is surfaced via the
      // toggleStatus AsyncValue, which the screen listens to and maps
      // to a short snackbar (see technician_dashboard_screen.dart).
      state = AsyncData(
        after.copyWith(
          dashboard: after.dashboard.copyWith(isOnline: previousIsOnline),
          toggleStatus: result,
        ),
      );
    } else {
      // Reconcile local state from the server's authoritative shape.
      // The response's `isOnline` already matches our optimistic flip
      // (otherwise the server would have raised); the `walletBalance`
      // might differ if a top-up or commission landed mid-request.
      final patched = result.requireValue;
      state = AsyncData(
        after.copyWith(
          dashboard: after.dashboard.copyWith(
            isOnline: patched.isOnline,
            walletBalance: patched.walletBalance,
          ),
          toggleStatus: const AsyncData(null),
        ),
      );
    }
  }

  /// Patches the cached wallet balance from a realtime event.
  ///
  /// Wired by the realtime event router when a low-urgency
  /// `WALLET_BALANCE_UPDATED` event arrives. Single-field patch: the rest
  /// of the dashboard entity is preserved, no AsyncLoading flash.
  ///
  /// **Auto-offline on negative-balance crossover.** When the new balance is
  /// `< 0` and the tech is currently online, the same patch ALSO flips
  /// `isOnline` to false. Mirrors backend `wallet.services.ledger` B6 —
  /// the ledger row write and the auto-offline are atomic on the server,
  /// and we replicate that atomicity on the client so the toggle pill and
  /// lockout banner stay in sync without a second round-trip. Top-ups that
  /// clear lockout do NOT auto-flip back to online (intentional asymmetric
  /// recovery — see memory `wallet-money-mechanics`).
  ///
  /// Silently ignored if the dashboard hasn't loaded yet — events that
  /// arrive before first paint will be reconciled by the upcoming
  /// [build]/refresh call.
  void onWalletBalanceEvent(double newBalance) {
    if (state is! AsyncData<TechnicianDashboardState>) return;
    final current = state.requireValue;

    // Mirror B6 backend: balance going underwater forces offline in the
    // same patch. Condition checks current.dashboard.isOnline so a
    // subsequent balance event on an already-offline tech is a no-op
    // for the column. Lockout rule shared via core/common/wallet_lockout.
    final shouldForceOffline =
        lockout.isWalletLocked(newBalance) && current.dashboard.isOnline;

    state = AsyncData(
      current.copyWith(
        dashboard: current.dashboard.copyWith(
          walletBalance: newBalance,
          isOnline: shouldForceOffline ? false : current.dashboard.isOnline,
        ),
      ),
    );
  }

  /// Forces the technician offline in response to a backend event.
  ///
  /// Wired by the realtime event router when the backend emits a forced-
  /// offline event (canonical case: wallet balance dropped below the
  /// commission threshold, so the technician is ineligible for matchmaking).
  /// The user cannot self-recover from this until they top up — a subsequent
  /// [setOnline]`(true)` call will succeed only if the backend permits it.
  ///
  /// Silently ignored if the dashboard hasn't loaded yet.
  void onForcedOfflineEvent() {
    if (state is! AsyncData<TechnicianDashboardState>) return;
    final current = state.requireValue;
    if (!current.dashboard.isOnline) return;
    state = AsyncData(
      current.copyWith(dashboard: current.dashboard.copyWith(isOnline: false)),
    );
  }
}
