// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workLocationHttpClient)
final workLocationHttpClientProvider = WorkLocationHttpClientProvider._();

final class WorkLocationHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  WorkLocationHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workLocationHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workLocationHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return workLocationHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$workLocationHttpClientHash() =>
    r'9b10202c51baaa0df3c1bca398a0da3fece7c25e';

@ProviderFor(workLocationRemoteDataSource)
final workLocationRemoteDataSourceProvider =
    WorkLocationRemoteDataSourceProvider._();

final class WorkLocationRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          WorkLocationRemoteDataSource,
          WorkLocationRemoteDataSource,
          WorkLocationRemoteDataSource
        >
    with $Provider<WorkLocationRemoteDataSource> {
  WorkLocationRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workLocationRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workLocationRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<WorkLocationRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkLocationRemoteDataSource create(Ref ref) {
    return workLocationRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkLocationRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkLocationRemoteDataSource>(value),
    );
  }
}

String _$workLocationRemoteDataSourceHash() =>
    r'f37d0a60e9dd8433df0deff6cbd0033ea5ad68b6';

@ProviderFor(workLocationRepository)
final workLocationRepositoryProvider = WorkLocationRepositoryProvider._();

final class WorkLocationRepositoryProvider
    extends
        $FunctionalProvider<
          IWorkLocationRepository,
          IWorkLocationRepository,
          IWorkLocationRepository
        >
    with $Provider<IWorkLocationRepository> {
  WorkLocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workLocationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workLocationRepositoryHash();

  @$internal
  @override
  $ProviderElement<IWorkLocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IWorkLocationRepository create(Ref ref) {
    return workLocationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IWorkLocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IWorkLocationRepository>(value),
    );
  }
}

String _$workLocationRepositoryHash() =>
    r'57cbcc7455ce5a77e869b6e57a219f0b14b15379';

@ProviderFor(getWorkLocationUseCase)
final getWorkLocationUseCaseProvider = GetWorkLocationUseCaseProvider._();

final class GetWorkLocationUseCaseProvider
    extends
        $FunctionalProvider<
          GetWorkLocationUseCase,
          GetWorkLocationUseCase,
          GetWorkLocationUseCase
        >
    with $Provider<GetWorkLocationUseCase> {
  GetWorkLocationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getWorkLocationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getWorkLocationUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetWorkLocationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetWorkLocationUseCase create(Ref ref) {
    return getWorkLocationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetWorkLocationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetWorkLocationUseCase>(value),
    );
  }
}

String _$getWorkLocationUseCaseHash() =>
    r'2ad6a375e02894ff320ef3c31952ce01e0d4e6e3';

@ProviderFor(saveWorkLocationUseCase)
final saveWorkLocationUseCaseProvider = SaveWorkLocationUseCaseProvider._();

final class SaveWorkLocationUseCaseProvider
    extends
        $FunctionalProvider<
          SaveWorkLocationUseCase,
          SaveWorkLocationUseCase,
          SaveWorkLocationUseCase
        >
    with $Provider<SaveWorkLocationUseCase> {
  SaveWorkLocationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveWorkLocationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveWorkLocationUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveWorkLocationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveWorkLocationUseCase create(Ref ref) {
    return saveWorkLocationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveWorkLocationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveWorkLocationUseCase>(value),
    );
  }
}

String _$saveWorkLocationUseCaseHash() =>
    r'c2042255af7d282cdc5c917c165839488f7d9a77';
