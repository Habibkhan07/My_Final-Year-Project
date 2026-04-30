import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/domain/use_cases/create_instant_booking_use_case.dart';
import 'package:frontend/features/booking/presentation/providers/booking_notifier.dart';
import 'package:frontend/features/booking/presentation/providers/dependency_injection.dart';

class MockCreateInstantBookingUseCase extends Mock
    implements CreateInstantBookingUseCase {}

void main() {
  late MockCreateInstantBookingUseCase mockUseCase;
  late ProviderContainer container;

  const tEntity = CreatedBookingEntity(bookingId: 99);

  setUp(() {
    mockUseCase = MockCreateInstantBookingUseCase();
    container = ProviderContainer(overrides: [
      createInstantBookingUseCaseProvider.overrideWithValue(mockUseCase),
    ]);
    addTearDown(container.dispose);
  });

  // Helper: runs book() and collects every state the notifier emits.
  Future<List<AsyncValue<CreatedBookingEntity?>>> collectStates(
      Future<void> Function() action) async {
    final states = <AsyncValue<CreatedBookingEntity?>>[];
    final sub = container.listen(instantBookingProvider, (_, next) {
      states.add(next);
    });
    // Capture the initial state before any action
    states.add(container.read(instantBookingProvider));
    await action();
    sub.close();
    return states;
  }

  void stubSuccess() {
    when(() => mockUseCase.call(
          technicianId: any(named: 'technicianId'),
          addressId: any(named: 'addressId'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
        )).thenAnswer((_) async => tEntity);
  }

  void stubFailure(BookingFailure failure) {
    when(() => mockUseCase.call(
          technicianId: any(named: 'technicianId'),
          addressId: any(named: 'addressId'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
          scheduledStart: any(named: 'scheduledStart'),
          scheduledEnd: any(named: 'scheduledEnd'),
        )).thenThrow(failure);
  }

  Future<void> callBook() =>
      container.read(instantBookingProvider.notifier).book(
            technicianId: 42,
            addressId: 7,
            serviceId: 3,
            scheduledStart: '2026-04-07T10:00:00+05:00',
            scheduledEnd: '2026-04-07T11:00:00+05:00',
          );

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------
  test('initial state is AsyncData(null) — no booking attempted', () {
    final state = container.read(instantBookingProvider);
    expect(state, isA<AsyncData<CreatedBookingEntity?>>());
    expect(state.value, isNull);
  });

  // ---------------------------------------------------------------------------
  // book() — success
  // ---------------------------------------------------------------------------
  group('book() — success', () {
    test('transitions AsyncData(null) → AsyncLoading → AsyncData(entity)', () async {
      stubSuccess();

      final states = await collectStates(callBook);

      expect(states[0], isA<AsyncData>()); // initial null
      expect(states[1], isA<AsyncLoading>());
      expect(states[2], isA<AsyncData<CreatedBookingEntity?>>());
      expect(states[2].value?.bookingId, 99);
    });

    test('final state contains the correct CreatedBookingEntity', () async {
      stubSuccess();
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.value, tEntity);
      expect(state.value?.bookingId, 99);
    });
  });

  // ---------------------------------------------------------------------------
  // book() — failures
  // ---------------------------------------------------------------------------
  group('book() — failures', () {
    test('BookingSlotUnavailableFailure → AsyncError (UI pops to availability)', () async {
      stubFailure(const BookingSlotUnavailableFailure());
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<BookingSlotUnavailableFailure>());
    });

    test('BookingNetworkFailure → AsyncError', () async {
      stubFailure(const BookingNetworkFailure());
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<BookingNetworkFailure>());
    });

    test('BookingOutOfServiceAreaFailure → AsyncError preserves human-readable message', () async {
      const tMessage = 'Your address is 14.2 km away (limit: 10 km).';
      stubFailure(const BookingOutOfServiceAreaFailure(tMessage));
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.hasError, isTrue);
      expect(
        (state.error as BookingOutOfServiceAreaFailure).message,
        tMessage,
      );
    });

    test('BookingTechnicianNotFoundFailure → AsyncError', () async {
      stubFailure(const BookingTechnicianNotFoundFailure());
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<BookingTechnicianNotFoundFailure>());
    });

    test('BookingInvalidAddressFailure → AsyncError', () async {
      stubFailure(const BookingInvalidAddressFailure());
      await callBook();

      final state = container.read(instantBookingProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<BookingInvalidAddressFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // Defensive promo firewall — fail-fast at the Flutter layer so we don't
  // waste a round trip on a combination the server is guaranteed to reject.
  // ---------------------------------------------------------------------------
  test('book() asserts when subServiceId AND promotionId are both present', () {
    expect(
      () => container.read(instantBookingProvider.notifier).book(
            technicianId: 42,
            addressId: 7,
            serviceId: 3,
            subServiceId: 17,
            promotionId: 9,
            scheduledStart: '2026-04-08T10:00:00+05:00',
            scheduledEnd: '2026-04-08T11:00:00+05:00',
          ),
      throwsA(isA<AssertionError>()),
    );
  });

  // ---------------------------------------------------------------------------
  // Re-attempt after failure
  // ---------------------------------------------------------------------------
  test('can successfully book after a prior failure', () async {
    stubFailure(const BookingNetworkFailure());
    await callBook();
    expect(container.read(instantBookingProvider).hasError, isTrue);

    // Network recovers — try again
    stubSuccess();
    await callBook();

    final state = container.read(instantBookingProvider);
    expect(state.value?.bookingId, 99);
  });
}
