// Tests for EventUrgencyRouter — flag #22 banner copy, payload-key
// path substitution, and regression coverage for the existing
// static-path low-urgency events.
//
// `_handleLow` is private; we drive the public `handleEvent` entry
// point and assert on the rendered MaterialBanner. For the tap-target
// substitution we mount a GoRouter with a `:job_id` route that records
// the path parameter it received.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/entities/target_role.dart';
import 'package:frontend/core/realtime/presentation/router/event_urgency_router.dart';

class _RouterTestHarness {
  _RouterTestHarness({this.extraRoutes = const []});

  final List<GoRoute> extraRoutes;
  final navigatorKey = GlobalKey<NavigatorState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String? capturedBookingId;

  EventUrgencyRouter get router => EventUrgencyRouter(
    navigatorKey: navigatorKey,
    scaffoldMessengerKey: scaffoldMessengerKey,
  );

  Widget build() {
    final goRouter = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (_, _) => const Scaffold(body: Text('start')),
        ),
        GoRoute(
          path: '/booking/:job_id',
          builder: (context, state) {
            capturedBookingId = state.pathParameters['job_id'];
            return Scaffold(body: Text('booking-${capturedBookingId ?? "?"}'));
          },
        ),
        ...extraRoutes,
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: goRouter,
      ),
    );
  }

  /// Spin up a hidden Consumer overlay so we can hand `handleEvent` a
  /// real WidgetRef. booking_rejected is non-critical and never enters
  /// the ACK branch that touches the ref, but the signature still
  /// requires one. Returns a teardown closure.
  Future<({WidgetRef ref, void Function() dispose})> overlayRef(
    WidgetTester tester,
  ) async {
    final overlay = navigatorKey.currentState!.overlay!;
    WidgetRef? out;
    final entry = OverlayEntry(
      builder: (_) => ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            out = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    overlay.insert(entry);
    await tester.pump();
    return (ref: out!, dispose: entry.remove);
  }
}

SystemEventEntity _bookingRejectedEvent({
  required Map<String, dynamic> payload,
}) {
  // Going through `fromComponents` so urgency / criticality are derived
  // by the same code paths production uses (lowUrgency, isCritical=false).
  return SystemEventEntity.fromComponents(
    id: 'evt-${payload.hashCode}',
    rawType: 'booking_rejected',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: payload,
  );
}

SystemEventEntity _jobAcceptedEvent({required Map<String, dynamic> payload}) {
  // Production-equivalent derivation: flag #25 flipped jobAccepted to
  // lowUrgency + isCritical=false. The route fans out the same banner
  // surface as bookingRejected.
  return SystemEventEntity.fromComponents(
    id: 'evt-${payload.hashCode}',
    rawType: 'job_accepted',
    targetRoleStr: 'customer',
    timestamp: DateTime.now().toUtc(),
    payload: payload,
  );
}

