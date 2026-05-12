// Counts notifier — feeds the segmented control's badge numbers.
//
// **Lifecycle.** `keepAlive: true` and registered in
// `realtimeBootHooksProvider` alongside the list notifier. Same wakeup
// rule applies: must be subscribed before WS frames fire after auth so
// it can refetch counts when a status flip event lands.
//
// **Refresh policy.**
//
//   * Initial load — `build()` fetches counts immediately.
//   * Realtime triggers — every event that can move a row between
//     segments queues a refresh. We refetch rather than locally
//     decrement/increment because (a) it's a single cheap aggregate
//     query, (b) local arithmetic could drift if events are missed
//     during a network gap. One round-trip per status flip is fine —
//     status flips are sparse, not bursty.
//   * Manual — [refresh()] for pull-to-refresh wired through from the
//     screen.
//
// **Failure policy.** Counts are render-or-omit, not load-bearing.
// On failure the screen omits the badge numbers entirely (the segmented
// control still functions). The notifier surfaces failures via
// `AsyncError` — the screen's `when()` switch decides whether to omit
// or display.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../domain/entities/bookings_counts.dart';
import 'dependency_injection.dart';

part 'customer_bookings_counts_notifier.g.dart';

@Riverpod(keepAlive: true)
class CustomerBookingsCounts extends _$CustomerBookingsCounts {
  @override
  Future<BookingsCounts> build() async {
    // Same listen-on-event pattern as the list notifier. Re-fetches on
    // any event that can shift the upcoming/past balance. Type of the
    // (previous, next) tuple is inferred from the provider's value
    // type — matches the IncomingJobQueueNotifier convention.
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      switch (event.eventType) {
        // Every event that can move a booking between Upcoming and Past
        // segments. The Upcoming→Past trip is what changes counts; the
        // intermediate-status events (en-route, arrived, inspecting,
        // quoted) keep the row in Upcoming so counts don't move — they
        // are deliberately absent here. The list-side patcher still
        // updates the card's badge.
        case SystemEventType.jobAccepted:
        case SystemEventType.bookingRejected:
        case SystemEventType.bookingCancelled:
        case SystemEventType.bookingNoShow:
        case SystemEventType.quoteDeclined:
        case SystemEventType.jobCompleted:
        case SystemEventType.bookingRescheduled:
          _scheduleRefresh();
          break;
        // ignore: no_default_cases
        default:
          break;
      }
    });

    final useCase = ref.read(getBookingsCountsUseCaseProvider);
    return useCase.call();
  }

  /// Manual refresh — pull-to-refresh on the list also bumps counts.
  Future<void> refresh() async {
    state = const AsyncLoading<BookingsCounts>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getBookingsCountsUseCaseProvider);
      return useCase.call();
    });
  }

  /// Fire-and-forget refresh from inside the event listener. We don't
  /// await it because the listener callback is sync; the new state
  /// flows through `state =` like any other async mutation.
  void _scheduleRefresh() {
    refresh();
  }
}
