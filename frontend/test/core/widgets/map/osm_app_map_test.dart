import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:frontend/core/widgets/map/osm_app_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('OsmAppMap', () {
    testWidgets('renders with no markers / no polylines (empty layers)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OsmAppMap(initialCenter: LatLng(31.5, 74.3))),
        ),
      );
      // FlutterMap mounts even when markers/polylines are empty.
      expect(find.byType(FlutterMap), findsOneWidget);
      // No marker / polyline layers when both lists are empty.
      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('renders MarkerLayer when markers present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OsmAppMap(
              initialCenter: const LatLng(31.5, 74.3),
              markers: const [
                MapMarker(
                  id: 'cust',
                  position: LatLng(31.5, 74.3),
                  kind: MarkerKind.customer,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byIcon(Icons.home_filled), findsOneWidget);
    });

    testWidgets('renders PolylineLayer when polylines present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OsmAppMap(
              initialCenter: LatLng(31.5, 74.3),
              polylines: [
                MapPolyline(
                  id: 'route',
                  points: [LatLng(31.5, 74.3), LatLng(31.6, 74.4)],
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(PolylineLayer), findsOneWidget);
    });

    testWidgets('onUserGesture fires only on user-driven moves', (
      tester,
    ) async {
      var gestureCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OsmAppMap(
              initialCenter: const LatLng(31.5, 74.3),
              onUserGesture: () => gestureCalls++,
            ),
          ),
        ),
      );
      // Initial mount + idle frames should not count as "user gesture."
      await tester.pumpAndSettle();
      expect(gestureCalls, 0);
    });
  });
}
