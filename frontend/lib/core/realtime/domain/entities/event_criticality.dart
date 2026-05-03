import 'system_event_type.dart';

/// Mirrors the Django backend's Event Type Registry exactly.
/// If this set drifts from the backend, critical events will either
/// never be ACK'd or non-critical events will trigger unnecessary ACK calls.
abstract class EventCriticality {
  static const criticalTypes = <SystemEventType>{
    SystemEventType.jobNewRequest,
    // `jobAccepted` deliberately not in this set — flag #25 flipped its
    // backend `is_critical` to False (informational; EventLog persistence
    // + sync-replay cover offline). Mirrors `bookingRejected` (flag #22).
    SystemEventType.quoteGenerated,
    SystemEventType.quoteApproved,
    SystemEventType.jobCompleted,
    SystemEventType.disputeOpened,
    SystemEventType.disputeResolved,
  };

  static bool isCritical(SystemEventType type) => criticalTypes.contains(type);
}
