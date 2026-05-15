// Empty-state widgets for the Schedule feature. Pure presentation —
// hardcoded copy lives in the widget; we pin it here so future copy
// changes that miss either screen surface (tech vs customer) get caught.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/schedule/presentation/widgets/scheduled_jobs_empty_past.dart';
import 'package:frontend/features/technician/schedule/presentation/widgets/scheduled_jobs_empty_upcoming.dart';

void main() {
  group('ScheduledJobsEmptyUpcoming', () {
    testWidgets('renders tech-framed copy + event icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScheduledJobsEmptyUpcoming()),
        ),
      );
      expect(find.text('No upcoming jobs'), findsOneWidget);
      expect(
        find.textContaining('Go online from your dashboard'),
        findsOneWidget,
      );
      // Icon reads "you'll get jobs" — event icon matches design.
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    });

    testWidgets('has no CTA (tech go-online flow lives on dashboard)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScheduledJobsEmptyUpcoming()),
        ),
      );
      // The customer-side Upcoming empty has a "Browse services" button;
      // the tech-side intentionally doesn't (the dashboard's Online
      // toggle is the active affordance). Regression guard for this
      // intentional asymmetry.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ScheduledJobsEmptyPast', () {
    testWidgets('renders past-state copy + history icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScheduledJobsEmptyPast()),
        ),
      );
      expect(find.text('No past jobs'), findsOneWidget);
      expect(
        find.textContaining('completed and cancelled jobs'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('has no CTA (past-state is informational only)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScheduledJobsEmptyPast()),
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
