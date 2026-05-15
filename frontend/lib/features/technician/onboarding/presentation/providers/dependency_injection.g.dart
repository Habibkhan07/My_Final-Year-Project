// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'98f63376f52c5d86a41d57af2db15810d27f528b';

@ProviderFor(onboardingLocalDataSource)
final onboardingLocalDataSourceProvider = OnboardingLocalDataSourceProvider._();

final class OnboardingLocalDataSourceProvider
    extends
        $FunctionalProvider<
          OnboardingLocalDataSource,
          OnboardingLocalDataSource,
          OnboardingLocalDataSource
        >
    with $Provider<OnboardingLocalDataSource> {
  OnboardingLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<OnboardingLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingLocalDataSource create(Ref ref) {
    return onboardingLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingLocalDataSource>(value),
    );
  }
}

String _$onboardingLocalDataSourceHash() =>
    r'b9bfe571ace00bb56eb5a2eeb4bf391eaf5f8e78';

@ProviderFor(technicianOnboardingRemoteDataSource)
final technicianOnboardingRemoteDataSourceProvider =
    TechnicianOnboardingRemoteDataSourceProvider._();

final class TechnicianOnboardingRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TechnicianOnboardingRemoteDataSource,
          TechnicianOnboardingRemoteDataSource,
          TechnicianOnboardingRemoteDataSource
        >
    with $Provider<TechnicianOnboardingRemoteDataSource> {
  TechnicianOnboardingRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianOnboardingRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$technicianOnboardingRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TechnicianOnboardingRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianOnboardingRemoteDataSource create(Ref ref) {
    return technicianOnboardingRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianOnboardingRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<TechnicianOnboardingRemoteDataSource>(value),
    );
  }
}

String _$technicianOnboardingRemoteDataSourceHash() =>
    r'14f65818729a1d64918ac7c5ead5719bbef82fa5';

@ProviderFor(technicianRepository)
final technicianRepositoryProvider = TechnicianRepositoryProvider._();

final class TechnicianRepositoryProvider
    extends
        $FunctionalProvider<
          TechnicianRepositoryImpl,
          TechnicianRepositoryImpl,
          TechnicianRepositoryImpl
        >
    with $Provider<TechnicianRepositoryImpl> {
  TechnicianRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianRepositoryHash();

  @$internal
  @override
  $ProviderElement<TechnicianRepositoryImpl> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianRepositoryImpl create(Ref ref) {
    return technicianRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianRepositoryImpl>(value),
    );
  }
}

String _$technicianRepositoryHash() =>
    r'814d3846f1d82e4f2e933f35580d3f80c2193f73';

@ProviderFor(getOnboardingMetadataUseCase)
final getOnboardingMetadataUseCaseProvider =
    GetOnboardingMetadataUseCaseProvider._();

final class GetOnboardingMetadataUseCaseProvider
    extends
        $FunctionalProvider<
          GetOnboardingMetadataUseCase,
          GetOnboardingMetadataUseCase,
          GetOnboardingMetadataUseCase
        >
    with $Provider<GetOnboardingMetadataUseCase> {
  GetOnboardingMetadataUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getOnboardingMetadataUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getOnboardingMetadataUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetOnboardingMetadataUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetOnboardingMetadataUseCase create(Ref ref) {
    return getOnboardingMetadataUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetOnboardingMetadataUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetOnboardingMetadataUseCase>(value),
    );
  }
}

String _$getOnboardingMetadataUseCaseHash() =>
    r'8461e5f285970d1736ddf9e22f6ecb77b5e24e0e';

@ProviderFor(uploadMediaUseCase)
final uploadMediaUseCaseProvider = UploadMediaUseCaseProvider._();

final class UploadMediaUseCaseProvider
    extends
        $FunctionalProvider<
          UploadMediaUseCase,
          UploadMediaUseCase,
          UploadMediaUseCase
        >
    with $Provider<UploadMediaUseCase> {
  UploadMediaUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uploadMediaUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uploadMediaUseCaseHash();

  @$internal
  @override
  $ProviderElement<UploadMediaUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UploadMediaUseCase create(Ref ref) {
    return uploadMediaUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UploadMediaUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UploadMediaUseCase>(value),
    );
  }
}

String _$uploadMediaUseCaseHash() =>
    r'b1c6620f1993fbaa200be7f74da77aee94846fae';

@ProviderFor(registerTechnicianUseCase)
final registerTechnicianUseCaseProvider = RegisterTechnicianUseCaseProvider._();

final class RegisterTechnicianUseCaseProvider
    extends
        $FunctionalProvider<
          RegisterTechnicianUseCase,
          RegisterTechnicianUseCase,
          RegisterTechnicianUseCase
        >
    with $Provider<RegisterTechnicianUseCase> {
  RegisterTechnicianUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerTechnicianUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerTechnicianUseCaseHash();

  @$internal
  @override
  $ProviderElement<RegisterTechnicianUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RegisterTechnicianUseCase create(Ref ref) {
    return registerTechnicianUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterTechnicianUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterTechnicianUseCase>(value),
    );
  }
}

String _$registerTechnicianUseCaseHash() =>
    r'33e40f16d6585b8a039ffb3f727b67fc4a454bc4';

@ProviderFor(technicianStatusRemoteDataSource)
final technicianStatusRemoteDataSourceProvider =
    TechnicianStatusRemoteDataSourceProvider._();

final class TechnicianStatusRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TechnicianStatusRemoteDataSource,
          TechnicianStatusRemoteDataSource,
          TechnicianStatusRemoteDataSource
        >
    with $Provider<TechnicianStatusRemoteDataSource> {
  TechnicianStatusRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianStatusRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianStatusRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TechnicianStatusRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianStatusRemoteDataSource create(Ref ref) {
    return technicianStatusRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianStatusRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianStatusRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$technicianStatusRemoteDataSourceHash() =>
    r'5007c346dbc88790f09cc41a81c00b714aa353f4';

@ProviderFor(technicianStatusRepository)
final technicianStatusRepositoryProvider =
    TechnicianStatusRepositoryProvider._();

final class TechnicianStatusRepositoryProvider
    extends
        $FunctionalProvider<
          TechnicianStatusRepositoryImpl,
          TechnicianStatusRepositoryImpl,
          TechnicianStatusRepositoryImpl
        >
    with $Provider<TechnicianStatusRepositoryImpl> {
  TechnicianStatusRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianStatusRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianStatusRepositoryHash();

  @$internal
  @override
  $ProviderElement<TechnicianStatusRepositoryImpl> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianStatusRepositoryImpl create(Ref ref) {
    return technicianStatusRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianStatusRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianStatusRepositoryImpl>(
        value,
      ),
    );
  }
}

String _$technicianStatusRepositoryHash() =>
    r'7ab077b34842afdb8d0341cfb96a2d0f28b36ae2';
