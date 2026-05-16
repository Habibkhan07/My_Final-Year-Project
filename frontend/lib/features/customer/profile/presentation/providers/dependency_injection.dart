import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../technician/onboarding/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/profile_local_data_source.dart';
import '../../data/data_sources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../../domain/use_cases/get_me_use_case.dart';
import '../../domain/use_cases/update_me_use_case.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client profileHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage profileSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ---------------------------------------------------------------------------
// Data Sources
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) =>
    ProfileRemoteDataSource(client: ref.watch(profileHttpClientProvider));

@Riverpod(keepAlive: true)
ProfileLocalDataSource profileLocalDataSource(Ref ref) {
  // Reuses the global `sharedPreferencesProvider` defined in the
  // technician onboarding feature — overridden in main.dart's
  // ProviderScope so every feature shares one prefs instance.
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileLocalDataSource(prefs);
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IProfileRepository profileRepository(Ref ref) => ProfileRepositoryImpl(
      remote: ref.watch(profileRemoteDataSourceProvider),
      local: ref.watch(profileLocalDataSourceProvider),
      secureStorage: ref.watch(profileSecureStorageProvider),
    );

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetMeUseCase getMeUseCase(Ref ref) =>
    GetMeUseCase(ref.watch(profileRepositoryProvider));

@Riverpod(keepAlive: true)
UpdateMeUseCase updateMeUseCase(Ref ref) =>
    UpdateMeUseCase(ref.watch(profileRepositoryProvider));
