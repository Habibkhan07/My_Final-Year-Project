// Unit tests for `GoogleAppMapInternals` (audit H12 / T-1 / M-9).
//
// `_GoogleAppMapState` itself is not testable as a pure widget today —
// `gmaps.GoogleMap` mounts a platform view that needs the
// `google_maps_flutter` Android / iOS host alive, and
// `_maybeApplyCamera` awaits a controller completer that the host
// completes via `onMapCreated`. Both happen on a real device only.
//
// Until a controller-injection seam lands (tracked alongside H13's
// `IForegroundTaskBackend` work — same family of static-API → port
// refactor), the testable surface of `google_app_map.dart` is the
// pure-function helpers and the marker-resolution future-merge. This
// suite covers all four:
//   • `markersEqual`  — short-circuit + field-equal compare.
//   • `listsAreSame`  — null-handling + per-point compare.
//   • `computeBounds` — min/max sweep + single-point degenerate.
//   • `resolveAllMarkers` — Future.wait merge contract.
//
// The `_programmaticMoveInFlight` flag and the camera-target-vs-bounds
// priority remain unverified by automation today; that's the
// flag-tracked deferral.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/google_app_map.dart';
import 'package:frontend/core/widgets/map/i_app_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

void main() {
  group('GoogleAppMapInternals.markersEqual', () {
    test('identical references → true (cheap short-circuit)', () {
      const list = <MapMarker>[
        MapMarker(
          id: 'tech',
          position: LatLng(31.5, 74.3),
          kind: MarkerKind.technicianMoving,
        ),
      ];
      expect(GoogleAppMapInternals.markersEqual(list, list), isTrue);
    });

    test('different lengths → false', () {
      const a = <MapMarker>[
        MapMarker(
          id: 'a',
          position: LatLng(0, 0),
          kind: MarkerKind.customer,
        ),
      ];
      const b = <MapMarker>[];
      expect(GoogleAppMapInternals.markersEqual(a, b), isFalse);
    });

    test('field-equal but different references → true', () {
      // Without this branch, every parent rebuild that produced a
      // structurally identical list (the common case during a 5s GPS
      // tween) would trigger a marker re-resolve and visual flicker.
      //
      // Build the lists at runtime via `List.of(...)` so Dart's
      // const-canonicalisation does not collapse them into the same
      // reference (which would let an `identical()` short-circuit
      // mask a missing field-equal compare).
      final a = List<MapMarker>.of(const [
        MapMarker(
          id: 'tech',
          position: LatLng(31.5, 74.3),
          kind: MarkerKind.technicianMoving,
          rotationDegrees: 90,
        ),
      ]);
      final b = List<MapMarker>.of(const [
        MapMarker(
          id: 'tech',
          position: LatLng(31.5, 74.3),
          kind: MarkerKind.technicianMoving,
          rotationDegrees: 90,
        ),
      ]);
      expect(identical(a, b), isFalse);
      expect(GoogleAppMapInternals.markersEqual(a, b), isTrue);
    });

    test('one field differs → false (e.g. rotation)', () {
      const a = <MapMarker>[
        MapMarker(
          id: 'tech',
          position: LatLng(31.5, 74.3),
          kind: MarkerKind.technicianMoving,
          rotationDegrees: 90,
        ),
      ];
      const b = <MapMarker>[
        MapMarker(
          id: 'tech',
          position: LatLng(31.5, 74.3),
          kind: MarkerKind.technicianMoving,
          rotationDegrees: 91,
        ),
      ];
      expect(GoogleAppMapInternals.markersEqual(a, b), isFalse);
    });

    test('order matters — same elements, swapped → false', () {
      const m1 = MapMarker(
        id: 'a',
        position: LatLng(0, 0),
        kind: MarkerKind.customer,
      );
      const m2 = MapMarker(
        id: 'b',
        position: LatLng(1, 1),
        kind: MarkerKind.technicianMoving,
      );
      expect(
        GoogleAppMapInternals.markersEqual(const [m1, m2], const [m2, m1]),
        isFalse,
      );
    });
  });

  group('GoogleAppMapInternals.listsAreSame', () {
    test('both null → true', () {
      expect(GoogleAppMapInternals.listsAreSame(null, null), isTrue);
    });

    test('one null → false', () {
      expect(
        GoogleAppMapInternals.listsAreSame(
          null,
          const <LatLng>[LatLng(0, 0)],
        ),
        isFalse,
      );
      expect(
        GoogleAppMapInternals.listsAreSame(
          const <LatLng>[LatLng(0, 0)],
          null,
        ),
        isFalse,
      );
    });

    test('identical references → true (cheap short-circuit)', () {
      const list = <LatLng>[LatLng(31.5, 74.3)];
      expect(GoogleAppMapInternals.listsAreSame(list, list), isTrue);
    });

    test('different lengths → false', () {
      expect(
        GoogleAppMapInternals.listsAreSame(
          const <LatLng>[LatLng(0, 0)],
          const <LatLng>[LatLng(0, 0), LatLng(1, 1)],
        ),
        isFalse,
      );
    });

    test('component-equal but different references → true', () {
      // Built non-const so const-canonicalisation does not collapse
      // them into the same reference (would short-circuit the test).
      final a = List<LatLng>.of(const [LatLng(31.5, 74.3), LatLng(31.6, 74.4)]);
      final b = List<LatLng>.of(const [LatLng(31.5, 74.3), LatLng(31.6, 74.4)]);
      expect(identical(a, b), isFalse);
      expect(GoogleAppMapInternals.listsAreSame(a, b), isTrue);
    });

    test('latitude differs → false', () {
      expect(
        GoogleAppMapInternals.listsAreSame(
          const <LatLng>[LatLng(31.5, 74.3)],
          const <LatLng>[LatLng(31.50001, 74.3)],
        ),
        isFalse,
      );
    });

    test('longitude differs → false', () {
      expect(
        GoogleAppMapInternals.listsAreSame(
          const <LatLng>[LatLng(31.5, 74.3)],
          const <LatLng>[LatLng(31.5, 74.30001)],
        ),
        isFalse,
      );
    });
  });

  group('GoogleAppMapInternals.computeBounds', () {
    test(
      'two points → bounding box from min/max of each axis',
      () {
        final bounds = GoogleAppMapInternals.computeBounds(
          const <LatLng>[LatLng(31.5, 74.3), LatLng(31.6, 74.4)],
        );
        expect(bounds.southwest.latitude, 31.5);
        expect(bounds.southwest.longitude, 74.3);
        expect(bounds.northeast.latitude, 31.6);
        expect(bounds.northeast.longitude, 74.4);
      },
    );

    test(
      'unsorted points → still picks correct min/max across the sweep',
      () {
        final bounds = GoogleAppMapInternals.computeBounds(
          const <LatLng>[
            LatLng(31.6, 74.3),
            LatLng(31.4, 74.5),
            LatLng(31.5, 74.2),
            LatLng(31.55, 74.45),
          ],
        );
        expect(bounds.southwest.latitude, 31.4);
        expect(bounds.southwest.longitude, 74.2);
        expect(bounds.northeast.latitude, 31.6);
        expect(bounds.northeast.longitude, 74.5);
      },
    );

    test(
      'single point → degenerate bounds where SW == NE (callers tolerate)',
      () {
        final bounds = GoogleAppMapInternals.computeBounds(
          const <LatLng>[LatLng(31.5, 74.3)],
        );
        expect(bounds.southwest.latitude, bounds.northeast.latitude);
        expect(bounds.southwest.longitude, bounds.northeast.longitude);
      },
    );

    test('empty input → throws StateError (caller must gate)', () {
      expect(
        () => GoogleAppMapInternals.computeBounds(const <LatLng>[]),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('GoogleAppMapInternals.resolveAllMarkers', () {
    test('empty input → empty Set, resolveIcon never called', () async {
      var resolveCalls = 0;
      final result = await GoogleAppMapInternals.resolveAllMarkers(
        const <MapMarker>[],
        resolveIcon: (_) async {
          resolveCalls++;
          return gmaps.BitmapDescriptor.defaultMarker;
        },
      );
      expect(result, isEmpty);
      expect(resolveCalls, 0);
    });

    test(
      'all icons must resolve before any output emitted (Future.wait merge)',
      () async {
        // The contract: tests can fail this assertion only if the
        // helper drops the Future.wait and emits eagerly. Without
        // this, the marker layer would visually pop in as descriptors
        // landed individually — exactly the audit T-1 concern.
        final completer1 = Completer<gmaps.BitmapDescriptor>();
        final completer2 = Completer<gmaps.BitmapDescriptor>();
        final pending = <MarkerKind, Completer<gmaps.BitmapDescriptor>>{
          MarkerKind.customer: completer1,
          MarkerKind.technicianMoving: completer2,
        };

        final future = GoogleAppMapInternals.resolveAllMarkers(
          const <MapMarker>[
            MapMarker(
              id: 'a',
              position: LatLng(0, 0),
              kind: MarkerKind.customer,
            ),
            MapMarker(
              id: 'b',
              position: LatLng(1, 1),
              kind: MarkerKind.technicianMoving,
            ),
          ],
          resolveIcon: (kind) => pending[kind]!.future,
        );

        var done = false;
        future.then((_) => done = true);

        // Resolve only one — future must NOT complete yet.
        completer1.complete(gmaps.BitmapDescriptor.defaultMarker);
        await Future<void>.delayed(Duration.zero);
        expect(done, isFalse);

        // Resolve the second — future completes now.
        completer2.complete(gmaps.BitmapDescriptor.defaultMarker);
        final result = await future;
        expect(result, hasLength(2));
      },
    );

    test(
      'resolved marker carries position, rotation, id from the source MapMarker',
      () async {
        final result = await GoogleAppMapInternals.resolveAllMarkers(
          const <MapMarker>[
            MapMarker(
              id: 'tech-9',
              position: LatLng(31.5204, 74.3587),
              kind: MarkerKind.technicianMoving,
              rotationDegrees: 145,
            ),
          ],
          resolveIcon: (_) async => gmaps.BitmapDescriptor.defaultMarker,
        );

        expect(result, hasLength(1));
        final marker = result.first;
        expect(marker.markerId.value, 'tech-9');
        expect(marker.position.latitude, closeTo(31.5204, 1e-6));
        expect(marker.position.longitude, closeTo(74.3587, 1e-6));
        expect(marker.rotation, 145);
        expect(marker.flat, isTrue);
      },
    );

    test(
      'resolveIcon called once per input marker, in order',
      () async {
        final calls = <MarkerKind>[];
        await GoogleAppMapInternals.resolveAllMarkers(
          const <MapMarker>[
            MapMarker(
              id: 'a',
              position: LatLng(0, 0),
              kind: MarkerKind.customer,
            ),
            MapMarker(
              id: 'b',
              position: LatLng(0, 0),
              kind: MarkerKind.technicianStopped,
            ),
            MapMarker(
              id: 'c',
              position: LatLng(0, 0),
              kind: MarkerKind.technicianMoving,
            ),
          ],
          resolveIcon: (kind) async {
            calls.add(kind);
            return gmaps.BitmapDescriptor.defaultMarker;
          },
        );
        expect(calls, [
          MarkerKind.customer,
          MarkerKind.technicianStopped,
          MarkerKind.technicianMoving,
        ]);
      },
    );
  });
}
