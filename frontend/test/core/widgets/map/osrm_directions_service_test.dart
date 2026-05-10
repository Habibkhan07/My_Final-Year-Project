import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/directions_failures.dart';
import 'package:frontend/core/widgets/map/osrm_directions_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _origin = LatLng(31.5204, 74.3587);
const _destination = LatLng(31.5497, 74.3436);

const _validResponseBody = '''
{
  "code": "Ok",
  "routes": [
    {
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [74.3587, 31.5204],
          [74.3540, 31.5301],
          [74.3436, 31.5497]
        ]
      },
      "duration": 540,
      "distance": 4200,
      "weight_name": "routability"
    }
  ]
}
''';

void main() {
  group('OsrmDirectionsService', () {
    test('decodes geometry, eta, distance on a 200/Ok response', () async {
      final client = MockClient((request) async {
        // OSRM coords are lng,lat order — this is load-bearing.
        expect(request.url.path, contains('74.3587,31.5204'));
        expect(request.url.path, contains('74.3436,31.5497'));
        expect(request.url.queryParameters['geometries'], 'geojson');
        expect(request.url.queryParameters['overview'], 'full');
        return http.Response(_validResponseBody, 200);
      });
      final svc = OsrmDirectionsService(client);

      final result = await svc.getRoute(
        origin: _origin,
        destination: _destination,
      );

      expect(result.polyline, hasLength(3));
      // GeoJSON is lng,lat — adapter must flip to lat,lng for LatLng.
      expect(result.polyline.first.latitude, 31.5204);
      expect(result.polyline.first.longitude, 74.3587);
      expect(result.etaSeconds, 540);
      expect(result.distanceMeters, 4200);
    });

    test('raises DirectionsServerFailure on 500', () async {
      final client = MockClient((_) async => http.Response('boom', 503));
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsServerFailure>()),
      );
    });

    // Audit P1-1: HTTP-level 4xx now branches on semantics.
    test('raises DirectionsRateLimited on HTTP 429', () async {
      final client = MockClient(
        (_) async => http.Response('rate limited', 429),
      );
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsRateLimited>()),
      );
    });

    test('raises DirectionsNoRoute on HTTP 404', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsNoRoute>()),
      );
    });

    test(
      'raises UnknownDirectionsFailure on other 4xx (e.g. 400)',
      () async {
        final client = MockClient((_) async => http.Response('bad', 400));
        final svc = OsrmDirectionsService(client);

        await expectLater(
          svc.getRoute(origin: _origin, destination: _destination),
          throwsA(isA<UnknownDirectionsFailure>()),
        );
      },
    );

    test('raises DirectionsNoRoute when code != Ok', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'NoRoute', 'routes': []}), 200),
      );
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsNoRoute>()),
      );
    });

    test('raises DirectionsNoRoute on empty routes list', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'code': 'Ok', 'routes': []}), 200),
      );
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsNoRoute>()),
      );
    });

    test('raises UnknownDirectionsFailure on malformed JSON', () async {
      final client = MockClient((_) async => http.Response('not-json', 200));
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<UnknownDirectionsFailure>()),
      );
    });

    test('honours custom baseUrl override', () async {
      var requestedHost = '';
      final client = MockClient((request) async {
        requestedHost = request.url.host;
        return http.Response(_validResponseBody, 200);
      });
      final svc = OsrmDirectionsService(
        client,
        baseUrl: 'https://my.osrm.example',
      );
      await svc.getRoute(origin: _origin, destination: _destination);
      expect(requestedHost, 'my.osrm.example');
    });

    // ────────── T-8 (Batch E): network-level error branches ─────────

    test(
      'T-8 (Batch E) SocketException → DirectionsNetworkFailure',
      () async {
        final client = MockClient((_) async {
          throw const SocketException('host unreachable');
        });
        final svc = OsrmDirectionsService(client);

        await expectLater(
          svc.getRoute(origin: _origin, destination: _destination),
          throwsA(isA<DirectionsNetworkFailure>()),
        );
      },
    );

    test('T-8 (Batch E) timeout → DirectionsNetworkFailure', () async {
      // 8s timeout in production. Non-completing handler triggers it.
      final neverCompletes = Completer<http.Response>();
      final client = MockClient((_) => neverCompletes.future);
      final svc = OsrmDirectionsService(client);

      await expectLater(
        svc
            .getRoute(origin: _origin, destination: _destination)
            .timeout(const Duration(seconds: 10)),
        throwsA(isA<DirectionsNetworkFailure>()),
      );
      neverCompletes.complete(http.Response('', 200));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
