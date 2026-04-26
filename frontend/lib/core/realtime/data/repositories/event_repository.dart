import 'dart:async';
import 'dart:developer';
import 'dart:io';

import '../../../common/errors/http_failure.dart';
import '../../domain/entities/system_event_entity.dart';
import '../../domain/failures/event_failures.dart';
import '../datasources/event_local_data_source.dart';
import '../datasources/event_remote_data_source.dart';
import '../mappers/system_event_mapper.dart';
import '../models/system_event_model.dart';

/// Orchestrates event sync + FCM device registration.
///
/// Implements the project's mandatory offline-first pattern on every read:
///   1. Try remote.
///   2. On success: cache, update cursor, map to domain.
///   3. On [SocketException] / [TimeoutException]: fall back to cache,
///      or throw the Domain sealed [EventSyncNetworkFailure] if cache empty.
///   4. On [HttpFailure]: map the envelope to a Domain sealed class.
///
/// ACK writes use a best-effort local retry queue — a failed ACK never
/// surfaces as an error because the backend's unacknowledged-events
/// endpoint will resurface the same critical events on the next cycle.
class EventRepository {
  final EventRemoteDataSource _remote;
  final EventLocalDataSource _local;

  static const _logName = 'core.data.event_repository';

  const EventRepository(this._remote, this._local);

  /// Fetches events newer than [isoTimestamp], caching the response and
  /// advancing the local sync cursor to the newest event's timestamp.
  ///
  /// Offline-first: falls back to the cached event list if the network is
  /// unavailable. Throws [EventSyncNetworkFailure] only when both the
  /// network call and the cache are empty.
  ///
  /// Throws:
  ///   - [EventSyncNetworkFailure] — offline and no cached events.
  ///   - [EventSyncUnauthorized]   — 401 from the backend.
  ///   - [EventSyncServerFailure]  — any other non-2xx.
  Future<List<SystemEventEntity>> syncMissedEvents(String isoTimestamp) async {
    try {
      final models = await _remote.fetchEventsSince(isoTimestamp);
      await _local.cacheEventList(models);
      if (models.isNotEmpty) {
        await _local.saveLastSyncTimestamp(_newestTimestamp(models));
      }
      return _mapToDomain(models);
    } on SocketException {
      return _returnCacheOrThrow();
    } on TimeoutException {
      return _returnCacheOrThrow();
    } on HttpFailure catch (failure) {
      _mapFailure(failure);
    }
  }

  /// Fetches critical events the backend has not yet seen an ACK for.
  ///
  /// Offline-first with the same semantics as [syncMissedEvents].
  ///
  /// Throws:
  ///   - [EventSyncNetworkFailure] — offline and no cached events.
  ///   - [EventSyncUnauthorized]   — 401 from the backend.
  ///   - [EventSyncServerFailure]  — any other non-2xx.
  Future<List<SystemEventEntity>> fetchUnacknowledgedCritical() async {
    try {
      final models = await _remote.fetchUnacknowledgedCritical();
      await _local.cacheEventList(models);
      return _mapToDomain(models);
    } on SocketException {
      return _returnCacheOrThrow();
    } on TimeoutException {
      return _returnCacheOrThrow();
    } on HttpFailure catch (failure) {
      _mapFailure(failure);
    }
  }

  /// Best-effort acknowledge. Merges [eventIds] with any previously-failed
  /// ACKs, dedupes, POSTs to the backend. On success clears the local
  /// pending-acks queue; on any failure persists the merged list for the
  /// next cycle.
  ///
  /// Does NOT throw — callers must not treat ACK as a blocking step. The
  /// next `fetchUnacknowledgedCritical` will resurface anything the
  /// backend hasn't recorded yet.
  Future<void> acknowledgeEvents(List<String> eventIds) async {
    final merged =
        <String>{..._local.getPendingAcks(), ...eventIds}.toList();
    if (merged.isEmpty) return;
    try {
      await _remote.acknowledgeEvents(merged);
      await _local.clearPendingAcks();
    } catch (e, stack) {
      log(
        'acknowledgeEvents: queuing ${merged.length} IDs for retry: $e',
        name: _logName,
        stackTrace: stack,
      );
      await _local.savePendingAcks(merged);
    }
  }

  /// Registers this device's FCM token with the backend.
  ///
  /// Throws:
  ///   - [DeviceRegistrationNetworkFailure] — offline or timed out.
  ///   - [DeviceRegistrationServerFailure]  — any non-2xx.
  Future<void> registerDevice(String token, String deviceType) async {
    try {
      await _remote.registerDevice(token, deviceType);
    } on SocketException {
      throw const DeviceRegistrationNetworkFailure();
    } on TimeoutException {
      throw const DeviceRegistrationNetworkFailure();
    } on HttpFailure catch (failure) {
      _mapDeviceFailure(failure);
    }
  }

  /// Best-effort deregister. Swallows all failures — the backend's stale
  /// token sweep will reconcile abandoned tokens eventually, so there is
  /// no user-facing value in surfacing an error here.
  Future<void> unregisterDevice(String token) async {
    try {
      await _remote.unregisterDevice(token);
    } catch (e, stack) {
      log(
        'unregisterDevice: swallowing error for best-effort deregister: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────────

  List<SystemEventEntity> _mapToDomain(List<SystemEventModel> models) {
    final result = <SystemEventEntity>[];
    for (final model in models) {
      final entity = model.toDomain();
      if (entity != null) result.add(entity);
    }
    return result;
  }

  /// ISO-8601 strings with a consistent offset sort lexicographically,
  /// so `compareTo` yields the correct ordering for picking the newest.
  String _newestTimestamp(List<SystemEventModel> models) {
    return models
        .map((m) => m.timestamp)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
  }

  List<SystemEventEntity> _returnCacheOrThrow() {
    final cached = _local.getCachedEventList();
    if (cached == null) {
      throw const EventSyncNetworkFailure();
    }
    return _mapToDomain(cached);
  }

  Never _mapFailure(HttpFailure failure) {
    switch (failure.statusCode) {
      case 401:
        throw const EventSyncUnauthorized();
      default:
        throw EventSyncServerFailure(failure.message);
    }
  }

  Never _mapDeviceFailure(HttpFailure failure) {
    throw DeviceRegistrationServerFailure(failure.message);
  }
}
