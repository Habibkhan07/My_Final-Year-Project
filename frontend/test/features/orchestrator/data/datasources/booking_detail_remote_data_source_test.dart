// Tests for `BookingDetailRemoteDataSource.fetch`.
//
// The remote data source is the one place that:
//   1. Reads the JWT from secure storage and injects the
//      `Authorization: Token …` header.
//   2. Builds the URL `${baseUrl}/bookings/<id>/` (no `/api/` prefix —
//      AppConstants.baseUrl already includes it; sprint §24).
//   3. Decodes 200 bodies into `BookingDetailModel`.
//   4. Coerces non-2xx envelopes into typed `HttpFailure` so the
//      repository can map them to sealed-class domain failures.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/features/orchestrator/data/datasources/booking_detail_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../_helpers/booking_detail_fixture.dart';

class _MockClient extends Mock implements http.Client {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late _MockSecureStorage storage;
  late BookingDetailRemoteDataSource ds;

  setUp(() {
    client = _MockClient();
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'JWT_X');
    ds = BookingDetailRemoteDataSource(client, storage);
  });

  test('200 decodes into BookingDetailModel', () async {
    final body = jsonEncode(bookingDetailJson(id: 42));
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response(body, 200));

    final out = await ds.fetch(42);
    expect(out.id, 42);
  });

  test('URL is baseUrl + /bookings/<id>/ (no /api/ prefix)', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(jsonEncode(bookingDetailJson()), 200),
    );

    await ds.fetch(42);

    final captured =
        verify(
              () => client.get(captureAny(), headers: any(named: 'headers')),
            ).captured.single
            as Uri;
    final expected = '${AppConstants.baseUrl}/bookings/42/';
    expect(captured.toString(), expected);
    // Defensive double-guard: no double-/api/ in the path.
    expect(captured.toString().contains('/api/api/'), isFalse);
  });

  test(
    'Authorization header is "Token <jwt>" when secure storage has one',
    () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(bookingDetailJson()), 200),
      );

      await ds.fetch(42);

      final headers =
          verify(
                () => client.get(any(), headers: captureAny(named: 'headers')),
              ).captured.single
              as Map<String, String>;
      expect(headers['Authorization'], 'Token JWT_X');
      expect(headers['Accept'], 'application/json');
    },
  );

  test('Authorization header is omitted when storage returns null', () async {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(jsonEncode(bookingDetailJson()), 200),
    );

    await ds.fetch(42);

    final headers =
        verify(
              () => client.get(any(), headers: captureAny(named: 'headers')),
            ).captured.single
            as Map<String, String>;
    expect(headers.containsKey('Authorization'), isFalse);
  });

  test(
    'non-2xx with envelope throws HttpFailure carrying envelope fields',
    () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          '{"code":"booking_not_found","message":"Booking gone","errors":{}}',
          404,
        ),
      );

      await expectLater(
        ds.fetch(42),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'booking_not_found')
              .having((e) => e.message, 'message', 'Booking gone'),
        ),
      );
    },
  );

  test('non-2xx with non-JSON body falls back to generic message', () async {
    // Django's default 500 page is HTML — the data source must not
    // crash on `jsonDecode`. Generic message + statusCode preserves
    // the failure surface so the repository still maps to 5xx → server.
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response('<html>500 Internal Server Error</html>', 500),
    );

    await expectLater(
      ds.fetch(42),
      throwsA(
        isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.code, 'code', 'unknown')
            .having((e) => e.message, 'message', contains('500')),
      ),
    );
  });

  test(
    '204 No Content is treated as a non-2xx? (200..<300 inclusive)',
    () async {
      // Sanity: 204 is in the 200..<300 success range. The data source
      // would still try to JSON-decode, which would throw because the
      // body is empty. Pin the boundary: 204 raises a FormatException
      // (caller's responsibility) — endpoint contract returns 200
      // always, but a regression that flips to 204 must surface loudly.
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('', 204));

      await expectLater(ds.fetch(42), throwsA(isA<FormatException>()));
    },
  );
}
