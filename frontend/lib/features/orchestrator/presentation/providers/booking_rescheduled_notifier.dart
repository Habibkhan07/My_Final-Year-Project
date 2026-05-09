// Standalone notifier for `booking_rescheduled`. Distinct from the
// shared `booking_orchestrator_events_notifier` because the side
// effect is a nav, not a refresh — when the customer is on the
// original (now-CANCELLED) booking and the reschedule fires, we
// pushReplacement to the child booking's orchestrator screen. The
// EventUrgencyRouter intentionally does NOT add `bookingRescheduled`
// to its nav-guard, so a banner-tap from elsewhere also routes to
// the original; this notifier's pushReplacement is what lifts the
// user onto the child.
import 'dart:developer' as developer;

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../../../core/realtime/presentation/providers/dependency_injection.dart';
import '../../data/mappers/booking_event_payload_mapper.dart';

part 'booking_rescheduled_notifier.g.dart';

/// keepAlive: false — scoped to the orchestrator screen lifetime,
/// matching `BookingOrchestratorEventsNotifier`.
@Riverpod(keepAlive: false)
class BookingRescheduledNotifier extends _$BookingRescheduledNotifier {
  @override
  void build(int jobId) {
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      if (event.eventType != SystemEventType.bookingRescheduled) return;

      final eventJobId = BookingEventPayloadMapper.extractJobId(event);
      if (eventJobId != jobId) return;

      final childId = BookingEventPayloadMapper.extractChildBookingId(event);
      if (childId == null) {
        developer.log(
          'bookingRescheduled event missing child_booking_id; dropping',
          name: 'orchestrator.rescheduled',
          level: 900,
        );
        return;
      }

      // GoRouter is the router of record. We use `goNamed` via the
      // navigatorKey's currentContext — same pattern the
      // EventUrgencyRouter uses for its nav side effects.
      final ctx = ref.read(navigatorKeyProvider).currentContext;
      if (ctx == null) return;
      GoRouter.of(ctx).pushReplacement('/booking/$childId');
    });
  }
}

