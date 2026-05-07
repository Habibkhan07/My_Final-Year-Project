import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/core/realtime/data/datasources/event_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockHttpClient client;
  late _MockSecureStorage storage;
  late EventRemoteDataSource ds;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://placeholder/'));
  });

  setUp(() {
    client = _MockHttpClient();
    storage = _MockSecureStorage();
    ds = EventRemoteDataSource(client: client, secureStorage: storage);

    // Default token. Individual tests override as needed.
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'default-token');
  });

  // ───────────────────────────────────────────────────────────────────────
  // R1 — Token-at-call-site contract
  // ───────────────────────────────────────────────────────────────────────

  test('R1 — token rotation: each call re-reads from secureStorage (no DS-level caching)',
      () async {
    final tokens = ['tokenA', 'tokenB'];
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => tokens.removeAt(0));
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await ds.fetchEventsSince('2025-01-01T00:00:00Z');
    await ds.fetchEventsSince('2025-01-01T00:00:00Z');

    final calls = verify(
      () => client.get(any(), headers: captureAny(named: 'headers')),
    ).captured;

    expect(calls.length, 2);
    final firstHeaders = calls[0] as Map<String, String>;
    final secondHeaders = calls[1] as Map<String, String>;
    expect(firstHeaders['Authorization'], 'Token tokenA');
    expect(secondHeaders['Authorization'], 'Token tokenB');
  });

  // ───────────────────────────────────────────────────────────────────────
  // R2–R6 — Endpoint smoke tests (URI + body shape + headers)
  // ───────────────────────────────────────────────────────────────────────

  test('R2 — fetchEventsSince: GET /events/sync/?since=...&limit=... with auth header',
      () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await ds.fetchEventsSince('2025-01-01T00:00:00Z', limit: 25);

    final captured = verify(
      () => client.get(captureAny(), headers: captureAny(named: 'headers')),
    ).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;

    expect(uri.path, '/api/realtime/events/sync/');
    expect(uri.queryParameters['since'], '2025-01-01T00:00:00Z');
    expect(uri.queryParameters['limit'], '25');
    expect(headers['Authorization'], 'Token default-token');
  });

  test('R3 — fetchUnacknowledgedCritical: GET /events/unacknowledged/ with auth header',
      () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await ds.fetchUnacknowledgedCritical();

    final captured = verify(
      () => client.get(captureAny(), headers: captureAny(named: 'headers')),
    ).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;

    expect(uri.path, '/api/realtime/events/unacknowledged/');
    expect(uri.query, isEmpty);
    expect(headers['Authorization'], 'Token default-token');
  });

  test('R4 — acknowledgeEvents: POST /events/ack/ with {event_ids:[...]} JSON body',
      () async {
    when(() => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 204));

    await ds.acknowledgeEvents(['evt-1', 'evt-2']);

    final captured = verify(() => client.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;
    final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

    expect(uri.path, '/api/realtime/events/ack/');
    expect(headers['Authorization'], 'Token default-token');
    expect(headers['Content-Type'], 'application/json');
    expect(body, {'event_ids': ['evt-1', 'evt-2']});
  });

  test('R5 — registerDevice: POST /devices/register/ with {device_token, device_type}',
      () async {
    when(() => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 201));

    await ds.registerDevice('fcm-token-xyz', 'android');

    final captured = verify(() => client.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;
    final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

    expect(uri.path, '/api/realtime/devices/register/');
    expect(headers['Authorization'], 'Token default-token');
    expect(headers['Content-Type'], 'application/json');
    expect(body, {'device_token': 'fcm-token-xyz', 'device_type': 'android'});
  });

  test('R6 — unregisterDevice: POST /devices/unregister/ with {device_token}',
      () async {
    when(() => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('', 204));

    await ds.unregisterDevice('fcm-token-xyz');

    final captured = verify(() => client.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;
    final body = jsonDecode(captured[2] as String) as Map<String, dynamic>;

    expect(uri.path, '/api/realtime/devices/unregister/');
    expect(headers['Authorization'], 'Token default-token');
    expect(headers['Content-Type'], 'application/json');
    expect(body, {'device_token': 'fcm-token-xyz'});
  });

  // ───────────────────────────────────────────────────────────────────────
  // R7–R10 — Error envelope branches (consolidated on fetchEventsSince
  // because the same _handleResponse helper backs every endpoint).
  //
  // _handleResponse distinguishes two malformed-response paths:
  //   - Empty body (jsonDecode returns null) → code: 'unknown'
  //   - Non-JSON body (jsonDecode throws)    → code: 'server_error'
  // R9 and R10 lock both paths.
  // ───────────────────────────────────────────────────────────────────────

  test('R7 — 401 with standard envelope → HttpFailure(401, "unauthorized", "Token expired")',
      () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(
              '{"status":401,"code":"unauthorized","message":"Token expired","errors":{}}',
              401,
            ));

    await expectLater(
      () => ds.fetchEventsSince('2025-01-01T00:00:00Z'),
      throwsA(isA<HttpFailure>()
          .having((f) => f.statusCode, 'statusCode', 401)
          .having((f) => f.code, 'code', 'unauthorized')
          .having((f) => f.message, 'message', 'Token expired')),
    );
  });

  test('R8 — 500 with envelope (has "code" key) → HttpFailure preserves parsed code+message',
      () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(
              '{"status":500,"code":"internal_error","message":"DB unreachable","errors":{}}',
              500,
            ));

    await expectLater(
      () => ds.fetchEventsSince('2025-01-01T00:00:00Z'),
      throwsA(isA<HttpFailure>()
          .having((f) => f.statusCode, 'statusCode', 500)
          .having((f) => f.code, 'code', 'internal_error')
          .having((f) => f.message, 'message', 'DB unreachable')),
    );
  });

  test('R9 — 500 with empty body → HttpFailure with code "unknown"', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('', 500));

    await expectLater(
      () => ds.fetchEventsSince('2025-01-01T00:00:00Z'),
      throwsA(isA<HttpFailure>()
          .having((f) => f.statusCode, 'statusCode', 500)
          .having((f) => f.code, 'code', 'unknown')),
    );
  });

  test('R10 — 500 with non-JSON body (e.g., HTML error page) → HttpFailure with code "server_error"',
      () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(
              '<html><body>503 Service Unavailable</body></html>',
              500,
            ));

    await expectLater(
      () => ds.fetchEventsSince('2025-01-01T00:00:00Z'),
      throwsA(isA<HttpFailure>()
          .having((f) => f.statusCode, 'statusCode', 500)
          .having((f) => f.code, 'code', 'server_error')),
    );
  });

  // ───────────────────────────────────────────────────────────────────────
  // R11 — Timeout
  // ───────────────────────────────────────────────────────────────────────

  test('R11 — slow response (11s) → TimeoutException (locks 10s timeout contract)',
      () {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) => Completer<http.Response>().future, // never completes
    );

    fakeAsync((async) {
      Object? caught;
      ds.fetchEventsSince('2025-01-01T00:00:00Z').catchError((e) {
        caught = e;
        return <Never>[]; // satisfy return type
      });

      async.elapse(const Duration(seconds: 11));
      async.flushMicrotasks();

      expect(caught, isA<TimeoutException>());
    });
  });
}
