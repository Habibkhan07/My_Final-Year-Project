// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(TechnicianDashboardNotifier)
final technicianDashboardProvider = TechnicianDashboardNotifierProvider._();

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
final class TechnicianDashboardNotifierProvider
    extends
        $AsyncNotifierProvider<
          TechnicianDashboardNotifier,
          TechnicianDashboardState
        > {
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
  TechnicianDashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianDashboardNotifierHash();

  @$internal
  @override
  TechnicianDashboardNotifier create() => TechnicianDashboardNotifier();
}

String _$technicianDashboardNotifierHash() =>
    r'969602ea6c0cf215e0abb4d7dea248084612339f';

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

abstract class _$TechnicianDashboardNotifier
    extends $AsyncNotifier<TechnicianDashboardState> {
  FutureOr<TechnicianDashboardState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TechnicianDashboardState>,
              TechnicianDashboardState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TechnicianDashboardState>,
                TechnicianDashboardState
              >,
              AsyncValue<TechnicianDashboardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
