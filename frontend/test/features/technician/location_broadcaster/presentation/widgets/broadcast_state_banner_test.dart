// Widget tests for `BroadcastStateBanner` (audit C6 / S-5).
//
// Contract pinned by these tests:
//   • `BroadcastState.idle` and `BroadcastState.running` render NO
//     banner — the layout returns to its pristine state when tracking
//     is healthy (or has not started yet).
//   • Each of the three failure states renders a banner with a
//     state-specific icon + a copy fragment a tech can act on.
//
// These are pure widget tests against a hardcoded enum value — no
// network, no providers, no notifier mounting. We do NOT assert on
// exact colours; the banner spec table lives next to the widget and
// changes there shouldn't churn this test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/location_broadcaster/domain/entities/broadcast_state.dart';
import 'package:frontend/features/technician/location_broadcaster/presentation/widgets/broadcast_state_banner.dart';

Future<void> _pump(WidgetTester tester, BroadcastState state) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BroadcastStateBanner(state: state),
      ),
    ),
  );
}

void main() {
  group('BroadcastStateBanner — render-nothing states', () {
    testWidgets('idle → SizedBox.shrink (no banner chrome)', (tester) async {
      await _pump(tester, BroadcastState.idle);
      expect(find.byIcon(Icons.location_off), findsNothing);
      expect(find.byIcon(Icons.notifications_off), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('running → SizedBox.shrink (no banner chrome)', (tester) async {
      await _pump(tester, BroadcastState.running);
      expect(find.byIcon(Icons.location_off), findsNothing);
      expect(find.byIcon(Icons.notifications_off), findsNothing);
      expect(find.byType(Container), findsNothing);
    });
  });

  group('BroadcastStateBanner — failure states', () {
    testWidgets(
      'permissionDenied → location_off icon + "Location is off" copy',
      (tester) async {
        await _pump(tester, BroadcastState.permissionDenied);
        expect(find.byIcon(Icons.location_off), findsOneWidget);
        expect(
          find.textContaining('Location is off', findRichText: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'notificationPermissionDenied → notifications_off icon + '
      '"Allow notifications" copy',
      (tester) async {
        await _pump(tester, BroadcastState.notificationPermissionDenied);
        expect(find.byIcon(Icons.notifications_off), findsOneWidget);
        expect(
          find.textContaining('Allow notifications', findRichText: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'error → "Tracking unavailable" copy',
      (tester) async {
        await _pump(tester, BroadcastState.error);
        expect(
          find.textContaining('Tracking unavailable', findRichText: false),
          findsOneWidget,
        );
      },
    );
  });
}
