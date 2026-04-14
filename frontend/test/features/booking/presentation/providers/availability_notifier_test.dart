import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/domain/use_cases/get_availability_use_case.dart';
import 'package:frontend/features/booking/presentation/providers/availability_notifier.dart';
import 'package:frontend/features/booking/presentation/providers/dependency_injection.dart';

class MockGetAvailabilityUseCase extends Mock implements GetAvailabilityUseCase {}

void main() {
  late MockGetAvailabilityUseCase mockUseCase;
  late ProviderContainer container;

  const tTechnicianId = 42;
  const tDate = '2026-04-07';

  const tSlotAM = AvailabilitySlotEntity(
    timeString: '9:00 AM',
    isoStart: '2026-04-07T09:00:00+05:00',
    isoEnd: '2026-04-07T10:00:00+05:00',
    period: 'AM',
  );

  const tSlotPM = AvailabilitySlotEntity(
    timeString: '2:00 PM',
    isoStart: '2026-04-07T14:00:00+05:00',
    isoEnd: '2026-04-07T15:00:00+05:00',
    period: 'PM',
  );

  setUp(() {
    mockUseCase = MockGetAvailabilityUseCase();
    container = ProviderContainer(overrides: [
      getAvailabilityUseCaseProvider.overrideWithValue(mockUseCase),
    ]);
    addTearDown(container.dispose);
  });

  ProviderSubscription listen() =>
      container.listen(availabilityProvider(technicianId: tTechnicianId, date: tDate), (_, _) {});

  // ---------------------------------------------------------------------------
  // build — success
  // ---------------------------------------------------------------------------
  group('build', () {
    test('fetches slots and sets state to AsyncData with null selectedSlot', () async {
      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => [tSlotAM, tSlotPM]);

      final sub = listen();
      final state = await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);

      expect(state.slots, [tSlotAM, tSlotPM]);
      expect(state.selectedSlot, isNull);
      sub.close();
    });

    test('sets state to AsyncData with empty slots list when technician has no schedule', () async {
      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => []);

      final sub = listen();
      final state = await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);

      expect(state.slots, isEmpty);
      sub.close();
    });

    test('sets state to AsyncError when use case throws BookingNetworkFailure', () async {
      const tFailure = BookingNetworkFailure();
      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) => Future.error(tFailure));

      final sub = listen();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate));

      expect(state.hasError, isTrue);
      expect(state.error, isA<BookingNetworkFailure>());
      sub.close();
    });

    test('family isolation — different dates produce independent provider instances', () async {
      const tDateB = '2026-04-08';

      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: tDate,
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => [tSlotAM]);

      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: tDateB,
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => [tSlotPM]);

      final sub1 = container.listen(
          availabilityProvider(technicianId: tTechnicianId, date: tDate), (_, _) {});
      final sub2 = container.listen(
          availabilityProvider(technicianId: tTechnicianId, date: tDateB), (_, _) {});

      final stateA = await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);
      final stateB = await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDateB).future);

      expect(stateA.slots, [tSlotAM]);
      expect(stateB.slots, [tSlotPM]);
      sub1.close();
      sub2.close();
    });
  });

  // ---------------------------------------------------------------------------
  // selectSlot
  // ---------------------------------------------------------------------------
  group('selectSlot', () {
    setUp(() {
      when(() => mockUseCase.call(
            technicianId: any(named: 'technicianId'),
            date: any(named: 'date'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
          )).thenAnswer((_) async => [tSlotAM, tSlotPM]);
    });

    test('updates selectedSlot on current AsyncData state', () async {
      final sub = listen();
      await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);

      container
          .read(availabilityProvider(technicianId: tTechnicianId, date: tDate).notifier)
          .selectSlot(tSlotPM);

      final state = container
          .read(availabilityProvider(technicianId: tTechnicianId, date: tDate))
          .requireValue;

      expect(state.selectedSlot, tSlotPM);
      expect(state.slots.length, 2); // slots unchanged
      sub.close();
    });

    test('selecting the same slot twice does not change state reference', () async {
      final sub = listen();
      await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);

      final notifier = container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).notifier);

      notifier.selectSlot(tSlotAM);
      final stateAfterFirst = container
          .read(availabilityProvider(technicianId: tTechnicianId, date: tDate))
          .requireValue;

      notifier.selectSlot(tSlotAM); // same slot — no-op
      final stateAfterSecond = container
          .read(availabilityProvider(technicianId: tTechnicianId, date: tDate))
          .requireValue;

      // Freezed equality: same value object
      expect(stateAfterFirst, stateAfterSecond);
      sub.close();
    });

    test('can change selected slot from one to another', () async {
      final sub = listen();
      await container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).future);

      final notifier = container.read(
          availabilityProvider(technicianId: tTechnicianId, date: tDate).notifier);

      notifier.selectSlot(tSlotAM);
      expect(
          container
              .read(availabilityProvider(technicianId: tTechnicianId, date: tDate))
              .requireValue
              .selectedSlot,
          tSlotAM);

      notifier.selectSlot(tSlotPM);
      expect(
          container
              .read(availabilityProvider(technicianId: tTechnicianId, date: tDate))
              .requireValue
              .selectedSlot,
          tSlotPM);

      sub.close();
    });
  });
}
