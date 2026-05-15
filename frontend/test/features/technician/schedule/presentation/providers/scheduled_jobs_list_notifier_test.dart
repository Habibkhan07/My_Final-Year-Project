// Tests for ScheduledJobsList notifier — state-layer per CLAUDE.md
// (ProviderContainer, no widget mounting).
//
// Covers:
//   * build() awaits the use case and produces AsyncData.
//   * Initial fetch failure surfaces as AsyncError carrying the typed
//     ScheduledJobsFailure verbatim.
//   * refresh() re-fetches and replaces state.
//   * Refresh failure surfaces as AsyncError.
//   * Refresh after error recovers cleanly to AsyncData.
//   * loadMore() appends + advances cursor + drives isLoadingMore.
//   * loadMore() guards: !hasMore, isLoadingMore, no cursor, isStaleCache.
//   * loadMore() failure preserves prior items.
//   * Segment switch triggers a rebuild with a fresh first-page fetch.
//   * Realtime event types in the listener trigger refresh.
//   * Same-id events are deduped.
//   * Irrelevant event types do not trigger refresh.
//   * Stale-cache page surfaces with isStaleCache=true and gates loadMore.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job_segment.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_jobs_counts.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_jobs_page.dart';
import 'package:frontend/features/technician/schedule/domain/failures/scheduled_jobs_failure.dart';
import 'package:frontend/features/technician/schedule/domain/repositories/scheduled_jobs_repository.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/scheduled_jobs_list_notifier.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/selected_schedule_segment_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocal extends Mock implements EventLocalDataSource {}

