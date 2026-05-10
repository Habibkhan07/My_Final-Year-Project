// Dependency injection for the location-broadcaster feature.
//
// The foreground task isolate constructs its OWN `http.Client()`
// because Riverpod providers don't cross isolate boundaries (see
// `presentation/services/foreground_task_handler.dart`). The main
// isolate does not POST to `tech-location` itself, so this DI file
// only carries: secure-storage (for the controller's token read),
// the foreground-task lifecycle service, and the H13 ports for the
// static FlutterForegroundTask + Geolocator surfaces.
//
// Audit F-26 (Batch A): the previously-shipped
// `locationBroadcasterHttpClientProvider` and
// `techLocationRemoteDataSourceProvider` were dead code in
// production — kept "for tests + future tech-side admin actions"
// that never materialised, and the data-source test constructs
// `TechLocationRemoteDataSource(client)` directly with `MockClient`.
// Removed per CLAUDE.md "don't design for hypothetical future
// requirements." If a future feature needs main-isolate POSTs they
// can be reintroduced in one commit.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/adapters/flutter_foreground_task_backend.dart';
import '../../data/adapters/geolocator_backend.dart';
import '../../domain/ports/foreground_task_backend.dart';
import '../../domain/ports/geolocator_backend.dart';
import '../services/foreground_location_lifecycle.dart';

part 'dependency_injection.g.dart';

/// Per-feature secure-storage instance. Used by the controller to
/// read the auth token before saving it to the foreground task's
/// shared prefs (so the isolate can `Authorization: Token <...>`
/// every POST).
@Riverpod(keepAlive: true)
FlutterSecureStorage locationBroadcasterSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

/// Owned by `AppLifecycleOrchestrator.performTeardown`. Stateless —
/// kept as a provider so tests can override with a recording fake.
@Riverpod(keepAlive: true)
ForegroundLocationLifecycle foregroundLocationLifecycle(Ref ref) =>
    ForegroundLocationLifecycle(ref.watch(foregroundTaskBackendProvider));

/// Audit H13: port for the static `FlutterForegroundTask` API used by
/// the main-isolate consumers. Tests override this with a recording fake;
/// production uses `FlutterForegroundTaskBackend` (forwards to the real
/// statics). Stateless on the production side — the package owns its
/// own static state.
@Riverpod(keepAlive: true)
IForegroundTaskBackend foregroundTaskBackend(Ref ref) =>
    const FlutterForegroundTaskBackend();

/// Audit H13: port for the static `Geolocator` calls the controller
/// makes during permission resolution and the settings deep-link.
/// Production uses `GeolocatorBackend`; tests inject a recording fake.
@Riverpod(keepAlive: true)
IGeolocatorBackend geolocatorBackend(Ref ref) => const GeolocatorBackend();
