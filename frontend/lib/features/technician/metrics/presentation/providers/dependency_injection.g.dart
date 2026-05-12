// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(metricsHttpClient)
final metricsHttpClientProvider = MetricsHttpClientProvider._();

final class MetricsHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  MetricsHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return metricsHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$metricsHttpClientHash() => r'a6b39c0b0ac1b18020082a09a71dbf411192da49';

@ProviderFor(metricsRemoteDataSource)
final metricsRemoteDataSourceProvider = MetricsRemoteDataSourceProvider._();

final class MetricsRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IMetricsRemoteDataSource,
          IMetricsRemoteDataSource,
          IMetricsRemoteDataSource
        >
    with $Provider<IMetricsRemoteDataSource> {
  MetricsRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IMetricsRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IMetricsRemoteDataSource create(Ref ref) {
    return metricsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMetricsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMetricsRemoteDataSource>(value),
    );
  }
}

String _$metricsRemoteDataSourceHash() =>
    r'ca01f6cae4f9888e005d38c03a9c14f421365b05';

@ProviderFor(metricsRepository)
final metricsRepositoryProvider = MetricsRepositoryProvider._();

final class MetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  MetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return metricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$metricsRepositoryHash() => r'1354f5a42965c5fa9cf88bbe5e10fb91729ab16f';
