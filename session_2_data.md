# Session 2/4: Data Layer — Karigar Real-Time Events

## Context

Session 1 is complete. The Domain layer exists at `lib/core/domain/`. Read those files first to understand the entity contract, the sealed failure classes, and the enum mappings before writing anything.

This session builds the **Data layer**: JSON model, mapper to Domain, Remote DataSource (REST calls), Local DataSource (SharedPreferences), and Repository (offline-first + error mapping pipeline).

## Backend Endpoints (already live)

- `GET /api/events/sync/?since=<ISO-8601>&limit=50` — Fetch missed events.
- `GET /api/events/unacknowledged/` — Fetch unacknowledged critical events.
- `POST /api/events/ack/` body `{"event_ids": [...]}` — Acknowledge events (204 on success).
- `POST /api/devices/register/` body `{"device_token": ..., "device_type": "android"|"ios"}` — Register FCM token.
- `POST /api/devices/unregister/` body `{"device_token": ...}` — Unregister FCM token.

All errors use the project's **standard error envelope**:
```json
{"status": 400, "code": "validation_error", "message": "...", "errors": {...}}
```

## Constraints

Read `CLAUDE.md` in the repo root. Key reminders for this session:
- **Offline-First Pattern** is mandatory on every read operation (fetch → cache → fallback to cache on `SocketException` → throw `NetworkFailure` if cache empty).
- **4-Step Error Pipeline**: DataSource throws `HttpFailure` → Repository maps via `_mapFailures` helper → throws sealed class from Domain.
- `@freezed` for Data Models only. DataSources and Repositories are standard Dart classes.
- UI/Notifiers must NEVER import storage packages directly — all storage behind `LocalDataSource`.
- All `Duration` and key string constants defined at the top of files as named constants.
- No `print()` — use `dart:developer log()`.

## Workflow

Output a `<scratchpad>` plan. Wait for approval before writing code.

At the end, run `dart run build_runner build --delete-conflicting-outputs` for the Freezed model, then `dart analyze` to verify.

---

## Files to Create

### 1. `lib/core/data/models/system_event_model.dart`

A `@freezed` data class with `json_serializable` integration.

```dart
@freezed
class SystemEventModel with _$SystemEventModel {
  const factory SystemEventModel({
    required String id,
    @JsonKey(name: 'rawType') required String rawType,
    @JsonKey(name: 'targetRole') required String targetRole,
    required String timestamp,  // ISO-8601 string — DateTime parsing happens in mapper
    required Map<String, dynamic> payload,
  }) = _SystemEventModel;

  factory SystemEventModel.fromJson(Map<String, dynamic> json) =>
      _$SystemEventModelFromJson(json);
}
```

**Why `timestamp` is `String` here:** Parsing to `DateTime` is wrapped in try/catch in the mapper so malformed timestamps don't crash the entire listener loop.

### 2. `lib/core/data/mappers/system_event_mapper.dart`

An **extension** on `SystemEventModel`:

```dart
extension SystemEventMapper on SystemEventModel {
  /// Maps Data model to Domain entity.
  /// Returns null if any required field is malformed.
  /// This NEVER throws — the caller skips nulls.
  SystemEventEntity? toDomain() { ... }
}
```

**Logic inside `toDomain()`:**
1. Wrap the entire body in try/catch. On any exception, `log()` and return `null`.
2. Parse `timestamp` string → `DateTime` via `DateTime.parse()`.
3. Map `rawType` → `SystemEventType.fromRawType()`.
4. Map `targetRole` → `TargetRole.fromString()`.
5. Construct via `SystemEventEntity.fromComponents(...)` (the named constructor from session 1 that auto-derives `urgency` and `isCritical`).

**Why return `null` instead of throwing:** The mapper runs on every WebSocket message and every FCM payload. A single malformed event from the backend must not crash the listener loop. Callers simply `.where((e) => e != null)` or `if (entity == null) continue`.

### 3. `lib/core/data/datasources/event_remote_data_source.dart`

A standard Dart class. Accepts `Dio` via constructor. The `Dio` instance is expected to have an auth interceptor attaching `Authorization: Bearer <token>` — this DataSource does not manage tokens.

```dart
class EventRemoteDataSource {
  final Dio _dio;

  /// Applied to every HTTP call in this data source.
  static const _timeout = Duration(seconds: 10);

  const EventRemoteDataSource(this._dio);

  // methods below
}
```

**Methods:**

`Future<List<SystemEventModel>> fetchEventsSince(String isoTimestamp, {int limit = 50})`
- `GET /api/events/sync/?since=$isoTimestamp&limit=$limit`
- On 200: parse body as `List<dynamic>`, map each via `SystemEventModel.fromJson()`.
- On non-200: parse the standard error envelope and throw `HttpFailure(statusCode, message, errors)`.

`Future<List<SystemEventModel>> fetchUnacknowledgedCritical()`
- `GET /api/events/unacknowledged/`
- Same pattern.

`Future<void> acknowledgeEvents(List<String> eventIds)`
- `POST /api/events/ack/` body `{"event_ids": eventIds}`.
- On 204 → return. On non-2xx → throw `HttpFailure`.

`Future<void> registerDevice(String token, String deviceType)`
- `POST /api/devices/register/` body `{"device_token": token, "device_type": deviceType}`.
- On 200/201 → return. On non-2xx → throw `HttpFailure`.

