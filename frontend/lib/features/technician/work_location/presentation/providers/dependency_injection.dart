import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/work_location_remote_data_source.dart';
import '../../data/repositories/work_location_repository_impl.dart';
import '../../domain/repositories/i_work_location_repository.dart';
import '../../domain/use_cases/get_work_location_use_case.dart';
import '../../domain/use_cases/save_work_location_use_case.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client workLocationHttpClient(Ref ref) => http.Client();

// ---------------------------------------------------------------------------
// Data Source
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
WorkLocationRemoteDataSource workLocationRemoteDataSource(Ref ref) =>
    WorkLocationRemoteDataSource(
      client: ref.watch(workLocationHttpClientProvider),
      authLocalDataSource: ref.watch(authLocalDataSourceProvider),
    );

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IWorkLocationRepository workLocationRepository(Ref ref) =>
    WorkLocationRepositoryImpl(
      ref.watch(workLocationRemoteDataSourceProvider),
    );

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GetWorkLocationUseCase getWorkLocationUseCase(Ref ref) =>
    GetWorkLocationUseCase(ref.watch(workLocationRepositoryProvider));

@Riverpod(keepAlive: true)
SaveWorkLocationUseCase saveWorkLocationUseCase(Ref ref) =>
    SaveWorkLocationUseCase(ref.watch(workLocationRepositoryProvider));
