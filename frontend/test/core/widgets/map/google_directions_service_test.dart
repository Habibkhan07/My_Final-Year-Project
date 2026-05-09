import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/directions_failures.dart';
import 'package:frontend/core/widgets/map/google_directions_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const _origin = LatLng(31.5204, 74.3587);
const _destination = LatLng(31.5497, 74.3436);

// Encoded polyline that decodes to a non-empty list of LatLngs. This
// is the standard Google polyline encoding format that
// `flutter_polyline_points` decodes.
const _encodedPolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

const _validBody =
    '''
{
  "status": "OK",
  "routes": [
    {
      "overview_polyline": { "points": "$_encodedPolyline" },
      "legs": [
        {
          "duration": { "value": 540, "text": "9 mins" },
          "duration_in_traffic": { "value": 612, "text": "10 mins" },
          "distance": { "value": 4200, "text": "4.2 km" }
        }
      ]
    }
  ]
}
''';

void main() {
  group('GoogleDirectionsService', () {
    test(
      'happy path: parses polyline + traffic-aware ETA + distance',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'maps.googleapis.com');
          expect(request.url.queryParameters['key'], 'TEST_KEY');
          expect(
            request.url.queryParameters['origin'],
            '${_origin.latitude},${_origin.longitude}',
          );
          expect(request.url.queryParameters['mode'], 'driving');
          expect(request.url.queryParameters['departure_time'], 'now');
          return http.Response(_validBody, 200);
        });
        final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

        final result = await svc.getRoute(
          origin: _origin,
          destination: _destination,
        );

        expect(result.polyline, isNotEmpty);
        // Traffic-aware ETA wins over plain duration when both supplied.
        expect(result.etaSeconds, 612);
        expect(result.distanceMeters, 4200);
      },
    );

    test('falls back to plain duration when traffic value missing', () async {
      final client = MockClient(
        (_) async => http.Response('''
          {
            "status": "OK",
            "routes": [{
              "overview_polyline": { "points": "$_encodedPolyline" },
              "legs": [{
                "duration": { "value": 480, "text": "8 mins" },
                "distance": { "value": 3500 }
              }]
            }]
          }
          ''', 200),
      );
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      final result = await svc.getRoute(
        origin: _origin,
        destination: _destination,
      );

      expect(result.etaSeconds, 480);
      expect(result.distanceMeters, 3500);
    });

    test('raises UnknownDirectionsFailure when API key empty', () async {
      final svc = GoogleDirectionsService(
        MockClient((_) async => fail('client should not be invoked')),
        apiKey: '',
      );

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<UnknownDirectionsFailure>()),
      );
    });

    test('raises DirectionsApiQuotaExceeded on OVER_QUERY_LIMIT', () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"status": "OVER_QUERY_LIMIT", "routes": []}', 200),
      );
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsApiQuotaExceeded>()),
      );
    });

    test('raises DirectionsApiQuotaExceeded on OVER_DAILY_LIMIT', () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"status": "OVER_DAILY_LIMIT", "routes": []}', 200),
      );
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsApiQuotaExceeded>()),
      );
    });

    test('raises DirectionsNoRoute on ZERO_RESULTS', () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"status": "ZERO_RESULTS", "routes": []}', 200),
      );
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsNoRoute>()),
      );
    });

    test('raises UnknownDirectionsFailure on REQUEST_DENIED', () async {
      final client = MockClient(
        (_) async =>
            http.Response('{"status": "REQUEST_DENIED", "routes": []}', 200),
      );
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<UnknownDirectionsFailure>()),
      );
    });

    test('raises DirectionsServerFailure on 5xx', () async {
      final client = MockClient((_) async => http.Response('boom', 503));
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsServerFailure>()),
      );
    });

    test('raises DirectionsNetworkFailure on 4xx', () async {
      final client = MockClient((_) async => http.Response('forbidden', 403));
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<DirectionsNetworkFailure>()),
      );
    });

    test('raises UnknownDirectionsFailure on malformed JSON', () async {
      final client = MockClient((_) async => http.Response('not-json', 200));
      final svc = GoogleDirectionsService(client, apiKey: 'TEST_KEY');

      await expectLater(
        svc.getRoute(origin: _origin, destination: _destination),
        throwsA(isA<UnknownDirectionsFailure>()),
      );
    });
  });
}
