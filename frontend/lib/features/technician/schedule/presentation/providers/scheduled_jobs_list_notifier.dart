// Scheduled-jobs list notifier — the single source of truth for the
// Schedule screen's list.
//
// **Lifecycle.**
//
//   * `keepAlive: true` because the notifier MUST be subscribed to
//     `systemEventProvider` BEFORE any state-machine event arrives. The
//     orchestrator's `realtimeBootHooksProvider` registry includes
//     [scheduledJobsListProvider] (and the counts provider) so
//     `bootAfterAuth` performs an eager `ref.read(...)` before the WS
//     connect cascade fires. Same pattern the dashboard + customer
//     bookings list use.
//
// **Build.**
//
//   * Watches [selectedScheduleSegmentProvider]. A segment switch
//     triggers a fresh `build()` (re-fetch of the new segment's first
//     page). State is NOT preserved across segments — switching back
//     fetches fresh.
//   * Subscribes to `systemEventProvider` via `ref.listen` for typed
//     event matching. A `null` `latestEvent` (housekeeping rebuild) and
//     same-id repeats (envelope already deduped upstream) are skipped.
//
// **Mutations.**
//
//   * [refresh()] — pull-to-refresh. Drops cursor, fetches first page
//     fresh. Wraps in `AsyncValue.guard`.
//   * [loadMore()] — appends next page. Idempotent on `isLoadingMore`.
//
// **Realtime policy.** Unlike the customer-side list (which uses an
// inline event-patch mapper to update card badges without a round-trip),
// the Schedule list refetches the current page on every relevant event.
// Rationale:
//   * Backend status→UI table is the source of truth — mirroring it
//     client-side would force a per-event patch mapper that drifts.
//   * The page is small (≤20 rows) and the BE selector hits 1 SQL query
//     per page (verified by `django_assert_num_queries` tests).
//   * `state = AsyncLoading().copyWithPrevious(state)` keeps the
//     previous items rendered during the refetch — no skeleton flash.
//
// The set of events listened to is broader than the dashboard's because
// Schedule shows mid-job rows whose badge updates on intermediate
// transitions (`techEnRoute`, `techArrived`, `inspectionStarted`,
// `quoteGenerated`, etc.). The dashboard only cares about row entry/exit.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'dependency_injection.dart';
import 'scheduled_jobs_list_state.dart';
import 'selected_schedule_segment_notifier.dart';

part 'scheduled_jobs_list_notifier.g.dart';

@Riverpod(keepAlive: true)
class ScheduledJobsList extends _$ScheduledJobsList {
  @override
  Future<ScheduledJobsListState> build() async {
    final segment = ref.watch(selectedScheduleSegmentProvider);

    // Realtime invalidator. Any state-machine event that can change the
    // visible list (new row, terminal transition, mid-job badge) triggers
    // a single first-page refetch. Same dedup pattern as the dashboard
    // notifier: skip when previous and next reference the same event id.
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      switch (event.eventType) {
        // Row entry / exit between Upcoming and Past:
        case SystemEventType.jobAccepted:
        case SystemEventType.jobCompleted:
        case SystemEventType.bookingRejected:
        case SystemEventType.bookingCancelled:
        case SystemEventType.bookingNoShow:
        case SystemEventType.quoteDeclined:
        case SystemEventType.disputeOpened:
        case SystemEventType.paymentReceived:
        case SystemEventType.bookingRescheduled:
        // Mid-job badge transitions (row stays on Upcoming but the
        // ui.headline/badge_text changes — refetch picks up the new
        // server-resolved block):
        case SystemEventType.techEnRoute:
        case SystemEventType.techArrived:
        case SystemEventType.inspectionStarted:
        case SystemEventType.quoteGenerated:
        case SystemEventType.quoteApproved:
        case SystemEventType.quoteRevisionRequested:
          _scheduleRefresh();
          break;
        // ignore: no_default_cases
        default:
          break;
      }
    });

    final useCase = ref.read(getScheduledJobsUseCaseProvider);
    final page = await useCase.call(segment: segment);

    return ScheduledJobsListState(
      segment: segment,
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      isStaleCache: page.isStaleCache,
      cachedAt: page.cachedAt,
      serverTime: page.serverTime,
    );
  }

  /// Pull-to-refresh. Re-fetches the first page for the current segment.
  Future<void> refresh() async {
    final segment = ref.read(selectedScheduleSegmentProvider);
    state = const AsyncLoading<ScheduledJobsListState>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getScheduledJobsUseCaseProvider);
      final page = await useCase.call(segment: segment);
      return ScheduledJobsListState(
        segment: segment,
        items: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isStaleCache: page.isStaleCache,
        cachedAt: page.cachedAt,
        serverTime: page.serverTime,
      );
    });
  }

  /// Append the next page. No-op when not in `data`, when `hasMore` is
  /// false, when a previous loadMore is in flight, or when serving from
  /// stale cache (cursor is meaningless offline).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (!current.hasMore) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;
    if (current.isStaleCache) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(getScheduledJobsUseCaseProvider);
      final page = await useCase.call(
        segment: current.segment,
        cursor: current.nextCursor,
      );

      final after = state.value;
      if (after == null) return;

      state = AsyncData(
        after.copyWith(
          items: [...after.items, ...page.items],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
          // Defensive: pagination should never enter stale-cache mode
          // (the repo throws OfflineNoCache for non-first pages on
          // SocketException) but clear the flag in case the upstream
          // contract widens later.
          isStaleCache: false,
          cachedAt: null,
          serverTime: page.serverTime,
        ),
      );
    } catch (_) {
      // Don't blow away the list on a pagination error — the user can
      // still scroll back through what they have. Just clear the loading
      // flag. Future polish: surface a snackbar via screen-side state.
      final after = state.value;
      if (after != null) {
        state = AsyncData(after.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Fire-and-forget refresh from inside the event listener. The
  /// listener callback is sync; the new state flows through `state =`
  /// like any other async mutation.
  void _scheduleRefresh() {
    // ignore: discarded_futures
    refresh();
  }
}
