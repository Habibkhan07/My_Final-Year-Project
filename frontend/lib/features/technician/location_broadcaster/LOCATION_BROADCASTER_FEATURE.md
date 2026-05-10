# Tech Location Broadcaster — Feature

> Tech-side, Android-only Foreground GPS service. Streams the
> technician's GPS to the backend's `/api/bookings/<id>/tech-location/`
> endpoint every ~5 seconds while the booking is `EN_ROUTE` or
> `ARRIVED`. The backend publishes each frame to the booking's
> `tracking_job_<id>` channel-layer subgroup; the customer-side
> orchestrator screen consumes that stream and renders the live map
> (`features/orchestrator/.../technician_location_stream_notifier.dart`).

This feature is the publisher half of the live-tracking pair shipped
in session 4 of the Booking Orchestrator sprint. It is the **only**
place in the codebase that imports `flutter_foreground_task` or runs
inside a foreground-service isolate.

**Audit hardening pass (post-session-4)**: this doc reflects the
current state of the feature including the session-4 audit ship-blocker
fixes (C1–C6) and HIGH-finding remediations (H1, H3, H4). Where prior
behaviour matters for a reader cross-referencing commit history, the
audit ID appears in parentheses next to the relevant claim.

---

## Architecture

```
BookingOrchestratorScreen (tech, status=EN_ROUTE)
    │  ref.watch(foregroundLocationServiceControllerProvider(jobId))
    ▼
ForegroundLocationServiceController
    │  ref.listen(bookingDetailProvider(jobId)) — status × role gate
    │  └── _startService(booking) ─────┐
    └── ref.onDispose → stopService    │
                                       ▼
                              FlutterForegroundTask
                                  init + saveData(config)
                                  + startService(callback)
                                       │
                                       ▼  (Android binds the service,
                                       │   spawns a separate isolate,
                                       │   runs the callback)
                                  ┌────┴────┐
                                  │         │
                          Main isolate    FG isolate
                                          startTechLocationTaskCallback
                                          → TaskHandler.onStart
                                          ──────────────────────
                                          - http.Client() (isolate-local)
                                          - Geolocator.getPositionStream
                                          - per-fix → TechLocationRemoteDataSource.postLocation
                                                       → POST .../tech-location/
                                                          (publishes stream + may auto-transition)
```

---

## Domain entities

| Entity | Purpose |
|---|---|
| [`BroadcastState`](domain/entities/broadcast_state.dart) | `idle / running / permissionDenied / notificationPermissionDenied / error`. Surfaced by the controller; the orchestrator screen renders the [`BroadcastStateBanner`](presentation/widgets/broadcast_state_banner.dart) above the live map when the state is anything other than `idle` / `running` (audit C6). |

No domain failures sealed family — the controller communicates
exclusively via [`BroadcastState`] enum changes.

### Internal lifecycle FSM (`_LifecycleStatus`, audit C4)

The controller maintains a finer-grained internal state distinct from
the UI-facing `BroadcastState`:

| `_LifecycleStatus` | Meaning |
|---|---|
| `idle` | Service is not running and no transition is in flight. |
| `starting` | A start transition is in flight. Set **synchronously before any await** so re-entrant `bookingDetailProvider` fires short-circuit instead of racing two `_startService` calls (audit F-6/F-7/F-8/P-1-3/S-3). |
| `running` | Service is up; GPS frames are flowing. |
| `stopping` | A stop transition is in flight; symmetric guard. |

The transition machinery lives in `_evaluate()` — the single place
that decides start vs stop based on the current `bookingDetail`
snapshot. `_evaluate()` is invoked from the `bookingDetailProvider`
listener AND from the `finally` blocks of `_startService` /
`_stopService`, so a status flip arriving mid-transition is settled
the moment the wire becomes free. Every `await` inside
`_startService` is followed by a `ref.mounted` check; on
dispose-during-start with the platform service likely up, an
explicit cleanup `stopService` fires.

