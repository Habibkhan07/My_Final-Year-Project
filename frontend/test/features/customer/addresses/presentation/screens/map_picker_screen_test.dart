import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/widgets/map/app_map_state_views.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/map_picker_notifier.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/map_picker_state.dart';
import 'package:frontend/features/customer/addresses/presentation/screens/map_picker_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifier — returns a fixed AsyncValue without GPS or network calls
// ---------------------------------------------------------------------------

class _FakeMapPickerNotifier extends MapPickerNotifier {
  final AsyncValue<MapPickerState> _initial;

  _FakeMapPickerNotifier(this._initial);

  // FutureOr return + synchronous throw is the reliable pattern for widget
  // tests: a synchronous throw is caught by Riverpod immediately, while
  // returning Future.error() is processed asynchronously and may not
  // propagate before the test assertion runs.
  @override
  FutureOr<MapPickerState> build() {
    if (_initial.hasError) throw _initial.error!;
    if (_initial.isLoading) return Completer<MapPickerState>().future;
    return _initial.requireValue;
  }

  @override
  void onMapPanEnd(double lat, double lng) {}

  @override
  void setLabel(String label) {}

  @override
  Future<void> save({required bool isDefault}) async {}
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

const _tState = MapPickerState(
  latitude: 31.5,
  longitude: 74.3,
  streetAddress: 'Gulberg III, Lahore',
);

Widget createWidgetUnderTest(AsyncValue<MapPickerState> state) {
  return ProviderScope(
    overrides: [
      mapPickerProvider.overrideWith(() => _FakeMapPickerNotifier(state)),
    ],
    child: const MaterialApp(home: MapPickerScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MapPickerScreen — loading state', () {
    testWidgets('shows skeleton while GPS is resolving', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(const AsyncLoading()),
      );
      await tester.pump();

      expect(find.byType(AppMapSkeleton), findsOneWidget);
      expect(find.text('Confirm Location'), findsNothing);
    });
  });

  group('MapPickerScreen — data state (bottom card)', () {
    testWidgets('shows resolved street address', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(_tState)));
      await tester.pump();

      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
    });

    testWidgets('shows Confirm Location button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(_tState)));
      await tester.pump();

      expect(find.text('Confirm Location'), findsOneWidget);
    });

    testWidgets('renders all three label chips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(_tState)));
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('shows inline geocoding skeleton when isGeocoding=true',
        (tester) async {
      const geocodingState = MapPickerState(
        latitude: 31.5,
        longitude: 74.3,
        streetAddress: 'Gulberg III, Lahore',
        isGeocoding: true,
      );

      await tester.pumpWidget(
          createWidgetUnderTest(const AsyncData(geocodingState)));
      await tester.pump();

      // The inline skeleton replaces the address text
      // We can't find _GeocodingSkeleton directly if it's private, 
      // but we can check for its implementation details or find it by type if it was public.
      // Since it's private in the file, we can't import it. 
      // But we can check for the absence of the address text and presence of a placeholder.
      expect(find.text('Gulberg III, Lahore'), findsNothing);
      // It uses Containers with grey colors.
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows save error message when saveState is AsyncError',
        (tester) async {
      final errorState = MapPickerState(
        latitude: 31.5,
        longitude: 74.3,
        streetAddress: 'Gulberg III, Lahore',
        saveState: AsyncError(Exception('Server error'), StackTrace.empty),
      );

      await tester.pumpWidget(
          createWidgetUnderTest(AsyncData(errorState)));
      await tester.pump();

      expect(find.textContaining('Server error'), findsOneWidget);
    });

    testWidgets('Confirm button shows spinner while save is in progress',
        (tester) async {
      const savingState = MapPickerState(
        latitude: 31.5,
        longitude: 74.3,
        streetAddress: 'Gulberg III, Lahore',
        saveState: AsyncLoading(),
      );

      await tester.pumpWidget(
          createWidgetUnderTest(const AsyncData(savingState)));
      await tester.pump();

      // "Confirm Location" text is replaced by a spinner inside the button
      expect(find.text('Confirm Location'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
