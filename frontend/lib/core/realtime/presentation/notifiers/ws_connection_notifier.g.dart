// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_connection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, JSON-decode, and forward each decoded map into
///     [WsFrameDispatcher], which routes events vs. streams. This class
///     deliberately does NOT know about [SystemEventModel], the mapper,
///     or [SystemEventNotifier] — it is a transport object only.
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
///   - Surface lifecycle events via [connectionEvents] so consumers
///     (e.g. `TrackingSubscriptionController`) can replay upstream
///     subscriptions on every reconnect.
///   - Accept upstream messages via [sendUpstream] for the WS consumer's
///     `subscribe_tracking` / `unsubscribe_tracking` envelopes (the only
///     client-originated upstream payloads the backend honours).
///
/// keepAlive: the channel, timer, and retry counter cannot live with a
/// widget lifecycle. Disposing mid-session would kill the live connection.

@ProviderFor(WsConnectionNotifier)
final wsConnectionProvider = WsConnectionNotifierProvider._();

/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, JSON-decode, and forward each decoded map into
///     [WsFrameDispatcher], which routes events vs. streams. This class
///     deliberately does NOT know about [SystemEventModel], the mapper,
///     or [SystemEventNotifier] — it is a transport object only.
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
///   - Surface lifecycle events via [connectionEvents] so consumers
///     (e.g. `TrackingSubscriptionController`) can replay upstream
///     subscriptions on every reconnect.
///   - Accept upstream messages via [sendUpstream] for the WS consumer's
///     `subscribe_tracking` / `unsubscribe_tracking` envelopes (the only
///     client-originated upstream payloads the backend honours).
///
/// keepAlive: the channel, timer, and retry counter cannot live with a
/// widget lifecycle. Disposing mid-session would kill the live connection.
final class WsConnectionNotifierProvider
    extends $NotifierProvider<WsConnectionNotifier, WsConnectionStatus> {
  /// Owns the entire WebSocket lifecycle for the realtime event stream:
  ///   - Connect with the user's auth token in the query string.
  ///   - Listen to frames, JSON-decode, and forward each decoded map into
  ///     [WsFrameDispatcher], which routes events vs. streams. This class
  ///     deliberately does NOT know about [SystemEventModel], the mapper,
  ///     or [SystemEventNotifier] — it is a transport object only.
  ///   - Trigger a REST recovery sync immediately after the socket opens.
  ///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
  ///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
  ///     for the UI — but keep retrying on the cap so the socket recovers
  ///     if the server comes back.
  ///   - Surface lifecycle events via [connectionEvents] so consumers
  ///     (e.g. `TrackingSubscriptionController`) can replay upstream
  ///     subscriptions on every reconnect.
  ///   - Accept upstream messages via [sendUpstream] for the WS consumer's
  ///     `subscribe_tracking` / `unsubscribe_tracking` envelopes (the only
  ///     client-originated upstream payloads the backend honours).
  ///
  /// keepAlive: the channel, timer, and retry counter cannot live with a
  /// widget lifecycle. Disposing mid-session would kill the live connection.
  WsConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wsConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wsConnectionNotifierHash();

  @$internal
  @override
  WsConnectionNotifier create() => WsConnectionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WsConnectionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WsConnectionStatus>(value),
    );
  }
}

String _$wsConnectionNotifierHash() =>
    r'e3027bf2b04f4add2a13d6d3476d3ad6bd993f1d';

/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, JSON-decode, and forward each decoded map into
///     [WsFrameDispatcher], which routes events vs. streams. This class
///     deliberately does NOT know about [SystemEventModel], the mapper,
///     or [SystemEventNotifier] — it is a transport object only.
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
///   - Surface lifecycle events via [connectionEvents] so consumers
///     (e.g. `TrackingSubscriptionController`) can replay upstream
///     subscriptions on every reconnect.
///   - Accept upstream messages via [sendUpstream] for the WS consumer's
///     `subscribe_tracking` / `unsubscribe_tracking` envelopes (the only
///     client-originated upstream payloads the backend honours).
///
/// keepAlive: the channel, timer, and retry counter cannot live with a
/// widget lifecycle. Disposing mid-session would kill the live connection.

abstract class _$WsConnectionNotifier extends $Notifier<WsConnectionStatus> {
  WsConnectionStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WsConnectionStatus, WsConnectionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WsConnectionStatus, WsConnectionStatus>,
              WsConnectionStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
