// Widget tests for `TagChipsGrid`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/domain/entities/review.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/review/tag_chips_grid.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const tags = [
    PredefinedTag(key: 'on_time', label: 'On time'),
    PredefinedTag(key: 'polite', label: 'Polite'),
  ];

  testWidgets('renders the chip labels', (tester) async {
    await tester.pumpWidget(wrap(TagChipsGrid(
      tags: tags,
      selectedKeys: const {},
      onToggle: (_) {},
    )));
    expect(find.text('On time'), findsOneWidget);
    expect(find.text('Polite'), findsOneWidget);
  });

  testWidgets('empty tags renders SizedBox.shrink', (tester) async {
    await tester.pumpWidget(wrap(TagChipsGrid(
      tags: const [],
      selectedKeys: const {},
      onToggle: (_) {},
    )));
    // No labels at all.
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('tapping a chip fires onToggle with key', (tester) async {
    String? captured;
    await tester.pumpWidget(wrap(TagChipsGrid(
      tags: tags,
      selectedKeys: const {},
      onToggle: (k) => captured = k,
    )));

    await tester.tap(find.text('Polite'));
    await tester.pumpAndSettle();
    expect(captured, 'polite');
  });

  testWidgets('renders selected and unselected chips together',
      (tester) async {
    // Visual-state coverage via a smoke test: rendering doesn't throw,
    // both labels appear regardless of selection state. Tap callback
    // coverage is already in the previous test; deeper visual diff
    // testing belongs in golden tests, which the project hasn't set up
    // yet (per CLAUDE.md, integration/E2E is deferred).
    await tester.pumpWidget(wrap(TagChipsGrid(
      tags: tags,
      selectedKeys: const {'on_time'},
      onToggle: (_) {},
    )));
    expect(find.text('On time'), findsOneWidget);
    expect(find.text('Polite'), findsOneWidget);
  });
}
