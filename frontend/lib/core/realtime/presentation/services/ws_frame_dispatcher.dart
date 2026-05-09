import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mappers/system_event_mapper.dart';
import '../../data/models/system_event_model.dart';
import '../notifiers/system_event_notifier.dart';

/// Wire-edge router for every decoded WebSocket frame.
///
/// Two pipelines share `/ws/events/`:
///   - **Events** (`kind: "event"`) — durable facts. Routed into
///     [SystemEventNotifier], which dedupes + drives the urgency router.
///   - **Streams** (`kind: "stream"`) — transient state values (live
///     wallet balance, GPS, typing indicators). Routed into a per-
///     `streamType` handler registry. Streams MUST NOT touch
///     [SystemEventNotifier]: they have no id to dedup on, no critical
///     ACK contract, and would thrash the [SharedPreferences]-backed
///     event cache for nothing.
///
/// The dispatcher is intentionally a plain Dart class, not a Riverpod
/// notifier — it has no observable state. Its handler registry is mutated
/// by feature-side DI providers calling [register]; the dispatcher itself
/// imports nothing feature-specific so the core layer stays acyclic.
///
/// Logging policy (Adjustment 1 from the patch decision log):
///   - Missing `kind`: severe + assert in debug. Contract violation, not
///     version skew — backends are required to emit `kind` on every frame.
///   - Unknown `kind` value (e.g. a future `"telemetry-v2"`): warning.
///     Real version skew between deployed backend and frontend; surfaced
///     visibly but not fatal.
///   - Unknown `streamType` with no registered handler: warning. Same
///     category — backend can ship a new streamType before the frontend
///     wires its handler.
class WsFrameDispatcher {
  WsFrameDispatcher(this._ref);

  final Ref _ref;
  final Map<String, void Function(Map<String, dynamic> payload)>
  _streamHandlers = {};

  static const _logName = 'core.presentation.ws_dispatcher';
  static const _severeLevel = 1000;
  static const _warningLevel = 900;

  /// Registers [handler] for stream frames whose `streamType` equals
  /// [streamType]. Replaces any existing handler under the same key —
  /// last-writer-wins is intentional so hot reload during development
  /// doesn't accumulate stale closures.
  void register(
    String streamType,
    void Function(Map<String, dynamic> payload) handler,
  ) {
    _streamHandlers[streamType] = handler;
  }

  /// Removes the handler for [streamType] if any. Used by tests and by
  /// feature DI on logout-style teardown.
  void unregister(String streamType) {
    _streamHandlers.remove(streamType);
  }

  /// Routes a decoded WebSocket frame.
  ///
  /// The caller (`WsConnectionNotifier._onMessage`) is responsible for
  /// the JSON-decode try/catch — that is a transport concern. From this
  /// boundary inward, [frame] is trusted to be a JSON object.
  void dispatch(Map<String, dynamic> frame) {
    final kind = frame['kind'];
    switch (kind) {
      case 'event':
        _routeEvent(frame);
        return;
      case 'stream':
        _routeStream(frame);
        return;
      case null:
        log(
          'Frame is missing required "kind" field; dropping. frame=$frame',
          name: _logName,
          level: _severeLevel,
        );
        assert(false, 'WS frame missing required "kind" field: $frame');
        return;
      default:
        log(
          'Unknown frame kind="$kind"; dropping. Likely backend/frontend '
          'version skew. frame=$frame',
          name: _logName,
          level: _warningLevel,
        );
        return;
    }
  }

  void _routeEvent(Map<String, dynamic> frame) {
    final SystemEventModel model;
    try {
      model = SystemEventModel.fromJson(frame);
    } catch (e, stack) {
      log(
        'Dropping malformed event frame: $e',
        name: _logName,
        stackTrace: stack,
      );
      return;
    }
    final entity = model.toDomain();
    if (entity == null) {
      // Mapper already logged the reason. Do not push null into the
      // notifier — its dedup map keys on entity.id, and a null entity
      // would be a silent contract violation upstream.
      return;
    }
    // Tag as `ws` so `SystemEventNotifier` updates its server-time anchor
    // on this event. WS frames are near-live by definition; FCM and sync
    // paths do NOT pass `ws` for the same reason.
    _ref
        .read(systemEventProvider.notifier)
        .processEvent(entity, source: SystemEventSource.ws);
  }

  void _routeStream(Map<String, dynamic> frame) {
    final streamType = frame['streamType'];
    if (streamType is! String) {
      log(
        'Stream frame missing "streamType" string; dropping. frame=$frame',
        name: _logName,
        level: _warningLevel,
      );
      return;
    }
    final handler = _streamHandlers[streamType];
    if (handler == null) {
      log(
        'No handler registered for streamType="$streamType"; dropping. '
        'Likely backend shipped a stream type before the frontend wired '
        'its handler.',
        name: _logName,
        level: _warningLevel,
      );
      return;
    }
    final payload = frame['payload'];
    if (payload is! Map<String, dynamic>) {
      log(
        'Stream frame for streamType="$streamType" has non-object payload; '
        'dropping. payload=$payload',
        name: _logName,
        level: _warningLevel,
      );
      return;
    }
    handler(payload);
  }

  @visibleForTesting
  bool hasHandlerFor(String streamType) =>
      _streamHandlers.containsKey(streamType);
}
