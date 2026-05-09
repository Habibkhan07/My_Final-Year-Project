import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/domain/repositories/i_booking_repository.dart';
import 'package:frontend/features/booking/domain/use_cases/create_instant_booking_use_case.dart';

class MockBookingRepository extends Mock implements IBookingRepository {}

void main() {
  late CreateInstantBookingUseCase useCase;
  late MockBookingRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingRepository();
    useCase = CreateInstantBookingUseCase(mockRepository);
  });

  const tEntity = CreatedBookingEntity(bookingId: 99);

  void stubSuccess() {
    when(
      () => mockRepository.createInstantBooking(
        technicianId: any(named: 'technicianId'),
        addressId: any(named: 'addressId'),
        serviceId: any(named: 'serviceId'),
        subServiceId: any(named: 'subServiceId'),
        promotionId: any(named: 'promotionId'),
        scheduledStart: any(named: 'scheduledStart'),
        scheduledEnd: any(named: 'scheduledEnd'),
      ),
    ).thenAnswer((_) async => tEntity);
  }

  test(
    'Scenario A — threads serviceId + subServiceId, leaves promotionId null',
    () async {
      stubSuccess();

      final result = await useCase.call(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        subServiceId: 17,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );

      expect(result, tEntity);
      verify(
        () => mockRepository.createInstantBooking(
          technicianId: 42,
          addressId: 7,
          serviceId: 3,
          subServiceId: 17,
          promotionId: null,
          scheduledStart: '2026-04-08T10:00:00+05:00',
          scheduledEnd: '2026-04-08T11:00:00+05:00',
        ),
      ).called(1);
    },
  );

  test(
    'Scenario C — inspection booking: optional FK params default to null',
    () async {
      stubSuccess();

      await useCase.call(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );

      verify(
        () => mockRepository.createInstantBooking(
          technicianId: 42,
          addressId: 7,
          serviceId: 3,
          subServiceId: null,
          promotionId: null,
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
        ),
      ).called(1);
    },
  );

  test(
    'Scenario D — promo on parent: passes promotionId, leaves subServiceId null',
    () async {
      stubSuccess();

      await useCase.call(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        promotionId: 9,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );

      verify(
        () => mockRepository.createInstantBooking(
          technicianId: 42,
          addressId: 7,
          serviceId: 3,
          subServiceId: null,
          promotionId: 9,
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
        ),
      ).called(1);
    },
  );

  test('propagates BookingSlotUnavailableFailure from repository', () {
    when(
      () => mockRepository.createInstantBooking(
        technicianId: any(named: 'technicianId'),
        addressId: any(named: 'addressId'),
        serviceId: any(named: 'serviceId'),
        subServiceId: any(named: 'subServiceId'),
        promotionId: any(named: 'promotionId'),
        scheduledStart: any(named: 'scheduledStart'),
        scheduledEnd: any(named: 'scheduledEnd'),
      ),
    ).thenThrow(const BookingSlotUnavailableFailure());

    expect(
      () => useCase.call(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        scheduledStart: '2026-04-07T10:00:00+05:00',
        scheduledEnd: '2026-04-07T11:00:00+05:00',
      ),
      throwsA(isA<BookingSlotUnavailableFailure>()),
    );
  });
}
