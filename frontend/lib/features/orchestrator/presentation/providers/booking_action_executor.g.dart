// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_action_executor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookingActionExecutor)
final bookingActionExecutorProvider = BookingActionExecutorProvider._();

final class BookingActionExecutorProvider
    extends
        $FunctionalProvider<
          BookingActionExecutor,
          BookingActionExecutor,
          BookingActionExecutor
        >
    with $Provider<BookingActionExecutor> {
  BookingActionExecutorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingActionExecutorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingActionExecutorHash();

  @$internal
  @override
  $ProviderElement<BookingActionExecutor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookingActionExecutor create(Ref ref) {
    return bookingActionExecutor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingActionExecutor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingActionExecutor>(value),
    );
  }
}

String _$bookingActionExecutorHash() =>
    r'32f858dcb547c29e25aa9daa497872aae894fce5';
