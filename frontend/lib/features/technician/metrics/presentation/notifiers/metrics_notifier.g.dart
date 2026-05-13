// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metrics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State holder for the technician Metrics screen.
///
/// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
/// caches its own response independently. Tapping the segmented toggle is
/// a provider-key change, not a refetch — already-loaded periods snap back
/// instantly; new periods fetch on first read.
///
/// **keepAlive: false** — when the user backs out of the Metrics screen the
/// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
/// any jobs completed while away.

@ProviderFor(MetricsNotifier)
final metricsProvider = MetricsNotifierFamily._();

/// State holder for the technician Metrics screen.
///
/// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
/// caches its own response independently. Tapping the segmented toggle is
/// a provider-key change, not a refetch — already-loaded periods snap back
/// instantly; new periods fetch on first read.
///
/// **keepAlive: false** — when the user backs out of the Metrics screen the
/// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
/// any jobs completed while away.
final class MetricsNotifierProvider
    extends $AsyncNotifierProvider<MetricsNotifier, TechnicianMetricsEntity> {
  /// State holder for the technician Metrics screen.
  ///
  /// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
  /// caches its own response independently. Tapping the segmented toggle is
  /// a provider-key change, not a refetch — already-loaded periods snap back
  /// instantly; new periods fetch on first read.
  ///
  /// **keepAlive: false** — when the user backs out of the Metrics screen the
  /// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
  /// any jobs completed while away.
  MetricsNotifierProvider._({
    required MetricsNotifierFamily super.from,
    required MetricsPeriod super.argument,
  }) : super(
         retry: null,
         name: r'metricsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$metricsNotifierHash();

  @override
  String toString() {
    return r'metricsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MetricsNotifier create() => MetricsNotifier();

  @override
  bool operator ==(Object other) {
    return other is MetricsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$metricsNotifierHash() => r'3413b8ed3ce4a45822258bcbf1d5b2471ea51217';

/// State holder for the technician Metrics screen.
///
/// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
/// caches its own response independently. Tapping the segmented toggle is
/// a provider-key change, not a refetch — already-loaded periods snap back
/// instantly; new periods fetch on first read.
///
/// **keepAlive: false** — when the user backs out of the Metrics screen the
/// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
/// any jobs completed while away.

final class MetricsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MetricsNotifier,
          AsyncValue<TechnicianMetricsEntity>,
          TechnicianMetricsEntity,
          FutureOr<TechnicianMetricsEntity>,
          MetricsPeriod
        > {
  MetricsNotifierFamily._()
    : super(
        retry: null,
        name: r'metricsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// State holder for the technician Metrics screen.
  ///
  /// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
  /// caches its own response independently. Tapping the segmented toggle is
  /// a provider-key change, not a refetch — already-loaded periods snap back
  /// instantly; new periods fetch on first read.
  ///
  /// **keepAlive: false** — when the user backs out of the Metrics screen the
  /// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
  /// any jobs completed while away.

  MetricsNotifierProvider call(MetricsPeriod period) =>
      MetricsNotifierProvider._(argument: period, from: this);

  @override
  String toString() => r'metricsProvider';
}

/// State holder for the technician Metrics screen.
///
/// **Family-keyed by [MetricsPeriod]** so each tab (Day/Week/Month/Year)
/// caches its own response independently. Tapping the segmented toggle is
/// a provider-key change, not a refetch — already-loaded periods snap back
/// instantly; new periods fetch on first read.
///
/// **keepAlive: false** — when the user backs out of the Metrics screen the
/// notifier disposes; re-entry triggers a fresh fetch so the numbers reflect
/// any jobs completed while away.

abstract class _$MetricsNotifier
    extends $AsyncNotifier<TechnicianMetricsEntity> {
  late final _$args = ref.$arg as MetricsPeriod;
  MetricsPeriod get period => _$args;

  FutureOr<TechnicianMetricsEntity> build(MetricsPeriod period);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
