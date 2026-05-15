// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_jobs_counts_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduledJobsCountsNotifier)
final scheduledJobsCountsProvider = ScheduledJobsCountsNotifierProvider._();

final class ScheduledJobsCountsNotifierProvider
    extends
        $AsyncNotifierProvider<
          ScheduledJobsCountsNotifier,
          ScheduledJobsCounts
        > {
  ScheduledJobsCountsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsCountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsCountsNotifierHash();

  @$internal
  @override
  ScheduledJobsCountsNotifier create() => ScheduledJobsCountsNotifier();
}

String _$scheduledJobsCountsNotifierHash() =>
    r'32084eff0b409287e800b88aa07a2030cd4e65e6';

abstract class _$ScheduledJobsCountsNotifier
    extends $AsyncNotifier<ScheduledJobsCounts> {
  FutureOr<ScheduledJobsCounts> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ScheduledJobsCounts>, ScheduledJobsCounts>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ScheduledJobsCounts>, ScheduledJobsCounts>,
              AsyncValue<ScheduledJobsCounts>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
