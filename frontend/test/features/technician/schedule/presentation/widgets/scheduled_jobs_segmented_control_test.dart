// Segmented control reads two providers (selected segment + counts) and
// fires `set()` on tap. Override both with mock notifiers to exercise
// rendering + tap logic without touching the data layer.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_job_segment.dart';
import 'package:frontend/features/technician/schedule/domain/entities/scheduled_jobs_counts.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/scheduled_jobs_counts_notifier.dart';
import 'package:frontend/features/technician/schedule/presentation/providers/selected_schedule_segment_notifier.dart';
import 'package:frontend/features/technician/schedule/presentation/widgets/scheduled_jobs_segmented_control.dart';

class _MockSegment extends SelectedScheduleSegment {
  _MockSegment(this._initial);
  final ScheduledJobSegment _initial;
  final List<ScheduledJobSegment> setCalls = [];

  @override
  ScheduledJobSegment build() => _initial;

  @override
  void set(ScheduledJobSegment segment) {
    setCalls.add(segment);
    state = segment;
  }
}

class _MockCounts extends ScheduledJobsCountsNotifier {
  _MockCounts(this.mockState);
  final AsyncValue<ScheduledJobsCounts> mockState;

  @override
  Future<ScheduledJobsCounts> build() {
    return mockState.when<Future<ScheduledJobsCounts>>(
      data: (counts) => Future.value(counts),
      error: (e, st) => Future.error(e, st),
      loading: () => Completer<ScheduledJobsCounts>().future,
    );
  }
}

Widget _build({
  required ScheduledJobSegment initialSegment,
  required AsyncValue<ScheduledJobsCounts> countsState,
  _MockSegment? capture,
}) {
  return ProviderScope(
    overrides: [
      selectedScheduleSegmentProvider.overrideWith(
        () => capture ?? _MockSegment(initialSegment),
      ),
      scheduledJobsCountsProvider.overrideWith(
        () => _MockCounts(countsState),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ScheduledJobsSegmentedControl()),
    ),
  );
}

void main() {
  final tCounts = ScheduledJobsCounts(
    upcoming: 3,
    past: 11,
    serverTime: DateTime(2026, 5, 5, 12, 0, 0),
  );

  testWidgets('renders count badges when counts is AsyncData', (tester) async {
    await tester.pumpWidget(
      _build(
        initialSegment: ScheduledJobSegment.upcoming,
        countsState: AsyncData(tCounts),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming · 3'), findsOneWidget);
    expect(find.text('Past · 11'), findsOneWidget);
  });

  testWidgets('omits counts when AsyncLoading', (tester) async {
    await tester.pumpWidget(
      _build(
        initialSegment: ScheduledJobSegment.upcoming,
        countsState: const AsyncLoading(),
      ),
    );
    await tester.pump();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('omits counts when AsyncError', (tester) async {
    await tester.pumpWidget(
      _build(
        initialSegment: ScheduledJobSegment.upcoming,
        countsState: AsyncError('boom', StackTrace.empty),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('tapping a segment calls set() on the segment notifier', (
    tester,
  ) async {
    final capture = _MockSegment(ScheduledJobSegment.upcoming);
    await tester.pumpWidget(
      _build(
        initialSegment: ScheduledJobSegment.upcoming,
        countsState: AsyncData(tCounts),
        capture: capture,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past · 11'));
    await tester.pumpAndSettle();

    expect(capture.setCalls, contains(ScheduledJobSegment.past));
  });

  testWidgets(
    'tapping the currently active segment is a no-op (set() bails on '
    'equal state)',
    (tester) async {
      final capture = _MockSegment(ScheduledJobSegment.upcoming);
      await tester.pumpWidget(
        _build(
          initialSegment: ScheduledJobSegment.upcoming,
          countsState: AsyncData(tCounts),
          capture: capture,
        ),
      );
      await tester.pumpAndSettle();

      // Even though tapping the already-active segment calls set(), it
      // short-circuits when state == segment — but it still records the
      // call. The contract is: state must remain on upcoming. Useful as
      // a regression guard for future "toggle" semantics.
      await tester.tap(find.text('Upcoming · 3'));
      await tester.pumpAndSettle();

      // The notifier's state did not change.
      expect(capture.state, ScheduledJobSegment.upcoming);
    },
  );
}