class _FakeRepo implements IScheduledJobsRepository {
  final List<ScheduledJobsPage> queuedPages = [];
  final List<Object> queuedThrows = [];
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<ScheduledJobsPage> getScheduledJobs({
    required ScheduledJobSegment segment,
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
  Future<ScheduledJobsCounts> getCounts() async {
    // Counts notifier is exercised in its own test.
    return ScheduledJobsCounts(
      upcoming: 0,
      past: 0,
      serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
    );
  }
}

// ─── Fixtures ────────────────────────────────────────────────────────

ScheduledJob _job({
  required int id,
  BookingStatus status = BookingStatus.confirmed,
  BookingUiTone tone = BookingUiTone.positive,
  String badgeText = 'Confirmed',
  String headline = 'Booked with Sara Ahmed',
}) {
  return ScheduledJob(
    id: id,
    status: status,
    service: const ScheduledJobService(
      name: 'AC Repair',
      iconName: 'ac_repair',
    ),
    customer: const ScheduledJobCustomer(
      id: 109,
      displayName: 'Sara Ahmed',
      profilePictureUrl: null,
    ),
    addressLabel: 'Home — DHA Phase 5, Lahore',
    scheduledStart: DateTime.utc(2026, 5, 6, 15, 0, 0),
    scheduledEnd: DateTime.utc(2026, 5, 6, 17, 0, 0),
    createdAt: DateTime.utc(2026, 5, 5, 9, 12, 0),
    payout: const PayoutBlock(
      amount: 1620,
      context: 'After Rs. 405 commission',
      uiLabel: 'Rs. 1,620',
    ),
    ui: ScheduledJobUi(
      badgeText: badgeText,
      badgeTone: tone,
      headline: headline,
    ),
  );
}

ScheduledJobsPage _page({
  required List<ScheduledJob> items,
  String? nextCursor,
  bool hasMore = false,
  bool isStaleCache = false,
  DateTime? cachedAt,
}) {
  return ScheduledJobsPage(
    items: items,
    nextCursor: nextCursor,
    hasMore: hasMore,
    serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
    isStaleCache: isStaleCache,
    cachedAt: cachedAt,
  );
}

SystemEventEntity _event({
  required String id,
  required String rawType,
  int jobId = 42,
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: rawType,
    targetRoleStr: 'technician',
    timestamp: DateTime.now().toUtc(),
    payload: {
      'job_id': jobId,
      'service_name': 'AC Repair',
      'scheduled_start_iso': '2026-05-06T15:00:00Z',
    },
  );
}

SystemEventEntity _chatEvent({String id = 'evt-chat'}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'chat_message',
    targetRoleStr: 'technician',
    timestamp: DateTime.now().toUtc(),
    payload: const {'job_id': 42, 'text': 'hi'},
  );
}

ProviderContainer _build({
  required _FakeRepo repo,
  required EventLocalDataSource eventLocal,
}) {
  final container = ProviderContainer(
    overrides: [
      scheduledJobsRepositoryProvider.overrideWithValue(repo),
      eventLocalDataSourceProvider.overrideWithValue(eventLocal),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Poll the AsyncValue until it settles. Riverpod 2's `.future` accessor
/// can hang on a thrown initial build; polling is the documented workaround.
Future<void> _waitForResolution(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(scheduledJobsListProvider);
    if (state.hasValue || state.hasError) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw TimeoutException(
    'scheduledJobsListProvider did not resolve within $timeout',
  );
}

/// Settle the event loop for fire-and-forget refresh() flows.
Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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
          items: [_job(id: 1), _job(id: 2)],
          nextCursor: 'cur-1',
          hasMore: true,
        ),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);

      await container.read(scheduledJobsListProvider.future);

      final state = container.read(scheduledJobsListProvider);
      expect(state.hasValue, isTrue);
      final data = state.requireValue;
      expect(data.segment, ScheduledJobSegment.upcoming);
      expect(data.items.map((j) => j.id), [1, 2]);
      expect(data.nextCursor, 'cur-1');
      expect(data.hasMore, isTrue);
      expect(data.isStaleCache, isFalse);
      expect(data.cachedAt, isNull);
    });

    test('forwards the active segment to the repo', () async {
      repo.queuedPages.add(_page(items: const []));
      final container = _build(repo: repo, eventLocal: eventLocal);
      container
          .read(selectedScheduleSegmentProvider.notifier)
          .set(ScheduledJobSegment.past);

      await container.read(scheduledJobsListProvider.future);

      expect(repo.calls.single['segment'], ScheduledJobSegment.past);
    });

    test('initial fetch failure surfaces as typed AsyncError', () async {
      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(scheduledJobsListProvider);
      await _waitForResolution(container);

      final state = container.read(scheduledJobsListProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ScheduledJobsServerFailure>());
    });

    test('OfflineNoCache surfaces verbatim as AsyncError', () async {
      repo.queuedThrows.add(const ScheduledJobsOfflineNoCache());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(scheduledJobsListProvider);
      await _waitForResolution(container);

      expect(
        container.read(scheduledJobsListProvider).error,
        isA<ScheduledJobsOfflineNoCache>(),
      );
    });

    test('stale-cache page surfaces with isStaleCache=true', () async {
      final cachedAt = DateTime.utc(2026, 5, 5, 12, 0, 0);
      repo.queuedPages.add(
        _page(items: [_job(id: 1)], isStaleCache: true, cachedAt: cachedAt),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);

      await container.read(scheduledJobsListProvider.future);
      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.isStaleCache, isTrue);
      expect(data.cachedAt, cachedAt);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // refresh()
  // ──────────────────────────────────────────────────────────────────

  group('refresh()', () {
    test('replaces state with the new first page', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(_page(items: [_job(id: 99)]));
      await container.read(scheduledJobsListProvider.notifier).refresh();

      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.map((j) => j.id), [99]);
    });

    test('failure during refresh becomes AsyncError', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      await container.read(scheduledJobsListProvider.notifier).refresh();

      final state = container.read(scheduledJobsListProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ScheduledJobsServerFailure>());
    });

    test('refresh after error recovers cleanly to AsyncData', () async {
      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(scheduledJobsListProvider);
      await _waitForResolution(container);
      expect(container.read(scheduledJobsListProvider).hasError, isTrue);

      repo.queuedPages.add(_page(items: [_job(id: 7)]));
      await container.read(scheduledJobsListProvider.notifier).refresh();

      final state = container.read(scheduledJobsListProvider);
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
        _page(items: [_job(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(
        _page(items: [_job(id: 2)], nextCursor: 'cur-2', hasMore: true),
      );
      await container.read(scheduledJobsListProvider.notifier).loadMore();

      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.map((j) => j.id), [1, 2]);
      expect(data.nextCursor, 'cur-2');
      expect(data.hasMore, isTrue);
      expect(data.isLoadingMore, isFalse);
    });

    test('forwards the previous next_cursor to the repo', () async {
      repo.queuedPages.add(
        _page(items: [_job(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(_page(items: const [], hasMore: false));
      await container.read(scheduledJobsListProvider.notifier).loadMore();

      expect(repo.calls.length, 2);
      expect(repo.calls[1]['cursor'], 'cur-1');
    });

    test('no-op when hasMore is false', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)], hasMore: false));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      await container.read(scheduledJobsListProvider.notifier).loadMore();
      expect(repo.calls.length, 1);
    });

    test('no-op when nextCursor is null even if hasMore=true', () async {
      repo.queuedPages.add(
        _page(items: [_job(id: 1)], nextCursor: null, hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      await container.read(scheduledJobsListProvider.notifier).loadMore();
      expect(repo.calls.length, 1);
    });

    test('no-op when isStaleCache is true (offline)', () async {
      // Cursor is meaningless offline; repo would throw OfflineNoCache
      // for cursor != null. Notifier short-circuits before calling.
      repo.queuedPages.add(
        _page(
          items: [_job(id: 1)],
          nextCursor: 'cur-1',
          hasMore: true,
          isStaleCache: true,
          cachedAt: DateTime.utc(2026, 5, 5, 12, 0, 0),
        ),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      await container.read(scheduledJobsListProvider.notifier).loadMore();
      expect(repo.calls.length, 1);
    });

    test('loadMore failure preserves prior items', () async {
      repo.queuedPages.add(
        _page(items: [_job(id: 1)], nextCursor: 'cur-1', hasMore: true),
      );
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      await container.read(scheduledJobsListProvider.notifier).loadMore();

      // List still has page 1; pagination error doesn't blow it away.
      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.map((j) => j.id), [1]);
      expect(data.isLoadingMore, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Segment switch
  // ──────────────────────────────────────────────────────────────────

  group('segment switch', () {
    test('changing segment triggers a fresh first-page fetch', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)])); // upcoming
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(_page(items: [_job(id: 99)])); // past
      container
          .read(selectedScheduleSegmentProvider.notifier)
          .set(ScheduledJobSegment.past);
      await container.read(scheduledJobsListProvider.future);

      // Two calls, second carries past segment.
      expect(repo.calls.length, 2);
      expect(repo.calls[1]['segment'], ScheduledJobSegment.past);
      expect(repo.calls[1]['cursor'], isNull); // fresh first page
      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.single.id, 99);
      expect(data.segment, ScheduledJobSegment.past);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Realtime invalidation
  // ──────────────────────────────────────────────────────────────────

  group('realtime', () {
    test('jobAccepted triggers a refresh fetch', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);
      expect(repo.calls.length, 1);

      repo.queuedPages.add(_page(items: [_job(id: 1), _job(id: 2)]));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'e1', rawType: 'job_accepted'));
      await _settle();

      expect(repo.calls.length, 2);
      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.map((j) => j.id), [1, 2]);
    });

    test('techEnRoute triggers a refresh fetch (mid-job transition)', () async {
      // Customer-side notifier patches inline; tech-side refreshes.
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(
        _page(items: [_job(id: 1, status: BookingStatus.enRoute)]),
      );
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'e2', rawType: 'tech_en_route'));
      await _settle();

      expect(repo.calls.length, 2);
      final data = container.read(scheduledJobsListProvider).requireValue;
      expect(data.items.single.status, BookingStatus.enRoute);
    });

    test('jobCompleted triggers a refresh fetch', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(_page(items: const []));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'e3', rawType: 'job_completed'));
      await _settle();

      expect(repo.calls.length, 2);
    });

    test('chat_message does NOT trigger a refresh', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);
      expect(repo.calls.length, 1);

      container
          .read(systemEventProvider.notifier)
          .processEvent(_chatEvent());
      await _settle();

      expect(repo.calls.length, 1);
    });

    test('same-id event repeat does not trigger a second refresh', () async {
      repo.queuedPages.add(_page(items: [_job(id: 1)]));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsListProvider.future);

      repo.queuedPages.add(_page(items: [_job(id: 1), _job(id: 2)]));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'evt-once', rawType: 'job_accepted'));
      // Replay same id — upstream dedup, listener guard. Only one refresh.
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'evt-once', rawType: 'job_accepted'));
      await _settle();

      expect(repo.calls.length, 2); // build + 1 refresh
    });
  });
}
