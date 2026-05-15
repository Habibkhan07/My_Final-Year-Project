// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_jobs_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduledJobsList)
final scheduledJobsListProvider = ScheduledJobsListProvider._();

final class ScheduledJobsListProvider
    extends $AsyncNotifierProvider<ScheduledJobsList, ScheduledJobsListState> {
  ScheduledJobsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsListHash();

  @$internal
  @override
  ScheduledJobsList create() => ScheduledJobsList();
}

String _$scheduledJobsListHash() => r'f1372335979b358a04d5838326cce0eb2f44189c';

abstract class _$ScheduledJobsList
    extends $AsyncNotifier<ScheduledJobsListState> {
  FutureOr<ScheduledJobsListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ScheduledJobsListState>, ScheduledJobsListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ScheduledJobsListState>,
                ScheduledJobsListState
              >,
              AsyncValue<ScheduledJobsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
