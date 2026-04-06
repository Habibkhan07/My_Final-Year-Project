import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/data_sources/home_remote_data_source.dart';
import '../../data/data_sources/home_local_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home_feed_usecase.dart';
import '../../../../technician/onboarding/presentation/providers/dependency_injection.dart'; // For sharedPreferencesProvider

part 'dependency_injection.g.dart';

// --- DATA LAYER PROVIDERS ---

@Riverpod(keepAlive: true)
HomeRemoteDataSource homeRemoteDataSource(Ref ref) {
  return HomeRemoteDataSource();
}

@Riverpod(keepAlive: true)
HomeLocalDataSource homeLocalDataSource(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HomeLocalDataSource(prefs);
}

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) {
  final remoteDataSource = ref.watch(homeRemoteDataSourceProvider);
  final localDataSource = ref.watch(homeLocalDataSourceProvider);
  return HomeRepositoryImpl(remoteDataSource, localDataSource);
}

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

@Riverpod(keepAlive: true)
GetHomeFeedUseCase getHomeFeedUseCase(Ref ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return GetHomeFeedUseCase(repository);
}
