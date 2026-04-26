# Session 3/4: Presentation Layer — Karigar Real-Time Events

## Context

Sessions 1 and 2 are complete. Domain and Data layers exist at `lib/core/domain/` and `lib/core/data/`. **Read those files first** — especially `SystemEventEntity`, the sealed failure hierarchy, `EventRepository`, and `EventLocalDataSource` — before writing anything in this session.

This is the **heaviest session**. It builds the state management, the WebSocket lifecycle, the REST sync + ACK batching, the FCM handler (including the background isolate), the urgency-based router, and all DI wiring.

## Constraints

Read `CLAUDE.md`. Critical reminders for this session:
- **Riverpod is STRICT**: `@riverpod` annotation + `_$MyNotifier` pattern. NEVER `StateNotifierProvider` or manual `NotifierProvider`.
- **State classes**: `@freezed` immutable only.
- **Async mutations**: ALWAYS `state = await AsyncValue.guard(...)`.
- **Safe data access**: ALWAYS `state.requireValue`, NEVER `state.value!`.
- **DI wiring**: Leaf providers (DataSources, Repositories, utility classes) in a single `dependency_injection.dart`. Notifier providers auto-register — do NOT duplicate them in DI.
- **4-Step Error Pipeline**: UI uses `switch` expression pattern matching on sealed classes → user-friendly Snackbar.
- All `Duration`, integer thresholds, and key strings as **named constants** at the top of files.
- No `print()` — use `dart:developer log()`.

## Workflow

Output a `<scratchpad>` plan listing every file and its dependencies. Wait for approval.

At the end, run `dart run build_runner build --delete-conflicting-outputs` (for Riverpod and Freezed), then `dart analyze`.

---

## Files to Create

### A. State Classes

#### 1. `lib/core/presentation/state/system_event_state.dart`

A `@freezed` immutable state class:

```dart
@freezed
class SystemEventState with _$SystemEventState {
  const factory SystemEventState({
    /// Most recently processed event. Null on initial state.
    SystemEventEntity? latestEvent,

    /// Map of event ID → event timestamp for deduplication.
    /// Capped at 100. When exceeded, oldest 50 are removed in one batch.
    /// Batch pruning is cheaper than one-by-one eviction during bursts —
    /// a chat thread firing 60 messages triggers one prune, not 60.
    @Default({}) Map<String, DateTime> processedEventIds,

    /// Timestamp of most recently processed event. Used as `since`
    /// parameter for the sync endpoint on reconnect.
    DateTime? lastSyncTimestamp,
  }) = _SystemEventState;
}
```

#### 2. `lib/core/presentation/state/connection_state.dart`

```dart
enum WsConnectionStatus {
  /// Initial state before connect() called.
  disconnected,

  /// TCP handshake + auth in progress.
  connecting,

  /// Socket open, auth succeeded, sync triggered.
  connected,

  /// Socket dropped, backoff timer running.
  reconnecting,

  /// 10+ consecutive reconnect failures. UI shows persistent indicator.
  failed,
}
```

---

### B. Notifiers

#### 3. `lib/core/presentation/notifiers/system_event_notifier.dart`

**`@riverpod` generator syntax.**

```dart
@riverpod
class SystemEventNotifier extends _$SystemEventNotifier {
  static const _kMaxDedupEntries = 100;
  static const _kPruneCount = 50;

  @override
  SystemEventState build() => const SystemEventState();

  // methods below
}
```

**`bool processEvent(SystemEventEntity event)`** — execute in this exact order:

1. **Dedup check:** If `event.id` in `state.processedEventIds` → return `false`.

2. **Order guard:** If `state.latestEvent != null` AND incoming event has same `rawType` as `state.latestEvent!.rawType` AND `event.timestamp.isBefore(state.latestEvent!.timestamp)` → return `false`.
   - **Why:** If job goes `DISPATCHED → ACCEPTED → EN_ROUTE` and ACCEPTED arrives via FCM after EN_ROUTE arrived via WebSocket, do not let the older event overwrite the newer one. Same-type only — events of different types represent different things and always process.

3. **Prune check:** If `state.processedEventIds.length >= _kMaxDedupEntries`:
   - Sort entries by `DateTime` value ascending.
   - Take last `_kMaxDedupEntries - _kPruneCount = 50` entries (newest).
   - Build new map.
   - **Do not mutate** — `@freezed` state is immutable, always create new.

