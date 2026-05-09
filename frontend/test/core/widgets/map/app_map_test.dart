import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/widgets/map/app_map.dart';

void main() {
  const tCenter = LatLng(33.6844, 73.0479);

  testWidgets('AppMap renders FlutterMap and TileLayer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppMap(initialCenter: tCenter)),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);
  });

  testWidgets('AppMap renders additional children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMap(
            initialCenter: tCenter,
            children: [MarkerLayer(markers: [])],
          ),
        ),
      ),
    );

    expect(find.byType(MarkerLayer), findsOneWidget);
  });
}
