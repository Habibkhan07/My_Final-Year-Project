import 'system_event_type.dart';

/// Mirrors the Django backend's Event Type Registry exactly.
/// If this set drifts from the backend, critical events will either
/// never be ACK'd or non-critical events will trigger unnecessary ACK calls.
abstract class EventCriticality {
  static const criticalTypes = <SystemEventType>{
    SystemEventType.jobNewRequest,
    SystemEventType.jobAccepted,
    SystemEventType.quoteGenerated,
    SystemEventType.quoteApproved,
    SystemEventType.jobCompleted,
    SystemEventType.disputeOpened,
    SystemEventType.disputeResolved,
  };

  static bool isCritical(SystemEventType type) => criticalTypes.contains(type);
}
