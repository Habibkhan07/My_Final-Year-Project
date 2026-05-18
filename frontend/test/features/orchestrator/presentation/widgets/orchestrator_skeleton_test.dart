// Widget tests for `OrchestratorSkeleton`.
//
// Contract:
//   * Renders without error and stays in the tree across pumps (proves
//     the looping AnimationController doesn't break `pumpAndSettle`
//     under the test binding — `shouldLoopAnimations()` returns false
//     in the test isolate so the controller never repeats).
//   * Renders a ShaderMask — locks the shimmer pipeline. (The header
//     band used to be a `ClipPath`-clipped curved swoop; chunk 5
//     flattened it to a plain `Container` to match the flattened real
//     header, so the ClipPath assert is gone.)
//   * Disposes cleanly when removed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/orchestrator_skeleton.dart';

/// Phone-shaped surface so the skeleton (matching the real screen
/// layout) doesn't overflow the default landscape-shaped test viewport.
void _useRealisticPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('OrchestratorSkeleton', () {
    testWidgets('renders shimmer without hanging the binding', (
      tester,
    ) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OrchestratorSkeleton())),
      );
      // If the controller was repeating under the test binding the
      // following call would deadlock — locks the loop-guard contract.
      await tester.pumpAndSettle();
      expect(find.byType(OrchestratorSkeleton), findsOneWidget);
      expect(find.byType(ShaderMask), findsWidgets);
    });

    testWidgets('disposes cleanly when removed from the tree', (tester) async {
      _useRealisticPhoneSurface(tester);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OrchestratorSkeleton())),
      );
      await tester.pumpAndSettle();
      // Replace with an empty scaffold — the dispose path will run.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrchestratorSkeleton), findsNothing);
    });
  });
}
