import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../constants.dart';
import '../../data/mappers/system_event_mapper.dart';
import '../../data/models/system_event_model.dart';
import '../state/connection_state.dart';
import 'event_sync_notifier.dart';
import 'system_event_notifier.dart';

part 'ws_connection_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class WsConnectionNotifier extends _$WsConnectionNotifier {
  static const _kInitialBackoff = Duration(seconds: 1);
  static const _kMaxBackoff = Duration(seconds: 30);
  static const _kMaxRetries = 10;
  static const _kWsPath = '/ws/events/';

  static const _logName = 'core.presentation.ws_connection';

  @visibleForTesting
  static WebSocketChannel Function(Uri)? channelFactoryForTesting;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  int _retryCount = 0;
  Duration _currentBackoff = _kInitialBackoff;
  bool _manualDisconnect = false;

  @override
  WsConnectionStatus build() {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _socketSubscription?.cancel();
      _channel?.sink.close();
    });
    return WsConnectionStatus.disconnected;
  }

  WebSocketChannel _resolveChannel(Uri uri) =>
      channelFactoryForTesting?.call(uri) ?? WebSocketChannel.connect(uri);

  /// Opens the socket to `${baseWsUrl}${_kWsPath}?token=$authToken`.
  ///
  /// Any prior socket is closed first — callers are allowed to call
  /// `connect()` repeatedly (e.g. after a token refresh) without manually
  /// calling `disconnect()` in between.
  Future<void> connect(String authToken) async {
    _manualDisconnect = false;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;

    state = WsConnectionStatus.connecting;

    final uri = Uri.parse(
      '${AppConstants.baseWsUrl}$_kWsPath?token=$authToken',
    );

    try {
      _channel = _resolveChannel(uri);
      // `ready` completes once the handshake succeeds — after that we're
      // guaranteed that `stream` emissions are real frames, not handshake
      // errors surfacing as stream errors.
      await _channel!.ready;
    } catch (e, stack) {
      log(
        'WebSocket handshake failed: $e',
        name: _logName,
        stackTrace: stack,
      );
      _scheduleReconnect(authToken);
      return;
    }

    state = WsConnectionStatus.connected;
    _retryCount = 0;
    _currentBackoff = _kInitialBackoff;

    // Critical recovery step — pull anything we missed while disconnected.
    // Fire-and-forget: the socket stream is already live, and sync failures
    // are handled internally by EventSyncNotifier.
    unawaited(
      ref.read(eventSyncProvider.notifier).syncMissedEvents(),
    );

    _socketSubscription = _channel!.stream.listen(
      (raw) => _onMessage(raw),
      onDone: () {
        if (_manualDisconnect) return;
        _scheduleReconnect(authToken);
      },
      onError: (Object error, StackTrace stack) {
        log(
          'WebSocket stream error: $error',
          name: _logName,
          stackTrace: stack,
        );
        _scheduleReconnect(authToken);
      },
      cancelOnError: true,
    );
  }

  /// Each [raw] frame runs through its own try/catch. A single malformed
  /// message must never break the listener loop.
  void _onMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : raw.toString();
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final model = SystemEventModel.fromJson(decoded);
      final entity = model.toDomain();
      if (entity == null) return;
      ref.read(systemEventProvider.notifier).processEvent(entity);
    } catch (e, stack) {
      log(
        'dropping malformed WebSocket frame: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Clean shutdown — user-initiated (logout, app close). Suppresses the
  /// auto-reconnect that would otherwise fire on `onDone`.
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _retryCount = 0;
    _currentBackoff = _kInitialBackoff;
    state = WsConnectionStatus.disconnected;
  }

  void _scheduleReconnect(String authToken) {
    _reconnectTimer?.cancel();
    _retryCount++;

    if (_retryCount > _kMaxRetries) {
      state = WsConnectionStatus.failed;
      log(
        'WebSocket gave up after $_retryCount attempts; will keep retrying '
        'at max backoff. UI surfaces persistent-offline indicator.',
        name: _logName,
      );
    } else {
      state = WsConnectionStatus.reconnecting;
    }

    _reconnectTimer = Timer(_currentBackoff, () => connect(authToken));
    final nextMs =
        (_currentBackoff.inMilliseconds * 2).clamp(0, _kMaxBackoff.inMilliseconds);
    _currentBackoff = Duration(milliseconds: nextMs);
  }
}
