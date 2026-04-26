# Session 4/4: Lifecycle Orchestrator, Feature Doc, Test Suite — Karigar Real-Time Events

## Context

Sessions 1-3 complete. Domain, Data, and Presentation layers all exist. **Read the presentation layer first** — especially `WsConnectionNotifier`, `EventSyncNotifier`, `FCMHandler`, `EventUrgencyRouter`, and the DI file — before writing anything.

This final session wires everything into app lifecycle, writes the feature documentation, and suggests the test suite for approval.

## Constraints

Read `CLAUDE.md`. Critical for this session:
- **Feature doc is mandatory** at finalization: `lib/core/REALTIME_EVENTS_FEATURE.md`.
- Test framework: `flutter_test` + `mocktail` only (no `mockito`).
- Test directory mirrors `lib/` exactly.
- **State-layer tests use `ProviderContainer`** — NEVER mount widgets to test Notifiers.
- Testing warm-up: `await container.read(provider.future)` before mutations.
- **Suggest the test suite for approval before writing tests** (per `CLAUDE.md` rule).

## Workflow

Output a `<scratchpad>` plan. Wait for approval before writing any code.

---

## Part 1: App Lifecycle Orchestrator

### `lib/core/presentation/app_lifecycle_orchestrator.dart`

A `ConsumerStatefulWidget` that wraps the app root (placed above `MaterialApp.router` in the widget tree). Uses `WidgetsBindingObserver` to hook into lifecycle transitions.

**Responsibilities:**
1. Wire the boot sequence after authentication.
2. Handle logout teardown.
3. Handle app resume / pause transitions.
4. Set up the `ref.listen` that drives the `EventUrgencyRouter`.

```dart
class AppLifecycleOrchestrator extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const AppLifecycleOrchestrator({
    required this.child,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    super.key,
  });

  @override
  ConsumerState<AppLifecycleOrchestrator> createState() =>
      _AppLifecycleOrchestratorState();
}
```

**State class implements `WidgetsBindingObserver`.**

### `initState()`
1. `WidgetsBinding.instance.addObserver(this)`.
2. Instantiate the `EventUrgencyRouter` with the provided keys.
3. Set up `ref.listenManual(systemEventNotifierProvider, (prev, next) { ... })`:
   - Only act when `next.latestEvent` changed AND is non-null.
   - Read current user role from the existing auth provider.
   - Call `router.handleEvent(next.latestEvent!, currentRole, ref)`.

### `dispose()`
1. `WidgetsBinding.instance.removeObserver(this)`.
2. Close the `ref.listenManual` subscription.

### `didChangeAppLifecycleState(AppLifecycleState state)`

Handle `resumed` and `paused` only.

**On `AppLifecycleState.resumed`:**
1. Read current auth status. If not authenticated → no action.
2. Read `ref.read(wsConnectionNotifierProvider)`:
   - If `disconnected` or `failed` → `ref.read(wsConnectionNotifierProvider.notifier).connect(authToken)`.
     - This triggers the full cascade: socket connect → `syncMissedEvents()` → `syncUnacknowledgedCritical()` → flush pending ACKs.
   - If `connected` → call `ref.read(eventSyncNotifierProvider.notifier).syncMissedEvents()` directly. Socket may have been alive but OS might have dropped messages while backgrounded.
3. `ref.read(fcmHandlerProvider).processPendingBackgroundEvents()` — flush isolate storage.

**On `AppLifecycleState.paused`:**
No action. WebSocket stays alive as long as OS allows. FCM handles background delivery.

### Public methods (exposed for auth integration)

The auth feature (login/logout) needs to trigger boot and teardown. Expose:

**`static Future<void> bootAfterAuth(WidgetRef ref, String authToken)`:**
Execute in order:
1. `await ref.read(fcmHandlerProvider).initialize()` — permissions, token registration, listeners, pending background events.
2. `await ref.read(wsConnectionNotifierProvider.notifier).connect(authToken)` — cascades sync pipeline.
   - Note: The router listener set up in `initState` activates automatically once events start flowing.

