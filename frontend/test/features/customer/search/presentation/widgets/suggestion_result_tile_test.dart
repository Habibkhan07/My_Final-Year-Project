import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/search/presentation/widgets/suggestion_result_tile.dart';

void main() {
  group('SuggestionResultTile', () {
    testWidgets('renders title and category correctly', (
      WidgetTester tester,
    ) async {
      const String testTitle = 'Fix Leaking Pipe';
      const String testCategory = 'Plumbing';
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionResultTile(
              title: testTitle,
              categoryName: testCategory,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Icons also render as RichText, so we iterate over all RichTexts
      final richTextWidgets = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      bool foundMatchingText = false;

      for (final richText in richTextWidgets) {
        final textSpan = richText.text as TextSpan?;
        if (textSpan != null &&
            textSpan.toPlainText() == '$testTitle • $testCategory') {
          foundMatchingText = true;
          break;
        }
      }

      expect(foundMatchingText, isTrue);

      // Verify icons are present
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.arrow_outward), findsOneWidget);

      // Tap the tile
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify the onTap callback is fired
      expect(tapped, isTrue);
    });
  });
}
