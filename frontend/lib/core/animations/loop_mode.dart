import 'package:flutter/widgets.dart';

/// Whether continuous-loop animations should run.
///
/// Returns `false` under `flutter_test`'s `AutomatedTestWidgetsFlutterBinding`
/// so widgets driving infinite `AnimationController.repeat()` loops don't
/// cause `pumpAndSettle()` to hang. Returns `true` in every other
/// environment (debug runs on device, release builds, profile runs).
///
/// Use at the call site instead of unconditionally invoking `repeat()`:
///
/// ```dart
/// if (shouldLoopAnimations()) _pulse.repeat();
/// ```
///
/// Detection is done by `runtimeType.toString()` — the only reliable
/// signal accessible from production code without importing
/// `flutter_test` (which is a dev-dependency). The toString check is a
/// known-stable Flutter pattern.
bool shouldLoopAnimations() {
  try {
    final binding = WidgetsBinding.instance;
    final typeName = binding.runtimeType.toString();
    return !typeName.contains('Test');
  } catch (_) {
    // If the binding isn't initialised yet (which shouldn't happen
    // from a widget's initState but be defensive), default to running.
    return true;
  }
}
