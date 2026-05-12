// Tests for `MeetingCountdownButton`'s production polish.
//
// The button is the customer's primary CTA on ARRIVED — its visual
// behavior has to survive future regressions. The two non-obvious
// invariants here:
//
//   1. The looping pulse controller MUST be guarded under flutter_test
//      so `pumpAndSettle` never deadlocks. The widget previously did
//      this via a runtime type-name check; this test pins that.
//   2. The drained fill is a Tween over 950ms — never a hard step. A
//      regression that swapped TweenAnimationBuilder for a raw
//      `FractionallySizedBox(widthFactor: _fillFraction)` would
//      compile cleanly but lose the smooth retreat. We assert the
//      tween is in the tree.
//   3. Read-only constructor mounts no InkWell — communicates "look,
//      don't tap" on the tech-side mirror.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/meeting_countdown_button.dart';

void _useRealisticPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('MeetingCountdownButton', () {
    testWidgets('renders + survives pumpAndSettle (loop-guard contract)',
        (tester) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeetingCountdownButton(
              arrivedAt: DateTime.now(),
              label: "I'm coming out",
              expiredLabel: 'Come out — tech is waiting',
              icon: Icons.directions_walk_rounded,
              onTap: () {},
              busy: false,
            ),
          ),
        ),
      );
      // If the pulse loop were running under flutter_test this would
      // deadlock. Production survives this assertion.
      await tester.pumpAndSettle();
      expect(find.text("I'm coming out"), findsOneWidget);
    });

    testWidgets('drained fill is a TweenAnimationBuilder, not a hard step',
        (tester) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeetingCountdownButton(
              arrivedAt: DateTime.now(),
              label: 'go',
              expiredLabel: 'expired',
              icon: Icons.directions_walk_rounded,
              onTap: () {},
              busy: false,
            ),
          ),
        ),
      );
      // The TweenAnimationBuilder over the FractionallySizedBox is
      // what produces the eased retreat. Removing it would break the
      // production polish silently.
      expect(
        find.byType(TweenAnimationBuilder<double>),
        findsWidgets,
      );
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('read-only mode mounts no InkWell — no tap affordance',
        (tester) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeetingCountdownButton.readOnly(
              arrivedAt: DateTime.now(),
              label: 'Customer notified',
              expiredLabel: 'Customer is overdue',
              icon: Icons.person_pin_circle_rounded,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The tap layer is what mounts the InkWell — read-only skips it
      // so screen readers / pointer hover do not announce
      // interactivity.
      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Customer notified'), findsOneWidget);
    });

    testWidgets('busy=true shows spinner, hides label', (tester) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeetingCountdownButton(
              arrivedAt: DateTime.now(),
              label: "I'm coming out",
              expiredLabel: 'expired',
              icon: Icons.directions_walk_rounded,
              onTap: () {},
              busy: true,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("I'm coming out"), findsNothing);
    });
  });
}
