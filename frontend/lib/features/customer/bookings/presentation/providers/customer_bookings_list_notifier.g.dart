// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_bookings_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerBookingsList)
final customerBookingsListProvider = CustomerBookingsListProvider._();

final class CustomerBookingsListProvider
    extends
        $AsyncNotifierProvider<
          CustomerBookingsList,
          CustomerBookingsListState
        > {
  CustomerBookingsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsListHash();

  @$internal
  @override
  CustomerBookingsList create() => CustomerBookingsList();
}

String _$customerBookingsListHash() =>
    r'8d552a2214892d91c6935465be9cd49f626789ae';

abstract class _$CustomerBookingsList
    extends $AsyncNotifier<CustomerBookingsListState> {
  FutureOr<CustomerBookingsListState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CustomerBookingsListState>,
              CustomerBookingsListState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CustomerBookingsListState>,
                CustomerBookingsListState
              >,
              AsyncValue<CustomerBookingsListState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
