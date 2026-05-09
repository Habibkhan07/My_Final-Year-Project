// Wire-level tests for CustomerBookingsRemoteDataSource.
//
// Covers:
//   * URL composition for both endpoints (path + query params).
//   * Auth header attachment from secure storage (and missing-token case).
//   * Successful body decoding into the wire model.
//   * HttpFailure mapping for every documented error envelope shape.
//   * Synthetic server_error fallback for non-JSON / shapeless 5xx bodies.
//   * Status csv composition + skipping unknown status values.
//   * Cursor + page_size + segment query param wiring.
//   * Counts endpoint shape parity with list.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/bookings/data/data_sources/customer_bookings_remote_data_source.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_segment.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_status.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _Captured {
  http.Request? request;
}

CustomerBookingsRemoteDataSource _build({
  required http.Client client,
  required FlutterSecureStorage storage,
}) {
  return CustomerBookingsRemoteDataSource(
    client: client,
    secureStorage: storage,
  );
}

Map<String, dynamic> _envelope({
  List<Map<String, dynamic>>? items,
  String? nextCursor,
  bool hasMore = false,
}) {
  return {
    'items': items ?? <Map<String, dynamic>>[],
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'server_time': '2026-05-05T12:34:56+00:00',
  };
}

Map<String, dynamic> _sampleItem({
  int id = 99482,
  String status = 'CONFIRMED',
}) {
  return {
    'id': id,
    'status': status,
    'service': {'name': 'AC Repair', 'icon_name': 'ac_repair'},
    'technician': {
      'id': 17,
      'display_name': 'Ahmed Khan',
      'profile_picture_url': null,
    },
    // ASCII-only fixture: http.Response defaults to Latin-1; the em-dash
    // the real backend sends rides on `content-type: application/json;
    // charset=utf-8`. Test fixture uses a hyphen to keep the wire body
    // bytewise-safe under MockClient's default encoding.
    'address_label': 'Home - DHA Phase 5, Lahore',
    'scheduled_start': '2026-05-06T15:00:00+00:00',
    'scheduled_end': '2026-05-06T17:00:00+00:00',
    'created_at': '2026-05-05T09:12:00+00:00',
    'price': {
      'amount': 2500,
      'context': 'Fixed Price',
      'ui_label': 'Rs. 2,500',
    },
    'ui': {
      'badge_text': 'Confirmed',
      'badge_tone': 'positive',
      'headline': 'Confirmed with Ahmed Khan',
    },
  };
}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  // ─── getBookings — URL composition ──────────────────────────────────

  group('getBookings — URL composition', () {
    test('GETs /api/bookings/ with default segment + page_size', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });

      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming);

      final req = captured.request!;
      expect(req.method, 'GET');
      expect(req.url.path, '/api/bookings/');
      expect(req.url.queryParameters['segment'], 'upcoming');
      expect(req.url.queryParameters['page_size'], '20');
      expect(req.url.queryParameters.containsKey('cursor'), isFalse);
      expect(req.url.queryParameters.containsKey('status'), isFalse);
    });

    test('passes segment=past wire value when requested', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.past);
      expect(captured.request!.url.queryParameters['segment'], 'past');
    });

    test('passes cursor verbatim when supplied', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(client: client, storage: storage).getBookings(
        segment: BookingSegment.upcoming,
        cursor: 'opaque-token-abc',
      );
      expect(
        captured.request!.url.queryParameters['cursor'],
        'opaque-token-abc',
      );
    });

    test('skips cursor param when null or empty', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming, cursor: '');
      expect(
        captured.request!.url.queryParameters.containsKey('cursor'),
        isFalse,
      );
    });

    test('passes custom page_size', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming, pageSize: 50);
      expect(captured.request!.url.queryParameters['page_size'], '50');
    });

    test('composes status as csv from BookingStatus list', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(client: client, storage: storage).getBookings(
        segment: BookingSegment.upcoming,
        statusFilter: const [BookingStatus.awaiting, BookingStatus.confirmed],
      );
      expect(
        captured.request!.url.queryParameters['status'],
        'AWAITING,CONFIRMED',
      );
    });

    test('drops BookingStatus.unknown from csv (empty wire value)', () async {
      // Forward-compat: the unknown enum must not produce ",,," noise on
      // the wire when somehow surfaced into a filter list.
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(client: client, storage: storage).getBookings(
        segment: BookingSegment.upcoming,
        statusFilter: const [
          BookingStatus.awaiting,
          BookingStatus.unknown,
          BookingStatus.confirmed,
        ],
      );
      expect(
        captured.request!.url.queryParameters['status'],
        'AWAITING,CONFIRMED',
      );
    });

    test('omits status param when filter list is empty', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming, statusFilter: const []);
      expect(
        captured.request!.url.queryParameters.containsKey('status'),
        isFalse,
      );
    });
  });

  // ─── getBookings — Auth header ──────────────────────────────────────

  group('getBookings — auth header', () {
    test('attaches Authorization: Token <token> from secure storage', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming);
      expect(captured.request!.headers['authorization'], 'Token test-token');
    });

    test('omits Authorization header when no token stored', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(jsonEncode(_envelope()), 200);
      });
      await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming);
      expect(captured.request!.headers.containsKey('authorization'), isFalse);
    });
  });

  // ─── getBookings — Body parsing ─────────────────────────────────────

  group('getBookings — successful body parsing', () {
    test('decodes envelope into BookingsListResponseModel', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            _envelope(
              items: [_sampleItem(id: 99482)],
              nextCursor: 'cursor-page-2',
              hasMore: true,
            ),
          ),
          200,
        ),
      );

      final response = await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming);

      expect(response.items, hasLength(1));
      expect(response.items.first.id, 99482);
      expect(response.items.first.status, 'CONFIRMED');
      expect(response.nextCursor, 'cursor-page-2');
      expect(response.hasMore, isTrue);
      expect(response.serverTime, '2026-05-05T12:34:56+00:00');
    });

    test('handles empty items array', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode(_envelope()), 200),
      );

      final response = await _build(
        client: client,
        storage: storage,
      ).getBookings(segment: BookingSegment.upcoming);

      expect(response.items, isEmpty);
      expect(response.hasMore, isFalse);
      expect(response.nextCursor, isNull);
    });
  });

  // ─── getBookings — Error envelope mapping ───────────────────────────

  group('getBookings — non-2xx → HttpFailure', () {
    test('400 invalid_cursor envelope parsed verbatim', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 400,
            'code': 'invalid_cursor',
            'message': 'Cursor is malformed.',
            'errors': {
              'cursor': ['Cursor is malformed.'],
            },
          }),
          400,
        ),
      );
      try {
        await _build(
          client: client,
          storage: storage,
        ).getBookings(segment: BookingSegment.upcoming);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 400);
        expect(e.code, 'invalid_cursor');
        expect(e.errors['cursor'], ['Cursor is malformed.']);
      }
    });

    test('400 invalid_status_filter envelope parsed verbatim', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 400,
            'code': 'invalid_status_filter',
            'message': 'Invalid query parameters.',
            'errors': {
              'status': ['Unknown status value(s): WAITING.'],
            },
          }),
          400,
        ),
      );
      try {
        await _build(
          client: client,
          storage: storage,
        ).getBookings(segment: BookingSegment.upcoming);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'invalid_status_filter');
      }
    });

    test('401 unauthorized envelope', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 401,
            'code': 'unauthorized',
            'message': 'Unauthorized.',
            'errors': {},
          }),
          401,
        ),
      );
      try {
        await _build(
          client: client,
          storage: storage,
        ).getBookings(segment: BookingSegment.upcoming);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 401);
        expect(e.code, 'unauthorized');
      }
    });

    test('500 with envelope is parsed', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 500,
            'code': 'server_error',
            'message': 'Server error.',
            'errors': {},
          }),
          500,
        ),
      );
      try {
        await _build(
          client: client,
          storage: storage,
        ).getBookings(segment: BookingSegment.upcoming);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 500);
        expect(e.code, 'server_error');
      }
    });

    test('Non-JSON 5xx body falls back to synthetic server_error', () async {
      final client = MockClient(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );
      try {
        await _build(
          client: client,
          storage: storage,
        ).getBookings(segment: BookingSegment.upcoming);
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 502);
        expect(e.code, 'server_error');
      }
    });

    test(
      'JSON without `code` field → synthetic unknown / server_error',
      () async {
        // Body is JSON but doesn't carry the standard envelope.
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'something went wrong'}),
            400,
          ),
        );
        try {
          await _build(
            client: client,
            storage: storage,
          ).getBookings(segment: BookingSegment.upcoming);
          fail('expected HttpFailure');
        } on HttpFailure catch (e) {
          // Unknown body shape — code is `unknown` per the helper.
          expect(e.statusCode, 400);
          expect(e.code, anyOf(equals('unknown'), equals('server_error')));
        }
      },
    );
  });

  // ─── getCounts ──────────────────────────────────────────────────────

  group('getCounts', () {
    test('GETs /api/bookings/counts/ with auth header', () async {
      final captured = _Captured();
      final client = MockClient((request) async {
        captured.request = request;
        return http.Response(
          jsonEncode({
            'upcoming': 1,
            'past': 12,
            'server_time': '2026-05-05T12:34:56+00:00',
          }),
          200,
        );
      });

      await _build(client: client, storage: storage).getCounts();

      expect(captured.request!.method, 'GET');
      expect(captured.request!.url.path, '/api/bookings/counts/');
      expect(captured.request!.headers['authorization'], 'Token test-token');
    });

    test('decodes counts envelope', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'upcoming': 7,
            'past': 13,
            'server_time': '2026-05-05T12:34:56+00:00',
          }),
          200,
        ),
      );
      final result = await _build(client: client, storage: storage).getCounts();
      expect(result.upcoming, 7);
      expect(result.past, 13);
      expect(result.serverTime, '2026-05-05T12:34:56+00:00');
    });

    test('counts 5xx falls back to synthetic server_error', () async {
      final client = MockClient((_) async => http.Response('outage', 503));
      try {
        await _build(client: client, storage: storage).getCounts();
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.statusCode, 503);
        expect(e.code, 'server_error');
      }
    });

    test('counts 401 envelope parsed', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 401,
            'code': 'unauthorized',
            'message': 'Unauthorized.',
            'errors': {},
          }),
          401,
        ),
      );
      try {
        await _build(client: client, storage: storage).getCounts();
        fail('expected HttpFailure');
      } on HttpFailure catch (e) {
        expect(e.code, 'unauthorized');
      }
    });
  });
}