**`static Future<void> teardownOnLogout(WidgetRef ref)`:**
Execute in order:
1. `ref.read(wsConnectionNotifierProvider.notifier).disconnect()` — clean close, no reconnect.
2. `await ref.read(fcmHandlerProvider).unregister()` — unregister device token.
3. `ref.read(systemEventNotifierProvider.notifier).reset()` — clear dedup set, latest event, sync timestamp.

### `build()`

Return `widget.child` unchanged. This widget is purely a lifecycle hook — it does not render anything of its own.

### Integration note

The widget must be placed in the tree so that `navigatorKey` and `scaffoldMessengerKey` are attached to `MaterialApp.router` via `routerConfig` and `scaffoldMessengerKey` respectively. Document this in the dartdoc at the top of the file with a usage snippet.

---

## Part 2: Feature Documentation

### `lib/core/REALTIME_EVENTS_FEATURE.md`

Follow the project's `<FEATURE>_FEATURE.md` convention from `CLAUDE.md`. Cover:

**1. Overview**
- One-paragraph summary: what this feature solves (resilient dual-barrel delivery with offline recovery and critical-event ACK).
- The three delivery channels: WebSocket (primary), FCM (fallback), REST sync (recovery).

**2. Architecture Diagram (ASCII or Mermaid)**
Show the flow: Django → WebSocket/FCM → `WsConnectionNotifier`/`FCMHandler` → `SystemEventNotifier` (dedup + ordering) → `EventUrgencyRouter` → UI (full-screen or banner).
Show the recovery path: `syncMissedEvents` → `EventRepository` → `EventRemoteDataSource` → `/api/events/sync/`.

**3. Domain Entities**
Table with each entity, its fields, and which backend endpoint/channel feeds it.

**4. Sealed Failure Hierarchy**
Table: failure class | when thrown | recommended UI response (which Snackbar copy).

**5. Repository Interface Contract**
Table for each method: signature | throws | offline-first behavior.

**6. Use Cases**
List the user-facing scenarios this infrastructure enables:
- Technician gets new job notification while app open (WebSocket → full-screen).
- Technician gets new job notification while app closed (FCM → tap → full-screen on cold start).
- Customer was offline for an hour, comes back online (WebSocket reconnect → sync → missed events surface).
- Critical event never ACK'd (next sync re-surfaces via unacknowledged endpoint).
- Chat message while browsing (low-urgency banner).

**7. Data Sources**
- `EventRemoteDataSource`: endpoints, timeout (10s), auth via Dio interceptor.
- `EventLocalDataSource`: SharedPreferences keys, coupling with the background isolate handler.

**8. Repository Impl Flow (Offline-First)**
Explicit step list for `syncMissedEvents` showing the try/cache/fallback sequence.

**9. Error Propagation Pipeline**
Concrete example: `SocketException` in DataSource → Repository catches → maps to `EventSyncNetworkFailure` → UI `switch` emits "No connection — showing cached events" Snackbar.

**10. DI Wiring**
List every provider in `dependency_injection.dart` and `connection_status_provider.dart` with their dependencies.

**11. FCM Background Isolate Constraint**
Explain WHY the isolate accesses `SharedPreferences` directly instead of through `EventLocalDataSource`. Warn future contributors to keep the `_keyPendingBackgroundEvents` constant in sync between the two files.

