// Widget tests for `RatingStarsRow`.
//
// CLAUDE.md widget-layer rule: inject hardcoded state (here, the
// integer rating), assert text/icons render correctly. No mocked
// network — this is a pure presentational component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/review/rating_stars_row.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders 5 stars regardless of rating', (tester) async {
    await tester.pumpWidget(
      wrap(RatingStarsRow(rating: null, onChanged: (_) {})),
    );
    // All star icons render — empty when rating is null.
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('fills the first N stars when rating=N', (tester) async {
    await tester.pumpWidget(
      wrap(RatingStarsRow(rating: 3, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(2));
  });

  testWidgets('all stars filled when rating=5', (tester) async {
    await tester.pumpWidget(
      wrap(RatingStarsRow(rating: 5, onChanged: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
  });

  testWidgets('tapping a star fires onChanged with 1-based index',
      (tester) async {
    int? captured;
    await tester.pumpWidget(
      wrap(RatingStarsRow(rating: null, onChanged: (v) => captured = v)),
    );

    // Tap the 4th star (index 3, value 4).
    final stars = find.byIcon(Icons.star_border_rounded);
    await tester.tap(stars.at(3));
    await tester.pumpAndSettle();
    expect(captured, 4);
  });

  testWidgets('star buttons expose accessibility labels', (tester) async {
    await tester.pumpWidget(
      wrap(RatingStarsRow(rating: null, onChanged: (_) {})),
    );
    expect(find.bySemanticsLabel('1 star'), findsOneWidget);
    expect(find.bySemanticsLabel('5 stars'), findsOneWidget);
  });
}
