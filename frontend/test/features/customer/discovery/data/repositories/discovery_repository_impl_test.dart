import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/discovery/data/data_sources/discovery_remote_data_source.dart';
import 'package:frontend/features/customer/discovery/data/models/discovery_models.dart';
import 'package:frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:frontend/features/customer/discovery/domain/failures/discovery_failure.dart';

class MockDiscoveryRemoteDataSource extends Mock implements IDiscoveryRemoteDataSource {}

void main() {
  late DiscoveryRepositoryImpl repository;
  late MockDiscoveryRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockDiscoveryRemoteDataSource();
    repository = DiscoveryRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('DiscoveryRepositoryImpl Error Propagation Pipeline', () {
    const tLat = 31.5204;
    const tLng = 74.3587;

    const tTechnicianModel = TechnicianModel(
      id: 1,
      fullName: 'Ali Raza',
      primaryCategory: 'Plumbing',
      city: 'LHR',
      profilePicture: null,
      ratingAverage: 4.9,
      reviewCount: 120,
      distanceKm: 2.4,
      bayesianScore: 4.8,
      isActive: true,
      uiRatingText: '4.9 (120)',
      primaryPrice: 'Rs. 500',
      priceContext: 'per visit',
      promoTag: null,
      uiSubtitleText: 'Expert',
    );

    const tDiscoveryResultModel = DiscoveryResultModel(
      count: 1,
      next: null,
      previous: null,
      uiPromoBannerText: 'Promo',
      results: [tTechnicianModel],
    );

    test('should return DiscoveryResultEntity when remote call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => tDiscoveryResultModel);

      // Act
      final result = await repository.getNearbyTechnicians(lat: tLat, lng: tLng);

      // Assert
      expect(result.count, 1);
      expect(result.results.first.fullName, 'Ali Raza');
      verify(() => mockRemoteDataSource.getNearbyTechnicians(lat: tLat, lng: tLng)).called(1);
    });

    test('should throw DiscoveryValidationFailure when code is validation_error', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenThrow(HttpFailure(
        statusCode: 400,
        code: 'validation_error',
        message: 'Validation failed',
        errors: {'field': ['error']},
      ));

      // Act & Assert
      expect(
        () => repository.getNearbyTechnicians(lat: tLat, lng: tLng),
        throwsA(isA<DiscoveryValidationFailure>()
            .having((e) => e.message, 'message', 'Validation failed')
            .having((e) => e.errors?['field']?.first, 'first error', 'error')),
      );
    });

    test('should throw DiscoveryUnauthorizedFailure when code is unauthorized', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenThrow(HttpFailure(
        statusCode: 401,
        code: 'unauthorized',
        message: 'No auth',
      ));

      // Act & Assert
      expect(
        () => repository.getNearbyTechnicians(lat: tLat, lng: tLng),
        throwsA(isA<DiscoveryUnauthorizedFailure>()),
      );
    });

    test('should throw DiscoveryNotFoundFailure when code is resource_not_found', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenThrow(HttpFailure(
        statusCode: 404,
        code: 'resource_not_found',
        message: 'Not found',
      ));

      // Act & Assert
      expect(
        () => repository.getNearbyTechnicians(lat: tLat, lng: tLng),
        throwsA(isA<DiscoveryNotFoundFailure>().having((e) => e.message, 'message', 'Not found')),
      );
    });

    test('should throw DiscoveryNetworkFailure on SocketException', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenThrow(const SocketException('No internet'));

      // Act & Assert
      expect(
        () => repository.getNearbyTechnicians(lat: tLat, lng: tLng),
        throwsA(isA<DiscoveryNetworkFailure>()),
      );
    });

    test('should throw DiscoveryUnexpectedFailure on FormatException', () async {
      // Arrange
      when(() => mockRemoteDataSource.getNearbyTechnicians(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            query: any(named: 'query'),
            serviceId: any(named: 'serviceId'),
            subServiceId: any(named: 'subServiceId'),
            promotionId: any(named: 'promotionId'),
            page: any(named: 'page'),
          )).thenThrow(const FormatException('Bad JSON'));

      // Act & Assert
      expect(
        () => repository.getNearbyTechnicians(lat: tLat, lng: tLng),
        throwsA(isA<DiscoveryUnexpectedFailure>()),
      );
    });
  });
}
