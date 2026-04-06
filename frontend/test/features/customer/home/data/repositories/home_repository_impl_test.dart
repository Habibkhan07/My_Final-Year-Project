import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/home/data/data_sources/home_remote_data_source.dart';
import 'package:frontend/features/customer/home/data/data_sources/home_local_data_source.dart';
import 'package:frontend/features/customer/home/data/models/home_feed_model.dart';
import 'package:frontend/features/customer/home/data/repositories/home_repository_impl.dart';
import 'package:frontend/features/customer/home/domain/failures/home_failure.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}
class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

class FakeHomeFeedModel extends Fake implements HomeFeedModel {}

void main() {
  late HomeRepositoryImpl repository;
  late MockHomeRemoteDataSource mockRemoteDataSource;
  late MockHomeLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(FakeHomeFeedModel());
  });

  setUp(() {
    mockRemoteDataSource = MockHomeRemoteDataSource();
    mockLocalDataSource = MockHomeLocalDataSource();
    repository = HomeRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  group('HomeRepositoryImpl Error Propagation Pipeline', () {
    const double tLat = 31.5204;
    const double tLng = 74.3587;

    test('should return HomeFeedEntity when remote call is successful and cache the result', () async {
      // Arrange
      const tModel = HomeFeedModel(
        categories: [],
        promotions: [],
        fixedGigs: [],
        topTechnicians: [],
      );
      when(() => mockRemoteDataSource.getHomeFeed(lat: any(named: 'lat'), lng: any(named: 'lng')))
          .thenAnswer((_) async => tModel);
      when(() => mockLocalDataSource.cacheHomeFeed(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.getHomeFeed(lat: tLat, lng: tLng);

      // Assert
      expect(result.categories, isEmpty);
      verify(() => mockRemoteDataSource.getHomeFeed(lat: tLat, lng: tLng)).called(1);
      verify(() => mockLocalDataSource.cacheHomeFeed(tModel)).called(1);
    });

    test('should throw HomeServerFailure on any HttpFailure', () async {
      // Since Home Feed is a read-only BFF endpoint, any HttpFailure is a server-side collapse
      when(() => mockRemoteDataSource.getHomeFeed(lat: any(named: 'lat'), lng: any(named: 'lng')))
          .thenThrow(HttpFailure(statusCode: 500, code: 'server_error', message: 'DB Down', errors: {}));

      expect(
        () => repository.getHomeFeed(lat: tLat, lng: tLng),
        throwsA(isA<HomeServerFailure>().having((e) => e.message, 'message', 'DB Down')),
      );
    });

    test('should return cached data if SocketException occurs and cache is available', () async {
      const tModel = HomeFeedModel(
        categories: [],
        promotions: [],
        fixedGigs: [],
        topTechnicians: [],
      );

      when(() => mockRemoteDataSource.getHomeFeed(lat: any(named: 'lat'), lng: any(named: 'lng')))
          .thenThrow(const SocketException('Failed host lookup'));
      when(() => mockLocalDataSource.getCachedHomeFeed()).thenAnswer((_) async => tModel);

      final result = await repository.getHomeFeed(lat: tLat, lng: tLng);

      expect(result.categories, isEmpty);
      verify(() => mockLocalDataSource.getCachedHomeFeed()).called(1);
    });

    test('should throw HomeNetworkFailure on SocketException if no cache is available', () async {
      when(() => mockRemoteDataSource.getHomeFeed(lat: any(named: 'lat'), lng: any(named: 'lng')))
          .thenThrow(const SocketException('Failed host lookup'));
      when(() => mockLocalDataSource.getCachedHomeFeed()).thenAnswer((_) async => null);

      expect(
        () => repository.getHomeFeed(lat: tLat, lng: tLng),
        throwsA(isA<HomeNetworkFailure>()),
      );
    });

    test('should throw HomeParsingFailure on FormatException', () async {
      when(() => mockRemoteDataSource.getHomeFeed(lat: any(named: 'lat'), lng: any(named: 'lng')))
          .thenThrow(const FormatException('Bad JSON'));

      expect(
        () => repository.getHomeFeed(lat: tLat, lng: tLng),
        throwsA(isA<HomeParsingFailure>()),
      );
    });
  });
}
