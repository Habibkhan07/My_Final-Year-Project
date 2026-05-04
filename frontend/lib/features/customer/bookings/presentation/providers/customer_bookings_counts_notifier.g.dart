// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_bookings_counts_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerBookingsCounts)
final customerBookingsCountsProvider = CustomerBookingsCountsProvider._();

final class CustomerBookingsCountsProvider
    extends $AsyncNotifierProvider<CustomerBookingsCounts, BookingsCounts> {
  CustomerBookingsCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsCountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsCountsHash();

  @$internal
  @override
  CustomerBookingsCounts create() => CustomerBookingsCounts();
}

String _$customerBookingsCountsHash() =>
    r'cfd2a4985df0d372a849fac6e7ee9e555a45348f';

abstract class _$CustomerBookingsCounts extends $AsyncNotifier<BookingsCounts> {
  FutureOr<BookingsCounts> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BookingsCounts>, BookingsCounts>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BookingsCounts>, BookingsCounts>,
              AsyncValue<BookingsCounts>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
