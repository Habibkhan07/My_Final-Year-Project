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
///
/// [expiresAt] / [recipientUserId] are flag #19 envelope-level fields.
/// Both are optional and remain null on legacy events that were
/// dispatched before the backend started populating them.
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

  /// Server-stamped instant at which the event becomes useless to act on
  /// (e.g. a `job_new_request` whose SLA window has elapsed). Null on
  /// events with no time-windowed semantics. The pipeline filter in
  /// `SystemEventNotifier.processEvent` consults this to drop stale
  /// events before any feature subscriber sees them. See flag #19.
  final DateTime? expiresAt;

  /// Auth user id this event was dispatched to. Null on legacy events
  /// (during the wire contract rollout window). The pipeline filter
  /// rejects events whose recipient does not match the currently-
  /// authenticated user — defends against the multi-account-device race.
  /// See flag #19.
  final int? recipientUserId;

  const SystemEventEntity({
    required this.id,
    required this.rawType,
    required this.eventType,
    required this.targetRole,
    required this.timestamp,
    required this.payload,
    required this.urgency,
    required this.isCritical,
    this.expiresAt,
    this.recipientUserId,
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
    DateTime? expiresAt,
    int? recipientUserId,
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
      expiresAt: expiresAt,
      recipientUserId: recipientUserId,
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
