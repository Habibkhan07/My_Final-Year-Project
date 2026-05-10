import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TechLocationRemoteDataSource.postLocation', () {
    test(
      'happy path: 200 → returns true; URL + auth + body shape correct',
      () async {
        late final http.Request capturedRequest;
        final client = MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'published': true, 'transition_fired': null}),
            200,
          );
        });
        final svc = TechLocationRemoteDataSource(client);

        final ok = await svc.postLocation(
          bookingId: 42,
          authToken: 'TEST_TOKEN',
          lat: 31.5204,
          lng: 74.3587,
          accuracyMeters: 8.5,
          heading: 145.0,
        );

        expect(ok, isTrue);
        // URL — sprint meta §24: AppConstants.baseUrl already ends in /api;
        // path must NOT repeat /api.
        expect(capturedRequest.url.path, '/api/bookings/42/tech-location/');
        expect(capturedRequest.method, 'POST');
        expect(capturedRequest.headers['Authorization'], 'Token TEST_TOKEN');
        expect(
          capturedRequest.headers['Content-Type'],
          contains('application/json'),
        );
        // Body — must mirror backend serializer field names.
        final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
        expect(body['lat'], 31.5204);
        expect(body['lng'], 74.3587);
        expect(body['accuracy_meters'], 8.5);
        expect(body['heading'], 145.0);
      },
    );

    // Audit F-18 (Batch A): renamed from the misleading "omits null
    // optional fields (heading/accuracy)". The test pins the OPPOSITE
    // — that Freezed's default `toJson` emits explicit nulls for
    // missing optional fields, and the backend serializer accepts
    // them. Keeping the assertions verbatim; only the name changed.
    test(
      'emits accuracy_meters / heading keys with null when caller omits them',
      () async {
        late final String capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          return http.Response('{}', 200);
        });
        final svc = TechLocationRemoteDataSource(client);

        await svc.postLocation(
          bookingId: 42,
          authToken: 'tok',
          lat: 31.5,
          lng: 74.3,
        );

        final body = jsonDecode(capturedBody) as Map<String, dynamic>;
        expect(body.containsKey('accuracy_meters'), isTrue);
        expect(body['accuracy_meters'], isNull);
        expect(body['heading'], isNull);
      },
    );

    test('429 throttle → returns false (drop frame, no exception)', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 429,
            'code': 'too_many_requests',
            'message': 'GPS frames are limited to 1 per 4 seconds.',
            'errors': {},
          }),
          429,
        ),
      );
      final svc = TechLocationRemoteDataSource(client);

      final ok = await svc.postLocation(
        bookingId: 42,
        authToken: 'tok',
        lat: 31.5,
        lng: 74.3,
      );

      expect(ok, isFalse);
    });

    test('403 not_a_technician → throws HttpFailure with envelope', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 403,
            'code': 'not_a_technician',
            'message': 'Tech-only action.',
            'errors': {},
          }),
          403,
        ),
      );
      final svc = TechLocationRemoteDataSource(client);

      await expectLater(
        svc.postLocation(bookingId: 42, authToken: 'tok', lat: 31.5, lng: 74.3),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.code, 'code', 'not_a_technician'),
        ),
      );
    });

    test('timeout → throws HttpFailure(0, network_timeout)', () async {
      // Audit H3 (F-19/T-7d): the client is configured with an 8s
      // timeout. We can't sleep 8s in a test, so simulate by making
      // the MockClient never respond (Completer never completes) and
      // shrink the wait to a fast assertion. We rely on the fact that
      // `package:http/testing.dart`'s MockClient awaits the handler —
      // a non-completing handler effectively "hangs" until timeout.
      //
      // To keep the suite fast we wrap the call in our own timeout
      // and assert HttpFailure surfaces with the expected envelope.
      final neverCompletes = Completer<http.Response>();
      final client = MockClient((_) => neverCompletes.future);
      final svc = TechLocationRemoteDataSource(client);

      // Race with a short timeout so we don't actually wait 8s. The
      // production `.timeout(Duration(seconds: 8))` proves the path
      // exists — here we just confirm the `TimeoutException` branch
      // produces the right envelope by triggering it via dart:async
      // directly through a wrapping timeout call from the test.
      //
      // Because the data source's own timeout is 8s and we don't want
      // to wait that long, we instead instrument the test by
      // shortening the awaited future via a wrapper. Simpler: assert
      // the exact envelope emerges when the future does eventually
      // hit the data source's own timeout — the assertion completes
      // in 8s + epsilon; we mark this test with a higher timeout.
      await expectLater(
        svc
            .postLocation(
              bookingId: 42,
              authToken: 'tok',
              lat: 31.5,
              lng: 74.3,
            )
            .timeout(const Duration(seconds: 10)),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.code, 'code', 'network_timeout'),
        ),
      );
      // Ensure the dangling completer doesn't keep the test alive.
      neverCompletes.complete(http.Response('', 200));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('5xx → throws HttpFailure even when body is non-JSON', () async {
      // Some load balancers return raw HTML on 502.
      final client = MockClient(
        (_) async =>
            http.Response('<html><body>502 Bad Gateway</body></html>', 502),
      );
      final svc = TechLocationRemoteDataSource(client);

      await expectLater(
        svc.postLocation(bookingId: 42, authToken: 'tok', lat: 31.5, lng: 74.3),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.code, 'code', 'unknown'),
        ),
      );
    });

    // ────────── T-7 (Batch E): missing branches ──────────────────────

    test(
      'T-7 (Batch E) 401 token_expired → throws HttpFailure with '
      'auth-failed code',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 401,
              'code': 'authentication_failed',
              'message': 'Invalid or expired token.',
              'errors': {},
            }),
            401,
          ),
        );
        final svc = TechLocationRemoteDataSource(client);

        await expectLater(
          svc.postLocation(
            bookingId: 42,
            authToken: 'expired-tok',
            lat: 31.5,
            lng: 74.3,
          ),
          throwsA(
            isA<HttpFailure>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.code, 'code', 'authentication_failed'),
          ),
        );
      },
    );

    test(
      'T-7 (Batch E) 400 validation_error → throws HttpFailure with '
      'errors map populated',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 400,
              'code': 'validation_error',
              'message': 'lat must be between -90 and 90.',
              'errors': {
                'lat': ['Out of range.'],
              },
            }),
            400,
          ),
        );
        final svc = TechLocationRemoteDataSource(client);

        await expectLater(
          svc.postLocation(
            bookingId: 42,
            authToken: 'tok',
            lat: 999.0,
            lng: 74.3,
          ),
          throwsA(
            isA<HttpFailure>()
                .having((e) => e.statusCode, 'statusCode', 400)
                .having((e) => e.code, 'code', 'validation_error')
                .having(
                  (e) => e.errors,
                  'errors',
                  containsPair('lat', anything),
                ),
          ),
        );
      },
    );

    test(
      'T-7 (Batch E) SocketException → throws '
      'HttpFailure(0, network_failure)',
      () async {
        final client = MockClient((_) async {
          throw const SocketException('host unreachable');
        });
        final svc = TechLocationRemoteDataSource(client);

        await expectLater(
          svc.postLocation(
            bookingId: 42,
            authToken: 'tok',
            lat: 31.5,
            lng: 74.3,
          ),
          throwsA(
            isA<HttpFailure>()
                .having((e) => e.statusCode, 'statusCode', 0)
                .having((e) => e.code, 'code', 'network_failure'),
          ),
        );
      },
    );

    test(
      'T-7 (Batch E) 200 with empty body → returns true (happy path '
      'tolerates absent payload)',
      () async {
        // Backend returns 204-style on success in some configurations
        // (no body, just status). Data source must accept this.
        final client = MockClient((_) async => http.Response('', 200));
        final svc = TechLocationRemoteDataSource(client);

        final ok = await svc.postLocation(
          bookingId: 42,
          authToken: 'tok',
          lat: 31.5,
          lng: 74.3,
        );
        expect(ok, isTrue);
      },
    );
  });
}
