import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/event_local_data_source.dart';
import '../../data/datasources/event_remote_data_source.dart';
import '../../data/repositories/event_repository.dart';
import '../notifiers/event_sync_notifier.dart';
import '../notifiers/system_event_notifier.dart';
import '../services/fcm_handler.dart';
// SharedPreferences comes from the existing technician-onboarding DI; the
// main() entrypoint overrides it with the async-loaded instance. Reusing
// the same provider guarantees we're looking at the same SharedPreferences
// instance the FCM background isolate writes into.
import '../../../../features/technician/onboarding/presentation/providers/dependency_injection.dart';

part 'dependency_injection.g.dart';

/// Leaf-only wiring for the realtime event subsystem. Notifier classes
/// auto-register via `@riverpod` on their declarations — do NOT add them
/// here; duplicating would produce two distinct provider instances and
/// defeat the single-ingestion guarantee of [SystemEventNotifier].

// ─── Infrastructure ────────────────────────────────────────────────────────

/// Dedicated http.Client for the event remote. Kept separate from the
/// addresses feature's client so disposing one doesn't affect the other.
@Riverpod(keepAlive: true)
http.Client eventHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
FlutterSecureStorage eventSecureStorage(Ref ref) => const FlutterSecureStorage();

// ─── Data Sources ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
EventRemoteDataSource eventRemoteDataSource(Ref ref) {
  return EventRemoteDataSource(
    client: ref.watch(eventHttpClientProvider),
    secureStorage: ref.watch(eventSecureStorageProvider),
  );
}

@Riverpod(keepAlive: true)
EventLocalDataSource eventLocalDataSource(Ref ref) {
  // sharedPreferencesProvider is declared in the onboarding feature's DI
  // file and overridden in main() with the async-loaded instance.
  final prefs = ref.watch(sharedPreferencesProvider);
  return EventLocalDataSource(prefs);
}

// ─── Repository ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository(
    ref.watch(eventRemoteDataSourceProvider),
    ref.watch(eventLocalDataSourceProvider),
  );
}

// ─── FCM Handler ──────────────────────────────────────────────────────────

/// Instantiated once by the App Lifecycle Orchestrator in session 4. The
/// handler owns stream subscriptions, so this provider is keepAlive to
/// prevent repeated instantiation from double-subscribing to Firebase
/// message streams.
@Riverpod(keepAlive: true)
FCMHandler fcmHandler(Ref ref) {
  return FCMHandler(
    eventNotifier: ref.read(systemEventProvider.notifier),
    syncNotifier: ref.read(eventSyncProvider.notifier),
    repository: ref.watch(eventRepositoryProvider),
    localDataSource: ref.watch(eventLocalDataSourceProvider),
  );
}
