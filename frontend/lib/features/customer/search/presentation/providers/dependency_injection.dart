import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/data_sources/search_local_data_source.dart';
import '../../data/data_sources/search_remote_data_source.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/use_cases/get_search_suggestions_use_case.dart';
import '../../domain/use_cases/get_recent_searches_use_case.dart';
import '../../domain/use_cases/save_recent_search_use_case.dart';
import '../../domain/use_cases/clear_recent_searches_use_case.dart';
import '../../../../technician/onboarding/presentation/providers/dependency_injection.dart'; // Source of sharedPreferencesProvider

part 'dependency_injection.g.dart';

// --- DATA LAYER PROVIDERS ---

@riverpod
SearchRemoteDataSource searchRemoteDataSource(Ref ref) {
  return SearchRemoteDataSource();
}

@riverpod
SearchLocalDataSource searchLocalDataSource(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SearchLocalDataSource(prefs);
}

@riverpod
SearchRepository searchRepository(Ref ref) {
  final remote = ref.watch(searchRemoteDataSourceProvider);
  final local = ref.watch(searchLocalDataSourceProvider);
  return SearchRepositoryImpl(remote, local);
}

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

@riverpod
GetSearchSuggestionsUseCase getSearchSuggestionsUseCase(Ref ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return GetSearchSuggestionsUseCase(repository);
}

@riverpod
GetRecentSearchesUseCase getRecentSearchesUseCase(Ref ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return GetRecentSearchesUseCase(repository);
}

@riverpod
SaveRecentSearchUseCase saveRecentSearchUseCase(Ref ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SaveRecentSearchUseCase(repository);
}

@riverpod
ClearRecentSearchesUseCase clearRecentSearchesUseCase(Ref ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return ClearRecentSearchesUseCase(repository);
}
