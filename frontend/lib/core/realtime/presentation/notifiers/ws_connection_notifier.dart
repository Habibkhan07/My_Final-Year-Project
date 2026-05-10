import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../constants.dart';
import '../providers/dependency_injection.dart';
import '../state/connection_state.dart';
import 'event_sync_notifier.dart';

part 'ws_connection_notifier.g.dart';

/// WS connection lifecycle events surfaced via [WsConnectionNotifier.connectionEvents].
///
/// **Why a Stream and not a Riverpod listener.** Riverpod listeners
/// debounce equal-value writes — a fast disconnect→reconnect can be
/// coalesced into a single state change observation, missing the
/// transition. A broadcast Stream emits each lifecycle event
/// individually, so [TrackingSubscriptionController] (and any future
/// reconnect-aware consumer) can replay subscriptions reliably.
///
/// Late subscribers see only events fired after they listen — there
/// is no replay buffer. That's intentional: replays of stale events
/// would force every consumer to filter by recency, complicating their
/// logic.
sealed class WsConnectionEvent {
  const WsConnectionEvent();
}

/// Audit R-15 (Batch A): `at` is always UTC. Construction sites use
/// `DateTime.now().toUtc()` so cross-frame correlation (server logs,
/// other UTC-anchored clocks) works without TZ guessing.
class WsConnected extends WsConnectionEvent {
  final DateTime at;
  const WsConnected(this.at);
}

class WsDisconnected extends WsConnectionEvent {
  final DateTime at;
  const WsDisconnected(this.at);
}

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

  /// Audit H2 (R-5/R-6): tracks whether the most recent socket cycle
  /// emitted `WsConnected`. The `_emitDisconnect` helper only fires
  /// `WsDisconnected` when this is true so we cannot:
  ///   • emit `WsDisconnected` from `disconnect()` when the user
  ///     never successfully connected (R-6), or
  ///   • silently drop a `WsDisconnected` for a prior connection that
  ///     gets closed by `connect()` (token refresh) before the new
  ///     handshake (R-5).
  /// Set true after `_connectionEvents.add(WsConnected)`; reset false
  /// in `_emitDisconnect` after a successful emission.
  bool _announcedConnected = false;

  // Session 4: lifecycle event broadcast for reconnect-aware consumers.
  // Late subscribers see only events that fire after they listen
  // (no replay) — intentional, see WsConnectionEvent docs.
  final StreamController<WsConnectionEvent> _connectionEvents =
      StreamController<WsConnectionEvent>.broadcast();

  /// Broadcast stream of WS connection lifecycle events. Used by
  /// `TrackingSubscriptionController` (and any future consumer with
  /// upstream subscription state) to re-issue `subscribe_tracking` on
  /// every successful reconnect.
  Stream<WsConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  WsConnectionStatus build() {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _socketSubscription?.cancel();
      _channel?.sink.close();
      _connectionEvents.close();
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
    // Audit H2 (R-5): if a prior socket was open and announced, fire
    // WsDisconnected for it BEFORE we tear it down. Otherwise the
    // sequence "Connected → Connected" (token refresh) hides the
    // intermediate disconnect from reconnect-aware consumers.
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _emitDisconnect();

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
      log('WebSocket handshake failed: $e', name: _logName, stackTrace: stack);
      // Audit H2 (R-5): the handshake-throw path schedules a reconnect
      // but never emits the disconnect for whatever the *prior* cycle
      // was. _emitDisconnect was already called above for the prior
      // socket; this is just defence — if a future change adds a
      // post-_emitDisconnect transition that announces, this path
      // still cleans up correctly.
      _emitDisconnect();
      _scheduleReconnect(authToken);
      return;
    }

    state = WsConnectionStatus.connected;
    // Session 4: announce the (re)connect so TrackingSubscriptionController
    // can replay subscribe_tracking. Add() is a no-op if the controller
    // has been closed during shutdown.
    if (!_connectionEvents.isClosed) {
      _connectionEvents.add(WsConnected(DateTime.now().toUtc()));
      _announcedConnected = true;
    }
    _retryCount = 0;
    _currentBackoff = _kInitialBackoff;

    // Critical recovery step — pull anything we missed while disconnected.
    // Fire-and-forget: the socket stream is already live, and sync failures
    // are handled internally by EventSyncNotifier.
    unawaited(ref.read(eventSyncProvider.notifier).syncMissedEvents());

    _socketSubscription = _channel!.stream.listen(
      (raw) => _onMessage(raw),
      onDone: () {
        if (_manualDisconnect) return;
        _emitDisconnect();
        _scheduleReconnect(authToken);
      },
      onError: (Object error, StackTrace stack) {
        log(
          'WebSocket stream error: $error',
          name: _logName,
          stackTrace: stack,
        );
        // Audit H2 (R-21): mirror the manual-disconnect guard from
        // onDone. Without this, a stream error fired while logging
        // out (after `_manualDisconnect = true` in disconnect()) would
        // schedule a reconnect on a logged-out user — opening a
        // socket with a token the auth feature is about to clear,
        // and triggering the reconnect loop the audit warned about.
        if (_manualDisconnect) return;
        _emitDisconnect();
        _scheduleReconnect(authToken);
      },
      cancelOnError: true,
    );
  }

  /// Each [raw] frame runs through its own try/catch. A single malformed
  /// message must never break the listener loop. JSON-decode is the only
  /// concern at this layer; routing by `kind` and entity mapping live in
  /// [WsFrameDispatcher].
  void _onMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : raw.toString();
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      ref.read(wsFrameDispatcherProvider).dispatch(decoded);
    } catch (e, stack) {
      log(
        'dropping malformed WebSocket frame: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Send an upstream JSON message over the live socket. The backend
  /// honours exactly two upstream actions —
  /// `{action: 'subscribe_tracking', booking_id}` and
  /// `{action: 'unsubscribe_tracking', booking_id}`. Anything else is
  /// silently dropped server-side.
  ///
  /// Drops silently when the socket is not connected. Consumers that
  /// need at-least-once delivery (e.g. tracking subscriptions) listen
  /// to [connectionEvents] and re-issue their messages on every
  /// `WsConnected` so a reconnect replays the upstream state.
  void sendUpstream(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(message));
    } catch (e, stack) {
      log('WS upstream send failed: $e', name: _logName, stackTrace: stack);
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
    _emitDisconnect();
    state = WsConnectionStatus.disconnected;
  }

  void _emitDisconnect() {
    // Audit H2 (R-6): only emit if we previously announced a Connected.
    // Spurious WsDisconnected events from `disconnect()` calls on a
    // never-connected notifier confuse reconnect-aware consumers
    // (they'd think a prior cycle existed when none did).
    if (!_announcedConnected) return;
    if (!_connectionEvents.isClosed) {
      _connectionEvents.add(WsDisconnected(DateTime.now().toUtc()));
    }
    _announcedConnected = false;
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
    final nextMs = (_currentBackoff.inMilliseconds * 2).clamp(
      0,
      _kMaxBackoff.inMilliseconds,
    );
    _currentBackoff = Duration(milliseconds: nextMs);
  }
}
