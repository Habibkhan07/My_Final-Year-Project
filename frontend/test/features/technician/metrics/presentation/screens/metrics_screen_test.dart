import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/metrics/domain/entities/technician_metrics_entity.dart';
import 'package:frontend/features/technician/metrics/domain/failures/metrics_failure.dart';
import 'package:frontend/features/technician/metrics/presentation/notifiers/metrics_notifier.dart';
import 'package:frontend/features/technician/metrics/presentation/screens/metrics_screen.dart';

class _MockMetricsNotifier extends MetricsNotifier {
  _MockMetricsNotifier(this._states);

  /// Lookup: per period, the AsyncValue we want build() to resolve to.
  final Map<MetricsPeriod, AsyncValue<TechnicianMetricsEntity>> _states;

  @override
  Future<TechnicianMetricsEntity> build(MetricsPeriod period) async {
    final mock = _states[period];
    if (mock is AsyncData<TechnicianMetricsEntity>) {
      return mock.requireValue;
    }
    if (mock is AsyncError<TechnicianMetricsEntity>) {
      throw (mock as AsyncError).error;
    }
    return Completer<TechnicianMetricsEntity>().future;
  }
}

TechnicianMetricsEntity _weekEntity = const TechnicianMetricsEntity(
  period: MetricsPeriod.week,
  totalJobs: 8,
  totalCash: 15000.0,
  buckets: [
    MetricsBucket(label: 'Mon', jobs: 2, cash: 4500.0),
    MetricsBucket(label: 'Tue', jobs: 1, cash: 2000.0),
    MetricsBucket(label: 'Wed', jobs: 0, cash: 0.0),
    MetricsBucket(label: 'Thu', jobs: 3, cash: 5500.0),
    MetricsBucket(label: 'Fri', jobs: 2, cash: 3000.0),
    MetricsBucket(label: 'Sat', jobs: 0, cash: 0.0),
    MetricsBucket(label: 'Sun', jobs: 0, cash: 0.0),
  ],
);

Widget buildScreen({
  Map<MetricsPeriod, AsyncValue<TechnicianMetricsEntity>>? states,
}) {
  return ProviderScope(
    overrides: [
      metricsProvider.overrideWith(
        () => _MockMetricsNotifier(states ?? const {}),
      ),
    ],
    child: const MaterialApp(home: MetricsScreen()),
  );
}

void main() {
  group('MetricsScreen', () {
    testWidgets('renders AppBar title "Metrics"', (tester) async {
      await tester.pumpWidget(
        buildScreen(states: {MetricsPeriod.week: AsyncData(_weekEntity)}),
      );
      await tester.pump();
      expect(find.text('Metrics'), findsOneWidget);
    });

    testWidgets('renders all 4 period segment labels', (tester) async {
      await tester.pumpWidget(
        buildScreen(states: {MetricsPeriod.week: AsyncData(_weekEntity)}),
      );
      await tester.pump();
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    group('AsyncData (default = Week)', () {
      testWidgets('renders totals card values', (tester) async {
        await tester.pumpWidget(
          buildScreen(states: {MetricsPeriod.week: AsyncData(_weekEntity)}),
        );
        await tester.pump();

        expect(find.text('JOBS DONE'), findsOneWidget);
        expect(find.text('8'), findsOneWidget); // totalJobs
        expect(find.text('CASH COLLECTED'), findsWidgets); // card + chart caption
        expect(find.text('Rs. 15,000'), findsOneWidget); // totalCash
      });

      testWidgets('renders weekday bucket labels under the chart', (tester) async {
        await tester.pumpWidget(
          buildScreen(states: {MetricsPeriod.week: AsyncData(_weekEntity)}),
        );
        await tester.pump();
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncLoading', () {
      testWidgets('shows progress indicator while period is loading', (tester) async {
        await tester.pumpWidget(
          buildScreen(states: {MetricsPeriod.week: const AsyncLoading()}),
        );
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('period toggle is still rendered while loading', (tester) async {
        await tester.pumpWidget(
          buildScreen(states: {MetricsPeriod.week: const AsyncLoading()}),
        );
        await tester.pump();
        expect(find.text('Day'), findsOneWidget);
        expect(find.text('Week'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    group('AsyncError', () {
      testWidgets('network failure shows offline message + Retry', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            states: {
              MetricsPeriod.week:
                  AsyncError(const MetricsNetworkFailure(), StackTrace.empty),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('No internet'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('permission failure shows permission message', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            states: {
              MetricsPeriod.week:
                  AsyncError(const MetricsPermissionFailure(), StackTrace.empty),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('permission'), findsOneWidget);
      });

      testWidgets('server failure shows generic retry message', (tester) async {
        await tester.pumpWidget(
          buildScreen(
            states: {
              MetricsPeriod.week:
                  AsyncError(const MetricsServerFailure(), StackTrace.empty),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Something went wrong'), findsOneWidget);
      });
    });
  });
}
