// DI surface for the technician schedule feature.
//
// Mirrors `features/customer/bookings/presentation/providers/
// dependency_injection.dart`. Every provider is `keepAlive: true`
// because the list/counts notifiers are keepAlive — re-creating
// dependencies on each screen mount would orphan the realtime listener.
//
// Boot-time `SharedPreferences` instance comes from the shared
// `sharedPreferencesProvider` (declared once in the technician onboarding
// feature for historical reasons; every feature that touches local
// storage already imports from there). The provider is overridden in
// `main.dart` with the real `SharedPreferences.getInstance()` result.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../onboarding/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/scheduled_jobs_local_data_source.dart';
import '../../data/data_sources/scheduled_jobs_remote_data_source.dart';
import '../../data/repositories/scheduled_jobs_repository_impl.dart';
import '../../domain/repositories/scheduled_jobs_repository.dart';
import '../../domain/use_cases/get_scheduled_jobs_counts_use_case.dart';
import '../../domain/use_cases/get_scheduled_jobs_use_case.dart';

part 'dependency_injection.g.dart';

// ─── Infrastructure ─────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
http.Client scheduledJobsHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage scheduledJobsSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ─── Data Sources ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IScheduledJobsRemoteDataSource scheduledJobsRemoteDataSource(Ref ref) =>
    ScheduledJobsRemoteDataSource(
      client: ref.watch(scheduledJobsHttpClientProvider),
      secureStorage: ref.watch(scheduledJobsSecureStorageProvider),
    );

@Riverpod(keepAlive: true)
IScheduledJobsLocalDataSource scheduledJobsLocalDataSource(Ref ref) =>
    ScheduledJobsLocalDataSource(ref.watch(sharedPreferencesProvider));

// ─── Repository ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IScheduledJobsRepository scheduledJobsRepository(Ref ref) =>
    ScheduledJobsRepositoryImpl(
      remote: ref.watch(scheduledJobsRemoteDataSourceProvider),
      local: ref.watch(scheduledJobsLocalDataSourceProvider),
    );

// ─── Use Cases ───────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GetScheduledJobsUseCase getScheduledJobsUseCase(Ref ref) =>
    GetScheduledJobsUseCase(ref.watch(scheduledJobsRepositoryProvider));

@Riverpod(keepAlive: true)
GetScheduledJobsCountsUseCase getScheduledJobsCountsUseCase(Ref ref) =>
    GetScheduledJobsCountsUseCase(ref.watch(scheduledJobsRepositoryProvider));