**12. Configuration**
Environment variables required:
- `KARIGAR_WS_BASE_URL` (e.g., `wss://api.karigar.com`)
- `KARIGAR_API_BASE_URL` for REST endpoints.
- Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`).

**13. Boot & Teardown Integration**
Code snippet showing how auth calls `AppLifecycleOrchestrator.bootAfterAuth()` and `.teardownOnLogout()`.

**14. Known Limitations**
- First-time app launch has a 24-hour sync window fallback — longer offline periods lose events older than 24h.
- FCM background isolate failures are silent (storage write fails). Recovered by next reconnect + sync.
- iOS background WebSocket is subject to OS throttling. FCM is the reliable fallback.

**15. Status**
Mark all layers as `✅ complete`. This line gets updated if feature screens are added later that consume these events.

---

## Part 3: Test Suite Suggestion (DO NOT WRITE YET)

Per `CLAUDE.md`: "When a feature is complete, suggest the full test suite for approval before writing it."

Output a markdown list of every test file you propose, organized by layer. For each file, list the test cases as bullet points. **Wait for explicit approval** before writing any test code.

### Data Layer Tests (`test/core/data/`)

**`test/core/data/models/system_event_model_test.dart`**
- Parses a valid backend payload with all fields present.
- `fromJson` throws on missing required field (Freezed default behavior — document that this is acceptable because the mapper catches it).
- Round-trips `toJson` → `fromJson` without data loss.

**`test/core/data/mappers/system_event_mapper_test.dart`**
- `toDomain()` correctly maps a valid model.
- `toDomain()` returns `null` when `timestamp` is malformed.
- `toDomain()` maps unknown `rawType` to `SystemEventType.unknown` (does NOT return null — unknown is a valid entity state).
- `toDomain()` maps unknown `targetRole` to `TargetRole.customer` (defensive default).
- `toDomain()` correctly derives `urgency` and `isCritical` for every known event type.

**`test/core/data/datasources/event_remote_data_source_test.dart`**
Mock `Dio`.
- `fetchEventsSince` returns list on 200.
- `fetchEventsSince` throws `HttpFailure(400, ...)` with parsed error envelope on 400.
- `fetchEventsSince` throws `HttpFailure(401, ...)` on 401.
- `fetchEventsSince` throws `HttpFailure(500, ...)` on 500.
- `acknowledgeEvents` succeeds on 204.
- `acknowledgeEvents` sends correct request body shape.
- `registerDevice` sends correct request body shape.

**`test/core/data/datasources/event_local_data_source_test.dart`**
Mock `SharedPreferences`.
- `cacheEventList` + `getCachedEventList` round-trips.
- `getCachedEventList` returns `null` on missing key.
- `getCachedEventList` returns `null` on corrupt JSON.
- `consumePendingBackgroundEvents` returns list and clears key.
- `consumePendingBackgroundEvents` returns `[]` on corrupt data.
- `savePendingAcks` dedupes IDs.

**`test/core/data/repositories/event_repository_test.dart`**
Mock `EventRemoteDataSource` and `EventLocalDataSource`.
- `syncMissedEvents` caches response on network success.
- `syncMissedEvents` updates `lastSyncTimestamp` to newest event's timestamp.
- `syncMissedEvents` returns cached data on `SocketException`.
- `syncMissedEvents` throws `EventSyncNetworkFailure` when cache empty and network fails.
- `syncMissedEvents` throws `EventSyncUnauthorized` on 401.
- `syncMissedEvents` throws `EventSyncServerFailure` on 500.
- `acknowledgeEvents` saves to pending ACKs on network failure.
- `acknowledgeEvents` merges with existing pending ACKs and dedupes.
- `acknowledgeEvents` clears pending ACKs on success.
- `acknowledgeEvents` does NOT throw on network failure.
- `unregisterDevice` does NOT throw on network failure.
- `registerDevice` throws `DeviceRegistrationNetworkFailure` on `SocketException`.

### State Layer Tests (`test/core/presentation/`)

**`test/core/presentation/notifiers/system_event_notifier_test.dart`**
Use `ProviderContainer`. Await provider warm-up before mutations.
- `processEvent` returns `true` for a new event and updates `latestEvent`.
- `processEvent` returns `false` for a duplicate ID (dedup).
- `processEvent` returns `false` for an older event of the same `rawType` (order guard).
- `processEvent` returns `true` for an older event of a DIFFERENT `rawType` (order guard is same-type only).
- `processEvent` prunes dedup map at 100-entry threshold, keeping newest 50.
- `processEvent` updates `lastSyncTimestamp` to newer event timestamps only.
- `reset` clears all state back to initial.

**`test/core/presentation/notifiers/ws_connection_notifier_test.dart`**
Mock `WebSocketChannel` factory.
- `connect` emits `connecting` → `connected` on successful handshake.
- `connect` triggers `syncMissedEvents` on successful connection.
- Incoming valid message feeds `SystemEventNotifier.processEvent`.
- Incoming malformed JSON is logged and skipped — listener loop continues.
- On socket `onDone`, state becomes `reconnecting` and timer is scheduled.
- Backoff sequence: 1s → 2s → 4s → 8s → 16s → 30s cap (test the clamp).
- After 10 consecutive failures, state becomes `failed` but retries continue at max backoff.
- `disconnect` sets `_manualDisconnect = true` and prevents reconnect on subsequent `onDone`.

**`test/core/presentation/notifiers/event_sync_notifier_test.dart`**
Mock `EventRepository` and stub `SystemEventNotifier`.
- `syncMissedEvents` calls repo with correct ISO timestamp from `SystemEventNotifier.getLastSyncTimestamp()`.
- `syncMissedEvents` uses 24-hour fallback when no timestamp exists.
- `syncMissedEvents` feeds results to `SystemEventNotifier` in chronological order.
- `syncMissedEvents` calls `syncUnacknowledgedCritical` after main sync.
- `syncMissedEvents` flushes locally stored pending ACKs on success.
- `acknowledge` does NOT call HTTP immediately (debounce).
- `acknowledge` batches multiple IDs into ONE call after 2-second debounce.
- `acknowledge` dedupes repeated IDs within the same batch.

### Router Tests (`test/core/presentation/router/`)

**`test/core/presentation/router/event_urgency_router_test.dart`**
Mock navigator key and scaffold messenger key. Verify method invocations.
- Ignores event when `targetRole` mismatches current user role.
- Ignores event with `SystemEventType.unknown`.
- Pushes correct route for each high-urgency event type.
- Does NOT push duplicate route if already on target screen with same entity ID.
- Shows banner (no route push) for each low-urgency event type.
- Banner tap pushes correct route.
- Triggers `acknowledge()` for critical events.
- Does NOT trigger `acknowledge()` for non-critical events.

### FCM Tests (`test/core/presentation/services/`)

**`test/core/presentation/services/fcm_handler_test.dart`**
Mock `FirebaseMessaging`, `SystemEventNotifier`, `EventRepository`, `EventLocalDataSource`.
- `initialize` calls components in correct order.
- Foreground message with normal data is fed to notifier.
- Foreground message with string-encoded `payload` field is normalized (jsonDecode) before feeding to notifier.
- Malformed foreground message is logged and skipped.
- `processPendingBackgroundEvents` feeds all stored events to notifier.
- `processPendingBackgroundEvents` handles empty list.
- `unregister` calls repo with current token.
- `unregister` does NOT throw if repo call fails.
- Token refresh triggers re-registration.

### Not Tested (document why)

- `firebaseMessagingBackgroundHandler` top-level function — runs in isolate, cannot be unit tested meaningfully. Covered by integration tests when those are enabled (per `CLAUDE.md`: "Cross-Boundary Integration Testing — Deferred").
- `AppLifecycleOrchestrator` — widget-integration territory, covered when integration tests are enabled.

---

## Deliverable

1. **Code:** `lib/core/presentation/app_lifecycle_orchestrator.dart`.
2. **Doc:** `lib/core/REALTIME_EVENTS_FEATURE.md`.
3. **Test plan:** Markdown list of all proposed test files with test cases. **Do not write tests yet** — wait for my approval on the plan.

Run `dart analyze` on the orchestrator. Must pass.

Output the `<scratchpad>` execution plan and wait for my approval.