`Future<void> unregisterDevice(String token)`
- `POST /api/devices/unregister/` body `{"device_token": token}`.
- On 200/204 → return. On non-2xx → throw `HttpFailure`.

**Note on `HttpFailure`:** Use the existing `HttpFailure` class from the project's core network layer. If it doesn't exist yet, create it at `lib/core/network/http_failure.dart` with fields `int code`, `String message`, `Map<String, List<String>>? errors`.

### 4. `lib/core/data/datasources/event_local_data_source.dart`

Standard Dart class. Accepts `SharedPreferences` via constructor.

```dart
class EventLocalDataSource {
  final SharedPreferences _prefs;

  /// All keys prefixed to avoid collisions with other features.
  static const _keyPrefix = 'event_sync_';
  static const _keyCachedEvents = '${_keyPrefix}cached_events';
  static const _keyLastSyncTimestamp = '${_keyPrefix}last_sync_timestamp';
  static const _keyPendingBackgroundEvents = '${_keyPrefix}pending_bg_events';
  static const _keyPendingAcks = '${_keyPrefix}pending_acks';

  const EventLocalDataSource(this._prefs);
}
```

**Methods (all must be safe — never throw on corrupt data, return null/empty instead):**

**Event Cache:**
- `void cacheEventList(List<SystemEventModel> events)` — JSON-encode the list of `.toJson()` outputs, write to `_keyCachedEvents`.
- `List<SystemEventModel>? getCachedEventList()` — Read key, JSON-decode, map each to `SystemEventModel.fromJson()`. Return `null` if absent or on any parse error.

**Sync Timestamp:**
- `void saveLastSyncTimestamp(String isoTimestamp)`.
- `String? getLastSyncTimestamp()`.

**Pending Background FCM Events:**
- `void savePendingBackgroundEvent(Map<String, dynamic> eventJson)` — Read existing JSON-encoded list, append, write back. On corrupt data, start fresh list.
- `List<Map<String, dynamic>> consumePendingBackgroundEvents()` — Read all, clear key, return list (or `[]` if empty/corrupt).

**Pending ACKs:**
- `void savePendingAcks(List<String> ids)` — Merge with existing, dedupe, write back.
- `List<String> getPendingAcks()` — Return IDs or `[]`.
- `void clearPendingAcks()`.

**IMPORTANT note for session 3:** The background FCM isolate handler (in session 3) will write to `_keyPendingBackgroundEvents` **directly** via its own `SharedPreferences` instance — it cannot use this DataSource because DI is unavailable in isolates. The key string must stay stable. Document this coupling clearly in the class's dartdoc.

### 5. `lib/core/data/repositories/event_repository.dart`

Standard Dart class. Accepts `EventRemoteDataSource` and `EventLocalDataSource`.

```dart
class EventRepository {
  final EventRemoteDataSource _remote;
  final EventLocalDataSource _local;

  const EventRepository(this._remote, this._local);
}
```

**Methods:**

#### `Future<List<SystemEventEntity>> syncMissedEvents(String isoTimestamp)`

Offline-first + error mapping.

1. Try `_remote.fetchEventsSince(isoTimestamp)`.
2. On success:
   - `_local.cacheEventList(models)`.
   - If models list is non-empty, update `_local.saveLastSyncTimestamp()` with the **newest** event's timestamp.
   - Map each to domain via `.toDomain()`, filter out nulls.
   - Return the domain list.
3. On `SocketException` or `TimeoutException`:
   - `final cached = _local.getCachedEventList()`.
   - If non-null → map to domain, filter nulls, return.
   - If null → throw `const EventSyncNetworkFailure()`.
4. On `HttpFailure` → `_mapFailure(httpFailure)`.

#### `Future<List<SystemEventEntity>> fetchUnacknowledgedCritical()`

Same offline-first + error mapping pattern.

#### `Future<void> acknowledgeEvents(List<String> eventIds)`

Best-effort with local retry queue.

1. Merge with `_local.getPendingAcks()` and dedupe.
2. Try `_remote.acknowledgeEvents(allIds)`.
3. On success → `_local.clearPendingAcks()`.
4. On **any failure** (network, server, timeout) → `_local.savePendingAcks(allIds)`, `log()` the error. **Do NOT throw.** The next sync cycle re-surfaces unacknowledged events and flushes the queue.

#### `Future<void> registerDevice(String token, String deviceType)`

1. Try `_remote.registerDevice(token, deviceType)`.
2. On `SocketException`/`TimeoutException` → throw `const DeviceRegistrationNetworkFailure()`.
3. On `HttpFailure` → `_mapDeviceFailure()`.

#### `Future<void> unregisterDevice(String token)`

Best-effort — on failure, `log()` and swallow. The backend's stale token detection will clean up eventually.

#### `_mapFailure` helper

```dart
Never _mapFailure(HttpFailure failure) {
  switch (failure.code) {
    case 401:
      throw const EventSyncUnauthorized();
    default:
      throw EventSyncServerFailure(failure.message);
  }
}
```

Parallel `_mapDeviceFailure` for device registration.

**Dartdoc each public method** with which sealed class exceptions it throws (project's error contract rule).

---

## Deliverable

Five files under `lib/core/data/`. Plus `lib/core/network/http_failure.dart` if not already present.

Run:
1. `dart run build_runner build --delete-conflicting-outputs` (for the Freezed model).
2. `dart analyze` — must pass with zero errors/warnings.

Output the `<scratchpad>` execution plan and wait for my approval before writing any code.
