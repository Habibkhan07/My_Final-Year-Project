import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/domain/repositories/i_booking_repository.dart';
import 'package:frontend/features/booking/domain/use_cases/get_availability_use_case.dart';

class MockBookingRepository extends Mock implements IBookingRepository {}

void main() {
  late GetAvailabilityUseCase useCase;
  late MockBookingRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingRepository();
    useCase = GetAvailabilityUseCase(mockRepository);
  });

  const tTechnicianId = 42;
  const tDate = '2026-04-07';

  const tSlot = AvailabilitySlotEntity(
    timeString: '10:00 AM',
    isoStart: '2026-04-07T10:00:00+05:00',
    isoEnd: '2026-04-07T11:00:00+05:00',
    period: 'AM',
  );

  test(
    'delegates all params to repository.getAvailability unchanged',
    () async {
      when(
        () => mockRepository.getAvailability(
          technicianId: any(named: 'technicianId'),
          date: any(named: 'date'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
        ),
      ).thenAnswer((_) async => [tSlot]);

      final result = await useCase.call(
        technicianId: tTechnicianId,
        date: tDate,
        serviceId: 3,
        subServiceId: 7,
      );

      expect(result, [tSlot]);
      verify(
        () => mockRepository.getAvailability(
          technicianId: tTechnicianId,
          date: tDate,
          serviceId: 3,
          subServiceId: 7,
        ),
      ).called(1);
    },
  );

  test('propagates BookingNetworkFailure from repository', () {
    when(
      () => mockRepository.getAvailability(
        technicianId: any(named: 'technicianId'),
        date: any(named: 'date'),
        serviceId: any(named: 'serviceId'),
        subServiceId: any(named: 'subServiceId'),
      ),
    ).thenThrow(const BookingNetworkFailure());

    expect(
      () => useCase.call(technicianId: tTechnicianId, date: tDate),
      throwsA(isA<BookingNetworkFailure>()),
    );
  });
}
