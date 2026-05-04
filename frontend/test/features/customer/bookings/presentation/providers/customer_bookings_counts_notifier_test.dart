// Tests for CustomerBookingsCounts notifier.
//
// Covers:
//   * build() fetches counts and surfaces as AsyncData.
//   * Initial fetch failure surfaces as AsyncError.
//   * Manual refresh() re-fetches and replaces state.
//   * jobAccepted event triggers a refresh fetch.
//   * bookingRejected event triggers a refresh fetch.
//   * Same-id event repeat (envelope dedup upstream) does not trigger
//     a refresh.
//   * Irrelevant event types do not trigger a refresh.
//   * Refresh failure surfaces as AsyncError but state stays usable
//     for next refresh attempt.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_counts.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_page.dart';
import 'package:frontend/features/customer/bookings/domain/failures/customer_bookings_failure.dart';
import 'package:frontend/features/customer/bookings/domain/repositories/customer_bookings_repository.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_counts_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocal extends Mock implements EventLocalDataSource {}

/// Programmable repo that scripts counts responses one at a time.
class _FakeRepo implements ICustomerBookingsRepository {
  final List<BookingsCounts> queuedCounts = [];
  final List<Object> queuedThrows = [];
  int countsCallCount = 0;

  @override
  Future<BookingsCounts> getCounts() async {
    countsCallCount++;
    if (queuedThrows.isNotEmpty) {
      throw queuedThrows.removeAt(0);
    }
    return queuedCounts.removeAt(0);
  }

  @override
  Future<BookingsPage> getBookings({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) async {
    // Not used in this test file — the list provider isn't read here.
    throw UnimplementedError();
  }
}

BookingsCounts _counts({int upcoming = 1, int past = 12}) {
  return BookingsCounts(
    upcoming: upcoming,
    past: past,
    serverTime: DateTime.utc(2026, 5, 5, 12, 0, 0),
  );
}

SystemEventEntity _jobAcceptedEvent({
  required String id,
  int jobId = 99482,
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'job_accepted',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: {
      'job_id': jobId,
      'technician_id': 17,
      'technician_display_name': 'Ali Khan',
      'service_name': 'AC Repair',
      'scheduled_start_iso': '2026-05-06T15:00:00Z',
    },
  );
}

SystemEventEntity _bookingRejectedEvent({
  required String id,
  int jobId = 99482,
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'booking_rejected',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: {
      'job_id': jobId,
      'technician_id': 17,
      'reason': 'technician_declined',
      'service_name': 'AC Repair',
      'scheduled_start_iso': '2026-05-06T15:00:00Z',
    },
  );
}

SystemEventEntity _chatMessageEvent({String id = 'evt-chat'}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'chat_message',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: const {'job_id': 1, 'text': 'hi'},
  );
}

