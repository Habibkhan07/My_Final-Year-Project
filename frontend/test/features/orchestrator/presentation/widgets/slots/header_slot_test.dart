// Widget tests for `HeaderSlot`.
//
// Regression vectors:
//   * "Continued on #N" link only appears when childBookingId is set
//     AND status == CANCELLED (#B-42). Without this, a user landing on
//     a defunct original booking after a reschedule has no forward path.
//   * "Rescheduled from #N" line for parent-id (sanity guard).
//   * Counterparty name flips by viewerRole (customer sees tech name,
//     tech sees customer full name).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/slots/header_slot.dart';
import 'package:go_router/go_router.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking({
  String status = 'CONFIRMED',
  int? parentBookingId,
  int? childBookingId,
  int currentUserId = 7,
}) {
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(bookingDetailJson(
      status: status,
      parentBookingId: parentBookingId,
      childBookingId: childBookingId,
    )),
    currentUserId: currentUserId,
  );
}

Widget _wrap(Widget child) {
  // Real GoRouter so `GoRouter.of(context)` resolves. The slot itself
  // never navigates during render — only on tap — but the lookup is
  // performed lazily by the TextButton's onPressed.
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(path: '/host', builder: (_, _) => Scaffold(body: child)),
      GoRoute(
        path: '/booking/:job_id',
        builder: (_, state) => Scaffold(
          body: Text(
              'CHILD ${state.pathParameters['job_id']}',
              key: const ValueKey('child-screen')),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('HeaderSlot', () {
    testWidgets(
        'shows "Continued on #N" link when CANCELLED + childBookingId set',
        (tester) async {
      // The exact precondition: this booking is the cancelled parent of
      // a reschedule chain. The user MUST have a forward path.
      final booking = _booking(status: 'CANCELLED', childBookingId: 123);
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.text('Continued on #123'), findsOneWidget);
    });

    testWidgets(
        'omits the link when childBookingId is null even on CANCELLED',
        (tester) async {
      final booking = _booking(status: 'CANCELLED');
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.textContaining('Continued on'), findsNothing);
    });

    testWidgets(
        'omits the link when childBookingId is set but status is not CANCELLED',
        (tester) async {
      // A live booking with a child id is unusual but possible during
      // intermediate state. Don't surface a forward link mid-job — the
      // user is on the active booking already.
      final booking = _booking(status: 'CONFIRMED', childBookingId: 123);
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.textContaining('Continued on'), findsNothing);
    });

    testWidgets('tap on "Continued on #N" navigates to /booking/<child>',
        (tester) async {
      final booking = _booking(status: 'CANCELLED', childBookingId: 456);
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));

      await tester.tap(find.text('Continued on #456'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('child-screen')), findsOneWidget);
      expect(find.text('CHILD 456'), findsOneWidget);
    });

    testWidgets('shows "Rescheduled from #N" when parentBookingId is set',
        (tester) async {
      final booking = _booking(parentBookingId: 41);
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.text('Rescheduled from #41'), findsOneWidget);
    });

    testWidgets('customer view shows technician display name', (tester) async {
      // currentUserId == customer.id (fixture default 7) → viewerRole
      // is customer → counterparty is the technician.
      final booking = _booking();
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.text('Ali Raza'), findsOneWidget);
    });

    testWidgets('technician view shows customer full name', (tester) async {
      // currentUserId != customer.id (7) → viewerRole is technician →
      // counterparty is the customer.
      final booking = _booking(currentUserId: 555);
      await tester.pumpWidget(_wrap(HeaderSlot(booking: booking)));
      expect(find.text('Sara Customer'), findsOneWidget);
    });
  });
}
