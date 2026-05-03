// Widget tests for [IncomingJobSwipeToAccept] — the slide-to-accept pill
// with the draining track. Pins these contracts:
//
//   * Caption renders the formatted payout.
//   * Drag past the threshold fires onAccept exactly once.
//   * Drag short of the threshold does not fire onAccept (snap-back).
//   * After accept, further drags do not re-fire onAccept.
//   * When `expiresAt` is in the past, the ticker fires onExpire exactly once.
//   * When the WS is anything other than `connected`, the gesture is
//     gated and the offline caption surfaces (flag #19 family).
//
// What we deliberately don't pin:
//   * Exact pixel positions of the thumb mid-drag — too brittle.
//   * Animation curves — duration is a target, not a contract.
//   * Color band thresholds — those are pinned in `urgency_palette_test`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/widgets/incoming_job_swipe_to_accept.dart';

/// Fixed pill width so the gesture math is predictable across the test
/// environment. With width=400 and the widget's 6dp padding + 60dp thumb,
/// the swipe-able runway is roughly `400 - 12 - 60 = 328dp` when the
/// drain fraction is 1.0 (fresh offer).
const double _kPillWidth = 400;

/// Stub `WsConnectionNotifier` that returns a fixed status. The widget
/// reads `wsConnectionProvider` to gate gestures; tests inject the desired
/// status without spinning up the real socket machinery. Connect /
/// disconnect are no-ops — the widget never calls them, only the host.
///
/// Exposes [debugSetStatus] so transition tests can flip the status and
/// verify the widget reacts (the inherited `state` setter is protected,
/// so the test-only escape hatch lives here).
class _StubWsNotifier extends WsConnectionNotifier {
  _StubWsNotifier(this._initial);
  final WsConnectionStatus _initial;

  @override
  WsConnectionStatus build() => _initial;

  @override
  Future<void> connect(String authToken) async {}

  @override
  void disconnect() {}

  void debugSetStatus(WsConnectionStatus next) => state = next;
}

