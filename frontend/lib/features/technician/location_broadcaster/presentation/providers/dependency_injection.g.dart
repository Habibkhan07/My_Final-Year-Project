// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-feature secure-storage instance. Used by the controller to
/// read the auth token before saving it to the foreground task's
/// shared prefs (so the isolate can `Authorization: Token <...>`
/// every POST).

@ProviderFor(locationBroadcasterSecureStorage)
final locationBroadcasterSecureStorageProvider =
    LocationBroadcasterSecureStorageProvider._();

/// Per-feature secure-storage instance. Used by the controller to
/// read the auth token before saving it to the foreground task's
/// shared prefs (so the isolate can `Authorization: Token <...>`
/// every POST).

final class LocationBroadcasterSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  /// Per-feature secure-storage instance. Used by the controller to
  /// read the auth token before saving it to the foreground task's
  /// shared prefs (so the isolate can `Authorization: Token <...>`
  /// every POST).
  LocationBroadcasterSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationBroadcasterSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationBroadcasterSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return locationBroadcasterSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$locationBroadcasterSecureStorageHash() =>
    r'81fd74c078a6fb20f1852bec65f0d39ae8263127';

/// Per-feature http.Client. The controller does not POST itself —
/// only the foreground task isolate posts — but the data source is
/// constructible from main-isolate too for tests + future use.

@ProviderFor(locationBroadcasterHttpClient)
final locationBroadcasterHttpClientProvider =
    LocationBroadcasterHttpClientProvider._();

/// Per-feature http.Client. The controller does not POST itself —
/// only the foreground task isolate posts — but the data source is
/// constructible from main-isolate too for tests + future use.

final class LocationBroadcasterHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Per-feature http.Client. The controller does not POST itself —
  /// only the foreground task isolate posts — but the data source is
  /// constructible from main-isolate too for tests + future use.
  LocationBroadcasterHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationBroadcasterHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationBroadcasterHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return locationBroadcasterHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$locationBroadcasterHttpClientHash() =>
    r'd4c8b39aca14d95fe05b4a614e311407bd795111';

@ProviderFor(techLocationRemoteDataSource)
final techLocationRemoteDataSourceProvider =
    TechLocationRemoteDataSourceProvider._();

final class TechLocationRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TechLocationRemoteDataSource,
          TechLocationRemoteDataSource,
          TechLocationRemoteDataSource
        >
    with $Provider<TechLocationRemoteDataSource> {
  TechLocationRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'techLocationRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$techLocationRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TechLocationRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechLocationRemoteDataSource create(Ref ref) {
    return techLocationRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechLocationRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechLocationRemoteDataSource>(value),
    );
  }
}

String _$techLocationRemoteDataSourceHash() =>
    r'59ad0c9e3130f9c3de98422eb335fa04a8db23bc';
