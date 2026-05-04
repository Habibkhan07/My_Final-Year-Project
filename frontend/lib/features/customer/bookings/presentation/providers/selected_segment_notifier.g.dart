// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_segment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSegment)
final selectedSegmentProvider = SelectedSegmentProvider._();

final class SelectedSegmentProvider
    extends $NotifierProvider<SelectedSegment, BookingSegment> {
  SelectedSegmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSegmentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSegmentHash();

  @$internal
  @override
  SelectedSegment create() => SelectedSegment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingSegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingSegment>(value),
    );
  }
}

String _$selectedSegmentHash() => r'95a1a0a8a056b1e1b377319a13b2cc88f3cb8abd';

abstract class _$SelectedSegment extends $Notifier<BookingSegment> {
  BookingSegment build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BookingSegment, BookingSegment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingSegment, BookingSegment>,
              BookingSegment,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