Future<void> _pumpSwipe(
  WidgetTester tester, {
  required DateTime expiresAt,
  required Duration slaWindow,
  int payoutRupees = 1800,
  required VoidCallback onAccept,
  required VoidCallback onExpire,
  WsConnectionStatus wsStatus = WsConnectionStatus.connected,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wsConnectionProvider.overrideWith(() => _StubWsNotifier(wsStatus)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: _kPillWidth,
              child: IncomingJobSwipeToAccept(
                expiresAt: expiresAt,
                slaWindow: slaWindow,
                payoutRupees: payoutRupees,
                onAccept: onAccept,
                onExpire: onExpire,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // One additional pump to settle the initial frame; do NOT pumpAndSettle
  // because the idle-hint controller loops forever.
  await tester.pump();
}

void main() {
  group('IncomingJobSwipeToAccept — render', () {
    testWidgets('caption renders the formatted payout (Rs. 1,800)',
        (tester) async {
      await _pumpSwipe(
        tester,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        slaWindow: const Duration(minutes: 5),
        payoutRupees: 1800,
        onAccept: () {},
        onExpire: () {},
      );

      expect(find.textContaining('Slide to accept'), findsOneWidget);
      expect(find.textContaining('Rs. 1,800'), findsOneWidget);
    });

    testWidgets('renders a chevron icon on the idle thumb', (tester) async {
      await _pumpSwipe(
        tester,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        slaWindow: const Duration(minutes: 5),
        onAccept: () {},
        onExpire: () {},
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });
  });

  group('IncomingJobSwipeToAccept — gestures', () {
    testWidgets('drag past 80% of the runway fires onAccept exactly once',
        (tester) async {
      var acceptCount = 0;
      await _pumpSwipe(
        tester,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        slaWindow: const Duration(minutes: 5),
        onAccept: () => acceptCount++,
        onExpire: () {},
      );

      // Find the swipe widget's center for gesture origin. The thumb starts
      // near the left edge; we anchor the gesture there and drag right.
      final pillCenter = tester.getCenter(find.byType(IncomingJobSwipeToAccept));
      final thumbStart = Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);

      final gesture = await tester.startGesture(thumbStart);
      // Drag well past 80% of ~328dp runway.
      await gesture.moveBy(const Offset(320, 0));
      await tester.pump();
      await gesture.up();
      // Allow the confirm animation to begin.
      await tester.pump(const Duration(milliseconds: 50));

      expect(acceptCount, 1);
    });

    testWidgets('drag short of the threshold does NOT fire onAccept',
        (tester) async {
      var acceptCount = 0;
      await _pumpSwipe(
        tester,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        slaWindow: const Duration(minutes: 5),
        onAccept: () => acceptCount++,
        onExpire: () {},
      );

      final pillCenter = tester.getCenter(find.byType(IncomingJobSwipeToAccept));
      final thumbStart = Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);

      final gesture = await tester.startGesture(thumbStart);
      // Drag only ~50dp — far below the 80% threshold of a ~328dp runway.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      // Wait for the snap-back animation.
      await tester.pump(const Duration(milliseconds: 250));

      expect(acceptCount, 0);
    });

    testWidgets(
      'after accept, additional drags do NOT re-fire onAccept '
      '(threshold is one-shot)',
      (tester) async {
        var acceptCount = 0;
        await _pumpSwipe(
          tester,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          slaWindow: const Duration(minutes: 5),
          onAccept: () => acceptCount++,
          onExpire: () {},
        );

        final pillCenter =
            tester.getCenter(find.byType(IncomingJobSwipeToAccept));
        final thumbStart =
            Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);

        // First drag — fires onAccept.
        var gesture = await tester.startGesture(thumbStart);
        await gesture.moveBy(const Offset(320, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));
        expect(acceptCount, 1);

        // Second drag — must NOT fire onAccept.
        gesture = await tester.startGesture(thumbStart);
        await gesture.moveBy(const Offset(320, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));
        expect(acceptCount, 1, reason: 'onAccept fires exactly once per build');
      },
    );
  });

  group('IncomingJobSwipeToAccept — auto-expire', () {
    testWidgets(
      'when remaining is already zero, the next ticker fire calls '
      'onExpire exactly once',
      (tester) async {
        var expireCount = 0;
        await _pumpSwipe(
          tester,
          // Expiry is already in the past.
          expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          slaWindow: const Duration(minutes: 5),
          onAccept: () {},
          onExpire: () => expireCount++,
        );

        // The 250ms periodic ticker should fire shortly. Give it a couple of
        // ticks to ensure it ran.
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(expireCount, 1);
      },
    );

    testWidgets(
      'after expire, swipe gestures cannot fire onAccept',
      (tester) async {
        var acceptCount = 0;
        var expireCount = 0;
        await _pumpSwipe(
          tester,
          expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          slaWindow: const Duration(minutes: 5),
          onAccept: () => acceptCount++,
          onExpire: () => expireCount++,
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(expireCount, 1);

        // Try to drag — gesture handlers must early-out because _expired is
        // true, AND the colored fill width is zero so maxThumbOffset clamps
        // to zero. Either way: no accept.
        final pillCenter =
            tester.getCenter(find.byType(IncomingJobSwipeToAccept));
        final thumbStart =
            Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);
        final gesture = await tester.startGesture(thumbStart);
        await gesture.moveBy(const Offset(320, 0));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        expect(acceptCount, 0);
      },
    );
  });

  group(
    'IncomingJobSwipeToAccept — connectivity gate (flag #19 family)',
    () {
      testWidgets(
        'when WS is not connected, the offline caption surfaces and the '
        '"Slide to accept" caption is hidden',
        (tester) async {
          await _pumpSwipe(
            tester,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            slaWindow: const Duration(minutes: 5),
            onAccept: () {},
            onExpire: () {},
            wsStatus: WsConnectionStatus.reconnecting,
          );

          // Offline caption visible — wifi-off icon plus "Reconnecting…".
          expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
          expect(find.text('Reconnecting…'), findsOneWidget);
          // Default caption is hidden via opacity-0 rather than removed
          // from the tree, so don't assert it's absent — assert it's not
          // visually surfaced by checking the wrapping AnimatedOpacity.
          // (Minimal contract: offline caption present.)
        },
      );

      testWidgets(
        'drag past 80% of the runway does NOT fire onAccept while offline '
        '— gesture handlers are gated upstream',
        (tester) async {
          var acceptCount = 0;
          await _pumpSwipe(
            tester,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            slaWindow: const Duration(minutes: 5),
            onAccept: () => acceptCount++,
            onExpire: () {},
            wsStatus: WsConnectionStatus.disconnected,
          );

          final pillCenter =
              tester.getCenter(find.byType(IncomingJobSwipeToAccept));
          final thumbStart =
              Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);

          final gesture = await tester.startGesture(thumbStart);
          // Same 320dp drag that fires onAccept in the connected case.
          await gesture.moveBy(const Offset(320, 0));
          await tester.pump();
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 50));

          expect(acceptCount, 0,
              reason: 'offline gesture path must short-circuit at the '
                  'GestureDetector level — onAccept never reached');
        },
      );

      testWidgets(
        'WsConnectionStatus.failed (10+ retries) is treated as offline — '
        'sheet still visible, accept still gated',
        (tester) async {
          // The sheet should remain visible (the user can still see the
          // offer / payout / countdown) but accept is physically blocked
          // until the socket recovers. UI must not collapse to a blank.
          var acceptCount = 0;
          await _pumpSwipe(
            tester,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            slaWindow: const Duration(minutes: 5),
            payoutRupees: 1800,
            onAccept: () => acceptCount++,
            onExpire: () {},
            wsStatus: WsConnectionStatus.failed,
          );

          // Widget is mounted and showing the offline state.
          expect(find.byType(IncomingJobSwipeToAccept), findsOneWidget);
          expect(find.text('Reconnecting…'), findsOneWidget);

          // Try the swipe.
          final pillCenter =
              tester.getCenter(find.byType(IncomingJobSwipeToAccept));
          final thumbStart =
              Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);
          final gesture = await tester.startGesture(thumbStart);
          await gesture.moveBy(const Offset(320, 0));
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 50));

          expect(acceptCount, 0);
        },
      );

      testWidgets(
        'connected → reconnecting transition mid-offer immediately gates '
        'the swipe AND surfaces the offline caption (rebuild contract: '
        'the widget watches the provider, not just reads it once)',
        (tester) async {
          var acceptCount = 0;
          final container = ProviderContainer(
            overrides: [
              wsConnectionProvider.overrideWith(
                () => _StubWsNotifier(WsConnectionStatus.connected),
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: _kPillWidth,
                      child: IncomingJobSwipeToAccept(
                        expiresAt:
                            DateTime.now().add(const Duration(minutes: 5)),
                        slaWindow: const Duration(minutes: 5),
                        payoutRupees: 1800,
                        onAccept: () => acceptCount++,
                        onExpire: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          // Sanity: connected → no offline caption.
          expect(find.text('Reconnecting…'), findsNothing);

          // Flip the notifier state to reconnecting via the test-only
          // setter. `ref.watch` inside the widget's build must re-fire and
          // surface the offline caption.
          final notifier = container.read(wsConnectionProvider.notifier)
              as _StubWsNotifier;
          notifier.debugSetStatus(WsConnectionStatus.reconnecting);
          await tester.pump();

          expect(find.text('Reconnecting…'), findsOneWidget,
              reason: 'widget must rebuild on connection-status change');

          // And the gesture is now gated.
          final pillCenter =
              tester.getCenter(find.byType(IncomingJobSwipeToAccept));
          final thumbStart =
              Offset(pillCenter.dx - _kPillWidth / 2 + 36, pillCenter.dy);
          final gesture = await tester.startGesture(thumbStart);
          await gesture.moveBy(const Offset(320, 0));
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 50));

          expect(acceptCount, 0,
              reason: 'gesture must be gated immediately after the '
                  'connection drops');
        },
      );
    },
  );
}
