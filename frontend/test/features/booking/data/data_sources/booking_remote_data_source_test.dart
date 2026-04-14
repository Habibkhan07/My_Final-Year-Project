import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/booking/data/data_sources/booking_remote_data_source.dart';
import 'package:frontend/features/booking/data/models/booking_models.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late BookingRemoteDataSource dataSource;
  late MockHttpClient mockClient;
  late MockFlutterSecureStorage mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = BookingRemoteDataSource(
      client: mockClient,
      secureStorage: mockSecureStorage,
    );
  });

  // ---------------------------------------------------------------------------
  // getTechnicianProfile
  // ---------------------------------------------------------------------------
  group('getTechnicianProfile', () {
    const tId = 42;
    final tProfileJson = {
      'id': 42,
      'full_name': 'Ali Raza',
      'city': 'LHR',
      'profile_picture': 'https://example.com/pic.jpg',
      'rating_average': 4.9,
      'review_count': 120,
      'experience_years': 5,
      'bio': 'Test bio',
      'distance_km': 2.4,
      'bayesian_score': 4.8,
      'is_active': true,
      'ui_rating_text': '4.9 (120)',
      'primary_price': 'Rs. 500',
      'primary_price_raw': '500.00',
      'price_context': 'Inspection Fee',
      'promo_tag': '20% OFF',
      'skills': [{'name': 'AC Repair', 'icon_name': 'ac_repair'}],
      'recent_reviews': [{'reviewer_name': 'Sara', 'rating': 5, 'text': 'Good'}]
    };

    test('200 returns TechnicianProfileModel', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(tProfileJson), 200),
      );

      final result = await dataSource.getTechnicianProfile(id: tId);

      expect(result, isA<TechnicianProfileModel>());
      expect(result.id, 42);
      expect(result.fullName, 'Ali Raza');
      expect(result.skills.length, 1);
      expect(result.skills.first.name, 'AC Repair');
    });

    test('builds correct URL with optional contextual params', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(tProfileJson), 200),
      );

      await dataSource.getTechnicianProfile(
        id: tId,
        lat: 31.5,
        lng: 74.3,
        serviceId: 1,
        subServiceId: 2,
        promotionId: 3,
      );

      final captured = verify(() => mockClient.get(captureAny())).captured.first as Uri;
      expect(captured.path, contains('technician-profile/42/'));
      expect(captured.queryParameters['lat'], '31.5');
      expect(captured.queryParameters['lng'], '74.3');
      expect(captured.queryParameters['service_id'], '1');
      expect(captured.queryParameters['sub_service_id'], '2');
      expect(captured.queryParameters['promotion_id'], '3');
    });

    test('404 not_found throws HttpFailure with correct code', () async {
      final errorJson = {
        'status': 404,
        'code': 'not_found',
        'message': 'Technician not found.',
        'errors': {},
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(errorJson), 404),
      );

      expect(
        () => dataSource.getTechnicianProfile(id: tId),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.code, 'code', 'not_found')),
      );
    });

    test('500 server_error throws HttpFailure with correct code', () async {
      final errorJson = {
        'status': 500,
        'code': 'server_error',
        'message': 'Server error.',
        'errors': {},
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(errorJson), 500),
      );

      expect(
        () => dataSource.getTechnicianProfile(id: tId),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.code, 'code', 'server_error')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getAvailability
  // ---------------------------------------------------------------------------
  group('getAvailability', () {
    const tTechnicianId = 42;
    const tDate = '2026-04-07';

    final tSlotsJson = [
      {
        'time_string': '9:00 AM',
        'iso_start': '2026-04-07T09:00:00+05:00',
        'iso_end': '2026-04-07T10:00:00+05:00',
        'period': 'AM',
      },
      {
        'time_string': '10:00 AM',
        'iso_start': '2026-04-07T10:00:00+05:00',
        'iso_end': '2026-04-07T11:00:00+05:00',
        'period': 'AM',
      },
    ];

    test('200 returns list of AvailabilitySlotModels with correct values', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(tSlotsJson), 200),
      );

      final result = await dataSource.getAvailability(
          technicianId: tTechnicianId, date: tDate);

      expect(result, isA<List<AvailabilitySlotModel>>());
      expect(result.length, 2);
      expect(result.first.timeString, '9:00 AM');
      expect(result.first.isoStart, '2026-04-07T09:00:00+05:00');
    });

    test('200 with empty array returns empty list (technician has no schedule)', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('[]', 200),
      );

      final result = await dataSource.getAvailability(
          technicianId: tTechnicianId, date: tDate);

      expect(result, isEmpty);
    });

    test('builds correct URL with date and optional service params', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('[]', 200),
      );

      await dataSource.getAvailability(
        technicianId: tTechnicianId,
        date: tDate,
        serviceId: 3,
        subServiceId: 7,
      );

      final captured =
          verify(() => mockClient.get(captureAny())).captured.first as Uri;
      expect(captured.path, contains('technicians/$tTechnicianId/availability'));
      expect(captured.queryParameters['date'], tDate);
      expect(captured.queryParameters['service_id'], '3');
      expect(captured.queryParameters['sub_service_id'], '7');
    });

    test('non-200 throws HttpFailure with correct code and statusCode', () async {
      final errorJson = {
        'code': 'not_found',
        'message': 'Technician not found.',
        'errors': {},
      };
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(errorJson), 404),
      );

      expect(
        () => dataSource.getAvailability(
            technicianId: tTechnicianId, date: tDate),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.code, 'code', 'not_found')),
      );
    });

    test('500 with non-JSON body throws HttpFailure with server_error code', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Internal Server Error', 500),
      );

      expect(
        () => dataSource.getAvailability(
            technicianId: tTechnicianId, date: tDate),
        throwsA(isA<HttpFailure>()
            .having((e) => e.code, 'code', 'server_error')
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // createInstantBooking
  // ---------------------------------------------------------------------------
  group('createInstantBooking', () {
    const tToken = 'test-jwt-token';
    const tRequest = InstantBookingRequestModel(
      technicianId: 42,
      addressId: 7,
      scheduledStart: '2026-04-07T10:00:00+05:00',
      scheduledEnd: '2026-04-07T11:00:00+05:00',
      priceAmount: '1500.00',
      priceContext: 'AC Repair',
    );
    const tResponseJson = {'booking_id': 123};

    setUp(() {
      when(() => mockSecureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => tToken);
    });

    test('201 returns InstantBookingResponseModel with correct bookingId', () async {
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(tResponseJson), 201));

      final result = await dataSource.createInstantBooking(tRequest);

      expect(result, isA<InstantBookingResponseModel>());
      expect(result.bookingId, 123);
    });

    test('sends Authorization: Token header with JWT from secure storage', () async {
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(tResponseJson), 201));

      await dataSource.createInstantBooking(tRequest);

      final captured = verify(() => mockClient.post(
            any(),
            headers: captureAny(named: 'headers'),
            body: any(named: 'body'),
          )).captured.first as Map<String, String>;

      expect(captured['Authorization'], 'Token $tToken');
      expect(captured['Content-Type'], 'application/json');
    });

    test('sends request body matching InstantBookingRequestModel.toJson()', () async {
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(tResponseJson), 201));

      await dataSource.createInstantBooking(tRequest);

      final capturedBody = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.first as String;

      final decoded = jsonDecode(capturedBody) as Map<String, dynamic>;
      expect(decoded['technician_id'], 42);
      expect(decoded['address_id'], 7);
      expect(decoded['scheduled_start'], '2026-04-07T10:00:00+05:00');
      expect(decoded['price_amount'], '1500.00');
    });

    test('400 validation_error throws HttpFailure with correct code', () async {
      final errorJson = {
        'status': 400,
        'code': 'validation_error',
        'message': 'Invalid booking data.',
        'errors': {'scheduled_end': ['scheduled_end must be after scheduled_start.']},
      };
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(errorJson), 400));

      expect(
        () => dataSource.createInstantBooking(tRequest),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.code, 'code', 'validation_error')),
      );
    });

    test('400 out_of_service_area throws HttpFailure with correct code and message', () async {
      final errorJson = {
        'status': 400,
        'code': 'out_of_service_area',
        'message': 'Your address is 14.2 km away (limit: 10 km).',
        'errors': {},
      };
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(errorJson), 400));

      expect(
        () => dataSource.createInstantBooking(tRequest),
        throwsA(isA<HttpFailure>()
            .having((e) => e.code, 'code', 'out_of_service_area')
            .having((e) => e.message, 'message',
                'Your address is 14.2 km away (limit: 10 km).')),
      );
    });

    test('409 slot_unavailable throws HttpFailure with statusCode 409', () async {
      final errorJson = {
        'status': 409,
        'code': 'slot_unavailable',
        'message': 'This time slot was just booked.',
        'errors': {},
      };
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(errorJson), 409));

      expect(
        () => dataSource.createInstantBooking(tRequest),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'slot_unavailable')),
      );
    });

    test('404 not_found throws HttpFailure', () async {
      final errorJson = {
        'status': 404,
        'code': 'not_found',
        'message': 'Technician not found.',
        'errors': {},
      };
      when(() => mockClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(errorJson), 404));

      expect(
        () => dataSource.createInstantBooking(tRequest),
        throwsA(isA<HttpFailure>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.code, 'code', 'not_found')),
      );
    });
  });
}
