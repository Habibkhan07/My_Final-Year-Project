// Smoke test for `BookingOrchestratorScreen`.
//
// The hot regression vector this test pins (#B-30, #B-40):
//
//   The screen's two screen-scoped notifiers
//   (`BookingOrchestratorEventsNotifier` and
//   `BookingRescheduledNotifier`) are `keepAlive: false`. The screen
//   wakes them via `ref.watch(...)` in its `build`. A regression that
//   reverted to `ref.read(...)` (or `initState` + `ref.read`) would
//   compile cleanly but fail to register a Riverpod subscription —
//   the providers would auto-dispose on the next microtask, canceling
//   their internal `ref.listen(systemEventProvider, ...)` and breaking
//   the entire realtime-refresh chain silently.
//
//   Verifying it: mount the screen, observe initial fetch (n=1), push
//   a refresh-trigger event through the fake `systemEventProvider`,
//   observe the repo was called again (n=2). If the events notifier
//   wasn't subscribed, no second call happens.
import 'package:flutter/material.dart';
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
import 'package:frontend/features/orchestrator/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart';

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

  void push(SystemEventEntity e) {
    state = state.copyWith(latestEvent: e);
  }

  @override
  void reset() {}
}

SystemEventEntity _event({required SystemEventType type, int jobId = 42}) =>
    SystemEventEntity(
      id: 'evt-${type.name}',
      rawType: type.name,
      eventType: type,
      targetRole: TargetRole.customer,
      timestamp: DateTime.utc(2026, 5, 9, 10, 0, 0),
      payload: {'job_id': jobId},
      urgency: EventUrgency.lowUrgency,
      isCritical: false,
    );

/// Sets the test surface to a realistic portrait phone size (412 × 920),
/// matching a Pixel 7 in dp. The orchestrator screen is designed for
/// portrait phones; the flutter_test default of 800 × 600 is landscape-
/// shaped and squeezes the hero header + summary card + action bar past
/// the body, so layout assertions in landscape produce false overflow
/// noise. Set on the harness, restored on tearDown.
void _useRealisticPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('mounts and renders the orchestrator chrome', (tester) async {
    _useRealisticPhoneSurface(tester);
    final repo = _CountingRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailRepositoryProvider.overrideWithValue(repo),
          systemEventProvider.overrideWith(_FakeSystemEventNotifier.new),
        ],
        child: const MaterialApp(home: BookingOrchestratorScreen(jobId: 42)),
      ),
    );
    // Settle the initial load.
    await tester.pumpAndSettle();

    // App bar and the loaded body chrome.
    expect(find.text('Booking #42'), findsOneWidget);
    expect(repo.callCount, 1, reason: 'initial fetch should fire once');
  });

  testWidgets(
    'screen ref.watch keeps event notifier alive — refresh fires (#B-30/#B-40)',
    (tester) async {
      _useRealisticPhoneSurface(tester);
      final repo = _CountingRepo();
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingDetailRepositoryProvider.overrideWithValue(repo),
            systemEventProvider.overrideWith(_FakeSystemEventNotifier.new),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: BookingOrchestratorScreen(jobId: 42),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.callCount, 1);

      // Push a refresh-trigger event. If the screen used `ref.read`
      // (the regressed pattern), the events notifier would have
      // auto-disposed and this push would do nothing.
      final fake =
          container.read(systemEventProvider.notifier)
              as _FakeSystemEventNotifier;
      fake.push(_event(type: SystemEventType.techEnRoute));
      await tester.pumpAndSettle();

      expect(
        repo.callCount,
        2,
        reason:
            'events notifier must be alive — it should have triggered a refresh',
      );
    },
  );

  testWidgets('unrelated event types do not refresh', (tester) async {
    _useRealisticPhoneSurface(tester);
    final repo = _CountingRepo();
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailRepositoryProvider.overrideWithValue(repo),
          systemEventProvider.overrideWith(_FakeSystemEventNotifier.new),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              home: BookingOrchestratorScreen(jobId: 42),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fake =
        container.read(systemEventProvider.notifier)
            as _FakeSystemEventNotifier;
    fake.push(_event(type: SystemEventType.jobNewRequest));
    await tester.pumpAndSettle();

    expect(repo.callCount, 1);
  });
}
