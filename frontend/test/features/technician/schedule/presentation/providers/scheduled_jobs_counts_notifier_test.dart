// Tests for ScheduledJobsCountsNotifier — feeds the segmented-control
// badge numbers.
//
// Covers:
//   * build() fetches counts and surfaces as AsyncData.
//   * Initial fetch failure surfaces as AsyncError.
//   * Manual refresh() re-fetches and replaces state.
//   * jobAccepted event triggers a refresh.
//   * jobCompleted event triggers a refresh.
//   * Mid-job transitions (techEnRoute etc.) do NOT trigger a count
//     refresh — count is unchanged when a row stays in Upcoming.
//   * chat_message does not trigger a refresh.
//   * Same-id event repeat does not trigger a second refresh.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job_segment.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_jobs_counts.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_jobs_page.dart';
import 'package:frontend/features/technician/schedule/domain/failures/scheduled_jobs_failure.dart';
import 'package:frontend/features/technician/schedule/domain/repositories/scheduled_jobs_repository.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/scheduled_jobs_counts_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocal extends Mock implements EventLocalDataSource {}

class _FakeRepo implements IScheduledJobsRepository {
  final List<ScheduledJobsCounts> queuedCounts = [];
  final List<Object> queuedThrows = [];
  int countsCallCount = 0;

  @override
  Future<ScheduledJobsCounts> getCounts() async {
    countsCallCount++;
    if (queuedThrows.isNotEmpty) {
      throw queuedThrows.removeAt(0);
    }
    return queuedCounts.removeAt(0);
  }

  @override
  Future<ScheduledJobsPage> getScheduledJobs({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    throw UnimplementedError();
  }
}

ScheduledJobsCounts _counts({int upcoming = 1, int past = 12}) {
  return ScheduledJobsCounts(
    upcoming: upcoming,
    past: past,
    serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
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

SystemEventEntity _chatEvent() {
  return SystemEventEntity.fromComponents(
    id: 'evt-chat',
    rawType: 'chat_message',
    targetRoleStr: 'technician',
    timestamp: DateTime.now().toUtc(),
    payload: const {'job_id': 1, 'text': 'hi'},
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

Future<void> _waitForResolution(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(scheduledJobsCountsProvider);
    if (state.hasValue || state.hasError) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw TimeoutException(
    'scheduledJobsCountsProvider did not resolve within $timeout',
  );
}

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

  group('build()', () {
    test('happy path produces AsyncData carrying counts', () async {
      repo.queuedCounts.add(_counts(upcoming: 7, past: 13));
      final container = _build(repo: repo, eventLocal: eventLocal);

      final counts = await container.read(
        scheduledJobsCountsProvider.future,
      );

      expect(counts.upcoming, 7);
      expect(counts.past, 13);
      expect(repo.countsCallCount, 1);
    });

    test('initial fetch failure surfaces as AsyncError', () async {
      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(scheduledJobsCountsProvider);
      await _waitForResolution(container);

      final state = container.read(scheduledJobsCountsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ScheduledJobsServerFailure>());
    });

    test('OfflineNoCache surfaces verbatim', () async {
      repo.queuedThrows.add(const ScheduledJobsOfflineNoCache());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(scheduledJobsCountsProvider);
      await _waitForResolution(container);

      expect(
        container.read(scheduledJobsCountsProvider).error,
        isA<ScheduledJobsOfflineNoCache>(),
      );
    });
  });

  group('refresh()', () {
    test('replaces state with the new counts', () async {
      repo.queuedCounts.add(_counts(upcoming: 1, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsCountsProvider.future);

      repo.queuedCounts.add(_counts(upcoming: 2, past: 5));
      await container.read(scheduledJobsCountsProvider.notifier).refresh();

      final counts =
          container.read(scheduledJobsCountsProvider).requireValue;
      expect(counts.upcoming, 2);
      expect(counts.past, 5);
      expect(repo.countsCallCount, 2);
    });

    test('subsequent refresh after error recovers cleanly', () async {
      repo.queuedThrows.add(const ScheduledJobsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);
      container.read(scheduledJobsCountsProvider);
      await _waitForResolution(container);
      expect(container.read(scheduledJobsCountsProvider).hasError, isTrue);

      repo.queuedCounts.add(_counts(upcoming: 9, past: 0));
      await container.read(scheduledJobsCountsProvider.notifier).refresh();

      expect(
        container.read(scheduledJobsCountsProvider).requireValue.upcoming,
        9,
      );
    });
  });

  group('realtime triggers', () {
    test('jobAccepted triggers a refresh', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsCountsProvider.future);
      expect(repo.countsCallCount, 1);

      repo.queuedCounts.add(_counts(upcoming: 6, past: 0));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'e1', rawType: 'job_accepted'));
      await _settle();

      expect(repo.countsCallCount, 2);
      expect(
        container.read(scheduledJobsCountsProvider).requireValue.upcoming,
        6,
      );
    });

    test('jobCompleted triggers a refresh', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsCountsProvider.future);

      repo.queuedCounts.add(_counts(upcoming: 4, past: 1));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'e2', rawType: 'job_completed'));
      await _settle();

      expect(repo.countsCallCount, 2);
    });

    test(
      'mid-job transition (tech_en_route) does NOT trigger a refresh — '
      'row stays in Upcoming so count is unchanged',
      () async {
        repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
        final container = _build(repo: repo, eventLocal: eventLocal);
        await container.read(scheduledJobsCountsProvider.future);
        expect(repo.countsCallCount, 1);

        container
            .read(systemEventProvider.notifier)
            .processEvent(_event(id: 'e-mid', rawType: 'tech_en_route'));
        await _settle();

        // No additional fetch — counts notifier intentionally ignores
        // mid-job transitions (segment doesn't change). List notifier
        // still refreshes for the badge update.
        expect(repo.countsCallCount, 1);
      },
    );

    test('chat_message does NOT trigger a refresh', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsCountsProvider.future);

      container.read(systemEventProvider.notifier).processEvent(_chatEvent());
      await _settle();

      expect(repo.countsCallCount, 1);
    });

    test('same-id event repeat does not trigger a second refresh', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(scheduledJobsCountsProvider.future);

      repo.queuedCounts.add(_counts(upcoming: 4, past: 1));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'evt-once', rawType: 'job_accepted'));
      container
          .read(systemEventProvider.notifier)
          .processEvent(_event(id: 'evt-once', rawType: 'job_accepted'));

      await _settle();

      expect(repo.countsCallCount, 2); // build + 1 refresh
    });
  });
}
