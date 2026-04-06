import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/failures/search_failure.dart';
import '../../domain/repositories/search_repository.dart';
import '../data_sources/search_local_data_source.dart';
import '../data_sources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final SearchLocalDataSource localDataSource;

  SearchRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<List<SearchResultEntity>> getSuggestions(String query) async {
    return _mapFailures(() async {
      final models = await remoteDataSource.getSuggestions(query);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<List<String>> getRecentSearches() async {
    return localDataSource.getRecentSearches();
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    await localDataSource.saveRecentSearch(query.trim());
  }

  @override
  Future<void> clearRecentSearches() async {
    await localDataSource.clearRecentSearches();
  }

  /// Mandatory 4-step Error Propagation Pipeline (Section 3B)
  Future<T> _mapFailures<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on HttpFailure catch (e) {
      // Map DRF codes to Domain Failures
      switch (e.code) {
        case 'server_error':
          throw SearchServerFailure(e.message);
        default:
          throw SearchServerFailure(e.message);
      }
    } on SocketException {
      throw const SearchNetworkFailure();
    } on FormatException {
      throw const SearchParsingFailure();
    } catch (e) {
      throw SearchServerFailure("Unexpected search error: ${e.toString()}");
    }
  }
}
