// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_action_executor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orchestratorAuthTokenReader)
final orchestratorAuthTokenReaderProvider =
    OrchestratorAuthTokenReaderProvider._();

final class OrchestratorAuthTokenReaderProvider
    extends
        $FunctionalProvider<
          IAuthTokenReader,
          IAuthTokenReader,
          IAuthTokenReader
        >
    with $Provider<IAuthTokenReader> {
  OrchestratorAuthTokenReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orchestratorAuthTokenReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orchestratorAuthTokenReaderHash();

  @$internal
  @override
  $ProviderElement<IAuthTokenReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAuthTokenReader create(Ref ref) {
    return orchestratorAuthTokenReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAuthTokenReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAuthTokenReader>(value),
    );
  }
}

String _$orchestratorAuthTokenReaderHash() =>
    r'd1e37a2bbce49ee388a20e3fbda220d3165eedec';

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
    r'56ab6feb7c3bb7335981709de3dd63a8697c4aff';
