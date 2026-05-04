// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customerBookingsHttpClient)
final customerBookingsHttpClientProvider =
    CustomerBookingsHttpClientProvider._();

final class CustomerBookingsHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  CustomerBookingsHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return customerBookingsHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$customerBookingsHttpClientHash() =>
    r'54f4442fa5ea9048fce890aa91db15697544415f';

@ProviderFor(customerBookingsSecureStorage)
final customerBookingsSecureStorageProvider =
    CustomerBookingsSecureStorageProvider._();

final class CustomerBookingsSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  CustomerBookingsSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return customerBookingsSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$customerBookingsSecureStorageHash() =>
    r'9fba28270c1ec16fa30897c266ed1a13b7920f6c';

@ProviderFor(customerBookingsRemoteDataSource)
final customerBookingsRemoteDataSourceProvider =
    CustomerBookingsRemoteDataSourceProvider._();

final class CustomerBookingsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ICustomerBookingsRemoteDataSource,
          ICustomerBookingsRemoteDataSource,
          ICustomerBookingsRemoteDataSource
        >
    with $Provider<ICustomerBookingsRemoteDataSource> {
  CustomerBookingsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ICustomerBookingsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ICustomerBookingsRemoteDataSource create(Ref ref) {
    return customerBookingsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ICustomerBookingsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ICustomerBookingsRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$customerBookingsRemoteDataSourceHash() =>
    r'058d60b47f10962bc0a9ed0752237eb71edb399f';

@ProviderFor(customerBookingsLocalDataSource)
final customerBookingsLocalDataSourceProvider =
    CustomerBookingsLocalDataSourceProvider._();

final class CustomerBookingsLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ICustomerBookingsLocalDataSource,
          ICustomerBookingsLocalDataSource,
          ICustomerBookingsLocalDataSource
        >
    with $Provider<ICustomerBookingsLocalDataSource> {
  CustomerBookingsLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ICustomerBookingsLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ICustomerBookingsLocalDataSource create(Ref ref) {
    return customerBookingsLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ICustomerBookingsLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ICustomerBookingsLocalDataSource>(
        value,
      ),
    );
  }
}

String _$customerBookingsLocalDataSourceHash() =>
    r'23ea2b939c388ff6bdeba94ce3ad9fef532c57c1';

@ProviderFor(customerBookingsRepository)
final customerBookingsRepositoryProvider =
    CustomerBookingsRepositoryProvider._();

final class CustomerBookingsRepositoryProvider
    extends
        $FunctionalProvider<
          ICustomerBookingsRepository,
          ICustomerBookingsRepository,
          ICustomerBookingsRepository
        >
    with $Provider<ICustomerBookingsRepository> {
  CustomerBookingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerBookingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerBookingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ICustomerBookingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ICustomerBookingsRepository create(Ref ref) {
    return customerBookingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ICustomerBookingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ICustomerBookingsRepository>(value),
    );
  }
}

String _$customerBookingsRepositoryHash() =>
    r'ac824dca8896dc1023191ce1c1bd1838050f4fd0';

@ProviderFor(getCustomerBookingsUseCase)
final getCustomerBookingsUseCaseProvider =
    GetCustomerBookingsUseCaseProvider._();

final class GetCustomerBookingsUseCaseProvider
    extends
        $FunctionalProvider<
          GetCustomerBookingsUseCase,
          GetCustomerBookingsUseCase,
          GetCustomerBookingsUseCase
        >
    with $Provider<GetCustomerBookingsUseCase> {
  GetCustomerBookingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCustomerBookingsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCustomerBookingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCustomerBookingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetCustomerBookingsUseCase create(Ref ref) {
    return getCustomerBookingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCustomerBookingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCustomerBookingsUseCase>(value),
    );
  }
}

String _$getCustomerBookingsUseCaseHash() =>
    r'ec1c9ed18b3566fceb65bf1717defe5a4bf4c380';

@ProviderFor(getBookingsCountsUseCase)
final getBookingsCountsUseCaseProvider = GetBookingsCountsUseCaseProvider._();

final class GetBookingsCountsUseCaseProvider
    extends
        $FunctionalProvider<
          GetBookingsCountsUseCase,
          GetBookingsCountsUseCase,
          GetBookingsCountsUseCase
        >
    with $Provider<GetBookingsCountsUseCase> {
  GetBookingsCountsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getBookingsCountsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getBookingsCountsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetBookingsCountsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetBookingsCountsUseCase create(Ref ref) {
    return getBookingsCountsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetBookingsCountsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetBookingsCountsUseCase>(value),
    );
  }
}

String _$getBookingsCountsUseCaseHash() =>
    r'9d6370f835340a7ead9f352b5687c615424cb89e';
