// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dedicated http client for the dashboard remote source. Kept separate
/// from other features' clients so disposing one doesn't ripple into the
/// dashboard's in-flight requests.

@ProviderFor(technicianDashboardHttpClient)
final technicianDashboardHttpClientProvider =
    TechnicianDashboardHttpClientProvider._();

/// Dedicated http client for the dashboard remote source. Kept separate
/// from other features' clients so disposing one doesn't ripple into the
/// dashboard's in-flight requests.

final class TechnicianDashboardHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Dedicated http client for the dashboard remote source. Kept separate
  /// from other features' clients so disposing one doesn't ripple into the
  /// dashboard's in-flight requests.
  TechnicianDashboardHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianDashboardHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return technicianDashboardHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$technicianDashboardHttpClientHash() =>
    r'f552ec00e58253d69a25911efbc1ea604d387044';

@ProviderFor(technicianDashboardRemoteDataSource)
final technicianDashboardRemoteDataSourceProvider =
    TechnicianDashboardRemoteDataSourceProvider._();

final class TechnicianDashboardRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ITechnicianDashboardRemoteDataSource,
          ITechnicianDashboardRemoteDataSource,
          ITechnicianDashboardRemoteDataSource
        >
    with $Provider<ITechnicianDashboardRemoteDataSource> {
  TechnicianDashboardRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$technicianDashboardRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ITechnicianDashboardRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ITechnicianDashboardRemoteDataSource create(Ref ref) {
    return technicianDashboardRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITechnicianDashboardRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ITechnicianDashboardRemoteDataSource>(value),
    );
  }
}

String _$technicianDashboardRemoteDataSourceHash() =>
    r'5a61c9f71ad6a0208d6af452dbdeb51b17342091';

@ProviderFor(technicianDashboardLocalDataSource)
final technicianDashboardLocalDataSourceProvider =
    TechnicianDashboardLocalDataSourceProvider._();

final class TechnicianDashboardLocalDataSourceProvider
    extends
        $FunctionalProvider<
          TechnicianDashboardLocalDataSource,
          TechnicianDashboardLocalDataSource,
          TechnicianDashboardLocalDataSource
        >
    with $Provider<TechnicianDashboardLocalDataSource> {
  TechnicianDashboardLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$technicianDashboardLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<TechnicianDashboardLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianDashboardLocalDataSource create(Ref ref) {
    return technicianDashboardLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianDashboardLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianDashboardLocalDataSource>(
        value,
      ),
    );
  }
}

String _$technicianDashboardLocalDataSourceHash() =>
    r'a766b41715c74ca68e831c74fe7c7912feedf3d8';

@ProviderFor(technicianDashboardRepository)
final technicianDashboardRepositoryProvider =
    TechnicianDashboardRepositoryProvider._();

final class TechnicianDashboardRepositoryProvider
    extends
        $FunctionalProvider<
          TechnicianDashboardRepository,
          TechnicianDashboardRepository,
          TechnicianDashboardRepository
        >
    with $Provider<TechnicianDashboardRepository> {
  TechnicianDashboardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianDashboardRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianDashboardRepositoryHash();

  @$internal
  @override
  $ProviderElement<TechnicianDashboardRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianDashboardRepository create(Ref ref) {
    return technicianDashboardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianDashboardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianDashboardRepository>(
        value,
      ),
    );
  }
}

String _$technicianDashboardRepositoryHash() =>
    r'00d0699f252acd11671497cadeda01c526d8b254';
