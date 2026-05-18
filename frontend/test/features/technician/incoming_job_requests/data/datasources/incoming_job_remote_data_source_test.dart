// Wire-level tests for `IncomingJobRemoteDataSource` — the URL it POSTs
// to, the auth header it attaches, and the way it converts non-2xx
// responses into `HttpFailure` instances the repository can map.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/incoming_job_requests/data/datasources/incoming_job_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Convenience wrapper for the captured request — the MockClient handler
/// receives [http.Request] and we want to assert about it later.
class _Captured {
  http.Request? request;
}

IncomingJobRemoteDataSource _build({
  required http.Client client,
  required FlutterSecureStorage storage,
}) {
  return IncomingJobRemoteDataSource(client: client, secureStorage: storage);
}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  group('IncomingJobRemoteDataSource.acceptJobRequest', () {
    test('POSTs to /api/bookings/<jobId>/accept/ with the auth header and an '
        'empty JSON body', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response('', 200);
      });

      await _build(client: client, storage: storage).acceptJobRequest(99482);

      final req = captured.request!;
      expect(req.method, 'POST');
      expect(req.url.path, '/api/bookings/99482/accept/');
      expect(req.headers['authorization'], 'Token test-token');
      expect(req.headers['content-type'], contains('application/json'));
      expect(req.body, jsonEncode(const <String, dynamic>{}));
    });

    test('2xx response resolves the future without throwing — the wire body '
        'is not parsed (we only care about success vs failure here)', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'booking_id': 1, 'status': 'CONFIRMED'}),
          200,
        ),
      );
      await expectLater(
        _build(client: client, storage: storage).acceptJobRequest(1),
        completes,
      );
    });

    test('Standard error envelope (status, code, message, errors) is parsed '
        'into HttpFailure verbatim', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 409,
            'code': 'booking_no_longer_available',
            'message': 'This job is no longer available.',
            'errors': {
              'current_status': ['TECH_NO_RESPONSE'],
            },
          }),
          409,
        ),
      );

      try {
        await _build(client: client, storage: storage).acceptJobRequest(42);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 409);
        expect(e.code, 'booking_no_longer_available');
        expect(e.message, 'This job is no longer available.');
        expect(e.errors['current_status'], ['TECH_NO_RESPONSE']);
      }
    });

    test('404 envelope is parsed into HttpFailure(404, not_found)', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 404,
            'code': 'not_found',
            'message': 'Booking not found.',
            'errors': {},
          }),
          404,
        ),
      );
      try {
        await _build(client: client, storage: storage).acceptJobRequest(42);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'not_found');
      }
    });

    test('Non-JSON 5xx body falls back to a synthetic server_error HttpFailure '
        '(server may have crashed before envelope rendering)', () async {
      final client = MockClient(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );
      try {
        await _build(client: client, storage: storage).acceptJobRequest(7);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 502);
        expect(e.code, 'server_error');
      }
    });

    test(
      'Missing auth token still POSTs (no Authorization header attached) '
      '— the server will surface a 401 envelope which the repository maps',
      () async {
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        final captured = _Captured();
        final client = MockClient((request) async {
          captured.request = request;
          return http.Response('', 200);
        });

        await _build(client: client, storage: storage).acceptJobRequest(1);

        expect(captured.request!.headers.containsKey('authorization'), isFalse);
      },
    );
  });

  group('IncomingJobRemoteDataSource.declineJobRequest', () {
    test('POSTs to /api/bookings/<jobId>/decline/', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response('', 200);
      });

      await _build(client: client, storage: storage).declineJobRequest(7);

      expect(captured.request!.url.path, '/api/bookings/7/decline/');
      expect(captured.request!.method, 'POST');
    });

    test('Errors map through the same envelope path as accept', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 409,
            'code': 'booking_no_longer_available',
            'message': 'This job is no longer available.',
            'errors': {
              'current_status': ['CONFIRMED'],
            },
          }),
          409,
        ),
      );
      try {
        await _build(client: client, storage: storage).declineJobRequest(42);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'booking_no_longer_available');
        expect(e.errors['current_status'], ['CONFIRMED']);
      }
    });
  });
}
