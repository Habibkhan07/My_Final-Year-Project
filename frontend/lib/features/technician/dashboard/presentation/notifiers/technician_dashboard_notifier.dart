import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/common/wallet_lockout.dart' as lockout;
import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
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
///   * The notifier wakes at boot (via `realtimeBootHooksProvider`) and
///     subscribes to `systemEventProvider` BEFORE the first WS frame, so
///     events that arrive while the dashboard tab isn't open still
///     refresh the cached state when the user navigates to it.
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
    // keepAlive: true + registered with realtimeBootHooksProvider, so
    // events arriving while the tech is on a different tab still hit
    // the listener.
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

    final result = await AsyncValue.guard<void>(() async {
      // TODO(dashboard): call repository.setOnline(desired) once
      // POST /api/technicians/online/ exists. Until then the optimistic
      // flip above is the only effect.
    });

    if (state is! AsyncData<TechnicianDashboardState>) return;
    final after = state.requireValue;

    if (result is AsyncError) {
      state = AsyncData(
        after.copyWith(
          dashboard: after.dashboard.copyWith(isOnline: previousIsOnline),
          toggleStatus: result,
        ),
      );
    } else {
      state = AsyncData(after.copyWith(toggleStatus: result));
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
