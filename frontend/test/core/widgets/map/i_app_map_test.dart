import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MapMarker equality', () {
    test('same fields → equal + same hashCode', () {
      const a = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
        rotationDegrees: 90,
      );
      const b = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
        rotationDegrees: 90,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different rotation → not equal', () {
      const a = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
      );
      const b = MapMarker(
        id: 'tech',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.technicianMoving,
        rotationDegrees: 1,
      );
      expect(a, isNot(equals(b)));
    });

    test('different position → not equal', () {
      const a = MapMarker(
        id: 'cust',
        position: LatLng(31.5, 74.3),
        kind: MarkerKind.customer,
      );
      const b = MapMarker(
        id: 'cust',
        position: LatLng(31.6, 74.3),
        kind: MarkerKind.customer,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('MapPolyline equality', () {
    test('same points list → equal', () {
      const points = [LatLng(31.5, 74.3), LatLng(31.6, 74.4)];
      const a = MapPolyline(id: 'route', points: points, color: Colors.blue);
      const b = MapPolyline(id: 'route', points: points, color: Colors.blue);
      expect(a, equals(b));
    });

    test('different point order → not equal', () {
      const a = MapPolyline(
        id: 'route',
        points: [LatLng(31.5, 74.3), LatLng(31.6, 74.4)],
        color: Colors.blue,
      );
      const b = MapPolyline(
        id: 'route',
        points: [LatLng(31.6, 74.4), LatLng(31.5, 74.3)],
        color: Colors.blue,
      );
      expect(a, isNot(equals(b)));
    });

    test('different stroke width → not equal', () {
      const a = MapPolyline(
        id: 'route',
        points: [LatLng(31.5, 74.3)],
        color: Colors.blue,
        strokeWidth: 6,
      );
      const b = MapPolyline(
        id: 'route',
        points: [LatLng(31.5, 74.3)],
        color: Colors.blue,
        strokeWidth: 4,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
