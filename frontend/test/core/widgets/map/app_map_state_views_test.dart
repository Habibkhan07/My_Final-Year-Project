import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/app_map_state_views.dart';

void main() {
  testWidgets('AppMapSkeleton renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMapSkeleton(),
        ),
      ),
    );

    // Verify presence of grey placeholder and card handle
    expect(find.byType(AppMapSkeleton), findsOneWidget);
    expect(find.descendant(of: find.byType(AppMapSkeleton), matching: find.byType(Stack)), findsAtLeastNWidgets(1));
    expect(find.byType(Column), findsOneWidget);
  });

  testWidgets('AppMapErrorView renders message and retry button', (tester) async {
    bool retryCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMapErrorView(
            message: 'Map Load Failed',
            onRetry: () => retryCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Map Load Failed'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    expect(retryCalled, isTrue);
  });
}
