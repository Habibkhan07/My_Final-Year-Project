// DI surface for the incoming job requests feature.
//
// Two distinct provider chains live here:
//
//   * **Sound player** — a Provider (no codegen) for the placeholder
//     stock-alert sound. Swap path documented inline.
//
//   * **Action chain** (data source → repository → use cases) — codegen
//     `@Riverpod(keepAlive: true)` providers wiring the technician's
//     accept/decline endpoints. The notifier reads the use cases (not the
//     repository directly) so the layering matches CLAUDE.md's Clean
//     Architecture rules. All four are `keepAlive` because the queue
//     notifier itself is keepAlive — re-creating dependencies on every
//     screen mount would orphan the in-flight request set.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/incoming_job_remote_data_source.dart';
import '../../data/repositories/incoming_job_repository_impl.dart';
import '../../domain/repositories/incoming_job_repository.dart';
import '../../domain/use_cases/accept_job_request_use_case.dart';
import '../../domain/use_cases/decline_job_request_use_case.dart';
import '../services/incoming_job_sound_player.dart';

part 'dependency_injection.g.dart';

// ---------------------------------------------------------------------------
// Sound player (placeholder; see flag.md #18 for the swap path)
// ---------------------------------------------------------------------------

/// Plays the audio cue for a new offer surfacing as the head of the queue.
/// Consumed by `IncomingJobSheetHost` during the vanish-reappear ceremony.
///
/// Today's binding is the placeholder `SystemSoundIncomingJobSoundPlayer`
/// which delegates to Flutter's built-in alert sound. To swap to a custom
/// chime: override this provider in the test/app setup with an
/// `AssetIncomingJobSoundPlayer` (or similar) that loads a bundled audio
/// asset via `audioplayers`. No host or widget changes required.
final incomingJobSoundPlayerProvider = Provider<IncomingJobSoundPlayer>(
  (ref) => const SystemSoundIncomingJobSoundPlayer(),
);

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
http.Client incomingJobHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
FlutterSecureStorage incomingJobSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ---------------------------------------------------------------------------
// Data Source
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IIncomingJobRemoteDataSource incomingJobRemoteDataSource(Ref ref) =>
    IncomingJobRemoteDataSource(
      client: ref.watch(incomingJobHttpClientProvider),
      secureStorage: ref.watch(incomingJobSecureStorageProvider),
    );

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
IIncomingJobRepository incomingJobRepository(Ref ref) =>
    IncomingJobRepositoryImpl(ref.watch(incomingJobRemoteDataSourceProvider));

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AcceptJobRequestUseCase acceptJobRequestUseCase(Ref ref) =>
    AcceptJobRequestUseCase(ref.watch(incomingJobRepositoryProvider));

@Riverpod(keepAlive: true)
DeclineJobRequestUseCase declineJobRequestUseCase(Ref ref) =>
    DeclineJobRequestUseCase(ref.watch(incomingJobRepositoryProvider));
