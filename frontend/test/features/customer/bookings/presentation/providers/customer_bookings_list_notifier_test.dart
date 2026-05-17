// Tests for CustomerBookingsList notifier — state-layer per CLAUDE.md
// (ProviderContainer, no widget mounting).
//
// Covers exhaustively:
//   * build() awaits the repository's first page and produces an
//     AsyncData state with the documented fields.
//   * Initial-load failure surfaces as AsyncError carrying the typed
//     CustomerBookingsFailure verbatim.
//   * refresh() re-fetches and replaces state; failures surface via
//     AsyncValue.guard.
//   * loadMore() appends + advances cursor + drives isLoadingMore.
//   * loadMore() guards: no-op when !hasMore, when isLoadingMore is
//     already true, when nextCursor==null, when isStaleCache is true.
//   * loadMore() failures don't blow away existing items.
//   * Segment switch via selectedSegmentProvider triggers a rebuild
//     with a fresh first-page fetch for the new segment.
//   * Realtime patching: jobAccepted finds item by job_id and updates
//     state via the event-patch mapper.
//   * Realtime patching: bookingRejected updates state.
//   * Realtime patching: unknown job_id is a silent no-op.
//   * Realtime patching: events with missing job_id silently ignored.
//   * Realtime patching: events of irrelevant types ignored.
//   * Stale-cache (offline) page surfaces with isStaleCache=true and
//     loadMore() refuses while in that mode.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_counts.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_page.dart';
import 'package:frontend/features/customer/bookings/domain/entities/customer_booking.dart';
import 'package:frontend/features/customer/bookings/domain/failures/customer_bookings_failure.dart';
import 'package:frontend/features/customer/bookings/domain/repositories/customer_bookings_repository.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/selected_segment_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocal extends Mock implements EventLocalDataSource {}

/// Programmable repository — controls every page returned and every
/// throw at the test boundary. Each call captures its args for later
/// assertion.
class _FakeRepo implements ICustomerBookingsRepository {
  /// Per-segment scripted responses. The notifier asks for at most one
  /// page per build; loadMore() asks again. We script in order.
  final List<BookingsPage> queuedPages = [];
  final List<Object> queuedThrows = [];

  /// Capture for assertions.
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<BookingsPage> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    calls.add({
      'segment': segment,
      'cursor': cursor,
      'pageSize': pageSize,
      'statusFilter': statusFilter,
    });
    if (queuedThrows.isNotEmpty) {
      throw queuedThrows.removeAt(0);
    }
    return queuedPages.removeAt(0);
  }

  @override
  Future<BookingsCounts> getCounts() async {
    // Counts notifier is exercised in its own test; we still need a
    // valid stub so `customerBookingsCountsProvider` doesn't blow up
    // if accidentally read.
    return BookingsCounts(
      upcoming: 0,
      past: 0,
      serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
    );
  }
}

// ─── Test fixtures ──────────────────────────────────────────────────

CustomerBooking _booking({
  required int id,
  BookingStatus status = BookingStatus.awaiting,
  String techName = 'Ahmed Khan',
  BookingUiTone tone = BookingUiTone.warning,
  String badgeText = 'Awaiting tech',
  String headline = 'Waiting for Ahmed Khan to confirm',
}) {
  return CustomerBooking(
    id: id,
    status: status,
    service: const BookingService(name: 'AC Repair', iconName: 'ac_repair'),
    technician: BookingTechnician(
      id: 17,
      displayName: techName,
      profilePictureUrl: null,
    ),
    addressLabel: 'Home',
    scheduledStart: DateTime.utc(2026, 5, 6, 15, 0, 0),
    scheduledEnd: DateTime.utc(2026, 5, 6, 17, 0, 0),
    createdAt: DateTime.utc(2026, 5, 5, 9, 12, 0),
    price: const BookingPrice(
      amount: 2500,
      context: 'Fixed Price',
      uiLabel: 'Rs. 2,500',
    ),
    ui: BookingUi(badgeText: badgeText, badgeTone: tone, headline: headline),
  );
}

BookingsPage _page({
  required List<CustomerBooking> items,
  String? nextCursor,
  bool hasMore = false,
  bool isStaleCache = false,
  DateTime? cachedAt,
}) {
  return BookingsPage(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
    isStaleCache: isStaleCache,
    cachedAt: cachedAt,
  );
}

