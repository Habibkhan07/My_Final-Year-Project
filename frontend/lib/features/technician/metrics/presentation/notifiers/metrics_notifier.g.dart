// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State holder for the technician metrics row on the dashboard.
///
/// **keepAlive: false** — metrics are per-session fresh data. When the
/// dashboard is disposed (e.g. during a booking flow), the notifier
/// disposes and re-fetches on return, ensuring the counts reflect any
/// jobs completed while away.
///
/// Pull-to-refresh is delegated to [refresh]. The dashboard screen
/// calls this when the user drags the RefreshIndicator, same as the
/// dashboard notifier itself.

@ProviderFor(MetricsNotifier)
final metricsProvider = MetricsNotifierProvider._();

/// State holder for the technician metrics row on the dashboard.
///
/// **keepAlive: false** — metrics are per-session fresh data. When the
/// dashboard is disposed (e.g. during a booking flow), the notifier
/// disposes and re-fetches on return, ensuring the counts reflect any
/// jobs completed while away.
///
/// Pull-to-refresh is delegated to [refresh]. The dashboard screen
/// calls this when the user drags the RefreshIndicator, same as the
/// dashboard notifier itself.
final class MetricsNotifierProvider
    extends $AsyncNotifierProvider<MetricsNotifier, TechnicianMetricsEntity> {
  /// State holder for the technician metrics row on the dashboard.
  ///
  /// **keepAlive: false** — metrics are per-session fresh data. When the
  /// dashboard is disposed (e.g. during a booking flow), the notifier
  /// disposes and re-fetches on return, ensuring the counts reflect any
  /// jobs completed while away.
  ///
  /// Pull-to-refresh is delegated to [refresh]. The dashboard screen
  /// calls this when the user drags the RefreshIndicator, same as the
  /// dashboard notifier itself.
  MetricsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsNotifierHash();

  @$internal
  @override
  MetricsNotifier create() => MetricsNotifier();
}

String _$metricsNotifierHash() => r'919bcbbec573856d5cc719ed536e98d87350859c';

/// State holder for the technician metrics row on the dashboard.
///
/// **keepAlive: false** — metrics are per-session fresh data. When the
/// dashboard is disposed (e.g. during a booking flow), the notifier
/// disposes and re-fetches on return, ensuring the counts reflect any
/// jobs completed while away.
///
/// Pull-to-refresh is delegated to [refresh]. The dashboard screen
/// calls this when the user drags the RefreshIndicator, same as the
/// dashboard notifier itself.

abstract class _$MetricsNotifier
    extends $AsyncNotifier<TechnicianMetricsEntity> {
  FutureOr<TechnicianMetricsEntity> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TechnicianMetricsEntity>,
              TechnicianMetricsEntity
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TechnicianMetricsEntity>,
                TechnicianMetricsEntity
              >,
              AsyncValue<TechnicianMetricsEntity>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