4. **Add:** New map = existing (possibly pruned) + `event.id: event.timestamp`.

5. **Update timestamp:** If `event.timestamp` after `state.lastSyncTimestamp` (or lastSync is null) → update.

6. **Emit:** `state = state.copyWith(latestEvent: event, processedEventIds: newMap, lastSyncTimestamp: newTs)`.

7. Return `true`.

**`DateTime? getLastSyncTimestamp()`** → return `state.lastSyncTimestamp`.

**`void reset()`** → `state = const SystemEventState()`. Called on logout.

---

#### 4. `lib/core/presentation/notifiers/ws_connection_notifier.dart`

**`@riverpod` generator syntax.** Owns the entire WebSocket lifecycle.

```dart
@riverpod
class WsConnectionNotifier extends _$WsConnectionNotifier {
  static const _kInitialBackoff = Duration(seconds: 1);
  static const _kMaxBackoff = Duration(seconds: 30);
  static const _kMaxRetries = 10;
  static const _kWsPath = '/ws/events/';

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _retryCount = 0;
  Duration _currentBackoff = _kInitialBackoff;
  bool _manualDisconnect = false;

  @override
  WsConnectionStatus build() {
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _channel?.sink.close();
    });
    return WsConnectionStatus.disconnected;
  }
}
```

**`Future<void> connect(String authToken)`:**

1. `_manualDisconnect = false`.
2. `state = WsConnectionStatus.connecting`.
3. Build URL: `$baseWsUrl$_kWsPath?token=$authToken`. `baseWsUrl` comes from env config (`--dart-define` or `.env`).
4. Open `WebSocketChannel.connect(uri)`.
5. **On successful connection:**
   - `state = WsConnectionStatus.connected`.
   - Reset `_retryCount = 0`, `_currentBackoff = _kInitialBackoff`.
   - `ref.read(eventSyncNotifierProvider.notifier).syncMissedEvents()` — **critical recovery step**.
6. **Listen to stream:**
   - `onData(raw)`: Wrap entire callback in try/catch. `jsonDecode(raw)` → `SystemEventModel.fromJson()` → `.toDomain()` → if non-null, `ref.read(systemEventNotifierProvider.notifier).processEvent(entity)`. Malformed messages are logged and skipped — **never break the listener loop**.
   - `onDone`: If `!_manualDisconnect` → `_scheduleReconnect(authToken)`.
   - `onError(e)`: log, `_scheduleReconnect(authToken)`.

**`void _scheduleReconnect(String authToken)`:**

1. `state = WsConnectionStatus.reconnecting`.
2. `_retryCount++`.
3. If `_retryCount > _kMaxRetries`:
   - `state = WsConnectionStatus.failed`.
   - Log.
   - **Do NOT stop trying** — schedule one more attempt at `_kMaxBackoff`. User can still use REST sync; socket may recover if server was down.
4. `_reconnectTimer = Timer(_currentBackoff, () => connect(authToken))`.
5. Double backoff with cap: `_currentBackoff = Duration(milliseconds: (_currentBackoff.inMilliseconds * 2).clamp(0, _kMaxBackoff.inMilliseconds))`.

**`void disconnect()`:**

1. `_manualDisconnect = true`.
2. `_reconnectTimer?.cancel()`.
3. `_channel?.sink.close()`.
4. `_channel = null`.
5. `state = WsConnectionStatus.disconnected`.
6. Reset retry count and backoff.

---

#### 5. `lib/core/presentation/notifiers/event_sync_notifier.dart`

**`@riverpod` generator syntax.** Handles REST-based recovery and ACK batching.

```dart
@riverpod
class EventSyncNotifier extends _$EventSyncNotifier {
  /// Debounce window: batch all acknowledge() calls made within
  /// this window into a single HTTP request. Prevents 10 separate
  /// calls when 10 critical events arrive after offline period.
  static const _kAckDebounceDuration = Duration(seconds: 2);

  /// Fallback sync window for first-ever launch / fresh install.
  static const _kDefaultSyncWindow = Duration(hours: 24);

  final List<String> _pendingAcks = [];
  Timer? _ackDebounceTimer;

  @override
  Object? build() {
    ref.onDispose(() {
      _ackDebounceTimer?.cancel();
    });
    return null;
  }
}
```

