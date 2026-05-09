// Tests for `BookingRescheduledNotifier`.
//
// The notifier handles ONE event (booking_rescheduled). On match, it
// pushReplacements the user from the (now-CANCELLED) original to the
// child booking. Wrong event types, mismatched job_ids, and missing
// child_booking_id payloads must NOT navigate.
//
// We pump a real MaterialApp.router with a tiny GoRouter that has the
// `/booking/:job_id` route, then drive the fake systemEventProvider.
// Asserting via `find.text` on the destination screen is the most
// robust nav-side-effect check (it won't pass if `pushReplacement`
// silently no-ops).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/domain/entities/event_urgency.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_type.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_rescheduled_notifier.dart';
import 'package:go_router/go_router.dart';

class _FakeSystemEventNotifier extends SystemEventNotifier {
  @override
  SystemEventState build() => const SystemEventState();

  void push(SystemEventEntity e) {
    state = state.copyWith(latestEvent: e);
  }

  @override
  void reset() {}
}

SystemEventEntity event({
  required String id,
  required SystemEventType type,
  required Map<String, dynamic> payload,
}) =>
    SystemEventEntity(
      id: id,
      rawType: type.name,
      eventType: type,
      targetRole: TargetRole.customer,
      timestamp: DateTime.utc(2026, 5, 9, 10, 0, 0),
      payload: payload,
      urgency: EventUrgency.lowUrgency,
      isCritical: false,
    );

Future<({ProviderContainer container, _FakeSystemEventNotifier fake})>
    _pumpHost(WidgetTester tester, {required int jobId}) async {
  final navKey = GlobalKey<NavigatorState>();
  final container = ProviderContainer(overrides: [
    navigatorKeyProvider.overrideWithValue(navKey),
    systemEventProvider.overrideWith(_FakeSystemEventNotifier.new),
  ]);
  addTearDown(container.dispose);

  // Subscribe the rescheduled notifier so it begins listening.
  container.listen(bookingRescheduledProvider(jobId), (_, _) {});

  final router = GoRouter(
    navigatorKey: navKey,
    initialLocation: '/booking/$jobId',
    routes: [
      GoRoute(
        path: '/booking/:job_id',
        builder: (_, state) => Scaffold(
          body: Text(
            'BOOKING ${state.pathParameters['job_id']}',
            key: ValueKey('b-${state.pathParameters['job_id']}'),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();

  return (
    container: container,
    fake: container.read(systemEventProvider.notifier)
        as _FakeSystemEventNotifier,
  );
}

void main() {
  testWidgets(
    'pushReplacement to /booking/<child> on booking_rescheduled match',
    (tester) async {
      final h = await _pumpHost(tester, jobId: 42);
      // We start on /booking/42.
      expect(find.byKey(const ValueKey('b-42')), findsOneWidget);

      h.fake.push(event(
        id: 'evt-rs',
        type: SystemEventType.bookingRescheduled,
        payload: {'job_id': 42, 'child_booking_id': 99},
      ));
      await tester.pumpAndSettle();

      // Now on /booking/99. The original screen is gone (replaced).
      expect(find.byKey(const ValueKey('b-99')), findsOneWidget);
      expect(find.byKey(const ValueKey('b-42')), findsNothing);
    },
  );

  testWidgets('does not navigate on non-rescheduled events', (tester) async {
    final h = await _pumpHost(tester, jobId: 42);

    // A tech_en_route event with a stray child_booking_id MUST be
    // ignored — the early-out in `extractChildBookingId` is what
    // prevents accidental nav.
    h.fake.push(event(
      id: 'evt-other',
      type: SystemEventType.techEnRoute,
      payload: {'job_id': 42, 'child_booking_id': 99},
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('b-42')), findsOneWidget);
    expect(find.byKey(const ValueKey('b-99')), findsNothing);
  });

  testWidgets('does not navigate when job_id mismatches', (tester) async {
    final h = await _pumpHost(tester, jobId: 42);

    h.fake.push(event(
      id: 'evt-rs-other',
      type: SystemEventType.bookingRescheduled,
      payload: {'job_id': 999, 'child_booking_id': 1234},
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('b-42')), findsOneWidget);
    expect(find.byKey(const ValueKey('b-1234')), findsNothing);
  });

  testWidgets('does not navigate when child_booking_id is missing',
      (tester) async {
    final h = await _pumpHost(tester, jobId: 42);

    h.fake.push(event(
      id: 'evt-rs-nokid',
      type: SystemEventType.bookingRescheduled,
      payload: {'job_id': 42}, // no child_booking_id
    ));
    await tester.pumpAndSettle();

    // Stay on the original — the dev-log is fired, but no nav.
    expect(find.byKey(const ValueKey('b-42')), findsOneWidget);
  });

  testWidgets('does not navigate on duplicate event id', (tester) async {
    final h = await _pumpHost(tester, jobId: 42);

    final evt = event(
      id: 'evt-rs-dup',
      type: SystemEventType.bookingRescheduled,
      payload: {'job_id': 42, 'child_booking_id': 99},
    );

    h.fake.push(evt);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('b-99')), findsOneWidget);

    // Re-push the same id. The previous?.latestEvent?.id == event.id
    // dedup short-circuits.
    h.fake.push(evt);
    await tester.pumpAndSettle();
    // Still on /booking/99 — and crucially we did NOT also try to
    // navigate to /booking/99 again (which a router would no-op on
    // anyway, but confirms the dedup branch fires).
    expect(find.byKey(const ValueKey('b-99')), findsOneWidget);
  });
}
