// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_injection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Leaf-only wiring for the realtime event subsystem. Notifier classes
/// auto-register via `@riverpod` on their declarations — do NOT add them
/// here; duplicating would produce two distinct provider instances and
/// defeat the single-ingestion guarantee of [SystemEventNotifier].
// ─── Infrastructure ────────────────────────────────────────────────────────
/// Dedicated http.Client for the event remote. Kept separate from the
/// addresses feature's client so disposing one doesn't affect the other.

@ProviderFor(eventHttpClient)
final eventHttpClientProvider = EventHttpClientProvider._();

/// Leaf-only wiring for the realtime event subsystem. Notifier classes
/// auto-register via `@riverpod` on their declarations — do NOT add them
/// here; duplicating would produce two distinct provider instances and
/// defeat the single-ingestion guarantee of [SystemEventNotifier].
// ─── Infrastructure ────────────────────────────────────────────────────────
/// Dedicated http.Client for the event remote. Kept separate from the
/// addresses feature's client so disposing one doesn't affect the other.

final class EventHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Leaf-only wiring for the realtime event subsystem. Notifier classes
  /// auto-register via `@riverpod` on their declarations — do NOT add them
  /// here; duplicating would produce two distinct provider instances and
  /// defeat the single-ingestion guarantee of [SystemEventNotifier].
  // ─── Infrastructure ────────────────────────────────────────────────────────
  /// Dedicated http.Client for the event remote. Kept separate from the
  /// addresses feature's client so disposing one doesn't affect the other.
  EventHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return eventHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$eventHttpClientHash() => r'd6410bb9fd32b5530e7b80f506b952979ce083f0';

@ProviderFor(eventSecureStorage)
final eventSecureStorageProvider = EventSecureStorageProvider._();

final class EventSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  EventSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventSecureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return eventSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$eventSecureStorageHash() =>
    r'e5ac0ad96d77e592c1b462bf11dcc3ee88b3b16e';

@ProviderFor(eventRemoteDataSource)
final eventRemoteDataSourceProvider = EventRemoteDataSourceProvider._();

final class EventRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          EventRemoteDataSource,
          EventRemoteDataSource,
          EventRemoteDataSource
        >
    with $Provider<EventRemoteDataSource> {
  EventRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<EventRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventRemoteDataSource create(Ref ref) {
    return eventRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRemoteDataSource>(value),
    );
  }
}

String _$eventRemoteDataSourceHash() =>
    r'e9ec2f7ab8f891a5c66ca978772671878e824817';

@ProviderFor(eventLocalDataSource)
final eventLocalDataSourceProvider = EventLocalDataSourceProvider._();

final class EventLocalDataSourceProvider
    extends
        $FunctionalProvider<
          EventLocalDataSource,
          EventLocalDataSource,
          EventLocalDataSource
        >
    with $Provider<EventLocalDataSource> {
  EventLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<EventLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventLocalDataSource create(Ref ref) {
    return eventLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventLocalDataSource>(value),
    );
  }
}

String _$eventLocalDataSourceHash() =>
    r'501ced14ef516cef65627a0ec412aaae75803faa';

@ProviderFor(eventRepository)
final eventRepositoryProvider = EventRepositoryProvider._();

final class EventRepositoryProvider
    extends
        $FunctionalProvider<EventRepository, EventRepository, EventRepository>
    with $Provider<EventRepository> {
  EventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventRepository create(Ref ref) {
    return eventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRepository>(value),
    );
  }
}

String _$eventRepositoryHash() => r'8d1be6d03a2ce89a5ae47ac236250e12bef0f94a';

/// Wire-edge router for WebSocket frames. Splits `kind: "event"` traffic
/// (durable, pipelined into [SystemEventNotifier]) from `kind: "stream"`
/// traffic (transient, dispatched to per-`streamType` handlers registered
/// by feature DI files).
///
/// keepAlive: the handler registry must outlive widget lifecycles, same
/// reason [systemEventProvider] is keepAlive. Disposing the dispatcher
/// mid-session would silently drop every registered stream handler.

@ProviderFor(wsFrameDispatcher)
final wsFrameDispatcherProvider = WsFrameDispatcherProvider._();

/// Wire-edge router for WebSocket frames. Splits `kind: "event"` traffic
/// (durable, pipelined into [SystemEventNotifier]) from `kind: "stream"`
/// traffic (transient, dispatched to per-`streamType` handlers registered
/// by feature DI files).
///
/// keepAlive: the handler registry must outlive widget lifecycles, same
/// reason [systemEventProvider] is keepAlive. Disposing the dispatcher
/// mid-session would silently drop every registered stream handler.

final class WsFrameDispatcherProvider
    extends
        $FunctionalProvider<
          WsFrameDispatcher,
          WsFrameDispatcher,
          WsFrameDispatcher
        >
    with $Provider<WsFrameDispatcher> {
  /// Wire-edge router for WebSocket frames. Splits `kind: "event"` traffic
  /// (durable, pipelined into [SystemEventNotifier]) from `kind: "stream"`
  /// traffic (transient, dispatched to per-`streamType` handlers registered
  /// by feature DI files).
  ///
  /// keepAlive: the handler registry must outlive widget lifecycles, same
  /// reason [systemEventProvider] is keepAlive. Disposing the dispatcher
  /// mid-session would silently drop every registered stream handler.
  WsFrameDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wsFrameDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wsFrameDispatcherHash();

  @$internal
  @override
  $ProviderElement<WsFrameDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WsFrameDispatcher create(Ref ref) {
    return wsFrameDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WsFrameDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WsFrameDispatcher>(value),
    );
  }
}

String _$wsFrameDispatcherHash() => r'1f219a1061bc8d3e67b42b74f2934e1f4a3d3244';

/// Instantiated once by the App Lifecycle Orchestrator in session 4. The
/// handler owns stream subscriptions, so this provider is keepAlive to
/// prevent repeated instantiation from double-subscribing to Firebase
/// message streams.

@ProviderFor(fcmHandler)
final fcmHandlerProvider = FcmHandlerProvider._();

/// Instantiated once by the App Lifecycle Orchestrator in session 4. The
/// handler owns stream subscriptions, so this provider is keepAlive to
/// prevent repeated instantiation from double-subscribing to Firebase
/// message streams.

final class FcmHandlerProvider
    extends $FunctionalProvider<FCMHandler, FCMHandler, FCMHandler>
    with $Provider<FCMHandler> {
  /// Instantiated once by the App Lifecycle Orchestrator in session 4. The
  /// handler owns stream subscriptions, so this provider is keepAlive to
  /// prevent repeated instantiation from double-subscribing to Firebase
  /// message streams.
  FcmHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fcmHandlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fcmHandlerHash();

  @$internal
  @override
  $ProviderElement<FCMHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FCMHandler create(Ref ref) {
    return fcmHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FCMHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FCMHandler>(value),
    );
  }
}

String _$fcmHandlerHash() => r'b317016323a7bc3b601cec11979febe7e6ff7443';
