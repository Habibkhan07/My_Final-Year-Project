// lib/features/technician/onboarding/presentation/dependency_injection.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/technician_onboarding_remote_datasource.dart';
import '../../data/repositories/technician_onboarding_repository_impl.dart';
import '../../domain/usecases/get_onboarding_metadata_usecase.dart';
import '../../domain/usecases/upload_media_usecase.dart';
import '../../domain/usecases/register_technician_usecase.dart';

// --- DATA LAYER PROVIDERS ---

// 1. Provide the Raw Data Source
final technicianOnboardingRemoteDataSourceProvider =
    Provider<TechnicianOnboardingRemoteDataSource>((ref) {
      return TechnicianOnboardingRemoteDataSource();
    });

// 2. Provide the Repository Implementation
final technicianRepositoryProvider = Provider<TechnicianRepositoryImpl>((ref) {
  final dataSource = ref.watch(technicianOnboardingRemoteDataSourceProvider);
  return TechnicianRepositoryImpl(dataSource);
});

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

// 3. Provide the Metadata Use Case (Step 1: Get Skills/Cities)
final getOnboardingMetadataUseCaseProvider =
    Provider<GetOnboardingMetadataUseCase>((ref) {
      final repository = ref.watch(technicianRepositoryProvider);
      return GetOnboardingMetadataUseCase(repository);
    });

// 4. Provide the Upload Media Use Case (Phase 1: Multipart)
final uploadMediaUseCaseProvider = Provider<UploadMediaUseCase>((ref) {
  final repository = ref.watch(technicianRepositoryProvider);
  return UploadMediaUseCase(repository);
});

// 5. Provide the Finalize Registration Use Case (Phase 2: JSON)
final registerTechnicianUseCaseProvider = Provider<RegisterTechnicianUseCase>((
  ref,
) {
  final repository = ref.watch(technicianRepositoryProvider);
  return RegisterTechnicianUseCase(repository);
});