**`Future<void> syncMissedEvents()`:**

1. Read last timestamp: `ref.read(systemEventNotifierProvider.notifier).getLastSyncTimestamp()`.
   - If null → `DateTime.now().subtract(_kDefaultSyncWindow)`.
   - Convert to ISO-8601 UTC string: `.toUtc().toIso8601String()`.
2. Call `ref.read(eventRepositoryProvider).syncMissedEvents(isoTimestamp)`.
3. Sort results by `timestamp` ascending — process in chronological order so `SystemEventNotifier`'s order guard works correctly.
4. For each entity → `ref.read(systemEventNotifierProvider.notifier).processEvent(event)`.
5. Call `syncUnacknowledgedCritical()`.
6. Flush local pending ACKs: `final pending = ref.read(eventLocalDataSourceProvider).getPendingAcks()`. If non-empty, feed to `_flushAcks()`.
7. Wrap entire body in `AsyncValue.guard()`.
8. On `EventSyncUnauthorized` → read auth notifier and trigger logout/refresh.

**`Future<void> syncUnacknowledgedCritical()`:**

1. Call `ref.read(eventRepositoryProvider).fetchUnacknowledgedCritical()`.
2. Feed each into `SystemEventNotifier`. Router re-displays them if user never acted.

**`void acknowledge(String eventId)`:**

1. If `_pendingAcks.contains(eventId)` → return (dedupe).
2. `_pendingAcks.add(eventId)`.
3. `_ackDebounceTimer?.cancel()`.
4. `_ackDebounceTimer = Timer(_kAckDebounceDuration, _flushAcks)`.

**`Future<void> _flushAcks()`:**

1. If `_pendingAcks.isEmpty` → return.
2. `final toSend = List<String>.from(_pendingAcks)`.
3. `_pendingAcks.clear()`.
4. `await ref.read(eventRepositoryProvider).acknowledgeEvents(toSend)` — repository handles failure internally (saves to local for retry), does not throw.

---

### C. Router

#### 6. `lib/core/presentation/router/event_urgency_router.dart`

**Not a Notifier.** A listener function initialized once in the app's root widget via `ref.listen` on `systemEventNotifierProvider`.

```dart
class EventUrgencyRouter {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const EventUrgencyRouter({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  void handleEvent(SystemEventEntity event, TargetRole currentUserRole, WidgetRef ref) {
    // logic below
  }
}
```

**Route mapping constant:**
```dart
static const _highUrgencyRoutes = <SystemEventType, String>{
  SystemEventType.jobDispatched: '/technician/incoming-job',
  SystemEventType.jobAccepted: '/customer/job-accepted',
  SystemEventType.quoteGenerated: '/customer/incoming-quote',
  SystemEventType.quoteApproved: '/technician/quote-approved',
  SystemEventType.jobCompleted: '/shared/job-completed',
  SystemEventType.disputeOpened: '/shared/dispute-details',
  SystemEventType.disputeResolved: '/shared/dispute-resolved',
};

static const _lowUrgencyTapRoutes = <SystemEventType, String>{
  SystemEventType.techEnRoute: '/customer/track-technician',
  SystemEventType.techArrived: '/customer/track-technician',
  SystemEventType.chatMessage: '/shared/chat',
  SystemEventType.paymentReceived: '/shared/wallet',
  SystemEventType.walletLowBalance: '/shared/wallet',
};
```

**Banner icon mapping:**
```dart
static const _bannerIcons = <SystemEventType, IconData>{
  SystemEventType.chatMessage: Icons.chat_bubble,
  SystemEventType.techEnRoute: Icons.location_on,
  SystemEventType.techArrived: Icons.location_on,
  SystemEventType.paymentReceived: Icons.account_balance_wallet,
  SystemEventType.walletLowBalance: Icons.account_balance_wallet_outlined,
};
```

**Logic in `handleEvent`:**

**Step 1 — Role gate:** if `event.targetRole != currentUserRole` → log, return.

**Step 2 — Unknown gate:** if `event.eventType == SystemEventType.unknown` → return.

**Step 3 — Urgency switch** (pattern matching on `event.urgency`):