---

## Repository interface contract

There is **no repository** in this feature. The data source is called
directly from inside the foreground task isolate (which can't reach
the main isolate's repository / Riverpod graph anyway). Future tech-
side admin actions on the same endpoint would warrant a repository,
but v1's only consumer is the isolate.

---

## Use cases

None (no business logic beyond "POST GPS to the endpoint" and
"start/stop service based on status × role"). Both live in the
controller and the data source directly.

---

## Data models

| Model | Purpose |
|---|---|
| [`TechLocationRequestModel`](data/models/tech_location_request_model.dart) | Wire DTO for the POST body. `{lat, lng, accuracy_meters?, heading?}` per `backend/bookings/api/tech_location/serializers.py:7`. |

No response model — the backend's `200 {published, transition_fired}`
is consumed implicitly (the data source returns `bool` for accepted /
throttled, throws `HttpFailure` for everything else).

---

## Data sources

| Source | Purpose |
|---|---|
| [`TechLocationRemoteDataSource`](data/datasources/tech_location_remote_data_source.dart) | `package:http`-based POST. Handles `200 → true`, `429 → false (drop)`, `4xx/5xx → HttpFailure`. URL constructed with `${AppConstants.baseUrl}/bookings/$id/tech-location/` (no `/api/` prefix in path; sprint meta §24). 8-second `.timeout(...)` per call (audit H3): a hung POST otherwise blocks the foreground task's serial executor and Geolocator queues fixes behind it, so customers see "tech offline" even though GPS is working. Timeout → `HttpFailure(statusCode: 0, code: 'network_timeout')`; `SocketException` → `HttpFailure(0, 'network_failure')`. |

No local data source (the foreground service has no offline cache —
GPS frames are transient state, not facts to replay).

---

## Repository impl flow

N/A (no repository). The flow is:

1. Controller's `_startService` writes
   `{authToken, bookingId}`-encoded blob via
   `FlutterForegroundTask.saveData`.
2. Controller registers `addTaskDataCallback(_onIsolateData)` so the
   isolate can signal fatal auth errors back to the main isolate
   (audit H4 — see §"Isolate → main fatal-auth channel" below).
3. Foreground task isolate boots; `TaskHandler.onStart` reads the
   blob, decodes via `TechLocationTaskKeys.decodeConfig`.
4. `Geolocator.getPositionStream(distanceFilter: 10, accuracy: high)`
   subscription; each `Position` flows through `_onFix`.
5. `_onFix` calls
   `TechLocationRemoteDataSource.postLocation(..., authToken: ...)`.
   Heading is gated on `position.headingAccuracy <= 0` (audit H1 —
   `position.heading == 0.0` is ambiguous between "facing north" and
   "no compass fix"; the previous `>= 0` check never produced null).
6. Failures are logged (`developer.log`, level 1000) — never silently
   swallowed (audit H4). Specifically:
   - `200` → frame accepted; loop continues.
   - `429` → throttle drop; loop continues.
   - `401` / `403` → fatal auth error. Isolate calls
     `FlutterForegroundTask.sendDataToMain(...)` with a typed
     `fatal_auth_error` envelope. Controller flips state to
     `BroadcastState.error`, stops the service, and **latches** so
     `_evaluate` does not immediately restart with the same bad token.
     The latch clears when the booking transitions out of
     `{EN_ROUTE, ARRIVED}`.
   - Other 4xx/5xx + transient network errors → log + drop the frame.
     Next fix retries implicitly.
7. Controller's `ref.onDispose` calls `stopService` for any
   non-`idle` `_LifecycleStatus` (audit C4 — covers the dispose-mid-start
   race where the prior `bool _running` flag was still false).

---

## Error propagation pipeline

Per CLAUDE.md the four-step pipeline applies; here the layers are
shaped to span an isolate boundary.

| Layer | Behaviour |
|---|---|
| Data Source | 200 → `true`. 429 → `false`. Timeout → `HttpFailure(0, 'network_timeout')`. SocketException → `HttpFailure(0, 'network_failure')`. Other 4xx/5xx → throws `HttpFailure(code, message, errors)`. |
| Isolate task handler | Logs every failure (`developer.log` level 1000) — never the bare `catch (_)` of the original (audit H4). On `HttpFailure(401|403)` forwards a typed fatal envelope to main via `sendDataToMain`. Other failures drop the frame; the next fix retries. |
| Controller (main isolate) | Watches `bookingDetailProvider` and owns `BroadcastState`. Receives isolate fatal envelopes via `addTaskDataCallback`; flips state to `BroadcastState.error` and latches `_fatalAuthErrorLatched = true`. Surfaces `permissionDenied` / `notificationPermissionDenied` / `error` via state changes the orchestrator screen reads. |
| Presentation | The orchestrator screen mounts [`BroadcastStateBanner`](presentation/widgets/broadcast_state_banner.dart) above the map (audit C6) for the three failure states. The banner colour-codes severity (red / amber / orange) and exposes an "Open settings" CTA on the two permission-denied variants (audit C2) — tapping it deeplinks to the OS app-settings page via `Geolocator.openAppSettings()`. |

---

## DI wiring

| Provider | Lifetime | Purpose |
|---|---|---|
| `locationBroadcasterSecureStorageProvider` | keepAlive: true | `FlutterSecureStorage` instance for reading the auth token before saveData. |
| `locationBroadcasterHttpClientProvider` | keepAlive: true | Main-isolate `http.Client`. Used by tests + future tech-side admin actions; the foreground task isolate constructs its OWN client because Riverpod doesn't cross isolates. |
| `techLocationRemoteDataSourceProvider` | keepAlive: true | Wraps the http client. Same caveat: the FG isolate makes its own. |
| `foregroundLocationServiceControllerProvider(int jobId)` | keepAlive: false (family) | The notifier. Watched by `BookingOrchestratorScreen.build`. |
| `foregroundLocationLifecycleProvider` | keepAlive: true | Stateless helper consumed by `AppLifecycleOrchestrator.performTeardown` on logout (audit C3 — see §"Logout teardown" below). |

### Top-level isolate entry-point

[`startTechLocationTaskCallback`](presentation/services/foreground_task_handler.dart)
is `@pragma('vm:entry-point')` and lives at file scope (NOT a
class method) — required by `flutter_foreground_task` so the AOT
compiler retains it for the background isolate.

---

## Lifecycle binding

| Booking transition | Tech viewer | Customer viewer |
|---|---|---|
| `... → EN_ROUTE` | service starts; persistent notification appears | (covered by `TrackingSubscriptionController` — subscribe_tracking goes upstream) |
| `EN_ROUTE → ARRIVED` | service keeps running; notification text unchanged | (still subscribed) |
| `ARRIVED → INSPECTING/QUOTED/...` | service stops; `_fatalAuthErrorLatched` clears | unsubscribe_tracking |
| `... → CANCELLED/REJECTED/NO_SHOW/COMPLETED/COMPLETED_INSPECTION_ONLY/DISPUTED` | service stops | unsubscribe_tracking |
| Screen pop while EN_ROUTE | service stops (`ref.onDispose` fires `stopService` for any non-`idle` `_LifecycleStatus`, audit C4) | (handled identically by `TrackingSubscriptionController`) |
| Logout while EN_ROUTE | service stops AND saved auth-token blob is cleared (audit C3 — see §"Logout teardown") | WS disconnect tears down subscription |

The "service stops on screen pop" behaviour is a v1 limitation —
acceptable because the foreground service is by design tied to app
foreground state. A sprint-v2 promotion of the controller to
keepAlive: true (or a global LocationBroadcasterCoordinator that
listens to a tech-active-booking provider) would let the tech briefly
navigate away without losing tracking.

---

## Permission flow (audit C2)

Required permissions, in `AndroidManifest.xml`:

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — runtime location.
- `POST_NOTIFICATIONS` — Android 13+ runtime notification permission;
  the foreground service notification cannot be shown without it.
- `FOREGROUND_SERVICE_LOCATION` — Android 14+ requirement for any
  foreground service that uses location.
- `ACCESS_BACKGROUND_LOCATION` — required so GPS keeps streaming
  after the OS classifies the app as "background" (screen lock,
  briefly switching apps). Without it, Android 10+ throttles
  location to ~hourly batched updates even with the foreground
  notification showing.

`_ensurePermissions()` follows this sequence:

1. Foreground location: `Geolocator.checkPermission()` →
   `requestPermission()` if denied. Hard-block (`BroadcastState.permissionDenied`) when still denied / deniedForever.
2. Notifications: `FlutterForegroundTask.checkNotificationPermission()`
   → `requestNotificationPermission()` if not granted. Hard-block
   (`BroadcastState.notificationPermissionDenied`) when still not granted.
3. **Best-effort** background-location upgrade: when foreground is
   `whileInUse`, attempt `Geolocator.requestPermission()` again —
   on Android 10 this can succeed via the runtime dialog; on
   Android 11+ it returns `whileInUse` unchanged (the user MUST visit
   Settings). **Background denial does NOT block service start** —
   the foreground service can still publish GPS while the
   notification keeps the app foregrounded; we just log it.

The controller exposes `openSystemSettings()` →
`Geolocator.openAppSettings()` so the
`BroadcastStateBanner`'s "Open settings" CTA can deeplink to the OS
app-settings page (the only path on Android 11+ to grant background
location). The banner does NOT show the CTA for `BroadcastState.error`
— settings won't fix a generic init failure.

---

## Logout teardown (audit C3)

[`ForegroundLocationLifecycle`](presentation/services/foreground_location_lifecycle.dart) is a stateless helper consumed by `AppLifecycleOrchestrator.performTeardown` on logout. It runs **between** `fcmHandler.unregister()` and `wsConnection.disconnect()`, mirroring the family of "stop device → backend publishers before cutting the WS" already enforced for FCM:

```dart
Future<void> tearDown() async {
  await FlutterForegroundTask.stopService();
  await FlutterForegroundTask.removeData(
    key: TechLocationTaskKeys.configKey,
  );
}
```

**Why both calls.** `FlutterForegroundTask.saveData(...)` persists the auth-token blob in shared-prefs across app restarts, independent of the controller's Riverpod lifecycle. Without an explicit logout teardown, tech B logging in on the same device would inherit tech A's saved auth token via the shared-prefs file (and the next service start would POST as the wrong tech until the backend's assigned-tech IDOR check rejected it).

Both platform calls are idempotent — calling `stopService` on a not-running service is a no-op; `removeData` on an absent key is a no-op.

---

## Isolate → main fatal-auth channel (audit H4)

`flutter_foreground_task`'s `sendDataToMain(data) ↔ addTaskDataCallback(cb)` API bridges the isolate boundary. Wire format (defined alongside `TechLocationTaskKeys` in `foreground_task_handler.dart`):

```dart
{
  'kind': 'fatal_auth_error',
  'status_code': 401 | 403,
  'code': '<envelope code from backend>',
}
```

Lifecycle:

- Controller registers `_onIsolateData` via `addTaskDataCallback` after a successful `_startService`.
- Isolate `_onFix` catches `HttpFailure`, logs every failure, and on `statusCode ∈ {401, 403}` calls `sendDataToMain` with the envelope.
- Controller's `_onIsolateData` flips `state = BroadcastState.error`, sets `_fatalAuthErrorLatched = true`, and (if running) calls `_stopService`. The latch survives the `_stopService` tail-`_evaluate` so the controller does NOT immediately restart with the same bad token in a tight loop.
- Latch clears automatically when the booking transitions out of `{EN_ROUTE, ARRIVED}` (in `_evaluate`), or on screen pop (controller disposes).
- Callback is unregistered in `_stopService` and `ref.onDispose` so it cannot leak across screen pops or logout.

---

## What this feature does NOT include

- iOS variant — flag #10 / flag #35 deferred (no Mac in pipeline).
- True background location when the OS kills the app — would need
  `flutter_background_geolocation` (paid) or an Android service set
  to `START_STICKY` with a different host plugin.
- Auth-token rotation handling — the token is read once per service
  start. If the backend rotates tokens mid-session (flag #8), the
  next service stop/start cycle picks up the new one. (The H4 fatal-
  auth channel covers the case where rotation invalidates the
  in-flight token.)
- Distributed throttle — the backend's process-local 4s throttle is
  per-Daphne-worker (flag #33). Multi-worker production deployments
  may surface a 4N s effective floor.
- Custom marker icons / tech-side UI polish — the orchestrator screen
  renders the same `LiveTrackingMap` for both audiences (with the
  same procedural marker bubbles); a tech-specific overlay (e.g.
  bigger "I have arrived" CTA) is sprint-v2 polish.
- Unit tests for the controller / isolate task handler — tracked in
  flag #36 alongside the parallel map-widget coverage gap (audit
  H13). Closing this requires a port-and-adapter refactor wrapping
  `FlutterForegroundTask.<static>` and `Geolocator.<static>` behind
  injectable interfaces.

---

## Tests

| File | Coverage |
|---|---|
| `test/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source_test.dart` | URL + auth header + body shape; 200/429/403/5xx response handling; **8s timeout → `HttpFailure(0, 'network_timeout')`** (audit H3). |
| `test/features/technician/location_broadcaster/presentation/widgets/broadcast_state_banner_test.dart` | Render-nothing for `idle`/`running`; failure-state matrix (icon + copy); "Open settings" CTA visibility (audit C2 — only on the two permission-denied variants); tap dispatch through `onOpenSettings`. |
| (orchestrator-side) `test/features/orchestrator/data/mappers/tech_gps_frame_mapper_test.dart` | Wire-shape parse + bounds validation (audit H5 — out-of-range lat/lng/heading drop). |
| (auth/realtime sides) `test/core/realtime/presentation/app_lifecycle_orchestrator_test.dart`, `test/features/auth/presentation/providers/auth_notifier_*_test.dart` | `performTeardown` `verifyInOrder` pins `foregroundLocationLifecycle.tearDown()` between `fcm.unregister` and `ws.disconnect` (audit C3). |

The `ForegroundLocationServiceController` and the
`TechLocationTaskHandler` are NOT unit-tested — both depend on
`FlutterForegroundTask` static method calls which require a wrapper
abstraction to mock (audit H13). The controller's logic (status × role
→ start/stop, the `_LifecycleStatus` FSM, the `_fatalAuthErrorLatched`
recovery, the `addTaskDataCallback` registration / unregistration)
ships covered only by inspection + the manual smoke checklist in
`booking_orchestrator_sprint/session_4_live_tracking_and_dual_maps.md
§6`. Tracked in flag #36 alongside the analogous map-widget gap.

---

## Manual smoke

See sprint doc §6 — the canonical checklist. Tech-side specifics:

1. Tech opens the booking at status `CONFIRMED`; taps "Start journey".
2. Permission dialog (location → "Always" recommended; notifications
   on Android 13+).
3. Persistent notification "Tracking job to <Customer>" appears.
4. Lock screen — notification persists; backend logs show 200s every
   ~5s.
5. Move ~150m → backend's geofence triggers `EN_ROUTE → ARRIVED`
   transition (sprint meta §10).
6. Tap "I have arrived" → status flips to `INSPECTING`; service stops;
   notification disappears.
