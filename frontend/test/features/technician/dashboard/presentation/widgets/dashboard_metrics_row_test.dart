import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/dashboard/domain/entities/technician_dashboard_entity.dart';
import 'package:frontend/features/technician/dashboard/presentation/widgets/dashboard_metrics_row.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget buildRow(DashboardMetricsEntity metrics) => MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardMetricsRow(metrics: metrics),
        ),
      ),
    );

const DashboardMetricsEntity _zero = DashboardMetricsEntity(
  jobsCompletedToday: 0,
  cashCollectedToday: 0,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardMetricsRow', () {
    // -----------------------------------------------------------------------
    group('labels', () {
      testWidgets('renders "Jobs Completed" label', (tester) async {
        await tester.pumpWidget(buildRow(_zero));
        expect(find.text('Jobs Completed'), findsOneWidget);
      });

      testWidgets('renders "Cash Collected" label', (tester) async {
        await tester.pumpWidget(buildRow(_zero));
        expect(find.text('Cash Collected'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('jobs completed value', () {
      testWidgets('displays count as plain integer string', (tester) async {
        await tester.pumpWidget(buildRow(
          const DashboardMetricsEntity(
            jobsCompletedToday: 7,
            cashCollectedToday: 0,
          ),
        ));
        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('displays zero count as "0"', (tester) async {
        await tester.pumpWidget(buildRow(_zero));
        expect(find.text('0'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('cash collected formatting', () {
      testWidgets('formats 3500 as "Rs. 3,500"', (tester) async {
        await tester.pumpWidget(buildRow(
          const DashboardMetricsEntity(
            jobsCompletedToday: 0,
            cashCollectedToday: 3500,
          ),
        ));
        expect(find.text('Rs. 3,500'), findsOneWidget);
      });

      testWidgets('formats 100000 as "Rs. 100,000"', (tester) async {
        await tester.pumpWidget(buildRow(
          const DashboardMetricsEntity(
            jobsCompletedToday: 0,
            cashCollectedToday: 100000,
          ),
        ));
        expect(find.text('Rs. 100,000'), findsOneWidget);
      });

      testWidgets('formats 500 as "Rs. 500" (no comma below 1000)', (tester) async {
        await tester.pumpWidget(buildRow(
          const DashboardMetricsEntity(
            jobsCompletedToday: 0,
            cashCollectedToday: 500,
          ),
        ));
        expect(find.text('Rs. 500'), findsOneWidget);
      });

      testWidgets('formats zero cash as "Rs. 0"', (tester) async {
        await tester.pumpWidget(buildRow(_zero));
        expect(find.text('Rs. 0'), findsOneWidget);
      });
    });
  });
}
