// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orchestratorSecureStorage)
final orchestratorSecureStorageProvider = OrchestratorSecureStorageProvider._();

final class OrchestratorSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  OrchestratorSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orchestratorSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orchestratorSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return orchestratorSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$orchestratorSecureStorageHash() =>
    r'8a5e6432008e32455ddcc228a6a3426d906ccf5f';

@ProviderFor(bookingDetailRemoteDataSource)
final bookingDetailRemoteDataSourceProvider =
    BookingDetailRemoteDataSourceProvider._();

final class BookingDetailRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IBookingDetailRemoteDataSource,
          IBookingDetailRemoteDataSource,
          IBookingDetailRemoteDataSource
        >
    with $Provider<IBookingDetailRemoteDataSource> {
  BookingDetailRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingDetailRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IBookingDetailRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBookingDetailRemoteDataSource create(Ref ref) {
    return bookingDetailRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBookingDetailRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBookingDetailRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$bookingDetailRemoteDataSourceHash() =>
    r'471449daeea9c0bba0c2577605dbd7a6c43b7c27';

@ProviderFor(bookingDetailLocalDataSource)
final bookingDetailLocalDataSourceProvider =
    BookingDetailLocalDataSourceProvider._();

final class BookingDetailLocalDataSourceProvider
    extends
        $FunctionalProvider<
          IBookingDetailLocalDataSource,
          IBookingDetailLocalDataSource,
          IBookingDetailLocalDataSource
        >
    with $Provider<IBookingDetailLocalDataSource> {
  BookingDetailLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingDetailLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<IBookingDetailLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBookingDetailLocalDataSource create(Ref ref) {
    return bookingDetailLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBookingDetailLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBookingDetailLocalDataSource>(
        value,
      ),
    );
  }
}

String _$bookingDetailLocalDataSourceHash() =>
    r'04c19717ea3a0e35f3463d59bae6c1377013e5f8';

/// Tech-side quote builder catalog — fetches the sub-services the
/// authenticated tech is qualified for (via TechnicianSkill bridge),
/// scoped to a given parent service. Reused HTTP client + secure
/// storage; no separate auth surface.

@ProviderFor(quotableSubServicesRemoteDataSource)
final quotableSubServicesRemoteDataSourceProvider =
    QuotableSubServicesRemoteDataSourceProvider._();

/// Tech-side quote builder catalog — fetches the sub-services the
/// authenticated tech is qualified for (via TechnicianSkill bridge),
/// scoped to a given parent service. Reused HTTP client + secure
/// storage; no separate auth surface.

final class QuotableSubServicesRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IQuotableSubServicesRemoteDataSource,
          IQuotableSubServicesRemoteDataSource,
          IQuotableSubServicesRemoteDataSource
        >
    with $Provider<IQuotableSubServicesRemoteDataSource> {
  /// Tech-side quote builder catalog — fetches the sub-services the
  /// authenticated tech is qualified for (via TechnicianSkill bridge),
  /// scoped to a given parent service. Reused HTTP client + secure
  /// storage; no separate auth surface.
  QuotableSubServicesRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotableSubServicesRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$quotableSubServicesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IQuotableSubServicesRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IQuotableSubServicesRemoteDataSource create(Ref ref) {
    return quotableSubServicesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IQuotableSubServicesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<IQuotableSubServicesRemoteDataSource>(value),
    );
  }
}

String _$quotableSubServicesRemoteDataSourceHash() =>
    r'1d00a063d6ad9baa37a2014f80d07543a8530ac9';

@ProviderFor(bookingDetailRepository)
final bookingDetailRepositoryProvider = BookingDetailRepositoryProvider._();

final class BookingDetailRepositoryProvider
    extends
        $FunctionalProvider<
          IBookingDetailRepository,
          IBookingDetailRepository,
          IBookingDetailRepository
        >
    with $Provider<IBookingDetailRepository> {
  BookingDetailRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingDetailRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingDetailRepositoryHash();

  @$internal
  @override
  $ProviderElement<IBookingDetailRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBookingDetailRepository create(Ref ref) {
    return bookingDetailRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBookingDetailRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBookingDetailRepository>(value),
    );
  }
}

String _$bookingDetailRepositoryHash() =>
    r'd26b92015959992988e644126f41cad049e221b5';

@ProviderFor(getBookingDetailUseCase)
final getBookingDetailUseCaseProvider = GetBookingDetailUseCaseProvider._();

final class GetBookingDetailUseCaseProvider
    extends
        $FunctionalProvider<
          GetBookingDetailUseCase,
          GetBookingDetailUseCase,
          GetBookingDetailUseCase
        >
    with $Provider<GetBookingDetailUseCase> {
  GetBookingDetailUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getBookingDetailUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getBookingDetailUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetBookingDetailUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetBookingDetailUseCase create(Ref ref) {
    return getBookingDetailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetBookingDetailUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetBookingDetailUseCase>(value),
    );
  }
}

String _$getBookingDetailUseCaseHash() =>
    r'8a7aa6aaa0c75ccd75ffef6f2409e04e9c552aca';
