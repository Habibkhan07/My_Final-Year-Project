import 'package:riverpod_annotation/riverpod_annotation.dart';

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
@riverpod
class TechnicianDashboardNotifier extends _$TechnicianDashboardNotifier {
  @override
  Future<TechnicianDashboardState> build() async {
    final dashboard =
        await ref.read(technicianDashboardRepositoryProvider).getDashboard();
    return TechnicianDashboardState(dashboard: dashboard);
  }

  /// Re-fetches the dashboard from the backend. Used by pull-to-refresh and
  /// by the realtime router for high-urgency events that may have invalidated
  /// multiple fields at once (e.g. a job moving from upcoming → in-progress).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dashboard =
          await ref.read(technicianDashboardRepositoryProvider).getDashboard();
      return TechnicianDashboardState(dashboard: dashboard);
    });
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
  /// No-op when the dashboard hasn't loaded yet — the toggle widget is
  /// disabled in that state, but the guard makes the contract explicit.
  Future<void> setOnline(bool desired) async {
    final current = state.value;
    if (current == null) return;

    final previousIsOnline = current.dashboard.isOnline;
    if (previousIsOnline == desired) return;

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

    final after = state.value;
    if (after == null) return;

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
  /// Silently ignored if the dashboard hasn't loaded yet — events that
  /// arrive before first paint will be reconciled by the upcoming
  /// [build]/refresh call.
  void onWalletBalanceEvent(double newBalance) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        dashboard: current.dashboard.copyWith(walletBalance: newBalance),
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
    final current = state.value;
    if (current == null) return;
    if (!current.dashboard.isOnline) return;
    state = AsyncData(
      current.copyWith(
        dashboard: current.dashboard.copyWith(isOnline: false),
      ),
    );
  }
}