- **`EventUrgency.highUrgency`:**
  - Look up route from `_highUrgencyRoutes`.
  - **Nav guard:** Read current location from GoRouter. If already on target with same entity ID from payload (e.g., same `job_id`) → skip.
  - Use `GoRouter.of(navigatorKey.currentContext!).pushNamed(route, extra: jsonEncode(event.payload))`. Use `navigatorKey.currentContext!` — not a BuildContext captured from the listener (stale during transitions).

- **`EventUrgency.lowUrgency`:**
  - Do NOT push a route.
  - Build a `MaterialBanner` (or custom overlay):
    - Leading icon from `_bannerIcons`.
    - Title from `SystemEventType` (human-readable: "New Message", "Technician On The Way").
    - Body: a brief summary from `event.payload` (e.g., `payload['sender_name']` for chat).
  - Show via `scaffoldMessengerKey.currentState?.showMaterialBanner(banner)`.
  - Auto-dismiss after **5 seconds** (`Future.delayed(Duration(seconds: 5), () => scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner())`).
  - On tap: look up `_lowUrgencyTapRoutes`, push with encoded payload. Hide banner.

- **`EventUrgency.silent`:** do nothing.

**Step 4 — ACK trigger:**
- After routing (regardless of urgency), if `event.isCritical == true`:
  - `ref.read(eventSyncNotifierProvider.notifier).acknowledge(event.id)` — fire and forget, do NOT await.

---

### D. FCM Handler (Including Background Isolate)

#### 7. `lib/core/presentation/services/fcm_handler.dart`

**Standard Dart class** — not a Notifier. Instantiated once by the App Lifecycle Orchestrator in session 4.

```dart
class FCMHandler {
  final SystemEventNotifier _eventNotifier;
  final EventSyncNotifier _syncNotifier;
  final EventRepository _repository;
  final EventLocalDataSource _localDataSource;

  String? _currentToken;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  FCMHandler({
    required SystemEventNotifier eventNotifier,
    required EventSyncNotifier syncNotifier,
    required EventRepository repository,
    required EventLocalDataSource localDataSource,
  })  : _eventNotifier = eventNotifier,
        _syncNotifier = syncNotifier,
        _repository = repository,
        _localDataSource = localDataSource;
}
```

**`Future<void> initialize()`** — call in order:
1. `requestPermission()`.
2. `_registerToken()`.
3. `_listenForegroundMessages()`.
4. `_setupBackgroundTapHandlers()`.
5. `processPendingBackgroundEvents()`.

**`Future<void> requestPermission()`:** `FirebaseMessaging.instance.requestPermission()`. Log if denied, continue — WebSocket is primary, FCM is fallback.

**`Future<void> _registerToken()`:**
- `_currentToken = await FirebaseMessaging.instance.getToken()`.
- If non-null: `await _repository.registerDevice(_currentToken!, Platform.isIOS ? 'ios' : 'android')`.
- Listen to `onTokenRefresh`:
  - Update `_currentToken`, call `_repository.registerDevice(...)`.

**`void _listenForegroundMessages()`:**
- `_foregroundSub = FirebaseMessaging.onMessage.listen((message) { ... })`.
- Call `_processRemoteMessage(message.data)`.
- **Do NOT show a local notification** — Urgency Router handles UI. Showing both = duplicate UX.

**`void _setupBackgroundTapHandlers()`:**
- `FirebaseMessaging.onMessageOpenedApp.listen((message) => _processRemoteMessage(message.data))`.
- `final initial = await FirebaseMessaging.instance.getInitialMessage()`; if non-null → `_processRemoteMessage(initial.data)`.

**`void _processRemoteMessage(Map<String, dynamic> data)`:**

**CRITICAL — FCM string serialization:** FCM data payloads serialize ALL values as strings. The nested `payload` field arrives as a JSON string, not a Map. Detect and normalize:

```dart
void _processRemoteMessage(Map<String, dynamic> rawData) {
  try {
    // Normalize: FCM serializes nested maps as JSON strings
    final normalized = Map<String, dynamic>.from(rawData);
    if (normalized['payload'] is String) {
      normalized['payload'] = jsonDecode(normalized['payload'] as String);
    }

    final model = SystemEventModel.fromJson(normalized);
    final entity = model.toDomain();
    if (entity != null) {
      _eventNotifier.processEvent(entity);
    }
  } catch (e, st) {
    log('Failed to process FCM message: $e', stackTrace: st);
  }
}
```

