import 'system_event_type.dart';

enum EventUrgency {
  highUrgency,
  lowUrgency,
  silent;

  static const Map<SystemEventType, EventUrgency> _urgencyMap = {
    SystemEventType.jobNewRequest: EventUrgency.highUrgency,
    // `jobAccepted` is informational — the customer initiated the booking
    // and is implicitly waiting. A `MaterialBanner` ("Booking confirmed —
    // Ali Khan is on the way") respects whatever they were doing while
    // they waited; a high-urgency push would yank them into a screen they
    // can self-navigate to. Mirrors the `bookingRejected` choice (flag #22).
    SystemEventType.jobAccepted: EventUrgency.lowUrgency,
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
