import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/search/data/data_sources/search_local_data_source.dart';
import 'package:frontend/features/customer/search/data/data_sources/search_remote_data_source.dart';
import 'package:frontend/features/customer/search/data/models/search_result_model.dart';
import 'package:frontend/features/customer/search/data/repositories/search_repository_impl.dart';
import 'package:frontend/features/customer/search/domain/failures/search_failure.dart';

class MockSearchRemoteDataSource extends Mock implements SearchRemoteDataSource {}
class MockSearchLocalDataSource extends Mock implements SearchLocalDataSource {}

void main() {
  late SearchRepositoryImpl repository;
  late MockSearchRemoteDataSource mockRemoteDataSource;
  late MockSearchLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockSearchRemoteDataSource();
    mockLocalDataSource = MockSearchLocalDataSource();
    repository = SearchRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  const tQuery = 'plumbing';
  final tSearchResultModel = SearchResultModel(
    id: 1,
    name: 'Pipe Fix',
    categoryName: 'Plumbing',
    basePrice: '500.00',
    isFixedPrice: true,
  );

  group('SearchRepositoryImpl - getSuggestions', () {
    test('should return entities when remote call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.getSuggestions(any()))
          .thenAnswer((_) async => [tSearchResultModel]);

      // Act
      final result = await repository.getSuggestions(tQuery);

      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Pipe Fix');
      verify(() => mockRemoteDataSource.getSuggestions(tQuery)).called(1);
    });

    test('should throw SearchNetworkFailure on SocketException', () async {
      // Arrange
      when(() => mockRemoteDataSource.getSuggestions(any()))
          .thenThrow(const SocketException('No Internet'));

      // Act & Assert
      expect(() => repository.getSuggestions(tQuery), throwsA(isA<SearchNetworkFailure>()));
    });

    test('should throw SearchServerFailure on HttpFailure', () async {
      // Arrange
      when(() => mockRemoteDataSource.getSuggestions(any()))
          .thenThrow(HttpFailure(statusCode: 500, code: 'server_error', message: 'Explosion', errors: {}));

      // Act & Assert
      expect(
        () => repository.getSuggestions(tQuery), 
        throwsA(isA<SearchServerFailure>().having((e) => e.message, 'message', 'Explosion'))
      );
    });
  });

  group('SearchRepositoryImpl - Recent Searches', () {
    test('should call localDataSource.saveRecentSearch when query is not empty', () async {
      // Arrange
      when(() => mockLocalDataSource.saveRecentSearch(any())).thenAnswer((_) async => Future.value());

      // Act
      await repository.saveRecentSearch('  cleaning  ');

      // Assert
      verify(() => mockLocalDataSource.saveRecentSearch('cleaning')).called(1);
    });

    test('should NOT call localDataSource.saveRecentSearch when query is empty', () async {
      // Act
      await repository.saveRecentSearch('   ');

      // Assert
      verifyNever(() => mockLocalDataSource.saveRecentSearch(any()));
    });
  });
}
