import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/repositories/i_booking_repository.dart';
import 'package:frontend/features/booking/domain/use_cases/get_technician_profile_use_case.dart';

class MockBookingRepository extends Mock implements IBookingRepository {}

void main() {
  late GetTechnicianProfileUseCase useCase;
  late MockBookingRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingRepository();
    useCase = GetTechnicianProfileUseCase(mockRepository);
  });

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
    distanceKm: null,
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

  test(
    'should delegate to repository and return TechnicianProfileEntity',
    () async {
      // Arrange
      when(
        () => mockRepository.getTechnicianProfile(
          id: any(named: 'id'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          serviceId: any(named: 'serviceId'),
          subServiceId: any(named: 'subServiceId'),
          promotionId: any(named: 'promotionId'),
        ),
      ).thenAnswer((_) async => tProfileEntity);

      // Act
      final result = await useCase.call(
        id: tId,
        lat: 31.5,
        lng: 74.3,
        serviceId: 1,
        subServiceId: 2,
        promotionId: 3,
      );

      // Assert
      expect(result, tProfileEntity);
      verify(
        () => mockRepository.getTechnicianProfile(
          id: tId,
          lat: 31.5,
          lng: 74.3,
          serviceId: 1,
          subServiceId: 2,
          promotionId: 3,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    },
  );
}
