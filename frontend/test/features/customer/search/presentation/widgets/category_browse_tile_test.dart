import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/features/customer/search/presentation/widgets/category_browse_tile.dart';

void main() {
  group('CategoryBrowseTile', () {
    testWidgets('renders category name and triggers onTap', (
      WidgetTester tester,
    ) async {
      const String testCategoryName = 'Electrician';
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryBrowseTile(
              name: testCategoryName,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify category name is displayed
      expect(find.text(testCategoryName), findsOneWidget);

      // Tap the tile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify the onTap callback is fired
      expect(tapped, isTrue);
    });

    testWidgets('renders fallback icon when iconUrl is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryBrowseTile(name: 'Test', iconUrl: null, onTap: () {}),
          ),
        ),
      );

      // Expect the default category icon
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders CachedNetworkImage when iconUrl is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryBrowseTile(
              name: 'Test',
              iconUrl: 'https://example.com/icon.png',
              onTap: () {},
            ),
          ),
        ),
      );

      // CachedNetworkImage should be present
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
