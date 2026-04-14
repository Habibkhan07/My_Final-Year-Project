import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/booking/data/data_sources/booking_remote_data_source.dart';
import 'package:frontend/features/booking/data/models/booking_models.dart';
import 'package:frontend/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';

class MockBookingRemoteDataSource extends Mock
    implements IBookingRemoteDataSource {}

class FakeInstantBookingRequestModel extends Fake
    implements InstantBookingRequestModel {}

void main() {
  late BookingRepositoryImpl repository;
  late MockBookingRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(FakeInstantBookingRequestModel());
  });

  setUp(() {
    mockRemote = MockBookingRemoteDataSource();
    repository = BookingRepositoryImpl(remoteDataSource: mockRemote);
  });

  // ---------------------------------------------------------------------------
  // Shared test fixtures
  // ---------------------------------------------------------------------------

  const tTechnicianId = 42;
  const tDate = '2026-04-07';

  const tSlotModel = AvailabilitySlotModel(
    timeString: '10:00 AM',
    isoStart: '2026-04-07T10:00:00+05:00',
    isoEnd: '2026-04-07T11:00:00+05:00',
    period: 'AM',
  );

  const tResponseModel = InstantBookingResponseModel(bookingId: 99);

  // ---------------------------------------------------------------------------
  // getTechnicianProfile — success
  // ---------------------------------------------------------------------------
  group('getTechnicianProfile', () {
    const tId = 42;
    const tProfileModel = TechnicianProfileModel(
      id: 1,
      fullName: 'Ali Raza',
      city: 'LHR',
      profilePicture: null,
      ratingAverage: 4.9,
      reviewCount: 120,
      experienceYears: 5,
      bio: 'bio',
      distanceKm: 2.5,
      bayesianScore: 4.8,
      isActive: true,
      uiRatingText: '4.9',
      primaryPrice: '500',
      primaryPriceRaw: '500.00',
      priceContext: 'Fee',
      promoTag: null,
      skills: [],
      recentReviews: [],
    );


    test('success — returns TechnicianProfileEntity', () async {
      when(() => mockRemote.getTechnicianProfile(
            id: any(named: 'id'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
          )).thenAnswer((_) async => tProfileModel);

      final result = await repository.getTechnicianProfile(id: tId);

      expect(result, isA<TechnicianProfileEntity>());
      expect(result.id, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // getAvailability — success
  // ---------------------------------------------------------------------------
  group('getAvailability', () {
    test('success — returns list of AvailabilitySlotEntity', () async {
      when(() => mockRemote.getAvailability(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => [tSlotModel]);

      final result = await repository.getAvailability(
          technicianId: tTechnicianId, date: tDate);

      expect(result, isA<List<AvailabilitySlotEntity>>());
      expect(result.length, 1);
      expect(result.first.isoStart, tSlotModel.isoStart);
    });

    test('success — empty list is returned as-is (no schedule case)', () async {
      when(() => mockRemote.getAvailability(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => []);

      final result = await repository.getAvailability(
          technicianId: tTechnicianId, date: tDate);

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // createInstantBooking — success
  // ---------------------------------------------------------------------------
  group('createInstantBooking', () {
    test('success — returns CreatedBookingEntity with correct bookingId', () async {
      when(() => mockRemote.createInstantBooking(any()))
          .thenAnswer((_) async => tResponseModel);

      final result = await repository.createInstantBooking(
        technicianId: tTechnicianId,
        addressId: 7,
        scheduledStart: '2026-04-07T10:00:00+05:00',
        scheduledEnd: '2026-04-07T11:00:00+05:00',
        priceAmount: '1500.00',
      );

      expect(result, isA<CreatedBookingEntity>());
      expect(result.bookingId, 99);
    });
  });

  // ---------------------------------------------------------------------------
  // Error Propagation Pipeline (both methods follow the same mapping)
  // The full matrix is exercised on createInstantBooking as it exercises
  // every code the backend can return. getAvailability shares the same
  // _mapFailure() so SocketException + FormatException are verified there too.
  // ---------------------------------------------------------------------------
  group('Error Propagation Pipeline', () {
    void stubAvailabilityThrows(Object e) {
      when(() => mockRemote.getAvailability(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenThrow(e);
    }

    void stubBookingThrows(Object e) {
      when(() => mockRemote.createInstantBooking(any())).thenThrow(e);
    }

    Future<void> callBooking() => repository.createInstantBooking(
          technicianId: tTechnicianId,
          addressId: 7,
          scheduledStart: '2026-04-07T10:00:00+05:00',
          scheduledEnd: '2026-04-07T11:00:00+05:00',
          priceAmount: '1500.00',
        );

    test('SocketException → BookingNetworkFailure', () {
      stubBookingThrows(const SocketException('No internet'));
      expect(callBooking, throwsA(isA<BookingNetworkFailure>()));
    });

    test('SocketException on availability → BookingNetworkFailure', () {
      stubAvailabilityThrows(const SocketException('No internet'));
      expect(
        () => repository.getAvailability(technicianId: tTechnicianId, date: tDate),
        throwsA(isA<BookingNetworkFailure>()),
      );
    });

    test('FormatException → BookingUnexpectedFailure', () {
      stubBookingThrows(const FormatException('Bad JSON'));
      expect(callBooking, throwsA(isA<BookingUnexpectedFailure>()));
    });

    test('not_found → BookingTechnicianNotFoundFailure', () {
      stubBookingThrows(HttpFailure(
          statusCode: 404, code: 'not_found', message: 'Technician not found.'));
      expect(callBooking, throwsA(isA<BookingTechnicianNotFoundFailure>()));
    });

    test('out_of_service_area → BookingOutOfServiceAreaFailure with message pass-through', () {
      const tMessage = 'Your address is 14.2 km away (limit: 10 km).';
      stubBookingThrows(HttpFailure(
          statusCode: 400, code: 'out_of_service_area', message: tMessage));
      expect(
        callBooking,
        throwsA(isA<BookingOutOfServiceAreaFailure>()
            .having((e) => e.message, 'message', tMessage)),
      );
    });

    test('slot_unavailable → BookingSlotUnavailableFailure', () {
      stubBookingThrows(HttpFailure(
          statusCode: 409,
          code: 'slot_unavailable',
          message: 'This time slot was just booked.'));
      expect(callBooking, throwsA(isA<BookingSlotUnavailableFailure>()));
    });

    test('validation_error with address_id key → BookingInvalidAddressFailure', () {
      stubBookingThrows(HttpFailure(
        statusCode: 400,
        code: 'validation_error',
        message: 'Invalid address.',
        errors: {'address_id': ['No matching address found for this account.']},
      ));
      expect(callBooking, throwsA(isA<BookingInvalidAddressFailure>()));
    });

    test('validation_error without address_id → BookingValidationFailure', () {
      stubBookingThrows(HttpFailure(
        statusCode: 400,
        code: 'validation_error',
        message: 'Invalid booking data.',
        errors: {'scheduled_end': ['Must be after scheduled_start.']},
      ));
      expect(
        callBooking,
        throwsA(isA<BookingValidationFailure>()
            .having((e) => e.message, 'message', 'Invalid booking data.')),
      );
    });

    test('server_error → BookingServerFailure', () {
      stubBookingThrows(HttpFailure(
          statusCode: 500, code: 'server_error', message: 'Server error: 500'));
      expect(callBooking, throwsA(isA<BookingServerFailure>()));
    });

    test('unknown code → BookingUnexpectedFailure', () {
      stubBookingThrows(HttpFailure(
          statusCode: 400, code: 'unknown_xyz', message: 'Mystery error'));
      expect(callBooking, throwsA(isA<BookingUnexpectedFailure>()));
    });
  });
}
