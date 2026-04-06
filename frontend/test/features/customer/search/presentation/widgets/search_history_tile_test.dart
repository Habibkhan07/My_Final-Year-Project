import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/search/presentation/widgets/search_history_tile.dart';

void main() {
  group('SearchHistoryTile', () {
    testWidgets('renders query text correctly', (WidgetTester tester) async {
      const String testQuery = 'plumber';
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryTile(
              query: testQuery,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify the query text is displayed
      expect(find.text(testQuery), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.arrow_outward), findsOneWidget);

      // Tap the tile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify the onTap callback is fired
      expect(tapped, isTrue);
    });
  });
}
