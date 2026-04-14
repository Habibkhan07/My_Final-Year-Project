// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookingHttpClient)
final bookingHttpClientProvider = BookingHttpClientProvider._();

final class BookingHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  BookingHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return bookingHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$bookingHttpClientHash() => r'3a47b0cc19b479d8c47f825d4ba0ee8722dc80a5';

@ProviderFor(bookingSecureStorage)
final bookingSecureStorageProvider = BookingSecureStorageProvider._();

final class BookingSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  BookingSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return bookingSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$bookingSecureStorageHash() =>
    r'21ab7f0eca316f5faec13b54f553fe77ce60726c';

@ProviderFor(bookingRemoteDataSource)
final bookingRemoteDataSourceProvider = BookingRemoteDataSourceProvider._();

final class BookingRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IBookingRemoteDataSource,
          IBookingRemoteDataSource,
          IBookingRemoteDataSource
        >
    with $Provider<IBookingRemoteDataSource> {
  BookingRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IBookingRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBookingRemoteDataSource create(Ref ref) {
    return bookingRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBookingRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBookingRemoteDataSource>(value),
    );
  }
}

String _$bookingRemoteDataSourceHash() =>
    r'df1f4e6f5561f4c073e51ba0834b2d30d2738c3e';

@ProviderFor(bookingRepository)
final bookingRepositoryProvider = BookingRepositoryProvider._();

final class BookingRepositoryProvider
    extends
        $FunctionalProvider<
          IBookingRepository,
          IBookingRepository,
          IBookingRepository
        >
    with $Provider<IBookingRepository> {
  BookingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingRepositoryHash();

  @$internal
  @override
  $ProviderElement<IBookingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBookingRepository create(Ref ref) {
    return bookingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBookingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBookingRepository>(value),
    );
  }
}

String _$bookingRepositoryHash() => r'6afdf984d838527a4bd1fa103ad75323aa5d60c8';

@ProviderFor(getTechnicianProfileUseCase)
final getTechnicianProfileUseCaseProvider =
    GetTechnicianProfileUseCaseProvider._();

final class GetTechnicianProfileUseCaseProvider
    extends
        $FunctionalProvider<
          GetTechnicianProfileUseCase,
          GetTechnicianProfileUseCase,
          GetTechnicianProfileUseCase
        >
    with $Provider<GetTechnicianProfileUseCase> {
  GetTechnicianProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getTechnicianProfileUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getTechnicianProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTechnicianProfileUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetTechnicianProfileUseCase create(Ref ref) {
    return getTechnicianProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTechnicianProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTechnicianProfileUseCase>(value),
    );
  }
}

String _$getTechnicianProfileUseCaseHash() =>
    r'43e734cacbc357214c114b851702fd52dedf017d';

@ProviderFor(getAvailabilityUseCase)
final getAvailabilityUseCaseProvider = GetAvailabilityUseCaseProvider._();

final class GetAvailabilityUseCaseProvider
    extends
        $FunctionalProvider<
          GetAvailabilityUseCase,
          GetAvailabilityUseCase,
          GetAvailabilityUseCase
        >
    with $Provider<GetAvailabilityUseCase> {
  GetAvailabilityUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAvailabilityUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAvailabilityUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetAvailabilityUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetAvailabilityUseCase create(Ref ref) {
    return getAvailabilityUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetAvailabilityUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetAvailabilityUseCase>(value),
    );
  }
}

String _$getAvailabilityUseCaseHash() =>
    r'4a4acfe0446e1340ccffcd5196f031f682ea4cf8';

@ProviderFor(createInstantBookingUseCase)
final createInstantBookingUseCaseProvider =
    CreateInstantBookingUseCaseProvider._();

final class CreateInstantBookingUseCaseProvider
    extends
        $FunctionalProvider<
          CreateInstantBookingUseCase,
          CreateInstantBookingUseCase,
          CreateInstantBookingUseCase
        >
    with $Provider<CreateInstantBookingUseCase> {
  CreateInstantBookingUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createInstantBookingUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createInstantBookingUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateInstantBookingUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateInstantBookingUseCase create(Ref ref) {
    return createInstantBookingUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateInstantBookingUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateInstantBookingUseCase>(value),
    );
  }
}

String _$createInstantBookingUseCaseHash() =>
    r'bf50d8b3aec390afc297d338d55c358fa8a8911c';

@ProviderFor(getSavedAddressesUseCase)
final getSavedAddressesUseCaseProvider = GetSavedAddressesUseCaseProvider._();

final class GetSavedAddressesUseCaseProvider
    extends
        $FunctionalProvider<
          GetSavedAddressesUseCase,
          GetSavedAddressesUseCase,
          GetSavedAddressesUseCase
        >
    with $Provider<GetSavedAddressesUseCase> {
  GetSavedAddressesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSavedAddressesUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSavedAddressesUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSavedAddressesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSavedAddressesUseCase create(Ref ref) {
    return getSavedAddressesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSavedAddressesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSavedAddressesUseCase>(value),
    );
  }
}

String _$getSavedAddressesUseCaseHash() =>
    r'dd78a9f0313d0683e8452c5c98e0c8788542b006';

@ProviderFor(savedAddresses)
final savedAddressesProvider = SavedAddressesProvider._();

final class SavedAddressesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedAddressEntity>>,
          List<SavedAddressEntity>,
          FutureOr<List<SavedAddressEntity>>
        >
    with
        $FutureModifier<List<SavedAddressEntity>>,
        $FutureProvider<List<SavedAddressEntity>> {
  SavedAddressesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedAddressesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedAddressesHash();

  @$internal
  @override
  $FutureProviderElement<List<SavedAddressEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavedAddressEntity>> create(Ref ref) {
    return savedAddresses(ref);
  }
}

String _$savedAddressesHash() => r'1c528576750013dc6ed15a2a734ea994d1135739';
