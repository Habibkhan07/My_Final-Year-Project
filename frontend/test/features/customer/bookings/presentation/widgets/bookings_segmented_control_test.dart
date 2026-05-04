// Segmented control reads two providers (selected segment + counts) and
// fires `set()` on tap. We override both with mock notifiers to exercise
// the rendering and tap logic without touching the data layer.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/bookings_counts.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/customer_bookings_counts_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/providers/selected_segment_notifier.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/bookings_segmented_control.dart';

class _MockSegment extends SelectedSegment {
  _MockSegment(this._initial);
  final BookingSegment _initial;
  final List<BookingSegment> setCalls = [];

  @override
  BookingSegment build() => _initial;

  @override
  void set(BookingSegment segment) {
    setCalls.add(segment);
    state = segment;
  }
}

class _MockCounts extends CustomerBookingsCounts {
  _MockCounts(this.mockState);
  final AsyncValue<BookingsCounts> mockState;

  @override
  Future<BookingsCounts> build() {
    return mockState.when<Future<BookingsCounts>>(
      data: (counts) => Future.value(counts),
      error: (e, st) => Future.error(e, st),
      loading: () => Completer<BookingsCounts>().future,
    );
  }
}

Widget _build({
  required BookingSegment initialSegment,
  required AsyncValue<BookingsCounts> countsState,
  _MockSegment? capture,
}) {
  return ProviderScope(
    overrides: [
      selectedSegmentProvider.overrideWith(
        () => capture ?? _MockSegment(initialSegment),
      ),
      customerBookingsCountsProvider.overrideWith(() => _MockCounts(countsState)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: BookingsSegmentedControl()),
    ),
  );
}

void main() {
  final tCounts = BookingsCounts(
    upcoming: 1,
    past: 12,
    serverTime: DateTime(2026, 5, 5, 12, 0, 0),
  );

  testWidgets('renders count badges when counts is AsyncData', (tester) async {
    await tester.pumpWidget(_build(
      initialSegment: BookingSegment.upcoming,
      countsState: AsyncData(tCounts),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming · 1'), findsOneWidget);
    expect(find.text('Past · 12'), findsOneWidget);
  });

  testWidgets('omits counts when AsyncLoading', (tester) async {
    await tester.pumpWidget(_build(
      initialSegment: BookingSegment.upcoming,
      countsState: const AsyncLoading(),
    ));
    await tester.pump();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('omits counts when AsyncError', (tester) async {
    await tester.pumpWidget(_build(
      initialSegment: BookingSegment.upcoming,
      countsState: AsyncError('boom', StackTrace.empty),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing);
  });

  testWidgets('tapping a segment calls set() on the segment notifier',
      (tester) async {
    final capture = _MockSegment(BookingSegment.upcoming);
    await tester.pumpWidget(_build(
      initialSegment: BookingSegment.upcoming,
      countsState: AsyncData(tCounts),
      capture: capture,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past · 12'));
    await tester.pumpAndSettle();

    expect(capture.setCalls, contains(BookingSegment.past));
  });
}
