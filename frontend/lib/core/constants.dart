import 'package:flutter/foundation.dart';

class AppConstants {
  // We added the /api prefix here so the Remote Data Sources don't have to!
  static const String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://127.0.0.1:8000/api';

  // WebSocket origin — mirrors [baseUrl]'s host. Has no `/api` prefix because
  // Django Channels mounts its routes at the project root (e.g. `/ws/events/`).
  // Tech-debt: migrate baseUrl + baseWsUrl to --dart-define once an
  // env-loading story is agreed. For now they are hardcoded for dev.
  static const String baseWsUrl = kIsWeb
      ? 'ws://127.0.0.1:8000'
      : 'ws://127.0.0.1:8000';
}