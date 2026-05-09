import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/later_today_list.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

List<LaterTodayJobEntity> _twoJobs() => [
  LaterTodayJobEntity(
    jobId: 1,
    serviceTitle: 'Ceiling Fan Repair',
    scheduledTime: DateTime(2026, 4, 26, 16),
    addressText: 'DHA Phase 5',
  ),
  LaterTodayJobEntity(
    jobId: 2,
    serviceTitle: 'Geyser Installation',
    scheduledTime: DateTime(2026, 4, 26, 18, 30),
    addressText: 'Model Town',
  ),
];

Widget buildList(List<LaterTodayJobEntity> jobs) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LaterTodayList(jobs: jobs),
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LaterTodayList', () {
    // -----------------------------------------------------------------------
    group('section heading', () {
      testWidgets('always renders "Later Today" heading with jobs', (
        tester,
      ) async {
        await tester.pumpWidget(buildList(_twoJobs()));
        expect(find.text('Later Today'), findsOneWidget);
      });

      testWidgets('always renders "Later Today" heading when empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildList(const []));
        expect(find.text('Later Today'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('non-empty list', () {
      testWidgets('renders all service titles', (tester) async {
        await tester.pumpWidget(buildList(_twoJobs()));
        await tester.pumpAndSettle();

        expect(find.text('Ceiling Fan Repair'), findsOneWidget);
        expect(find.text('Geyser Installation'), findsOneWidget);
      });

      testWidgets('renders address text for each job', (tester) async {
        await tester.pumpWidget(buildList(_twoJobs()));
        await tester.pumpAndSettle();

        expect(find.text('DHA Phase 5'), findsOneWidget);
        expect(find.text('Model Town'), findsOneWidget);
      });

      testWidgets('does not show empty-state message', (tester) async {
        await tester.pumpWidget(buildList(_twoJobs()));
        expect(find.text('No more jobs scheduled for today'), findsNothing);
      });

      testWidgets('renders a chevron_right icon per job row', (tester) async {
        await tester.pumpWidget(buildList(_twoJobs()));
        await tester.pumpAndSettle();

        // One chevron per row.
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
      });
    });

    // -----------------------------------------------------------------------
    group('empty list', () {
      testWidgets('shows "No more jobs scheduled for today" message', (
        tester,
      ) async {
        await tester.pumpWidget(buildList(const []));
        expect(find.text('No more jobs scheduled for today'), findsOneWidget);
      });

      testWidgets('renders no job-title text', (tester) async {
        await tester.pumpWidget(buildList(const []));
        expect(find.text('Ceiling Fan Repair'), findsNothing);
      });

      testWidgets('renders no chevron icons', (tester) async {
        await tester.pumpWidget(buildList(const []));
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });
  });
}
