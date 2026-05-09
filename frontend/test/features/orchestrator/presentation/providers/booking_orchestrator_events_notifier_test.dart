// Tests for `BookingOrchestratorEventsNotifier`.
//
// The notifier is the screen's realtime refresh engine. The contract:
//   * 12 specific event types invalidate `bookingDetailProvider(jobId)`.
//   * `bookingRescheduled` is INTENTIONALLY NOT in that set — it is
//     handled by the rescheduled notifier (the side effect is nav, not
//     refresh) (#B-29).
//   * Events for other booking ids are dropped.
//   * Already-seen event ids are deduped.
//
// Mocking strategy: we override `bookingDetailRepositoryProvider` with
// a counting fake repo. Each `ref.invalidate(bookingDetailProvider(...))`
// causes a fresh build → fresh `getBookingDetail` call → counter ++.
// Driving events through a stub `systemEventProvider` shows whether the
// notifier filtered them correctly.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/event_urgency.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_type.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/domain/repositories/booking_detail_repository.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_detail_provider.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_orchestrator_events_notifier.dart';
import 'package:frontend/features/orchestrator/presentation/providers/dependency_injection.dart';

import '../../_helpers/booking_detail_fixture.dart';

class _CountingRepo implements IBookingDetailRepository {
  int callCount = 0;

  @override
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    callCount++;
    return BookingDetailMapper.toDomain(
      BookingDetailModel.fromJson(bookingDetailJson(id: bookingId)),
      currentUserId: 7,
    );
  }
}

class _FakeSystemEventNotifier extends SystemEventNotifier {
  @override
  SystemEventState build() => const SystemEventState();

  /// Test seam: push an event through the listener pipeline by setting
  /// `latestEvent` to the new entity. Bypasses the production
  /// dedup/expiry filters so tests can drive arbitrary events.
  void push(SystemEventEntity event) {
    state = state.copyWith(latestEvent: event);
  }

  @override
  void reset() {
    // No-op: keep the fake's state alone during teardown.
  }
}

SystemEventEntity event({
  required String id,
  required SystemEventType type,
  Map<String, dynamic>? payload,
}) =>
    SystemEventEntity(
      id: id,
      rawType: type.name,
      eventType: type,
      targetRole: TargetRole.customer,
      timestamp: DateTime.utc(2026, 5, 9, 10, 0, 0),
      payload: payload ?? {'job_id': 42},
      urgency: EventUrgency.lowUrgency,
      isCritical: false,
    );

ProviderContainer _container({required _CountingRepo repo}) {
  return ProviderContainer(overrides: [
    bookingDetailRepositoryProvider.overrideWithValue(repo),
    systemEventProvider.overrideWith(_FakeSystemEventNotifier.new),
  ]);
}

void main() {
  test(
    'each of the 12 trigger event types invalidates bookingDetailProvider',
    () async {
      final triggers = <SystemEventType>[
        SystemEventType.techEnRoute,
        SystemEventType.techArrived,
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
      ];

      for (final t in triggers) {
        final repo = _CountingRepo();
        final c = _container(repo: repo);
        addTearDown(c.dispose);

        // Subscribe the events notifier (keepAlive: false → ref.read
        // alone wouldn't keep it alive long enough; use listen).
        c.listen(bookingOrchestratorEventsProvider(42), (_, _) {});
        // Initial load (count=1).
        await c.read(bookingDetailProvider(42).future);
        expect(repo.callCount, 1, reason: 'initial load failed for $t');

        // Push a matching trigger event.
        final notifier = c.read(systemEventProvider.notifier)
            as _FakeSystemEventNotifier;
        notifier.push(event(id: 'evt-${t.name}', type: t));
        // Allow the listener microtask + invalidate rebuild to land.
        await c.read(bookingDetailProvider(42).future);

        expect(
          repo.callCount,
          2,
          reason: '$t did NOT trigger refresh',
        );
      }
    },
  );

  test(
    'bookingRescheduled is INTENTIONALLY NOT in the refresh set (#B-29)',
    () async {
      // The rescheduled notifier handles this event with a
      // pushReplacement. Refreshing the (now-CANCELLED) original
      // would race with the nav and produce a brief flicker on the
      // wrong screen.
      final repo = _CountingRepo();
      final c = _container(repo: repo);
      addTearDown(c.dispose);

      c.listen(bookingOrchestratorEventsProvider(42), (_, _) {});
      await c.read(bookingDetailProvider(42).future);
      expect(repo.callCount, 1);

      final notifier = c.read(systemEventProvider.notifier)
          as _FakeSystemEventNotifier;
      notifier.push(event(
        id: 'evt-resched',
        type: SystemEventType.bookingRescheduled,
        payload: {'job_id': 42, 'child_booking_id': 99},
      ));
      // Give the listener a tick.
      await Future<void>.delayed(Duration.zero);
      // No refresh — call count must NOT increment.
      expect(repo.callCount, 1);
    },
  );

  test('events for a different jobId are dropped', () async {
    final repo = _CountingRepo();
    final c = _container(repo: repo);
    addTearDown(c.dispose);

    c.listen(bookingOrchestratorEventsProvider(42), (_, _) {});
    await c.read(bookingDetailProvider(42).future);
    expect(repo.callCount, 1);

    final notifier = c.read(systemEventProvider.notifier)
        as _FakeSystemEventNotifier;
    notifier.push(event(
      id: 'evt-other',
      type: SystemEventType.techEnRoute,
      payload: {'job_id': 999}, // some other booking
    ));
    await Future<void>.delayed(Duration.zero);
    expect(repo.callCount, 1);
  });

  test('duplicate event ids dedup at the previous-equals-next check',
      () async {
    final repo = _CountingRepo();
    final c = _container(repo: repo);
    addTearDown(c.dispose);

    c.listen(bookingOrchestratorEventsProvider(42), (_, _) {});
    await c.read(bookingDetailProvider(42).future);
    expect(repo.callCount, 1);

    final notifier = c.read(systemEventProvider.notifier)
        as _FakeSystemEventNotifier;
    final evt = event(id: 'evt-x', type: SystemEventType.techEnRoute);

    // First push triggers refresh.
    notifier.push(evt);
    await c.read(bookingDetailProvider(42).future);
    expect(repo.callCount, 2);

    // Re-push the same id — listener's previous?.latestEvent?.id ==
    // event.id check must short-circuit.
    notifier.push(evt);
    await Future<void>.delayed(Duration.zero);
    expect(repo.callCount, 2);
  });

  test('non-trigger event types (e.g. job_new_request) do not refresh',
      () async {
    final repo = _CountingRepo();
    final c = _container(repo: repo);
    addTearDown(c.dispose);

    c.listen(bookingOrchestratorEventsProvider(42), (_, _) {});
    await c.read(bookingDetailProvider(42).future);
    expect(repo.callCount, 1);

    final notifier = c.read(systemEventProvider.notifier)
        as _FakeSystemEventNotifier;
    // jobNewRequest is the technician-side incoming-request event.
    // It is NOT in the orchestrator's refresh set.
    notifier.push(event(
      id: 'evt-newreq',
      type: SystemEventType.jobNewRequest,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(repo.callCount, 1);
  });
}
