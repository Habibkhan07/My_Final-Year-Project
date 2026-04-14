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
    when(() => mockRepository.createInstantBooking(
          technicianId: any(named: 'technicianId'),
          addressId: any(named: 'addressId'),
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
          priceAmount: any(named: 'priceAmount'),
          priceContext: any(named: 'priceContext'),
        )).thenAnswer((_) async => tEntity);
  }

  test('delegates all params to repository.createInstantBooking unchanged', () async {
    stubSuccess();

    final result = await useCase.call(
      technicianId: 42,
      addressId: 7,
      scheduledStart: '2026-04-07T10:00:00+05:00',
      scheduledEnd: '2026-04-07T11:00:00+05:00',
      priceAmount: '1500.00',
      priceContext: 'AC Repair',
    );

    expect(result, tEntity);
    verify(() => mockRepository.createInstantBooking(
          technicianId: 42,
          addressId: 7,
          scheduledStart: '2026-04-07T10:00:00+05:00',
          scheduledEnd: '2026-04-07T11:00:00+05:00',
          priceAmount: '1500.00',
          priceContext: 'AC Repair',
        )).called(1);
  });

  test('priceContext defaults to empty string when not provided', () async {
    stubSuccess();

    await useCase.call(
      technicianId: 42,
      addressId: 7,
      scheduledStart: '2026-04-07T10:00:00+05:00',
      scheduledEnd: '2026-04-07T11:00:00+05:00',
      priceAmount: '1500.00',
    );

    verify(() => mockRepository.createInstantBooking(
          technicianId: 42,
          addressId: 7,
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
          priceAmount: any(named: 'priceAmount'),
          priceContext: '',
        )).called(1);
  });

  test('propagates BookingSlotUnavailableFailure from repository', () {
    when(() => mockRepository.createInstantBooking(
          technicianId: any(named: 'technicianId'),
          addressId: any(named: 'addressId'),
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
          priceAmount: any(named: 'priceAmount'),
          priceContext: any(named: 'priceContext'),
        )).thenThrow(const BookingSlotUnavailableFailure());

    expect(
      () => useCase.call(
        technicianId: 42,
        addressId: 7,
        scheduledStart: '2026-04-07T10:00:00+05:00',
        scheduledEnd: '2026-04-07T11:00:00+05:00',
        priceAmount: '1500.00',
      ),
      throwsA(isA<BookingSlotUnavailableFailure>()),
    );
  });
}
