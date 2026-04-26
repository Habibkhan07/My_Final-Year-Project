import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/system_event_entity.dart';

part 'system_event_state.freezed.dart';

/// Observable state owned by [SystemEventNotifier].
///
/// Three slots:
///   1. [latestEvent]         — last event that cleared dedup + order checks.
///                              Router listens on transitions of this field.
///   2. [processedEventIds]   — bounded dedup set (id → event timestamp).
///                              Capped at 100; when exceeded the oldest 50
///                              are pruned in a single batch. Batch pruning
///                              beats per-insert eviction during bursts —
///                              a 60-message chat burst prunes once, not 60.
///   3. [lastSyncTimestamp]   — newest event timestamp ever observed. Used
///                              as the `since` cursor for `/api/events/sync/`
///                              on the next reconnect.
@freezed
abstract class SystemEventState with _$SystemEventState {
  const factory SystemEventState({
    SystemEventEntity? latestEvent,
    @Default(<String, DateTime>{}) Map<String, DateTime> processedEventIds,
    DateTime? lastSyncTimestamp,
  }) = _SystemEventState;
}
