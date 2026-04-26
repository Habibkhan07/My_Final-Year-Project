import 'event_criticality.dart';
import 'event_urgency.dart';
import 'system_event_type.dart';
import 'target_role.dart';

/// Represents a real-time system event delivered from the backend.
///
/// Fed by two sources:
///   - WebSocket stream (live push from Django Channels)
///   - `/api/events/sync/` (missed-event recovery on reconnect)
///
/// The [payload] field is opaque to the core layer — feature-specific
/// notifiers are responsible for interpreting its contents.
class SystemEventEntity {
  final String id;
  final String rawType;
  final SystemEventType eventType;
  final TargetRole targetRole;
  final DateTime timestamp;

  /// Opaque map — core layer never reads inside this.
  final Map<String, dynamic> payload;

  final EventUrgency urgency;
  final bool isCritical;

  const SystemEventEntity({
    required this.id,
    required this.rawType,
    required this.eventType,
    required this.targetRole,
    required this.timestamp,
    required this.payload,
    required this.urgency,
    required this.isCritical,
  });

  /// Used by the Data layer mapper in session 2.
  /// Derives [eventType], [urgency], and [isCritical] from primitives
  /// so the mapper only needs to pass raw strings and the decoded payload.
  factory SystemEventEntity.fromComponents({
    required String id,
    required String rawType,
    required String targetRoleStr,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) {
    final eventType = SystemEventType.fromRawType(rawType);
    return SystemEventEntity(
      id: id,
      rawType: rawType,
      eventType: eventType,
      targetRole: TargetRole.fromString(targetRoleStr),
      timestamp: timestamp,
      payload: payload,
      urgency: EventUrgency.of(eventType),
      isCritical: EventCriticality.isCritical(eventType),
    );
  }

  /// Two events with the same UUID are the same event — used by dedup logic.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemEventEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
