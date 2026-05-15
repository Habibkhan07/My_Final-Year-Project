// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scheduledJobsHttpClient)
final scheduledJobsHttpClientProvider = ScheduledJobsHttpClientProvider._();

final class ScheduledJobsHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  ScheduledJobsHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return scheduledJobsHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$scheduledJobsHttpClientHash() =>
    r'f3e066944986252850fdc2b957ce831e28e269fc';

@ProviderFor(scheduledJobsSecureStorage)
final scheduledJobsSecureStorageProvider =
    ScheduledJobsSecureStorageProvider._();

final class ScheduledJobsSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  ScheduledJobsSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return scheduledJobsSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$scheduledJobsSecureStorageHash() =>
    r'0d854af912f43d935f4beb715c03b468d0d30340';

@ProviderFor(scheduledJobsRemoteDataSource)
final scheduledJobsRemoteDataSourceProvider =
    ScheduledJobsRemoteDataSourceProvider._();

final class ScheduledJobsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IScheduledJobsRemoteDataSource,
          IScheduledJobsRemoteDataSource,
          IScheduledJobsRemoteDataSource
        >
    with $Provider<IScheduledJobsRemoteDataSource> {
  ScheduledJobsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IScheduledJobsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IScheduledJobsRemoteDataSource create(Ref ref) {
    return scheduledJobsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IScheduledJobsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IScheduledJobsRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$scheduledJobsRemoteDataSourceHash() =>
    r'868aa47eeace3c9241a94a05e2bcd9b31d68bba9';

@ProviderFor(scheduledJobsLocalDataSource)
final scheduledJobsLocalDataSourceProvider =
    ScheduledJobsLocalDataSourceProvider._();

final class ScheduledJobsLocalDataSourceProvider
    extends
        $FunctionalProvider<
          IScheduledJobsLocalDataSource,
          IScheduledJobsLocalDataSource,
          IScheduledJobsLocalDataSource
        >
    with $Provider<IScheduledJobsLocalDataSource> {
  ScheduledJobsLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<IScheduledJobsLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IScheduledJobsLocalDataSource create(Ref ref) {
    return scheduledJobsLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IScheduledJobsLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IScheduledJobsLocalDataSource>(
        value,
      ),
    );
  }
}

String _$scheduledJobsLocalDataSourceHash() =>
    r'297930c48a34b3879518d9a0a4d542668f8f782d';

@ProviderFor(scheduledJobsRepository)
final scheduledJobsRepositoryProvider = ScheduledJobsRepositoryProvider._();

final class ScheduledJobsRepositoryProvider
    extends
        $FunctionalProvider<
          IScheduledJobsRepository,
          IScheduledJobsRepository,
          IScheduledJobsRepository
        >
    with $Provider<IScheduledJobsRepository> {
  ScheduledJobsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledJobsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledJobsRepositoryHash();

  @$internal
  @override
  $ProviderElement<IScheduledJobsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IScheduledJobsRepository create(Ref ref) {
    return scheduledJobsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IScheduledJobsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IScheduledJobsRepository>(value),
    );
  }
}

String _$scheduledJobsRepositoryHash() =>
    r'984cf8631181a80e469e355a9d7788f8cd639b24';

@ProviderFor(getScheduledJobsUseCase)
final getScheduledJobsUseCaseProvider = GetScheduledJobsUseCaseProvider._();

final class GetScheduledJobsUseCaseProvider
    extends
        $FunctionalProvider<
          GetScheduledJobsUseCase,
          GetScheduledJobsUseCase,
          GetScheduledJobsUseCase
        >
    with $Provider<GetScheduledJobsUseCase> {
  GetScheduledJobsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getScheduledJobsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getScheduledJobsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetScheduledJobsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetScheduledJobsUseCase create(Ref ref) {
    return getScheduledJobsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetScheduledJobsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetScheduledJobsUseCase>(value),
    );
  }
}

String _$getScheduledJobsUseCaseHash() =>
    r'e4503a322fe2cbd32576cf6dc700e76755a8a919';

@ProviderFor(getScheduledJobsCountsUseCase)
final getScheduledJobsCountsUseCaseProvider =
    GetScheduledJobsCountsUseCaseProvider._();

final class GetScheduledJobsCountsUseCaseProvider
    extends
        $FunctionalProvider<
          GetScheduledJobsCountsUseCase,
          GetScheduledJobsCountsUseCase,
          GetScheduledJobsCountsUseCase
        >
    with $Provider<GetScheduledJobsCountsUseCase> {
  GetScheduledJobsCountsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getScheduledJobsCountsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getScheduledJobsCountsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetScheduledJobsCountsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetScheduledJobsCountsUseCase create(Ref ref) {
    return getScheduledJobsCountsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetScheduledJobsCountsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetScheduledJobsCountsUseCase>(
        value,
      ),
    );
  }
}

String _$getScheduledJobsCountsUseCaseHash() =>
    r'faf5b1a457d5650ac6a0567b28180b3f3ea90a08';
