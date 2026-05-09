// Tests for `BookingActionExecutor.execute`.
//
// The executor is the only place where the orchestrator's HTTP verbs
// fan out. The critical regression vectors:
//   * DELETE must NOT carry a body (#B-70). RFC 7231 leaves DELETE
//     bodies unspecified; some proxies / servers reject or strip them.
//   * Non-2xx responses must throw [HttpFailure] with the standard
//     error envelope so the UI can render server-provided messages.
//   * Auth header (`Token <jwt>`) must be injected from secure storage.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_ui_block.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_action_executor.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements http.Client {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late _MockSecureStorage storage;
  late BookingActionExecutor executor;

  setUp(() {
    client = _MockClient();
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'TOKEN_X');
    executor = BookingActionExecutor(client, storage);
  });

  BookingUiAction action({
    String method = 'POST',
    String endpoint = '/bookings/42/cash/',
  }) => BookingUiAction(
    label: 'Do',
    endpoint: endpoint,
    method: method,
    style: BookingUiActionStyle.primary,
  );

  test('POST sends auth + JSON body and resolves on 200', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('{}', 200));

    await executor.execute(action(), body: {'amount_received': 1500});

    final captured = verify(
      () => client.post(
        captureAny(),
        headers: captureAny(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final uri = captured[0] as Uri;
    final headers = captured[1] as Map<String, String>;
    final body = captured[2] as String;

    expect(uri.toString(), endsWith('/bookings/42/cash/'));
    expect(headers['Authorization'], 'Token TOKEN_X');
    expect(headers['Content-Type'], 'application/json');
    expect(body, contains('"amount_received":1500'));
  });

  test('DELETE call does NOT carry a body (#B-70 regression guard)', () async {
    // RFC 7231 §4.3.5 leaves DELETE bodies unspecified. Some proxies
    // reject them; some servers silently strip them. The bulletproof
    // fix dropped the body parameter from `_client.delete` even when
    // a caller passes one — DELETE always ignores it.
    //
    // The regression guard: stub ONLY the body-less DELETE signature.
    // If a future edit reintroduces `body: encodedBody` on the DELETE
    // arm, the call would land on a different mock signature and
    // mocktail throws — failing this test loudly.
    when(
      () => client.delete(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('', 204));

    // Pass a body intentionally — the executor MUST drop it for DELETE.
    await executor.execute(
      action(method: 'DELETE'),
      body: {'reason': 'duplicate'},
    );

    // Verify the body-less signature was used.
    verify(
      () => client.delete(any(), headers: any(named: 'headers')),
    ).called(1);

    // And explicitly: no DELETE-with-body call occurred.
    verifyNever(
      () => client.delete(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    );
  });

  test('non-2xx response throws HttpFailure with envelope fields', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        '{"code":"validation_error","message":"Bad amount","errors":{"amount_received":["too low"]}}',
        400,
      ),
    );

    await expectLater(
      executor.execute(action(), body: {'amount_received': -1}),
      throwsA(
        isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.code, 'code', 'validation_error')
            .having((e) => e.message, 'message', 'Bad amount')
            .having((e) => e.errors['amount_received'], 'errors', ['too low']),
      ),
    );
  });

  test('non-JSON error body falls back to generic message', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response('<html>oops</html>', 502));

    await expectLater(
      executor.execute(action()),
      throwsA(
        isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.code, 'code', 'unknown')
            .having((e) => e.message, 'message', contains('502')),
      ),
    );
  });

  test('unsupported HTTP method throws StateError', () async {
    await expectLater(
      executor.execute(action(method: 'OPTIONS')),
      throwsA(isA<StateError>()),
    );
  });

  test('GET issues a GET (no body, no Content-Type)', () async {
    when(
      () => client.get(any(), headers: any(named: 'headers')),
    ).thenAnswer((_) async => http.Response('{}', 200));

    await executor.execute(action(method: 'GET'));

    final captured = verify(
      () => client.get(captureAny(), headers: captureAny(named: 'headers')),
    ).captured;
    final headers = captured[1] as Map<String, String>;
    expect(headers.containsKey('Content-Type'), isFalse);
  });
}
