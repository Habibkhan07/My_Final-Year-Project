// Tests for `TimelineSlot` — the 5-dot phase progression.
//
// Regression vectors (#B-53):
//   * INSPECTING + QUOTED both render the "Quote" dot as current —
//     they're the same phase from the user's POV.
//   * IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY all render
//     "Done" as current (collapse to done is via timestamp).
//   * Terminal states (cancelled / rejected / no-show / disputed /
//     pending / unknown) have NO current marker — no FontWeight.w600
//     phase label in the row.
//
// We assert via the bolded-label heuristic — `_PhaseState.current`
// is the only state that produces `FontWeight.w700` on its label.
// That's a single, observable rendering signal. Terminal states do
// not render the phase row at all (they show a "Booking ended" pill
// whose own text weight is intentionally lower), so the helper
// returns null for them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/timeline_slot.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking(BookingStatus s) {
  final wire = switch (s) {
    BookingStatus.awaiting => 'AWAITING',
    BookingStatus.confirmed => 'CONFIRMED',
    BookingStatus.enRoute => 'EN_ROUTE',
    BookingStatus.arrived => 'ARRIVED',
    BookingStatus.inspecting => 'INSPECTING',
    BookingStatus.quoted => 'QUOTED',
    BookingStatus.inProgress => 'IN_PROGRESS',
    BookingStatus.completed => 'COMPLETED',
    BookingStatus.completedInspectionOnly => 'COMPLETED_INSPECTION_ONLY',
    BookingStatus.cancelled => 'CANCELLED',
    BookingStatus.rejected => 'REJECTED',
    BookingStatus.noShow => 'NO_SHOW',
    BookingStatus.disputed => 'DISPUTED',
    BookingStatus.pending => 'PENDING',
    BookingStatus.unknown => 'UNRECOGNIZED',
  };
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson(status: wire)),
    currentUserId: 7,
  );
}

/// Find the unique phase label rendered with `FontWeight.w600` (the
/// "current" state). Returns null when no label is current — which is
/// the expected outcome for terminal/unknown statuses.
String? _currentPhaseLabel(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text));
  for (final t in texts) {
    if (t.style?.fontWeight == FontWeight.w700 && t.data != null) {
      return t.data;
    }
  }
  return null;
}

Future<void> _pump(WidgetTester tester, BookingDetail b) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TimelineSlot(booking: b)),
    ),
  );
}

void main() {
  group('current dot per status', () {
    final cases = <(BookingStatus, String)>[
      (BookingStatus.awaiting, 'Confirmed'),
      (BookingStatus.confirmed, 'Confirmed'),
      (BookingStatus.enRoute, 'On the way'),
      (BookingStatus.arrived, 'Arrived'),
      // Inspecting + Quoted both map to phase index 3 = "Quote".
      (BookingStatus.inspecting, 'Quote'),
      (BookingStatus.quoted, 'Quote'),
      // In-progress / completed / completed-inspection-only all map to
      // phase index 4 = "Done".
      (BookingStatus.inProgress, 'Done'),
      (BookingStatus.completed, 'Done'),
      (BookingStatus.completedInspectionOnly, 'Done'),
    ];

    for (final (status, expectedLabel) in cases) {
      testWidgets('${status.name} → "$expectedLabel" is current', (
        tester,
      ) async {
        await _pump(tester, _booking(status));
        expect(_currentPhaseLabel(tester), expectedLabel);
      });
    }
  });

  group('terminal / unknown statuses have no current marker', () {
    for (final s in [
      BookingStatus.cancelled,
      BookingStatus.rejected,
      BookingStatus.noShow,
      BookingStatus.disputed,
      BookingStatus.pending,
      BookingStatus.unknown,
    ]) {
      testWidgets('${s.name} → no phase is current', (tester) async {
        await _pump(tester, _booking(s));
        expect(_currentPhaseLabel(tester), isNull);
      });
    }
  });

  testWidgets('renders all five phase labels', (tester) async {
    await _pump(tester, _booking(BookingStatus.confirmed));
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('Quote'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
