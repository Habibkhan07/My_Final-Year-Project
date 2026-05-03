import 'system_event_type.dart';

enum EventUrgency {
  highUrgency,
  lowUrgency,
  silent;

  static const Map<SystemEventType, EventUrgency> _urgencyMap = {
    SystemEventType.jobNewRequest: EventUrgency.highUrgency,
    SystemEventType.jobAccepted: EventUrgency.highUrgency,
    SystemEventType.bookingRejected: EventUrgency.lowUrgency,
    SystemEventType.quoteGenerated: EventUrgency.highUrgency,
    SystemEventType.quoteApproved: EventUrgency.highUrgency,
    SystemEventType.jobCompleted: EventUrgency.highUrgency,
    SystemEventType.disputeOpened: EventUrgency.highUrgency,
    SystemEventType.disputeResolved: EventUrgency.highUrgency,
    SystemEventType.techEnRoute: EventUrgency.lowUrgency,
    SystemEventType.techArrived: EventUrgency.lowUrgency,
    SystemEventType.chatMessage: EventUrgency.lowUrgency,
    SystemEventType.paymentReceived: EventUrgency.lowUrgency,
    SystemEventType.walletLowBalance: EventUrgency.lowUrgency,
    SystemEventType.unknown: EventUrgency.silent,
  };

  static EventUrgency of(SystemEventType type) =>
      _urgencyMap[type] ?? EventUrgency.silent;
}
