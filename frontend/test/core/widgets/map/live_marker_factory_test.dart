import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:frontend/core/widgets/map/live_marker_factory.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LiveMarkerFactory.buildOsmMarker', () {
    testWidgets('customer marker shows home_filled icon, no rotation', (
      tester,
    ) async {
      const marker = MapMarker(
        id: 'cust',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.customer,
        rotationDegrees: 90, // ignored for customer kind
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LiveMarkerFactory.buildOsmMarker(marker)),
        ),
      );
      // The icon glyph is the only Icon under the bubble.
      final iconFinder = find.byIcon(Icons.home_filled);
      expect(iconFinder, findsOneWidget);
      // No heading-rotation wrapper for a customer marker.
      expect(find.byKey(LiveMarkerFactory.headingRotationKey), findsNothing);
    });

    testWidgets('moving technician marker shows two_wheeler icon + rotates', (
      tester,
    ) async {
      const marker = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
        rotationDegrees: 45,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LiveMarkerFactory.buildOsmMarker(marker)),
        ),
      );
      expect(find.byIcon(Icons.two_wheeler), findsOneWidget);
      // Heading-rotation wrapper present for non-zero rotation.
      expect(find.byKey(LiveMarkerFactory.headingRotationKey), findsOneWidget);
    });

    testWidgets('moving technician at 0 rotation is NOT wrapped in Transform', (
      tester,
    ) async {
      const marker = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
        rotationDegrees: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LiveMarkerFactory.buildOsmMarker(marker)),
        ),
      );
      expect(find.byIcon(Icons.two_wheeler), findsOneWidget);
      // No rotation when degrees == 0 → skip the wrapper for layout perf.
      expect(find.byKey(LiveMarkerFactory.headingRotationKey), findsNothing);
    });

    testWidgets('stopped technician marker shows directions_walk', (
      tester,
    ) async {
      const marker = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianStopped,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LiveMarkerFactory.buildOsmMarker(marker)),
        ),
      );
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });
  });

  group('LiveMarkerFactory.buildGoogleMarker', () {
    setUp(LiveMarkerFactory.clearCache);

    testWidgets('caches BitmapDescriptors by kind', (tester) async {
      // Run inside a widget pump cycle so the painter has a Flutter
      // engine to talk to (canvas + image conversion).
      await tester.runAsync(() async {
        final a = await LiveMarkerFactory.buildGoogleMarker(
          MarkerKind.customer,
        );
        final b = await LiveMarkerFactory.buildGoogleMarker(
          MarkerKind.customer,
        );
        // Same kind → identical (cache hit).
        expect(identical(a, b), isTrue);

        final c = await LiveMarkerFactory.buildGoogleMarker(
          MarkerKind.technicianMoving,
        );
        // Different kind → different descriptor.
        expect(identical(a, c), isFalse);
      });
    });
  });
}
