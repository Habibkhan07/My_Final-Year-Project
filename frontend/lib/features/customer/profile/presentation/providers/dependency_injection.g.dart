// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileHttpClient)
final profileHttpClientProvider = ProfileHttpClientProvider._();

final class ProfileHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  ProfileHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return profileHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$profileHttpClientHash() => r'6e45c50ec3243a9681e1ec71ea967b039dd799e3';

@ProviderFor(profileSecureStorage)
final profileSecureStorageProvider = ProfileSecureStorageProvider._();

final class ProfileSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  ProfileSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return profileSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$profileSecureStorageHash() =>
    r'1aab999db46d9fb7b8a89c7039d24c3ada248660';

@ProviderFor(profileRemoteDataSource)
final profileRemoteDataSourceProvider = ProfileRemoteDataSourceProvider._();

final class ProfileRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ProfileRemoteDataSource,
          ProfileRemoteDataSource,
          ProfileRemoteDataSource
        >
    with $Provider<ProfileRemoteDataSource> {
  ProfileRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProfileRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRemoteDataSource create(Ref ref) {
    return profileRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRemoteDataSource>(value),
    );
  }
}

String _$profileRemoteDataSourceHash() =>
    r'26d16345804192cfc1f47810a4bc3a34ed9e9a3b';

@ProviderFor(profileLocalDataSource)
final profileLocalDataSourceProvider = ProfileLocalDataSourceProvider._();

final class ProfileLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ProfileLocalDataSource,
          ProfileLocalDataSource,
          ProfileLocalDataSource
        >
    with $Provider<ProfileLocalDataSource> {
  ProfileLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProfileLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileLocalDataSource create(Ref ref) {
    return profileLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileLocalDataSource>(value),
    );
  }
}

String _$profileLocalDataSourceHash() =>
    r'c354f18ae3032274c59d281a1885ce7c590e0daf';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          IProfileRepository,
          IProfileRepository,
          IProfileRepository
        >
    with $Provider<IProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<IProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'18c8ba6d0bcd9756664bcffce7d7878224d8a658';

@ProviderFor(getMeUseCase)
final getMeUseCaseProvider = GetMeUseCaseProvider._();

final class GetMeUseCaseProvider
    extends $FunctionalProvider<GetMeUseCase, GetMeUseCase, GetMeUseCase>
    with $Provider<GetMeUseCase> {
  GetMeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getMeUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getMeUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetMeUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetMeUseCase create(Ref ref) {
    return getMeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetMeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetMeUseCase>(value),
    );
  }
}

String _$getMeUseCaseHash() => r'46402895bae6fba9aa5f3a8eb3234050478e04ca';

@ProviderFor(updateMeUseCase)
final updateMeUseCaseProvider = UpdateMeUseCaseProvider._();

final class UpdateMeUseCaseProvider
    extends
        $FunctionalProvider<UpdateMeUseCase, UpdateMeUseCase, UpdateMeUseCase>
    with $Provider<UpdateMeUseCase> {
  UpdateMeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateMeUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateMeUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateMeUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateMeUseCase create(Ref ref) {
    return updateMeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateMeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateMeUseCase>(value),
    );
  }
}

String _$updateMeUseCaseHash() => r'0a6b6c8faf8587591657e9d533c1dd60a7aae318';
