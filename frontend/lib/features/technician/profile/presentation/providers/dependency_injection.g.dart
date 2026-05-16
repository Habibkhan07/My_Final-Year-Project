// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillsHttpClient)
final skillsHttpClientProvider = SkillsHttpClientProvider._();

final class SkillsHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  SkillsHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return skillsHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$skillsHttpClientHash() => r'6d7aaf783a82c40080d22d22ba5a4214361a38f9';

@ProviderFor(skillsSecureStorage)
final skillsSecureStorageProvider = SkillsSecureStorageProvider._();

final class SkillsSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  SkillsSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return skillsSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$skillsSecureStorageHash() =>
    r'd80c1eb9fcd6bddbadcc203a1766fb336a7736bd';

@ProviderFor(skillsRemoteDataSource)
final skillsRemoteDataSourceProvider = SkillsRemoteDataSourceProvider._();

final class SkillsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          SkillsRemoteDataSource,
          SkillsRemoteDataSource,
          SkillsRemoteDataSource
        >
    with $Provider<SkillsRemoteDataSource> {
  SkillsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<SkillsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SkillsRemoteDataSource create(Ref ref) {
    return skillsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkillsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkillsRemoteDataSource>(value),
    );
  }
}

String _$skillsRemoteDataSourceHash() =>
    r'8939ee10b59ea04932d0cb68b335c3ffa9eee185';

@ProviderFor(skillsLocalDataSource)
final skillsLocalDataSourceProvider = SkillsLocalDataSourceProvider._();

final class SkillsLocalDataSourceProvider
    extends
        $FunctionalProvider<
          SkillsLocalDataSource,
          SkillsLocalDataSource,
          SkillsLocalDataSource
        >
    with $Provider<SkillsLocalDataSource> {
  SkillsLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<SkillsLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SkillsLocalDataSource create(Ref ref) {
    return skillsLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SkillsLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SkillsLocalDataSource>(value),
    );
  }
}

String _$skillsLocalDataSourceHash() =>
    r'b7d4e8d3a64e6ebef6df547a48838af4297f85a0';

@ProviderFor(skillsRepository)
final skillsRepositoryProvider = SkillsRepositoryProvider._();

final class SkillsRepositoryProvider
    extends
        $FunctionalProvider<
          ISkillsRepository,
          ISkillsRepository,
          ISkillsRepository
        >
    with $Provider<ISkillsRepository> {
  SkillsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ISkillsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ISkillsRepository create(Ref ref) {
    return skillsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ISkillsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ISkillsRepository>(value),
    );
  }
}

String _$skillsRepositoryHash() => r'd24022c18c3408a5253180d0f20d178a2aa639f3';

@ProviderFor(listMySkillsUseCase)
final listMySkillsUseCaseProvider = ListMySkillsUseCaseProvider._();

final class ListMySkillsUseCaseProvider
    extends
        $FunctionalProvider<
          ListMySkillsUseCase,
          ListMySkillsUseCase,
          ListMySkillsUseCase
        >
    with $Provider<ListMySkillsUseCase> {
  ListMySkillsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listMySkillsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listMySkillsUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListMySkillsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListMySkillsUseCase create(Ref ref) {
    return listMySkillsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListMySkillsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListMySkillsUseCase>(value),
    );
  }
}

String _$listMySkillsUseCaseHash() =>
    r'e69cb0fc45c021a736aee06e8d0d74e7fd2eedc3';

@ProviderFor(addSkillUseCase)
final addSkillUseCaseProvider = AddSkillUseCaseProvider._();

final class AddSkillUseCaseProvider
    extends
        $FunctionalProvider<AddSkillUseCase, AddSkillUseCase, AddSkillUseCase>
    with $Provider<AddSkillUseCase> {
  AddSkillUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addSkillUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addSkillUseCaseHash();

  @$internal
  @override
  $ProviderElement<AddSkillUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AddSkillUseCase create(Ref ref) {
    return addSkillUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddSkillUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddSkillUseCase>(value),
    );
  }
}

String _$addSkillUseCaseHash() => r'102958765d721b8292db35b2965764fc02221618';

@ProviderFor(removeSkillUseCase)
final removeSkillUseCaseProvider = RemoveSkillUseCaseProvider._();

final class RemoveSkillUseCaseProvider
    extends
        $FunctionalProvider<
          RemoveSkillUseCase,
          RemoveSkillUseCase,
          RemoveSkillUseCase
        >
    with $Provider<RemoveSkillUseCase> {
  RemoveSkillUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeSkillUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeSkillUseCaseHash();

  @$internal
  @override
  $ProviderElement<RemoveSkillUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoveSkillUseCase create(Ref ref) {
    return removeSkillUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoveSkillUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoveSkillUseCase>(value),
    );
  }
}

String _$removeSkillUseCaseHash() =>
    r'aa5ae27429da346695ac0fc07872fb7228a4a51b';

@ProviderFor(listAvailableServicesUseCase)
final listAvailableServicesUseCaseProvider =
    ListAvailableServicesUseCaseProvider._();

final class ListAvailableServicesUseCaseProvider
    extends
        $FunctionalProvider<
          ListAvailableServicesUseCase,
          ListAvailableServicesUseCase,
          ListAvailableServicesUseCase
        >
    with $Provider<ListAvailableServicesUseCase> {
  ListAvailableServicesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listAvailableServicesUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listAvailableServicesUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListAvailableServicesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListAvailableServicesUseCase create(Ref ref) {
    return listAvailableServicesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListAvailableServicesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListAvailableServicesUseCase>(value),
    );
  }
}

String _$listAvailableServicesUseCaseHash() =>
    r'21e82d1559616a41afebf9f2a270f95de1516b8f';
