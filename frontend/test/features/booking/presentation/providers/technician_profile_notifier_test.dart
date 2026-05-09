import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/domain/use_cases/get_technician_profile_use_case.dart';
import 'package:frontend/features/booking/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/booking/presentation/providers/technician_profile_notifier.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

class MockGetTechnicianProfileUseCase extends Mock
    implements GetTechnicianProfileUseCase {}

void main() {
  late MockGetTechnicianProfileUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetTechnicianProfileUseCase();
  });

  const tDefaultAddress = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: '123 Main St',
    latitude: 31.5204,
    longitude: 74.3587,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  ProviderContainer makeProviderContainer(
    MockGetTechnicianProfileUseCase useCase,
  ) {
    final container = ProviderContainer(
      overrides: [
        getTechnicianProfileUseCaseProvider.overrideWithValue(useCase),
        addressesProvider.overrideWith(
          (ref) => Future.value([tDefaultAddress]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const tId = 42;
  const tProfileEntity = TechnicianProfileEntity(
    id: 42,
    fullName: 'Ali Raza',
    city: 'LHR',
    profilePicture: null,
    ratingAverage: 4.9,
    reviewCount: 120,
    experienceYears: 5,
    bio: 'bio',
    distanceKm: 2.5,
    bayesianScore: null,
    isActive: true,
    uiRatingText: '4.9',
    primaryPrice: '500',
    primaryPriceRaw: '500.00',
    priceContext: 'Fee',
    promoTag: null,
    skills: [],
    recentReviews: [],
  );

  test('build() returns TechnicianProfileEntity on success', () async {
    when(
      () => mockUseCase.call(
        id: any(named: 'id'),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        serviceId: any(named: 'serviceId'),
        subServiceId: any(named: 'subServiceId'),
        promotionId: any(named: 'promotionId'),
      ),
    ).thenAnswer((_) async => tProfileEntity);

    final container = makeProviderContainer(mockUseCase);
    final provider = technicianProfileProvider(id: tId);

    // Listen to prevent auto-dispose
    final sub = container.listen(provider, (_, __) {});

    // Initial state is loading
    expect(sub.read(), const AsyncLoading<TechnicianProfileEntity>());

    // Wait for the build to finish
    final result = await container.read(provider.future);

    expect(result, tProfileEntity);
    expect(
      sub.read(),
      const AsyncData<TechnicianProfileEntity>(tProfileEntity),
    );
    verify(
      () => mockUseCase.call(id: tId, lat: 31.5204, lng: 74.3587),
    ).called(1);
  });

  test('build() returns AsyncError on failure', () async {
    when(
      () => mockUseCase.call(
        id: any(named: 'id'),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        serviceId: any(named: 'serviceId'),
        subServiceId: any(named: 'subServiceId'),
        promotionId: any(named: 'promotionId'),
      ),
    ).thenThrow(const BookingTechnicianNotFoundFailure());

    final container = makeProviderContainer(mockUseCase);
    final provider = technicianProfileProvider(id: tId);

    // Listen to prevent auto-dispose
    final sub = container.listen(provider, (_, __) {});

    // wait for microtasks to finish
    await Future.delayed(Duration.zero);

    final currentState = sub.read();
    expect(currentState.hasError, isTrue);
    expect(currentState.error, isA<BookingTechnicianNotFoundFailure>());
  });
}
