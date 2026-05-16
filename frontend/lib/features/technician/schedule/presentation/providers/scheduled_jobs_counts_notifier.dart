// Counts notifier — feeds the Schedule segmented-control badge numbers.
//
// **Lifecycle.** `keepAlive: true` and registered in
// `realtimeTechnicianBootHooksProvider` alongside the list notifier
// (tech-only registry — only iterated when `isTechnician=true`). Same
// wakeup rule applies: must be subscribed before WS frames fire after
// auth so it can refetch counts when a state-machine event lands.
//
// **Refresh policy.**
//
//   * Initial load — `build()` fetches counts immediately.
//   * Realtime triggers — every event that can move a row between the
//     Upcoming and Past segments queues a refresh. Mid-job transitions
//     (`techEnRoute`, `techArrived`, `inspectionStarted`, `quoteGenerated`,
//     `quoteApproved`) deliberately do NOT trigger refetch — those keep
//     the row in Upcoming so the count is unchanged. The list-side
//     notifier picks up those for badge updates.
//   * Manual — [refresh()] for pull-to-refresh wired through from the
//     screen.
//
// **Failure policy.** Counts are render-or-omit, not load-bearing. On
// failure the screen omits the badge numbers entirely (the segmented
// control still functions). The notifier surfaces failures via
// `AsyncError`; the screen's `when()` switch decides whether to omit or
// display.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../domain/entities/scheduled_jobs_counts.dart';
import 'dependency_injection.dart';

part 'scheduled_jobs_counts_notifier.g.dart';

@Riverpod(keepAlive: true)
class ScheduledJobsCountsNotifier extends _$ScheduledJobsCountsNotifier {
  @override
  Future<ScheduledJobsCounts> build() async {
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      switch (event.eventType) {
        // Every event that can move a job between Upcoming and Past
        // counts. Intermediate-status events (en-route, arrived,
        // inspecting, quoted, approved) keep the row in Upcoming so the
        // count doesn't move — they are intentionally absent here. The
        // list notifier still updates badge_text/headline for those.
        case SystemEventType.jobAccepted:
        case SystemEventType.bookingRejected:
        case SystemEventType.bookingCancelled:
        case SystemEventType.bookingNoShow:
        case SystemEventType.quoteDeclined:
        case SystemEventType.jobCompleted:
        case SystemEventType.disputeOpened:
        case SystemEventType.paymentReceived:
        case SystemEventType.bookingRescheduled:
          _scheduleRefresh();
          break;
        // ignore: no_default_cases
        default:
          break;
      }
    });

    final useCase = ref.read(getScheduledJobsCountsUseCaseProvider);
    return useCase.call();
  }

  /// Manual refresh — pull-to-refresh on the list also bumps counts.
  Future<void> refresh() async {
    state = const AsyncLoading<ScheduledJobsCounts>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getScheduledJobsCountsUseCaseProvider);
      return useCase.call();
    });
  }

  void _scheduleRefresh() {
    // ignore: discarded_futures
    refresh();
  }
}
