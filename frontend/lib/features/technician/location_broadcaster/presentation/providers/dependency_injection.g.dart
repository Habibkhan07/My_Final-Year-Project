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

/// Owned by `AppLifecycleOrchestrator.performTeardown`. Stateless —
/// kept as a provider so tests can override with a recording fake.

@ProviderFor(foregroundLocationLifecycle)
final foregroundLocationLifecycleProvider =
    ForegroundLocationLifecycleProvider._();

/// Owned by `AppLifecycleOrchestrator.performTeardown`. Stateless —
/// kept as a provider so tests can override with a recording fake.

final class ForegroundLocationLifecycleProvider
    extends
        $FunctionalProvider<
          ForegroundLocationLifecycle,
          ForegroundLocationLifecycle,
          ForegroundLocationLifecycle
        >
    with $Provider<ForegroundLocationLifecycle> {
  /// Owned by `AppLifecycleOrchestrator.performTeardown`. Stateless —
  /// kept as a provider so tests can override with a recording fake.
  ForegroundLocationLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foregroundLocationLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foregroundLocationLifecycleHash();

  @$internal
  @override
  $ProviderElement<ForegroundLocationLifecycle> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ForegroundLocationLifecycle create(Ref ref) {
    return foregroundLocationLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForegroundLocationLifecycle value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForegroundLocationLifecycle>(value),
    );
  }
}

String _$foregroundLocationLifecycleHash() =>
    r'076b6a8d2a1cafa21dc4f41b86401056a2f2de9e';

/// Audit H13: port for the static `FlutterForegroundTask` API used by
/// the main-isolate consumers. Tests override this with a recording fake;
/// production uses `FlutterForegroundTaskBackend` (forwards to the real
/// statics). Stateless on the production side — the package owns its
/// own static state.

@ProviderFor(foregroundTaskBackend)
final foregroundTaskBackendProvider = ForegroundTaskBackendProvider._();

/// Audit H13: port for the static `FlutterForegroundTask` API used by
/// the main-isolate consumers. Tests override this with a recording fake;
/// production uses `FlutterForegroundTaskBackend` (forwards to the real
/// statics). Stateless on the production side — the package owns its
/// own static state.

final class ForegroundTaskBackendProvider
    extends
        $FunctionalProvider<
          IForegroundTaskBackend,
          IForegroundTaskBackend,
          IForegroundTaskBackend
        >
    with $Provider<IForegroundTaskBackend> {
  /// Audit H13: port for the static `FlutterForegroundTask` API used by
  /// the main-isolate consumers. Tests override this with a recording fake;
  /// production uses `FlutterForegroundTaskBackend` (forwards to the real
  /// statics). Stateless on the production side — the package owns its
  /// own static state.
  ForegroundTaskBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foregroundTaskBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foregroundTaskBackendHash();

  @$internal
  @override
  $ProviderElement<IForegroundTaskBackend> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IForegroundTaskBackend create(Ref ref) {
    return foregroundTaskBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IForegroundTaskBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IForegroundTaskBackend>(value),
    );
  }
}

String _$foregroundTaskBackendHash() =>
    r'cfe38a4d01c147cd85643f383cd47a8cbe04e57e';

/// Audit H13: port for the static `Geolocator` calls the controller
/// makes during permission resolution and the settings deep-link.
/// Production uses `GeolocatorBackend`; tests inject a recording fake.

@ProviderFor(geolocatorBackend)
final geolocatorBackendProvider = GeolocatorBackendProvider._();

/// Audit H13: port for the static `Geolocator` calls the controller
/// makes during permission resolution and the settings deep-link.
/// Production uses `GeolocatorBackend`; tests inject a recording fake.

final class GeolocatorBackendProvider
    extends
        $FunctionalProvider<
          IGeolocatorBackend,
          IGeolocatorBackend,
          IGeolocatorBackend
        >
    with $Provider<IGeolocatorBackend> {
  /// Audit H13: port for the static `Geolocator` calls the controller
  /// makes during permission resolution and the settings deep-link.
  /// Production uses `GeolocatorBackend`; tests inject a recording fake.
  GeolocatorBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geolocatorBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geolocatorBackendHash();

  @$internal
  @override
  $ProviderElement<IGeolocatorBackend> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IGeolocatorBackend create(Ref ref) {
    return geolocatorBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IGeolocatorBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IGeolocatorBackend>(value),
    );
  }
}

String _$geolocatorBackendHash() => r'da1a963673e9a44cc5d4ff5c1501a8108acf7271';

/// Audit Batch H: production booking deep-link router.
///
/// Reads `navigatorKey` from the realtime DI (the same key
/// `EventUrgencyRouter` uses) and routes to `/booking/$bookingId` via
/// GoRouter when the controller receives an `open_booking` envelope
/// from the isolate. Best-effort — if `currentContext` is null (app in
/// a transient state during launch), the navigation is skipped and
/// the standard route restoration takes over on the next frame.
///
/// Tests override this provider with a recording closure so the
/// navigation can be asserted without spinning up a MaterialApp +
/// GoRouter.

@ProviderFor(bookingDeepLinkRouter)
final bookingDeepLinkRouterProvider = BookingDeepLinkRouterProvider._();

/// Audit Batch H: production booking deep-link router.
///
/// Reads `navigatorKey` from the realtime DI (the same key
/// `EventUrgencyRouter` uses) and routes to `/booking/$bookingId` via
/// GoRouter when the controller receives an `open_booking` envelope
/// from the isolate. Best-effort — if `currentContext` is null (app in
/// a transient state during launch), the navigation is skipped and
/// the standard route restoration takes over on the next frame.
///
/// Tests override this provider with a recording closure so the
/// navigation can be asserted without spinning up a MaterialApp +
/// GoRouter.

final class BookingDeepLinkRouterProvider
    extends
        $FunctionalProvider<
          BookingDeepLinkRouter,
          BookingDeepLinkRouter,
          BookingDeepLinkRouter
        >
    with $Provider<BookingDeepLinkRouter> {
  /// Audit Batch H: production booking deep-link router.
  ///
  /// Reads `navigatorKey` from the realtime DI (the same key
  /// `EventUrgencyRouter` uses) and routes to `/booking/$bookingId` via
  /// GoRouter when the controller receives an `open_booking` envelope
  /// from the isolate. Best-effort — if `currentContext` is null (app in
  /// a transient state during launch), the navigation is skipped and
  /// the standard route restoration takes over on the next frame.
  ///
  /// Tests override this provider with a recording closure so the
  /// navigation can be asserted without spinning up a MaterialApp +
  /// GoRouter.
  BookingDeepLinkRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingDeepLinkRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingDeepLinkRouterHash();

  @$internal
  @override
  $ProviderElement<BookingDeepLinkRouter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookingDeepLinkRouter create(Ref ref) {
    return bookingDeepLinkRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingDeepLinkRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingDeepLinkRouter>(value),
    );
  }
}

String _$bookingDeepLinkRouterHash() =>
    r'90c801cadd09b7802d5daa4c016efd3e6c317351';
