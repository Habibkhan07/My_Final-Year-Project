// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(httpClient)
final httpClientProvider = HttpClientProvider._();

final class HttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  HttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return httpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$httpClientHash() => r'd264add0180735bd60a171263e3981deb730538d';

@ProviderFor(discoveryRemoteDataSource)
final discoveryRemoteDataSourceProvider = DiscoveryRemoteDataSourceProvider._();

final class DiscoveryRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IDiscoveryRemoteDataSource,
          IDiscoveryRemoteDataSource,
          IDiscoveryRemoteDataSource
        >
    with $Provider<IDiscoveryRemoteDataSource> {
  DiscoveryRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IDiscoveryRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IDiscoveryRemoteDataSource create(Ref ref) {
    return discoveryRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDiscoveryRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDiscoveryRemoteDataSource>(value),
    );
  }
}

String _$discoveryRemoteDataSourceHash() =>
    r'c1332f589861de190c5814b50f7bd3377c6d4951';

@ProviderFor(discoveryRepository)
final discoveryRepositoryProvider = DiscoveryRepositoryProvider._();

final class DiscoveryRepositoryProvider
    extends
        $FunctionalProvider<
          IDiscoveryRepository,
          IDiscoveryRepository,
          IDiscoveryRepository
        >
    with $Provider<IDiscoveryRepository> {
  DiscoveryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryRepositoryHash();

  @$internal
  @override
  $ProviderElement<IDiscoveryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IDiscoveryRepository create(Ref ref) {
    return discoveryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDiscoveryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDiscoveryRepository>(value),
    );
  }
}

String _$discoveryRepositoryHash() =>
    r'a789f1a07c36ecd057211a81c30ef05791f47041';

@ProviderFor(getNearbyTechniciansUseCase)
final getNearbyTechniciansUseCaseProvider =
    GetNearbyTechniciansUseCaseProvider._();

final class GetNearbyTechniciansUseCaseProvider
    extends
        $FunctionalProvider<
          GetNearbyTechniciansUseCase,
          GetNearbyTechniciansUseCase,
          GetNearbyTechniciansUseCase
        >
    with $Provider<GetNearbyTechniciansUseCase> {
  GetNearbyTechniciansUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getNearbyTechniciansUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getNearbyTechniciansUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetNearbyTechniciansUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetNearbyTechniciansUseCase create(Ref ref) {
    return getNearbyTechniciansUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetNearbyTechniciansUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetNearbyTechniciansUseCase>(value),
    );
  }
}

String _$getNearbyTechniciansUseCaseHash() =>
    r'c836af049cc4173cc5d34727ceb6ab098e535811';
