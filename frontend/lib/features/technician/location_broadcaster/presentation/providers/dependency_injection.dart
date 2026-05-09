// Dependency injection for the location-broadcaster feature.
//
// The data source / http client live in this DI file rather than
// reusing the realtime singletons because the tech-location POST runs
// (a) from the main isolate when the controller starts the service
// (we do not POST from main directly today, but the data source is
// also useful for future tech-side admin actions), and (b) from
// inside the foreground task isolate, which constructs its own
// `http.Client()` because Riverpod providers don't cross isolate
// boundaries (see `presentation/services/foreground_task_handler.dart`).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/tech_location_remote_data_source.dart';

part 'dependency_injection.g.dart';

/// Per-feature secure-storage instance. Used by the controller to
/// read the auth token before saving it to the foreground task's
/// shared prefs (so the isolate can `Authorization: Token <...>`
/// every POST).
@Riverpod(keepAlive: true)
FlutterSecureStorage locationBroadcasterSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

/// Per-feature http.Client. The controller does not POST itself —
/// only the foreground task isolate posts — but the data source is
/// constructible from main-isolate too for tests + future use.
@Riverpod(keepAlive: true)
http.Client locationBroadcasterHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
TechLocationRemoteDataSource techLocationRemoteDataSource(Ref ref) {
  return TechLocationRemoteDataSource(
    ref.watch(locationBroadcasterHttpClientProvider),
  );
}
