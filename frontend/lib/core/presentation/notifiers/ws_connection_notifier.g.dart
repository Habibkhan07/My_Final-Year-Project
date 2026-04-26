// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_connection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, decode, and feed each into [SystemEventNotifier].
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
///
/// keepAlive: the channel, timer, and retry counter cannot live with a
/// widget lifecycle. Disposing mid-session would kill the live connection.

@ProviderFor(WsConnectionNotifier)
final wsConnectionProvider = WsConnectionNotifierProvider._();

/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, decode, and feed each into [SystemEventNotifier].
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
///
/// keepAlive: the channel, timer, and retry counter cannot live with a
/// widget lifecycle. Disposing mid-session would kill the live connection.
final class WsConnectionNotifierProvider
    extends $NotifierProvider<WsConnectionNotifier, WsConnectionStatus> {
  /// Owns the entire WebSocket lifecycle for the realtime event stream:
  ///   - Connect with the user's auth token in the query string.
  ///   - Listen to frames, decode, and feed each into [SystemEventNotifier].
  ///   - Trigger a REST recovery sync immediately after the socket opens.
  ///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
  ///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
  ///     for the UI — but keep retrying on the cap so the socket recovers
  ///     if the server comes back.
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
    r'480940f6762fd703ebb6b1f0d2f7b03e540c82b6';

/// Owns the entire WebSocket lifecycle for the realtime event stream:
///   - Connect with the user's auth token in the query string.
///   - Listen to frames, decode, and feed each into [SystemEventNotifier].
///   - Trigger a REST recovery sync immediately after the socket opens.
///   - Reconnect with exponential backoff, capped at [_kMaxBackoff].
///   - After [_kMaxRetries] consecutive failures, flip state to `failed`
///     for the UI — but keep retrying on the cap so the socket recovers
///     if the server comes back.
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
