import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../onboarding/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/skills_local_data_source.dart';
import '../../data/data_sources/skills_remote_data_source.dart';
import '../../data/repositories/skills_repository_impl.dart';
import '../../domain/repositories/i_skills_repository.dart';
import '../../domain/use_cases/add_skill_use_case.dart';
import '../../domain/use_cases/list_available_services_use_case.dart';
import '../../domain/use_cases/list_my_skills_use_case.dart';
import '../../domain/use_cases/remove_skill_use_case.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client skillsHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage skillsSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ---------------------------------------------------------------------------
// Data Sources
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
SkillsRemoteDataSource skillsRemoteDataSource(Ref ref) =>
    SkillsRemoteDataSource(client: ref.watch(skillsHttpClientProvider));

@Riverpod(keepAlive: true)
SkillsLocalDataSource skillsLocalDataSource(Ref ref) {
  // Reuses the global `sharedPreferencesProvider` overridden in
  // main.dart's ProviderScope so every feature shares one prefs.
  final prefs = ref.watch(sharedPreferencesProvider);
  return SkillsLocalDataSource(prefs);
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
ISkillsRepository skillsRepository(Ref ref) => SkillsRepositoryImpl(
      remote: ref.watch(skillsRemoteDataSourceProvider),
      local: ref.watch(skillsLocalDataSourceProvider),
      secureStorage: ref.watch(skillsSecureStorageProvider),
    );

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
ListMySkillsUseCase listMySkillsUseCase(Ref ref) =>
    ListMySkillsUseCase(ref.watch(skillsRepositoryProvider));

@Riverpod(keepAlive: true)
AddSkillUseCase addSkillUseCase(Ref ref) =>
    AddSkillUseCase(ref.watch(skillsRepositoryProvider));

@Riverpod(keepAlive: true)
RemoveSkillUseCase removeSkillUseCase(Ref ref) =>
    RemoveSkillUseCase(ref.watch(skillsRepositoryProvider));

@Riverpod(keepAlive: true)
ListAvailableServicesUseCase listAvailableServicesUseCase(Ref ref) =>
    ListAvailableServicesUseCase(ref.watch(skillsRepositoryProvider));
