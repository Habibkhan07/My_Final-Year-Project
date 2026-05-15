// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_schedule_segment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedScheduleSegment)
final selectedScheduleSegmentProvider = SelectedScheduleSegmentProvider._();

final class SelectedScheduleSegmentProvider
    extends $NotifierProvider<SelectedScheduleSegment, ScheduledJobSegment> {
  SelectedScheduleSegmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedScheduleSegmentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedScheduleSegmentHash();

  @$internal
  @override
  SelectedScheduleSegment create() => SelectedScheduleSegment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScheduledJobSegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScheduledJobSegment>(value),
    );
  }
}

String _$selectedScheduleSegmentHash() =>
    r'406b8491bff2813b5d19bf14a861f73ad131e0b7';

abstract class _$SelectedScheduleSegment
    extends $Notifier<ScheduledJobSegment> {
  ScheduledJobSegment build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScheduledJobSegment, ScheduledJobSegment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScheduledJobSegment, ScheduledJobSegment>,
              ScheduledJobSegment,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
