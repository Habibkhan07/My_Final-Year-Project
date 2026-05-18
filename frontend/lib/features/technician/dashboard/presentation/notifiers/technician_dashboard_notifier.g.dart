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
  TechnicianDashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardProvider',
        isAutoDispose: false,
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
    r'eb1f20fbbc6569aa0afad71cb78cb5efcaca4c11';

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
