// Unit tests for `HttpFailure.fromEnvelope` — the defensive parser
// added by audit S-14 (Batch B). Pre-fix, every data source pasted
// the same `envelope?['code'] as String?` cast — which throws
// `TypeError` if the server ever returns a non-string `code` (e.g.
// `42`). The new factory coerces via `toString()` and tolerates
// shape drift without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';

void main() {
  group('HttpFailure.fromEnvelope', () {
    test('happy path: well-formed envelope is preserved verbatim', () {
      final f = HttpFailure.fromEnvelope(
        statusCode: 400,
        body: <String, dynamic>{
          'code': 'validation_error',
          'message': 'Phone number is required.',
          'errors': {
            'phone_no': ['This field may not be blank.'],
          },
        },
      );
      expect(f.statusCode, 400);
      expect(f.code, 'validation_error');
      expect(f.message, 'Phone number is required.');
      expect(f.errors['phone_no'], ['This field may not be blank.']);
    });

    test('coerces non-string `code` to its string form (S-14)', () {
      // Server bug: numeric `code` instead of string. Pre-fix the
      // `as String?` cast threw TypeError; post-fix we toString().
      final f = HttpFailure.fromEnvelope(
        statusCode: 400,
        body: <String, dynamic>{
          'code': 42,
          'message': 'something',
        },
      );
      expect(f.code, '42');
      expect(f.message, 'something');
    });

    test('coerces non-string `message` to its string form (S-14)', () {
      final f = HttpFailure.fromEnvelope(
        statusCode: 500,
        body: <String, dynamic>{
          'code': 'server_error',
          'message': true, // accidental boolean
        },
      );
      expect(f.code, 'server_error');
      expect(f.message, 'true');
    });

    test('null `code` falls back to fallbackCode', () {
      final f = HttpFailure.fromEnvelope(
        statusCode: 502,
        body: <String, dynamic>{
          'message': 'gateway timeout',
        },
        fallbackCode: 'gateway_error',
      );
      expect(f.code, 'gateway_error');
      expect(f.message, 'gateway timeout');
    });

    test('null `message` falls back to fallbackMessage', () {
      final f = HttpFailure.fromEnvelope(
        statusCode: 503,
        body: <String, dynamic>{
          'code': 'unavailable',
        },
        fallbackMessage: 'service is being restarted',
      );
      expect(f.code, 'unavailable');
      expect(f.message, 'service is being restarted');
    });

    test(
      'null `message` AND null fallback — uses generic "request failed"',
      () {
        final f = HttpFailure.fromEnvelope(
          statusCode: 418,
          body: <String, dynamic>{},
        );
        expect(f.statusCode, 418);
        expect(f.code, 'unknown');
        expect(f.message, 'request failed (418)');
        expect(f.errors, isEmpty);
      },
    );

    test('non-Map `errors` is replaced with empty map (S-14)', () {
      // Server bug: `errors` is a list instead of a map.
      final f = HttpFailure.fromEnvelope(
        statusCode: 400,
        body: <String, dynamic>{
          'code': 'bad',
          'errors': ['not', 'a', 'map'],
        },
      );
      expect(f.errors, isEmpty);
    });

    test('non-Map body (e.g. HTML 502 from load balancer) is tolerated', () {
      // jsonDecode of an HTML page returns a String, not a Map. Pre-fix
      // would have crashed on `.['code']`; post-fix returns the
      // fallback envelope with the supplied status code.
      final f = HttpFailure.fromEnvelope(
        statusCode: 502,
        body: '<html>Bad gateway</html>',
        fallbackMessage: 'tech-location POST failed (502)',
      );
      expect(f.statusCode, 502);
      expect(f.code, 'unknown');
      expect(f.message, 'tech-location POST failed (502)');
      expect(f.errors, isEmpty);
    });

    test('null body (e.g. jsonDecode threw upstream) is tolerated', () {
      final f = HttpFailure.fromEnvelope(
        statusCode: 0,
        body: null,
        fallbackCode: 'network_failure',
        fallbackMessage: 'network unreachable',
      );
      expect(f.statusCode, 0);
      expect(f.code, 'network_failure');
      expect(f.message, 'network unreachable');
    });
  });
}
