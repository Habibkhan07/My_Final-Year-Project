// lib/features/technician/onboarding/presentation/dependency_injection.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data_sources/technician_onboarding_remote_datasource.dart';
import '../../data/data_sources/onboarding_local_data_source.dart';
import '../../data/repositories/technician_onboarding_repository_impl.dart';
import '../../domain/usecases/get_onboarding_metadata_usecase.dart';
import '../../domain/usecases/upload_media_usecase.dart';
import '../../domain/usecases/register_technician_usecase.dart';
import '../../../../auth/presentation/providers/dependency_injection.dart'; // To get authLocalDataSourceProvider

part 'dependency_injection.g.dart';

// --- DATA LAYER PROVIDERS ---

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
}

@Riverpod(keepAlive: true)
OnboardingLocalDataSource onboardingLocalDataSource(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingLocalDataSource(prefs);
}

@riverpod
TechnicianOnboardingRemoteDataSource technicianOnboardingRemoteDataSource(Ref ref) {
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);
  return TechnicianOnboardingRemoteDataSource(authLocalDataSource);
}

@riverpod
TechnicianRepositoryImpl technicianRepository(Ref ref) {
  final remoteDataSource = ref.watch(technicianOnboardingRemoteDataSourceProvider);
  final localDataSource = ref.watch(onboardingLocalDataSourceProvider);
  return TechnicianRepositoryImpl(remoteDataSource, localDataSource);
}

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

@riverpod
GetOnboardingMetadataUseCase getOnboardingMetadataUseCase(Ref ref) {
  final repository = ref.watch(technicianRepositoryProvider);
  return GetOnboardingMetadataUseCase(repository);
}

@riverpod
UploadMediaUseCase uploadMediaUseCase(Ref ref) {
  final repository = ref.watch(technicianRepositoryProvider);
  return UploadMediaUseCase(repository);
}

@riverpod
RegisterTechnicianUseCase registerTechnicianUseCase(Ref ref) {
  final repository = ref.watch(technicianRepositoryProvider);
  return RegisterTechnicianUseCase(repository);
}