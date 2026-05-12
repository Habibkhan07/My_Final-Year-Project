// Multi-event listener for the orchestrator screen. Per CLAUDE.md "no
// central switch" applies to `core/realtime` — within a feature, a
// single multi-event filter is idiomatic and matches the existing
// `customer_bookings_list_notifier` pattern.
//
// 12 of the 13 trigger events do exactly the same thing — invalidate
// the booking-detail provider so it refetches. Per-event notifiers
// would be 12 nearly-identical files. Only `booking_rescheduled` has
// a side effect beyond refresh (nav to child booking) and gets its
// own notifier (`booking_rescheduled_notifier.dart`).
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../data/mappers/booking_event_payload_mapper.dart';
import 'booking_detail_provider.dart';

part 'booking_orchestrator_events_notifier.g.dart';

/// keepAlive: false — this notifier is scoped to the orchestrator
/// screen lifetime. The screen `ref.read`s it in `initState` to wake
/// the listener; popping the screen unmounts the provider and stops
/// the refresh chain.
///
/// Rationale for *not* registering in `realtimeBootHooksProvider`:
/// the orchestrator screen is detail-route, not list-route. There's
/// no queue to fill at boot — the screen mounts on user nav and
/// hydrates on first read. Events arriving while the screen is closed
/// are persisted in `EventLog` and replayed on next mount via the
/// initial fetch (the response reflects the latest state).
@Riverpod(keepAlive: false)
class BookingOrchestratorEventsNotifier
    extends _$BookingOrchestratorEventsNotifier {
  /// Events that should trigger a refresh of `bookingDetailProvider(jobId)`.
  /// `bookingRescheduled` is intentionally absent — `bookingRescheduledNotifier`
  /// handles it (the side effect is nav, not refresh).
  static const _refreshTriggerEvents = <SystemEventType>{
    // Tech-accepted (AWAITING → CONFIRMED) and tech-rejected
    // (AWAITING → REJECTED). The customer is sitting on their
    // AWAITING orchestrator screen waiting for a decision; without
    // these the screen stays "Looking for a technician…" until the
    // user manually pulls to refresh.
    SystemEventType.jobAccepted,
    SystemEventType.bookingRejected,
    SystemEventType.techEnRoute,
    SystemEventType.techArrived,
    // InDrive-style customer ACK. Fired tech-side when the customer taps
    // "I'm coming out" on ARRIVED so the tech's meeting strip flips
    // from amber to green without a manual refresh.
    SystemEventType.customerArriving,
    // Tech-side fallback start_inspection: customer never tapped
    // "I'm coming out", tech advances ARRIVED → INSPECTING themselves.
    // Customer's screen needs to flip to the INSPECTING body. The event
    // is silent at the router level (no banner) but routed here so the
    // detail provider refetches.
    SystemEventType.inspectionStarted,
    SystemEventType.quoteGenerated,
    SystemEventType.quoteRevisionRequested,
    SystemEventType.quoteApproved,
    SystemEventType.quoteDeclined,
    SystemEventType.paymentReceived,
    SystemEventType.jobCompleted,
    SystemEventType.bookingCancelled,
    SystemEventType.bookingNoShow,
    SystemEventType.disputeOpened,
    SystemEventType.disputeResolved,
  };

  @override
  void build(int jobId) {
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      if (!_refreshTriggerEvents.contains(event.eventType)) return;

      final eventJobId = BookingEventPayloadMapper.extractJobId(event);
      if (eventJobId != jobId) return;

      // Audit CSC-02: ref.invalidate for event-driven refetches.
      // The detail provider's build() runs again; Riverpod 3's
      // AsyncValue preserves the prior value during the rebuild and
      // sets `isRefreshing == true`. The screen renders a thin top
      // progress bar instead of flashing to a spinner.
      ref.invalidate(bookingDetailProvider(jobId));
    });
  }
}
