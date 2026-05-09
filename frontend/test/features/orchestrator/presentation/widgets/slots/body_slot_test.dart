// Tests for `BodySlot` — the single switch on `BookingStatus` in the
// orchestrator feature.
//
// Adding a new BookingStatus enum value will fail compilation in the
// switch (Dart 3 exhaustiveness). This test pins the *runtime mapping*:
// each existing status renders its dedicated stub widget. A regression
// that swapped a case (e.g. arrived → quoted by typo) would compile
// cleanly but fail this test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/body_slot.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _bookingFor(BookingStatus s) {
  // Map domain status back to wire string. Keep this table in sync with
  // BookingStatus.fromWire.
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
    BookingStatus.unknown => 'UNKNOWN_STATUS_THAT_DOES_NOT_EXIST',
  };
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson(status: wire)),
    currentUserId: 7,
  );
}

void main() {
  // ─── Each known status renders the matching stub ──────────────────────
  final cases = <(BookingStatus, Type)>[
    (BookingStatus.awaiting, AwaitingBodyStub),
    (BookingStatus.confirmed, ConfirmedBodyStub),
    (BookingStatus.enRoute, EnRouteBodyStub),
    (BookingStatus.arrived, ArrivedBodyStub),
    (BookingStatus.inspecting, InspectingBodyStub),
    (BookingStatus.quoted, QuotedBodyStub),
    (BookingStatus.inProgress, InProgressBodyStub),
    (BookingStatus.completed, CompletedBodyStub),
    (BookingStatus.completedInspectionOnly, CompletedInspectionOnlyBodyStub),
    (BookingStatus.cancelled, CancelledBodyStub),
    (BookingStatus.rejected, RejectedBodyStub),
    (BookingStatus.noShow, NoShowBodyStub),
    (BookingStatus.disputed, DisputedBodyStub),
    // pending + unknown both fall through to UnknownBodyStub.
    (BookingStatus.pending, UnknownBodyStub),
    (BookingStatus.unknown, UnknownBodyStub),
  ];

  for (final (status, expectedType) in cases) {
    testWidgets('${status.name} renders ${expectedType.toString()}',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BodySlot(booking: _bookingFor(status))),
      ));
      expect(
        find.byWidgetPredicate((w) => w.runtimeType == expectedType),
        findsOneWidget,
        reason: '${status.name} should render $expectedType',
      );
    });
  }
}
