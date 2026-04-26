import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/widgets/map/job_location_map.dart';
import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/up_next_job_card.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

UpNextJobEntity _job() => UpNextJobEntity(
      jobId: 1,
      serviceTitle: 'AC Deep Wash',
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      customerName: 'Ali R.',
      addressText: '14 Street, Gulberg III',
      lat: 31.5204,
      lng: 74.3587,
    );

Widget buildCard({UpNextJobEntity? job}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UpNextJobCard(job: job),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UpNextJobCard', () {
    // -----------------------------------------------------------------------
    group('job present — content', () {
      testWidgets('shows "Up Next" section label', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.text('Up Next'), findsOneWidget);
      });

      testWidgets('shows service title', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.text('AC Deep Wash'), findsOneWidget);
      });

      testWidgets('shows customer name', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.text('Ali R.'), findsOneWidget);
      });

      testWidgets('shows address text', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.text('14 Street, Gulberg III'), findsOneWidget);
      });

      testWidgets('shows "Start Navigation" CTA button', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.text('Start Navigation'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('job present — map', () {
      testWidgets('renders JobLocationMap widget', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.byType(JobLocationMap), findsOneWidget);
      });

      testWidgets('FlutterMap is present inside JobLocationMap', (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        expect(find.byType(FlutterMap), findsOneWidget);
      });

      testWidgets('map is wrapped in IgnorePointer — scroll events pass through',
          (tester) async {
        await tester.pumpWidget(buildCard(job: _job()));
        // Verify our IgnorePointer is a direct child inside JobLocationMap,
        // scoped to avoid matching any IgnorePointer that flutter_map adds
        // internally for its own gesture handling.
        final jobMapFinder = find.byType(JobLocationMap);
        expect(jobMapFinder, findsOneWidget);
        expect(
          find.descendant(of: jobMapFinder, matching: find.byType(IgnorePointer)),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    group('job absent — empty state', () {
      testWidgets('shows "No upcoming jobs" text', (tester) async {
        await tester.pumpWidget(buildCard(job: null));
        expect(find.text('No upcoming jobs'), findsOneWidget);
      });

      testWidgets('shows "You\'re all caught up" sub-text', (tester) async {
        await tester.pumpWidget(buildCard(job: null));
        expect(find.textContaining("all caught up"), findsOneWidget);
      });

      testWidgets('does not render JobLocationMap', (tester) async {
        await tester.pumpWidget(buildCard(job: null));
        expect(find.byType(JobLocationMap), findsNothing);
      });

      testWidgets('does not render "Start Navigation"', (tester) async {
        await tester.pumpWidget(buildCard(job: null));
        expect(find.text('Start Navigation'), findsNothing);
      });

      testWidgets('does not render "Up Next" section label', (tester) async {
        await tester.pumpWidget(buildCard(job: null));
        expect(find.text('Up Next'), findsNothing);
      });
    });
  });
}