ProviderContainer _build({
  required _FakeRepo repo,
  required EventLocalDataSource eventLocal,
}) {
  final container = ProviderContainer(overrides: [
    customerBookingsRepositoryProvider.overrideWithValue(repo),
    eventLocalDataSourceProvider.overrideWithValue(eventLocal),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// See list-notifier test for rationale — Riverpod 2's `.future` can
/// hang on a thrown build; poll on hasValue/hasError instead.
Future<void> _waitForCountsResolution(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final state = container.read(customerBookingsCountsProvider);
    if (state.hasValue || state.hasError) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw TimeoutException(
    'customerBookingsCountsProvider did not resolve within $timeout',
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

  group('build()', () {
    test('happy path produces AsyncData carrying counts', () async {
      repo.queuedCounts.add(_counts(upcoming: 7, past: 13));
      final container = _build(repo: repo, eventLocal: eventLocal);

      final counts =
          await container.read(customerBookingsCountsProvider.future);

      expect(counts.upcoming, 7);
      expect(counts.past, 13);
      expect(repo.countsCallCount, 1);
    });

    test('initial fetch failure surfaces as AsyncError', () async {
      repo.queuedThrows.add(const CustomerBookingsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(customerBookingsCountsProvider);
      await _waitForCountsResolution(container);

      final state = container.read(customerBookingsCountsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<CustomerBookingsServerFailure>());
    });

    test('OfflineNoCache surfaces verbatim', () async {
      repo.queuedThrows.add(const CustomerBookingsOfflineNoCache());
      final container = _build(repo: repo, eventLocal: eventLocal);

      container.read(customerBookingsCountsProvider);
      await _waitForCountsResolution(container);

      expect(
        container.read(customerBookingsCountsProvider).error,
        isA<CustomerBookingsOfflineNoCache>(),
      );
    });
  });

  group('refresh()', () {
    test('replaces state with the new counts', () async {
      repo.queuedCounts.add(_counts(upcoming: 1, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);

      repo.queuedCounts.add(_counts(upcoming: 2, past: 5));
      await container
          .read(customerBookingsCountsProvider.notifier)
          .refresh();

      final counts =
          container.read(customerBookingsCountsProvider).requireValue;
      expect(counts.upcoming, 2);
      expect(counts.past, 5);
      expect(repo.countsCallCount, 2);
    });

    test('refresh failure surfaces as AsyncError', () async {
      repo.queuedCounts.add(_counts());
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);

      repo.queuedThrows.add(const CustomerBookingsServerFailure());
      await container
          .read(customerBookingsCountsProvider.notifier)
          .refresh();

      final state = container.read(customerBookingsCountsProvider);
      expect(state.hasError, isTrue);
    });

    test('subsequent refresh after error recovers cleanly', () async {
      repo.queuedThrows.add(const CustomerBookingsServerFailure());
      final container = _build(repo: repo, eventLocal: eventLocal);
      container.read(customerBookingsCountsProvider);
      await _waitForCountsResolution(container);
      expect(
        container.read(customerBookingsCountsProvider).hasError,
        isTrue,
      );

      repo.queuedCounts.add(_counts(upcoming: 9, past: 0));
      await container
          .read(customerBookingsCountsProvider.notifier)
          .refresh();

      expect(
        container.read(customerBookingsCountsProvider).requireValue.upcoming,
        9,
      );
    });
  });

  group('realtime triggers', () {
    test('jobAccepted event triggers a refresh fetch', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);
      expect(repo.countsCallCount, 1);

      // Subsequent refresh request triggered by the listener.
      repo.queuedCounts.add(_counts(upcoming: 4, past: 1));
      container.read(systemEventProvider.notifier).processEvent(
            _jobAcceptedEvent(id: 'evt-1'),
          );

      // Refresh is fire-and-forget; let the microtask + future settle.
      await _settle();

      expect(repo.countsCallCount, 2);
      final counts =
          container.read(customerBookingsCountsProvider).requireValue;
      expect(counts.upcoming, 4);
      expect(counts.past, 1);
    });

    test('bookingRejected event triggers a refresh fetch', () async {
      repo.queuedCounts.add(_counts(upcoming: 3, past: 7));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);

      repo.queuedCounts.add(_counts(upcoming: 2, past: 8));
      container.read(systemEventProvider.notifier).processEvent(
            _bookingRejectedEvent(id: 'evt-r1'),
          );
      await _settle();

      expect(repo.countsCallCount, 2);
      final counts =
          container.read(customerBookingsCountsProvider).requireValue;
      expect(counts.upcoming, 2);
      expect(counts.past, 8);
    });

    test('chat_message event does NOT trigger a refresh', () async {
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);
      expect(repo.countsCallCount, 1);

      container.read(systemEventProvider.notifier).processEvent(
            _chatMessageEvent(),
          );
      await _settle();

      // No additional fetch — count is unchanged.
      expect(repo.countsCallCount, 1);
    });

    test('same-id event repeat does not trigger a second refresh',
        () async {
      // SystemEventNotifier dedupes by id; the listener's
      // `previous?.latestEvent?.id == next.latestEvent?.id` guard
      // covers the housekeeping-rebuild case. Confirm only ONE refresh
      // is issued for repeated processEvent calls with the same id.
      repo.queuedCounts.add(_counts(upcoming: 5, past: 0));
      final container = _build(repo: repo, eventLocal: eventLocal);
      await container.read(customerBookingsCountsProvider.future);

      // Queue counts for the (hopefully single) refresh that fires.
      repo.queuedCounts.add(_counts(upcoming: 4, past: 1));

      container.read(systemEventProvider.notifier).processEvent(
            _jobAcceptedEvent(id: 'evt-once'),
          );
      // Try again with the same id — the upstream notifier dedupes,
      // so the listener's `latestEvent` doesn't change.
      container.read(systemEventProvider.notifier).processEvent(
            _jobAcceptedEvent(id: 'evt-once'),
          );

      await _settle();

      expect(repo.countsCallCount, 2); // build + 1 refresh
    });
  });
}

/// Settle the event loop so fire-and-forget refresh() calls and their
/// resulting state mutations propagate before the test asserts.
Future<void> _settle() async {
  // Two microtask hops cover the typical chain: listener → refresh()
  // schedules AsyncValue.guard → guard awaits use case → state =
  // AsyncData. Erring on the side of stability.
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
