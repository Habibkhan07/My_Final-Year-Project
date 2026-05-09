import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/bookings/presentation/widgets/booking_tech_avatar.dart';
import 'package:network_image_mock/network_image_mock.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('BookingTechAvatar', () {
    testWidgets('renders network image when imageUrl is non-null', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          _wrap(
            const BookingTechAvatar(
              imageUrl: 'https://example.com/pic.jpg',
              displayName: 'Ahmed Khan',
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });
    });

    testWidgets('renders initials fallback when imageUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BookingTechAvatar(imageUrl: null, displayName: 'Ahmed Khan'),
        ),
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('AK'), findsOneWidget);
    });

    testWidgets('renders initials fallback when imageUrl is empty string', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BookingTechAvatar(imageUrl: '   ', displayName: 'Ahmed Khan'),
        ),
      );
      expect(find.text('AK'), findsOneWidget);
    });

    testWidgets('single-name input → single-character initial', (tester) async {
      await tester.pumpWidget(
        _wrap(const BookingTechAvatar(imageUrl: null, displayName: 'Madonna')),
      );
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('all-whitespace name → empty initials, no crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const BookingTechAvatar(imageUrl: null, displayName: '   ')),
      );
      // Renders cleanly with an empty Text — no exception thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BookingTechAvatar(
            imageUrl: null,
            displayName: 'Ali Raza',
            size: 64,
          ),
        ),
      );
      final box = tester.getSize(find.byType(BookingTechAvatar));
      expect(box.width, 64);
      expect(box.height, 64);
    });
  });
}
