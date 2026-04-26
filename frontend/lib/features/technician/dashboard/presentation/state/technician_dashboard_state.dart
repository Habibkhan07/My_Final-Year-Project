import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/technician_dashboard_entity.dart';

part 'technician_dashboard_state.freezed.dart';

/// Composite state for the technician dashboard screen.
///
/// `dashboard` holds the loaded payload from `GET /api/technicians/dashboard/`
/// and is the surface that realtime event patches (wallet balance, forced
/// offline) mutate in place — the whole-screen `AsyncValue` wrapper around
/// this state must NEVER flip to loading for those patches, or the UI would
/// flash a spinner every time a low-urgency event lands.
///
/// `toggleStatus` is a sub-AsyncValue dedicated to the online/offline toggle
/// mutation. Keeping it separate from the screen-level AsyncValue means a
/// failed toggle surfaces an error to the toggle widget without wiping the
/// dashboard data the rest of the screen depends on.
@freezed
abstract class TechnicianDashboardState with _$TechnicianDashboardState {
  const factory TechnicianDashboardState({
    required TechnicianDashboardEntity dashboard,
    @Default(AsyncValue.data(null)) AsyncValue<void> toggleStatus,
  }) = _TechnicianDashboardState;
}
