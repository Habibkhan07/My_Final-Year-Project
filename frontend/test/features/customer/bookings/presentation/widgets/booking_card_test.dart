// Booking card render permutations + interaction.
//
// The card is the dumb-UI seam: server emits `ui.badgeText`,
// `ui.badgeTone`, `ui.headline`, `price.uiLabel`, `price.context`,
// `addressLabel`. The widget renders those verbatim and switches on
// `ui.badgeTone` for design tokens — never on raw [BookingStatus] for
// copy. These tests pin the contract by feeding hand-rolled entities
// for each status row in §5.8 and asserting the text + decorations
// render correctly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/domain/entities/customer_booking.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_card.dart';
import 'package:go_router/go_router.dart';

CustomerBooking _booking({
  int id = 42,
  BookingStatus status = BookingStatus.confirmed,
  BookingUiTone tone = BookingUiTone.positive,
  String badgeText = 'Confirmed',
  String headline = 'Confirmed with Ahmed Khan',
  String? profilePictureUrl,
  String? addressLabel = 'Home — DHA Phase 5, Lahore',
  String priceContext = 'Fixed Price',
  String priceLabel = 'Rs. 2,500',
  String techName = 'Ahmed Khan',
}) {
  return CustomerBooking(
    id: id,
    status: status,
    service: const BookingService(name: 'AC Repair', iconName: 'ac_repair'),
    technician: BookingTechnician(
      id: 7,
      displayName: techName,
      profilePictureUrl: profilePictureUrl,
    ),
    addressLabel: addressLabel,
    scheduledStart: DateTime(2026, 5, 6, 15, 0),
    scheduledEnd: DateTime(2026, 5, 6, 17, 0),
    createdAt: DateTime(2026, 5, 5, 9, 0),
    price: BookingPrice(
      amount: 2500,
      context: priceContext,
      uiLabel: priceLabel,
    ),
    ui: BookingUi(badgeText: badgeText, badgeTone: tone, headline: headline),
  );
}

GoRouter _router(Widget cardHost, {ValueChanged<int>? onPushed}) {
  return GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        path: '/list',
        builder: (_, _) => Scaffold(body: cardHost),
      ),
      GoRoute(
        path: '/booking/:job_id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['job_id']!);
          onPushed?.call(id);
          return Scaffold(body: Center(child: Text('detail-$id')));
        },
      ),
    ],
  );
}

Widget _wrap(CustomerBooking booking, {BookingSegment? segment}) {
  final card = BookingCard(
    booking: booking,
    segment: segment ?? BookingSegment.upcoming,
    serverTime: DateTime(2026, 5, 5, 12, 0),
  );
  return MaterialApp.router(routerConfig: _router(card));
}

void main() {
  group('BookingCard — status row renders', () {
    testWidgets('AWAITING', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.awaiting,
            tone: BookingUiTone.warning,
            badgeText: 'Awaiting tech',
            headline: 'Waiting for Ahmed Khan to confirm',
          ),
        ),
      );
      expect(find.text('AWAITING TECH'), findsOneWidget);
      expect(find.text('Waiting for Ahmed Khan to confirm'), findsOneWidget);
    });

    testWidgets('CONFIRMED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.confirmed,
            tone: BookingUiTone.positive,
            badgeText: 'Confirmed',
            headline: 'Confirmed with Ahmed Khan',
          ),
        ),
      );
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Confirmed with Ahmed Khan'), findsOneWidget);
    });

    testWidgets('COMPLETED', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.completed,
            tone: BookingUiTone.positive,
            badgeText: 'Completed',
            headline: 'Completed by Ahmed Khan',
          ),
          segment: BookingSegment.past,
        ),
      );
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Completed by Ahmed Khan'), findsOneWidget);
    });

    testWidgets('CANCELLED with neutral tone (overrides Stitch)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.cancelled,
            tone: BookingUiTone.neutral,
            badgeText: 'Cancelled',
            headline: 'You cancelled this booking',
          ),
          segment: BookingSegment.past,
        ),
      );
      expect(find.text('CANCELLED'), findsOneWidget);
      expect(find.text('You cancelled this booking'), findsOneWidget);
    });

    testWidgets('REJECTED — technician_declined', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.rejected,
            tone: BookingUiTone.negative,
            badgeText: 'Unavailable',
            headline: "Ahmed Khan couldn't take this",
          ),
          segment: BookingSegment.past,
        ),
      );
      expect(find.text('UNAVAILABLE'), findsOneWidget);
      expect(find.text("Ahmed Khan couldn't take this"), findsOneWidget);
    });

    testWidgets('REJECTED — sla_timeout', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.rejected,
            tone: BookingUiTone.negative,
            badgeText: 'Timed out',
            headline: "Ahmed Khan didn't respond in time",
          ),
          segment: BookingSegment.past,
        ),
      );
      expect(find.text('TIMED OUT'), findsOneWidget);
      expect(find.text("Ahmed Khan didn't respond in time"), findsOneWidget);
    });

    testWidgets('PENDING (legacy)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.pending,
            tone: BookingUiTone.neutral,
            badgeText: 'Pending',
            headline: 'Booking is being prepared',
          ),
        ),
      );
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Booking is being prepared'), findsOneWidget);
    });
  });

  group('BookingCard — nullable / empty fields', () {
    testWidgets('addressLabel == null hides the address row', (tester) async {
      await tester.pumpWidget(_wrap(_booking(addressLabel: null)));
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('profilePictureUrl == null shows initials avatar', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_booking(profilePictureUrl: null)));
      expect(find.text('AK'), findsOneWidget);
    });

    testWidgets('price.context == "" hides the context icon + text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_booking(priceContext: '')));
      expect(find.byIcon(Icons.payments_outlined), findsNothing);
      // The price label itself still renders.
      expect(find.text('Rs. 2,500'), findsOneWidget);
    });
  });

  group('BookingCard — interactions', () {
    testWidgets('tap pushes /booking/{id}', (tester) async {
      int? pushedId;
      final booking = _booking(id: 42);
      final card = BookingCard(
        booking: booking,
        segment: BookingSegment.upcoming,
        serverTime: DateTime(2026, 5, 5, 12, 0),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _router(card, onPushed: (id) => pushedId = id),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(pushedId, 42);
      expect(find.text('detail-42'), findsOneWidget);
    });

    testWidgets('hero tag is "booking-icon-{id}"', (tester) async {
      await tester.pumpWidget(_wrap(_booking(id: 99)));
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'booking-icon-99');
    });
  });

  group('BookingCard — Cancelled visual treatment', () {
    testWidgets('cancelled card wraps body in 0.85 opacity', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booking(
            status: BookingStatus.cancelled,
            tone: BookingUiTone.neutral,
            badgeText: 'Cancelled',
            headline: 'You cancelled this booking',
          ),
          segment: BookingSegment.past,
        ),
      );
      // The outer Opacity(0.85) wraps the card body for cancelled status.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, contains(0.85));
    });

    testWidgets(
      'address row renders with line-through decoration when cancelled',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _booking(
              status: BookingStatus.cancelled,
              tone: BookingUiTone.neutral,
              badgeText: 'Cancelled',
              headline: 'You cancelled this booking',
              addressLabel: 'Home — DHA Phase 5',
            ),
            segment: BookingSegment.past,
          ),
        );
        final addressText = tester.widget<Text>(
          find.text('Home — DHA Phase 5'),
        );
        expect(addressText.style?.decoration, TextDecoration.lineThrough);
      },
    );
  });
}