**`Future<void> processPendingBackgroundEvents()`:**
- `final pending = _localDataSource.consumePendingBackgroundEvents()`.
- For each → `_processRemoteMessage(data)`.

**`Future<void> unregister()`** (on logout):
- If `_currentToken != null`: `await _repository.unregisterDevice(_currentToken!)`.
- `_currentToken = null`.

**`void dispose()`** — cancel `_foregroundSub` and `_tokenRefreshSub`.

---

#### 8. `lib/core/presentation/services/fcm_background_handler.dart`

**Top-level function.** Runs in a separate Dart isolate. CANNOT access providers, GoRouter, or any Notifier. Can only write to SharedPreferences via its own instance.

```dart
/// TOP-LEVEL function — runs in separate Dart isolate.
/// No DI available. No providers. No Riverpod container.
/// The ONLY legal operation is SharedPreferences writes.
///
/// The key string must match EventLocalDataSource._keyPendingBackgroundEvents.
/// If you change one, change both.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for the background isolate (required on some platforms).
  // If your main.dart already calls Firebase.initializeApp() and you use the
  // DEFAULT app, this may be unnecessary — but it's safe to call defensively.
  // Check Firebase docs for your plugin versions.

  const key = 'event_sync_pending_bg_events';
  final prefs = await SharedPreferences.getInstance();

  try {
    final existing = prefs.getString(key);
    final List<dynamic> list = existing != null
        ? (jsonDecode(existing) as List<dynamic>)
        : <dynamic>[];

    list.add(message.data);

    await prefs.setString(key, jsonEncode(list));
  } catch (e) {
    // Best-effort. If storage fails in the isolate, the event is lost,
    // but the next WebSocket reconnect + sync will recover it anyway.
  }
}
```

Register in `main.dart`:
```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

---

### E. Dependency Injection

#### 9. `lib/core/presentation/providers/dependency_injection.dart`

Wire only **leaf dependencies** (DataSources, Repositories, utility classes). Notifier providers auto-register via `@riverpod` on their class declarations — do NOT duplicate them here.

```dart
@riverpod
EventRemoteDataSource eventRemoteDataSource(Ref ref) {
  final dio = ref.watch(dioProvider); // existing project DI
  return EventRemoteDataSource(dio);
}

@riverpod
EventLocalDataSource eventLocalDataSource(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider); // existing project DI
  return EventLocalDataSource(prefs);
}

@riverpod
EventRepository eventRepository(Ref ref) {
  return EventRepository(
    ref.watch(eventRemoteDataSourceProvider),
    ref.watch(eventLocalDataSourceProvider),
  );
}

@riverpod
FCMHandler fcmHandler(Ref ref) {
  return FCMHandler(
    eventNotifier: ref.read(systemEventNotifierProvider.notifier),
    syncNotifier: ref.read(eventSyncNotifierProvider.notifier),
    repository: ref.watch(eventRepositoryProvider),
    localDataSource: ref.watch(eventLocalDataSourceProvider),
  );
}
```

**Note:** If `dioProvider` or `sharedPreferencesProvider` don't exist in the project yet, create them here following the same pattern.

#### 10. `lib/core/presentation/providers/connection_status_provider.dart`

A **derived provider** so feature screens can watch connection status without rebuilding on every event:

```dart
@riverpod
WsConnectionStatus connectionStatus(Ref ref) {
  return ref.watch(wsConnectionNotifierProvider);
}
```

**Why separate:** Watching `systemEventNotifierProvider` rebuilds on every incoming event (chat messages, arrival alerts). A "connection lost" bar should watch `connectionStatusProvider` — it only rebuilds when connection state changes, which is rare.

---

## Deliverable

10 files total across:
- `lib/core/presentation/state/` (2 files)
- `lib/core/presentation/notifiers/` (3 files)
- `lib/core/presentation/router/` (1 file)
- `lib/core/presentation/services/` (2 files — fcm_handler + fcm_background_handler)
- `lib/core/presentation/providers/` (2 files)

Run:
1. `dart run build_runner build --delete-conflicting-outputs` (for Riverpod generator and Freezed state).
2. `dart analyze` — must pass.

Output the `<scratchpad>` execution plan listing every file and its dependencies. Wait for my approval.
