import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/widgets/map/location_picker.dart';

void main() {
  const tCenter = LatLng(33.6844, 73.0479);

  testWidgets('LocationPicker renders fixed center pin by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            initialCenter: tCenter,
            onLocationChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.location_pin), findsOneWidget);
  });

  testWidgets('LocationPicker allows hiding center pin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            initialCenter: tCenter,
            onLocationChanged: (_) {},
            showCenterPin: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.location_pin), findsNothing);
  });

  testWidgets('LocationPicker renders bottomCard and overlay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            initialCenter: tCenter,
            onLocationChanged: (_) {},
            bottomCard: const Text('Bottom Card'),
            overlay: const Text('Overlay Widget'),
          ),
        ),
      ),
    );

    expect(find.text('Bottom Card'), findsOneWidget);
    expect(find.text('Overlay Widget'), findsOneWidget);
  });

  testWidgets('LocationPicker allows custom pin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(
            initialCenter: tCenter,
            onLocationChanged: (_) {},
            pin: const Icon(Icons.home, key: Key('custom_pin')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom_pin')), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsNothing);
  });
}
