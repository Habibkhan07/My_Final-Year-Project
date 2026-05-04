// Customer bookings list notifier — the single source of truth for the
// list screen.
//
// **Lifecycle.**
//
//   * `keepAlive: true` because the notifier MUST be subscribed to
//     `systemEventProvider` BEFORE any `job_accepted` /
//     `booking_rejected` event arrives. The orchestrator's boot-hook
//     registry includes [customerBookingsListProvider] (and the counts
//     provider) so `bootAfterAuth` performs an eager `ref.read(...)`
//     before the WS connect cascade fires. Same pattern the technician
//     incoming-jobs queue uses — see CLAUDE.md "list-route wakeup" rule.
//
// **Build.**
//
//   * Watches [selectedSegmentProvider]. A segment switch triggers a
//     fresh `build()` (re-fetch of the new segment's first page). State
//     is NOT preserved across segments — switching back fetches fresh.
//   * Subscribes to `systemEventProvider` via `ref.listen` for typed
//     event matching. A `null` `latestEvent` (housekeeping rebuild) and
//     same-id repeats (envelope already deduped upstream) are skipped.
//
// **Mutations.**
//
//   * [refresh()] — pull-to-refresh. Drops cursor, fetches first page
//     fresh. Wraps in `AsyncValue.guard` per CLAUDE.md.
//   * [loadMore()] — appends next page. Idempotent on `isLoadingMore`.
//   * Realtime patches happen inline inside the listener; no public
//     method.
//
// **Realtime patch policy.**
//
//   * Match by `payload.job_id`. Found → patch in place via the
//     event-patch mapper (Option ii — no detail round-trip).
//   * Not found → silent no-op. The arriving event is for a booking
//     not in the current segment (e.g., `bookingRejected` arrived
//     while user is on Upcoming and the rejected booking is now in
//     Past). The counts notifier handles its own refresh; when the
//     user switches segments the new fetch picks up the row.
//
//   * Patches mutate `state.requireValue.items`. Per CLAUDE.md, never
//     `state.value!`.
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_entity.dart';
import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../data/mappers/booking_event_patch_mapper.dart';
import '../../domain/entities/customer_booking.dart';
import 'customer_bookings_list_state.dart';
import 'dependency_injection.dart';
import 'selected_segment_notifier.dart';

part 'customer_bookings_list_notifier.g.dart';

@Riverpod(keepAlive: true)
class CustomerBookingsList extends _$CustomerBookingsList {
  static const _logName = 'features.customer.bookings.list_notifier';

  @override
  Future<CustomerBookingsListState> build() async {
    // Watching `selectedSegmentProvider` makes a tab change rebuild
    // this notifier from scratch. The previous state is discarded —
    // each segment fetches its own first page on activation.
    final segment = ref.watch(selectedSegmentProvider);

    // Realtime patcher. Subscription survives across rebuilds because
    // `keepAlive: true` keeps the provider mounted, but the listener
    // re-registers on every build — that's fine, Riverpod cleans up
    // the previous registration as part of build's teardown.
    //
    // The listener type is inferred from the provider's value type
    // (`SystemEventState`); we don't import the type explicitly,
    // matching the cargo-cult pattern in `IncomingJobQueueNotifier`.
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      if (previous?.latestEvent?.id == event.id) return;
      _onSystemEvent(event);
    });

    final useCase = ref.read(getCustomerBookingsUseCaseProvider);
    final page = await useCase.call(segment: segment);

    return CustomerBookingsListState(
      segment: segment,
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      isStaleCache: page.isStaleCache,
      cachedAt: page.cachedAt,
      serverTime: page.serverTime,
    );
  }

  /// Pull-to-refresh. Re-fetches the first page for the current
  /// segment. Wraps in [AsyncValue.guard] so transient failures
  /// surface as `AsyncError` and the screen can render its retry UX
  /// against the previous data.
  Future<void> refresh() async {
    final segment = ref.read(selectedSegmentProvider);
    state = const AsyncLoading<CustomerBookingsListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getCustomerBookingsUseCaseProvider);
      final page = await useCase.call(segment: segment);
      return CustomerBookingsListState(
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

  /// Append the next page to the list. No-op when:
  ///   * we're not currently in a `data` state
  ///   * `hasMore` is false
  ///   * a previous loadMore is still in flight
  ///   * we're rendering from cache (offline; cursor is meaningless)
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (!current.hasMore) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;
    if (current.isStaleCache) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(getCustomerBookingsUseCaseProvider);
      final page = await useCase.call(
        segment: current.segment,
        cursor: current.nextCursor,
      );

      // Re-read current state in case a realtime patch landed between
      // dispatch and response. The patch mutates items without changing
      // cursor/hasMore, so concatenating is safe — but we want the
      // patched items to win, not the pre-dispatch snapshot.
      final after = state.value;
      if (after == null) return;

      state = AsyncData(after.copyWith(
        items: [...after.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
        // pagination should never put the list into stale-cache mode —
        // the repo throws OfflineNoCache for non-first pages on
        // SocketException — but defensively clear the flag just in case
        // the upstream contract widens later.
        isStaleCache: false,
        cachedAt: null,
        serverTime: page.serverTime,
      ));
    } catch (e, stack) {
      // Don't blow away the list on a pagination error — the user can
      // still scroll back through what they have. Just clear the
      // loading flag and log; surface a snackbar via a SnackError state
      // would be nice but is screen-side polish (next sprint).
      log(
        'loadMore() failed: $e',
        name: _logName,
        stackTrace: stack,
      );
      final after = state.value;
      if (after != null) {
        state = AsyncData(after.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Realtime patcher. Called inline from the `ref.listen` callback in
  /// build. Type-filters to the events we care about, defers the mapper
  /// for the actual transformation.
  void _onSystemEvent(SystemEventEntity event) {
    switch (event.eventType) {
      case SystemEventType.jobAccepted:
        _patch(event, BookingEventPatchMapper.applyJobAccepted);
        break;
      case SystemEventType.bookingRejected:
        _patch(event, BookingEventPatchMapper.applyBookingRejected);
        break;
      // Slot reserved for future events (`quote_generated`,
      // `quote_approved`, `tech_en_route`, `tech_arrived`,
      // `job_completed`, `payment_received`). Each will route through
      // its own mapper static method when it lands. For now: ignore.
      // ignore: no_default_cases
      default:
        break;
    }
  }

  /// Find the matching item by `payload.job_id`, run [transform], emit
  /// the new state. Missing or unknown job_id → no-op.
  void _patch(
    SystemEventEntity event,
    CustomerBooking Function(CustomerBooking, SystemEventEntity) transform,
  ) {
    final current = state.value;
    if (current == null) return;

    final jobId = BookingEventPatchMapper.jobIdFromPayload(event);
    if (jobId == null) {
      log(
        'Realtime event ${event.rawType} missing job_id; ignoring.',
        name: _logName,
      );
      return;
    }

    final index = current.items.indexWhere((b) => b.id == jobId);
    if (index < 0) {
      // Booking not in this segment — silent. The counts notifier
      // refreshes itself from the same listener; when the user switches
      // tabs the row will be present.
      return;
    }

    final patched = transform(current.items[index], event);
    final nextItems = [...current.items];
    nextItems[index] = patched;

    state = AsyncData(current.copyWith(items: nextItems));
  }
}