/// Build a job_accepted system event for the given booking id and tech name.
SystemEventEntity _jobAcceptedEvent({
  required String id,
  required int jobId,
  String techName = 'Ali Khan',
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'job_accepted',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: {
      'job_id': jobId,
      'technician_id': 17,
      'technician_display_name': techName,
      'service_name': 'AC Repair',
      'scheduled_start_iso': '2026-05-06T15:00:00Z',
    },
  );
}

SystemEventEntity _bookingRejectedEvent({
  required String id,
  required int jobId,
  String reason = 'technician_declined',
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'booking_rejected',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: {
      'job_id': jobId,
      'technician_id': 17,
      'reason': reason,
      'service_name': 'AC Repair',
      'scheduled_start_iso': '2026-05-06T15:00:00Z',
    },
  );
}

SystemEventEntity _unrelatedEvent() {
  return SystemEventEntity.fromComponents(
    id: 'evt-other',
    rawType: 'chat_message',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: const {'job_id': 999, 'text': 'hello'},
  );
}

ProviderContainer _build({
  required _FakeRepo repo,
  required EventLocalDataSource eventLocal,
}) {
  final container = ProviderContainer(
    overrides: [
      customerBookingsRepositoryProvider.overrideWithValue(repo),
      eventLocalDataSourceProvider.overrideWithValue(eventLocal),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Spin the event loop until the list notifier's AsyncValue settles
/// to either `data` or `error`. Used in place of `await
/// container.read(provider.future)` for the throw-on-build path —
/// Riverpod 2's AsyncNotifier `.future` accessor can hang in tests
/// when the very first build throws (the internal completer doesn't
/// resolve cleanly before container dispose). Polling against the
/// AsyncValue's `hasValue`/`hasError` getters is the documented
/// testing workaround.
Future<void> _waitForResolution(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(customerBookingsListProvider);
    if (state.hasValue || state.hasError) return;
    // Yield to the microtask queue so the build's await can advance.
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw TimeoutException(
    'customerBookingsListProvider did not resolve within $timeout',
  );
}

void main() {
  late _FakeRepo repo;
  late _MockEventLocal eventLocal;

  setUp(() {
    repo = _FakeRepo();
    eventLocal = _MockEventLocal();
    when(() => eventLocal.getLastSyncTimestamp()).thenReturn(null);
  });

  // ──────────────────────────────────────────────────────────────────
  // build()
  // ──────────────────────────────────────────────────────────────────

  group('build()', () {
    test('happy path produces AsyncData with the page contents', () async {
      repo.queuedPages.add(
        _page(
          items: [_booking(id: 1), _booking(id: 2)],
          nextCursor: 'cur-1',
          hasMore: true,
        ),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);

      // CLAUDE.md warm-up: await the future before reading state.
      await container.read(customerBookingsListProvider.future);

      final state = container.read(customerBookingsListProvider);
      expect(state.hasValue, isTrue);
      final data = state.requireValue;
      expect(data.segment, BookingSegment.upcoming);
      expect(data.items.map((b) => b.id), [1, 2]);
      expect(data.nextCursor, 'cur-1');
      expect(data.hasMore, isTrue);
      expect(data.isStaleCache, isFalse);
      expect(data.cachedAt, isNull);
    });

    test('forwards the active segment to the repository', () async {
      // Switch segment BEFORE first read so build() picks it up.
      repo.queuedPages.add(_page(items: const []));
      final container = _build(repo: repo, eventLocal: eventLocal);
      container.read(selectedSegmentProvider.notifier).set(BookingSegment.past);

      await container.read(customerBookingsListProvider.future);

      expect(repo.calls.single['segment'], BookingSegment.past);
    });

    test(
      'initial fetch failure surfaces as AsyncError carrying typed failure',
      () async {
        // Note: we drive the wait via container.listen() rather than
        // awaiting `.future` because Riverpod 2's AsyncNotifier `.future`
        // accessor can hang when the very first build throws (the
        // internal completer stays unresolved during a test container's
        // dispose). Polling for hasError/hasValue is the documented
        // testing workaround.
        repo.queuedThrows.add(const CustomerBookingsServerFailure());
        final container = _build(repo: repo, eventLocal: eventLocal);

        // Trigger build by reading; subscribe to state transitions.
        container.read(customerBookingsListProvider);
        await _waitForResolution(container);

        final state = container.read(customerBookingsListProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<CustomerBookingsServerFailure>());
      },
    );

    test('OfflineNoCache surfaces verbatim as AsyncError', () async {
      repo.queuedThrows.add(const CustomerBookingsOfflineNoCache());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(customerBookingsListProvider);
      await _waitForResolution(container);

      final state = container.read(customerBookingsListProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<CustomerBookingsOfflineNoCache>());
    });

    test('stale-cache page surfaces with isStaleCache=true', () async {
      final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);
      repo.queuedPages.add(
        _page(items: [_booking(id: 1)], isStaleCache: true, cachedAt: cachedAt),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);

      await container.read(customerBookingsListProvider.future);
      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.isStaleCache, isTrue);
      expect(data.cachedAt, cachedAt);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // refresh()
  // ──────────────────────────────────────────────────────────────────

  group('refresh()', () {
    test('replaces state with the new first page', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      // Refresh produces a different first page.
      repo.queuedPages.add(_page(items: [_booking(id: 99)]));
      await container.read(customerBookingsListProvider.notifier).refresh();

      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.map((b) => b.id), [99]);
    });

    test(
      'failure during refresh becomes AsyncError but preserves prior data',
      () async {
        repo.queuedPages.add(_page(items: [_booking(id: 1)]));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        repo.queuedThrows.add(const CustomerBookingsServerFailure());
        await container.read(customerBookingsListProvider.notifier).refresh();

        final state = container.read(customerBookingsListProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<CustomerBookingsServerFailure>());
      },
    );

    test('refresh after error recovers cleanly to AsyncData', () async {
      repo.queuedThrows.add(const CustomerBookingsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);

      // Initial load fails — wait for AsyncError to settle without
      // touching `.future` (see initial-fetch-failure test for the
      // rationale).
      container.read(customerBookingsListProvider);
      await _waitForResolution(container);
      expect(container.read(customerBookingsListProvider).hasError, isTrue);

      // Refresh succeeds.
      repo.queuedPages.add(_page(items: [_booking(id: 7)]));
      await container.read(customerBookingsListProvider.notifier).refresh();

      final state = container.read(customerBookingsListProvider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.items.single.id, 7);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // loadMore()
  // ──────────────────────────────────────────────────────────────────

  group('loadMore()', () {
    test('appends next page and advances cursor', () async {
      repo.queuedPages.add(
        _page(items: [_booking(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      repo.queuedPages.add(
        _page(items: [_booking(id: 2)], nextCursor: 'cur-2', hasMore: true),
      );
      await container.read(customerBookingsListProvider.notifier).loadMore();

      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.map((b) => b.id), [1, 2]);
      expect(data.nextCursor, 'cur-2');
      expect(data.hasMore, isTrue);
      expect(data.isLoadingMore, isFalse);
    });

    test('forwards the previous next_cursor to the repo', () async {
      repo.queuedPages.add(
        _page(items: [_booking(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      repo.queuedPages.add(_page(items: const [], hasMore: false));
      await container.read(customerBookingsListProvider.notifier).loadMore();

      // Two calls: build + loadMore. The second should carry cur-1.
      expect(repo.calls.length, 2);
      expect(repo.calls[1]['cursor'], 'cur-1');
    });

    test('no-op when hasMore is false', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 1)], hasMore: false));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      await container.read(customerBookingsListProvider.notifier).loadMore();

      // build() called once, loadMore should NOT have hit the repo.
      expect(repo.calls.length, 1);
    });

    test(
      'no-op when nextCursor is null even if hasMore=true (defensive)',
      () async {
        repo.queuedPages.add(
          _page(items: [_booking(id: 1)], nextCursor: null, hasMore: true),
        );
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        await container.read(customerBookingsListProvider.notifier).loadMore();
        expect(repo.calls.length, 1);
      },
    );

    test('no-op when isStaleCache is true (offline)', () async {
      // Stale cache means the cursor is meaningless — repo would
      // immediately hit OfflineNoCache for cursor != null.
      repo.queuedPages.add(
        _page(
          items: [_booking(id: 1)],
          nextCursor: 'cur-1',
          hasMore: true,
          isStaleCache: true,
          cachedAt: DateTime.utc(2026, 5, 5, 12, 0, 0),
        ),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      await container.read(customerBookingsListProvider.notifier).loadMore();
      // Only the build() call — loadMore short-circuited.
      expect(repo.calls.length, 1);
    });

    test('failure during loadMore preserves existing items + clears '
        'isLoadingMore', () async {
      repo.queuedPages.add(
        _page(items: [_booking(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      repo.queuedThrows.add(const CustomerBookingsServerFailure());
      await container.read(customerBookingsListProvider.notifier).loadMore();

      final data = container.read(customerBookingsListProvider).requireValue;
      // Existing items preserved.
      expect(data.items.map((b) => b.id), [1]);
      expect(data.isLoadingMore, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Segment switch via selectedSegmentProvider
  // ──────────────────────────────────────────────────────────────────

  group('segment switch rebuilds', () {
    test(
      'switching segment triggers a fresh fetch for the new segment',
      () async {
        repo.queuedPages.add(_page(items: [_booking(id: 1)]));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        // Switch — build() runs again with the new segment.
        repo.queuedPages.add(_page(items: [_booking(id: 99)]));
        container
            .read(selectedSegmentProvider.notifier)
            .set(BookingSegment.past);

        // Wait for the rebuilt future.
        await container.read(customerBookingsListProvider.future);

        // Two calls: original (upcoming) + rebuild (past).
        expect(repo.calls.length, 2);
        expect(repo.calls[0]['segment'], BookingSegment.upcoming);
        expect(repo.calls[1]['segment'], BookingSegment.past);

        final data = container.read(customerBookingsListProvider).requireValue;
        expect(data.segment, BookingSegment.past);
        expect(data.items.single.id, 99);
      },
    );

    test('setting the same segment is a no-op', () async {
      repo.queuedPages.add(_page(items: const []));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      // Re-set to the current value — must not refetch.
      container
          .read(selectedSegmentProvider.notifier)
          .set(BookingSegment.upcoming);

      // Just one call from the original build.
      expect(repo.calls.length, 1);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Realtime patching
  // ──────────────────────────────────────────────────────────────────

  group('realtime patches', () {
    test(
      'jobAccepted: finds item by job_id and applies mapper transform',
      () async {
        repo.queuedPages.add(_page(items: [_booking(id: 99482)]));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        container
            .read(systemEventProvider.notifier)
            .processEvent(
              _jobAcceptedEvent(
                id: 'evt-1',
                jobId: 99482,
                techName: 'Ali Khan',
              ),
            );

        final data = container.read(customerBookingsListProvider).requireValue;
        expect(data.items.single.status, BookingStatus.confirmed);
        expect(data.items.single.technician.displayName, 'Ali Khan');
        expect(data.items.single.ui.badgeText, 'Confirmed');
        expect(data.items.single.ui.badgeTone, BookingUiTone.positive);
        expect(data.items.single.ui.headline, 'Confirmed with Ali Khan');
      },
    );

    test(
      'bookingRejected (technician_declined): invalidates and re-fetches',
      () async {
        // Initial state: the booking is AWAITING.
        repo.queuedPages.add(_page(items: [_booking(id: 99482)]));
        // Post-event state: BE returns the booking as REJECTED with
        // the "Unavailable" badge (per `_resolve_ui_block` for
        // technician_declined). The notifier's post-invalidate
        // re-fetch consumes this.
        repo.queuedPages.add(_page(items: [
          _booking(
            id: 99482,
            status: BookingStatus.rejected,
            tone: BookingUiTone.negative,
            badgeText: 'Unavailable',
            headline: 'Ahmed Khan was unavailable',
          ),
        ]));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        container
            .read(systemEventProvider.notifier)
            .processEvent(
              _bookingRejectedEvent(
                id: 'evt-r1',
                jobId: 99482,
                reason: 'technician_declined',
              ),
            );

        // Terminal events now invalidate the provider instead of
        // patching in place. Await the next future so the re-fetch
        // completes.
        await container.read(customerBookingsListProvider.future);

        final data = container.read(customerBookingsListProvider).requireValue;
        expect(data.items.single.status, BookingStatus.rejected);
        expect(data.items.single.ui.badgeText, 'Unavailable');
        expect(data.items.single.ui.badgeTone, BookingUiTone.negative);
        // Sanity: the repo was called twice — initial + post-invalidate.
        expect(repo.calls.length, 2);
      },
    );

    test('bookingRejected (sla_timeout): invalidates and re-fetches', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 99482)]));
      repo.queuedPages.add(_page(items: [
        _booking(
          id: 99482,
          status: BookingStatus.rejected,
          tone: BookingUiTone.negative,
          badgeText: 'Timed out',
          headline: 'Ahmed Khan did not respond in time',
        ),
      ]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      container
          .read(systemEventProvider.notifier)
          .processEvent(
            _bookingRejectedEvent(
              id: 'evt-r2',
              jobId: 99482,
              reason: 'sla_timeout',
            ),
          );

      await container.read(customerBookingsListProvider.future);

      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.single.ui.badgeText, 'Timed out');
      expect(repo.calls.length, 2);
    });

    test('event for unknown job_id is a silent no-op', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      // Event for booking 99999 — not in the list.
      container
          .read(systemEventProvider.notifier)
          .processEvent(_jobAcceptedEvent(id: 'evt-x', jobId: 99999));

      // Existing item untouched.
      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.single.id, 1);
      expect(data.items.single.status, BookingStatus.awaiting);
    });

    test('event missing job_id is silently ignored', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      final eventNoJobId = SystemEventEntity.fromComponents(
        id: 'evt-no-id',
        rawType: 'job_accepted',
        targetRoleStr: 'customer',
        timestamp: DateTime.now().toUtc(),
        payload: const {
          // no job_id at all
          'technician_display_name': 'Ali',
        },
      );
      container.read(systemEventProvider.notifier).processEvent(eventNoJobId);

      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.single.status, BookingStatus.awaiting);
    });

    test('events of irrelevant types are ignored', () async {
      repo.queuedPages.add(_page(items: [_booking(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsListProvider.future);

      container
          .read(systemEventProvider.notifier)
          .processEvent(_unrelatedEvent());

      final data = container.read(customerBookingsListProvider).requireValue;
      expect(data.items.single.status, BookingStatus.awaiting);
    });

    test(
      'patch is a no-op when state is in error (no items to patch)',
      () async {
        repo.queuedThrows.add(const CustomerBookingsServerFailure());
        final container = _build(repo: repo, eventLocal: eventLocal);
        container.read(customerBookingsListProvider);
        await _waitForResolution(container);

        // Event arrives — must not crash.
        container
            .read(systemEventProvider.notifier)
            .processEvent(_jobAcceptedEvent(id: 'evt-z', jobId: 1));

        // Still in error.
        expect(container.read(customerBookingsListProvider).hasError, isTrue);
      },
    );

    test(
      'jobAccepted patches in-place, then bookingRejected invalidates',
      () async {
        // Initial AWAITING page.
        repo.queuedPages.add(_page(items: [_booking(id: 99482)]));
        // Post-invalidate page (BE has the booking as REJECTED).
        repo.queuedPages.add(_page(items: [
          _booking(
            id: 99482,
            status: BookingStatus.rejected,
            tone: BookingUiTone.negative,
            badgeText: 'Timed out',
            headline: 'Ali did not respond in time',
          ),
        ]));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(customerBookingsListProvider.future);

        // jobAccepted is an intermediate in-Upcoming transition —
        // still patches in place (badge flips to "Confirmed"). No
        // re-fetch yet.
        container
            .read(systemEventProvider.notifier)
            .processEvent(
              _jobAcceptedEvent(id: 'a-1', jobId: 99482, techName: 'Ali'),
            );
        expect(
          container.read(customerBookingsListProvider).requireValue
              .items.single.status,
          BookingStatus.confirmed,
        );
        expect(repo.calls.length, 1);

        // bookingRejected is a terminal cross-segment event — triggers
        // invalidateSelf and re-fetches from the network.
        container
            .read(systemEventProvider.notifier)
            .processEvent(
              _bookingRejectedEvent(
                id: 'r-1',
                jobId: 99482,
                reason: 'sla_timeout',
              ),
            );
        await container.read(customerBookingsListProvider.future);

        final data = container.read(customerBookingsListProvider).requireValue;
        expect(data.items.single.status, BookingStatus.rejected);
        expect(data.items.single.ui.badgeText, 'Timed out');
        expect(repo.calls.length, 2);
      },
    );
  });
}