void main() {
  group('booking_rejected banner copy', () {
    Future<void> expectBannerBody({
      required WidgetTester tester,
      required String reason,
      required String expectedSubstring,
    }) async {
      final harness = _RouterTestHarness();
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = _bookingRejectedEvent(
          payload: {'reason': reason, 'job_id': 99},
        );
        harness.router.handleEvent(event, TargetRole.customer, ref.ref);
        // Banner inserted on the next frame; animation takes ~250ms
        // before it's at its resting position. pumpAndSettle would block
        // on the 5s auto-dismiss timer in the router, so we pump a bounded
        // duration that's long enough for the slide-in but short of the
        // auto-dismiss.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining(expectedSubstring, findRichText: true),
          findsOneWidget,
          reason:
              'banner body should mention "$expectedSubstring" '
              'for reason="$reason"',
        );
      } finally {
        // Drain the router's 5s auto-dismiss timer before teardown.
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    }

    testWidgets('technician_declined → tech-declined copy', (tester) async {
      await expectBannerBody(
        tester: tester,
        reason: 'technician_declined',
        expectedSubstring: 'Technician declined',
      );
    });

    testWidgets('sla_timeout → no-response copy', (tester) async {
      await expectBannerBody(
        tester: tester,
        reason: 'sla_timeout',
        expectedSubstring: 'No technician responded',
      );
    });

    testWidgets('unknown reason → generic fallback copy', (tester) async {
      await expectBannerBody(
        tester: tester,
        reason: 'future_pathway_we_havent_shipped_yet',
        expectedSubstring: 'no longer available',
      );
    });
  });

  group('booking_rejected tap target', () {
    testWidgets('tapping "View" navigates to /booking/<job_id>', (
      tester,
    ) async {
      final harness = _RouterTestHarness();
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = _bookingRejectedEvent(
          payload: {'reason': 'technician_declined', 'job_id': 4242},
        );
        harness.router.handleEvent(event, TargetRole.customer, ref.ref);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('View'), findsOneWidget);
        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();

        expect(harness.capturedBookingId, '4242');
        expect(find.text('booking-4242'), findsOneWidget);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    });

    testWidgets('missing job_id skips the push (defensive)', (tester) async {
      // Defensive case: backend somehow ships booking_rejected without
      // job_id. The new generic templated-path resolver returns null
      // when a token is unresolvable, and the tap handler skips the
      // push — preferable to pushing the literal `:job_id` template
      // which would crash GoRouter. The user stays on the start screen.
      //
      // (Sprint v1, session 3: rewired in lockstep with the orchestrator
      // route convergence onto `/booking/:job_id`.)
      final harness = _RouterTestHarness();
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = _bookingRejectedEvent(
          payload: {'reason': 'sla_timeout'}, // no job_id
        );
        harness.router.handleEvent(event, TargetRole.customer, ref.ref);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();

        // Captor unchanged → no push happened. Start screen still
        // visible (defensive: better no-op than crash).
        expect(harness.capturedBookingId, isNull);
        expect(find.text('start'), findsOneWidget);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    });
  });

  group('job_accepted banner copy (flag #25)', () {
    Future<void> expectJobAcceptedBody({
      required WidgetTester tester,
      required Map<String, dynamic> payload,
      required String expectedSubstring,
    }) async {
      final harness = _RouterTestHarness();
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = _jobAcceptedEvent(payload: payload);
        harness.router.handleEvent(event, TargetRole.customer, ref.ref);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining(expectedSubstring, findRichText: true),
          findsOneWidget,
          reason:
              'banner body should mention "$expectedSubstring" '
              'for payload=$payload',
        );
        // Title should also surface — this guards against a future
        // regression where the title map gets pruned.
        expect(
          find.textContaining('Booking confirmed', findRichText: true),
          findsOneWidget,
        );
      } finally {
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    }

    testWidgets('with technician_display_name → personalised copy', (
      tester,
    ) async {
      await expectJobAcceptedBody(
        tester: tester,
        payload: {'job_id': 99482, 'technician_display_name': 'Ali Khan'},
        expectedSubstring: 'Ali Khan is on the way',
      );
    });

    testWidgets('without technician_display_name → generic fallback', (
      tester,
    ) async {
      // Defensive case: if a replayed pre-flag-#25 EventLog row landed
      // without the field, the surface should still be useful — generic
      // copy beats an empty banner body.
      await expectJobAcceptedBody(
        tester: tester,
        payload: {'job_id': 99482},
        expectedSubstring: 'Your technician is on the way',
      );
    });
  });

  group('job_accepted tap target (flag #25)', () {
    testWidgets('tapping "View" navigates to /booking/<job_id>', (
      tester,
    ) async {
      final harness = _RouterTestHarness();
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = _jobAcceptedEvent(
          payload: {'job_id': 7777, 'technician_display_name': 'Ali Khan'},
        );
        harness.router.handleEvent(event, TargetRole.customer, ref.ref);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('View'), findsOneWidget);
        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();

        // job_accepted reuses the same /booking/:job_id route
        // as booking_rejected (placeholder; flag #26 will swap in the
        // real customer detail screen).
        expect(harness.capturedBookingId, '7777');
        expect(find.text('booking-7777'), findsOneWidget);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    });
  });

  group('banner suppressed when viewing the same entity', () {
    // Locks the rule: if the user is already on `/booking/<id>` and a
    // low-urgency event arrives for that same booking, the banner is
    // SUPPRESSED — the screen's own event notifier refreshes the data
    // silently. Banners about a *different* booking still fire.
    Future<void> seed(WidgetTester tester, _RouterTestHarness harness) async {
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();
      // Navigate to /booking/42 — simulates the user being on that screen.
      harness.navigatorKey.currentState!.context;
      GoRouter.of(
        harness.navigatorKey.currentContext!,
      ).push('/booking/42');
      await tester.pumpAndSettle();
      expect(find.text('booking-42'), findsOneWidget);
    }

    testWidgets(
      'tech_en_route for the booking the user is on → no banner',
      (tester) async {
        final harness = _RouterTestHarness();
        await seed(tester, harness);
        final ref = await harness.overlayRef(tester);
        try {
          final event = SystemEventEntity.fromComponents(
            id: 'evt-en-route-42',
            rawType: 'tech_en_route',
            targetRoleStr: 'customer',
            timestamp: DateTime.now().toUtc(),
            payload: const {'job_id': 42, 'technician_name': 'Ali'},
          );
          harness.router.handleEvent(event, TargetRole.customer, ref.ref);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('View'), findsNothing);
          expect(find.text('Dismiss'), findsNothing);
        } finally {
          ref.dispose();
        }
      },
    );

    testWidgets(
      'tech_en_route for a DIFFERENT booking → banner still shows',
      (tester) async {
        // The user is on /booking/42; event is for booking 99.
        final harness = _RouterTestHarness();
        await seed(tester, harness);
        final ref = await harness.overlayRef(tester);
        try {
          final event = SystemEventEntity.fromComponents(
            id: 'evt-en-route-99',
            rawType: 'tech_en_route',
            targetRoleStr: 'customer',
            timestamp: DateTime.now().toUtc(),
            payload: const {'job_id': 99, 'technician_name': 'Ali'},
          );
          harness.router.handleEvent(event, TargetRole.customer, ref.ref);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('View'), findsOneWidget);
        } finally {
          await tester.pump(const Duration(seconds: 6));
          ref.dispose();
        }
      },
    );

    testWidgets(
      'job_accepted for the booking the user is on → no banner',
      (tester) async {
        final harness = _RouterTestHarness();
        await seed(tester, harness);
        final ref = await harness.overlayRef(tester);
        try {
          final event = _jobAcceptedEvent(
            payload: const {'job_id': 42, 'technician_display_name': 'Ali'},
          );
          harness.router.handleEvent(event, TargetRole.customer, ref.ref);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('View'), findsNothing);
        } finally {
          ref.dispose();
        }
      },
    );
  });

  group('regression — existing low-urgency events keep static paths', () {
    testWidgets('payment_received still pushes /shared/wallet unchanged', (
      tester,
    ) async {
      // Sanity-check that adding `_lowUrgencyTapPayloadKeys` did not
      // change behavior for existing low-urgency events that have no
      // entry in the new map — they should keep pushing the static path.
      final harness = _RouterTestHarness(
        extraRoutes: [
          GoRoute(
            path: '/shared/wallet',
            builder: (_, _) => const Scaffold(body: Text('wallet')),
          ),
        ],
      );
      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final ref = await harness.overlayRef(tester);
      try {
        final event = SystemEventEntity.fromComponents(
          id: 'evt-payment',
          rawType: 'payment_received',
          targetRoleStr: 'technician',
          timestamp: DateTime.now().toUtc(),
          payload: const {'amount': '500'},
        );
        harness.router.handleEvent(event, TargetRole.technician, ref.ref);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();

        expect(find.text('wallet'), findsOneWidget);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        ref.dispose();
      }
    });
  });
}
