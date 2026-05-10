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

    // Audit M-3 (Batch C): cache key now includes devicePixelRatio.
    // Pre-fix the cache was keyed only on `MarkerKind`, so a 3x device
    // would reuse the descriptor rendered at the default 2.0 dpr —
    // marker visibly small on 3x phones. Same kind + different dpr
    // must produce different descriptors.
    testWidgets(
      'cache distinguishes same kind at different devicePixelRatios',
      (tester) async {
        await tester.runAsync(() async {
          final at2x = await LiveMarkerFactory.buildGoogleMarker(
            MarkerKind.customer,
            devicePixelRatio: 2.0,
          );
          final at3x = await LiveMarkerFactory.buildGoogleMarker(
            MarkerKind.customer,
            devicePixelRatio: 3.0,
          );
          // Different dpr → different descriptor (NOT identical).
          expect(identical(at2x, at3x), isFalse);

          // But same kind + same dpr → cache hit.
          final at2xAgain = await LiveMarkerFactory.buildGoogleMarker(
            MarkerKind.customer,
            devicePixelRatio: 2.0,
          );
          expect(identical(at2x, at2xAgain), isTrue);
        });
      },
    );
  });
}
