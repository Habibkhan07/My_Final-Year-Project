# Realtime Events Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅ · Lifecycle ✅

> Feature screens that consume these events (incoming-job, incoming-quote,
> dispute, etc.) are owned by their respective feature directories. This doc
> covers only the core delivery infrastructure that fans events out to them.

---

## 1. Overview

The realtime subsystem delivers backend events to the Flutter app with three
redundant channels and a dedicated recovery path:

| Channel | Role | When it wins |
| :--- | :--- | :--- |
| **WebSocket** (`/ws/events/`) | Primary live push | App is in foreground with network available. |
| **FCM** | Fallback delivery | OS suspended the WebSocket (typical on iOS background) or the app is terminated. |
| **REST sync** (`/api/events/sync/`) | Recovery | Fired after every WS reconnect and FCM background drain to backfill anything the live channels lost. |

All three feed a single ingestion funnel — `SystemEventNotifier.processEvent`
— which dedupes, enforces same-type ordering, and emits an immutable
`SystemEventState`. The `EventUrgencyRouter` listens on that state and
decides between a full-screen route push (high urgency) and a
`MaterialBanner` (low urgency). Critical events are ACK'd back to the
backend through a debounced batch endpoint; an unacknowledged-critical
sweep on every reconnect guarantees the user sees them again if the ACK
never made it.

The WebSocket also carries a second pipeline — **streams** — for transient
state values (live wallet balance, GPS, typing indicators). Streams share
the socket, the consumer, and the per-user channel-layer group with events
but use a different envelope (`kind: "stream"`), a different publisher on
the backend, and never touch the event ingestion funnel. Routing happens
at the wire edge in `WsFrameDispatcher` (see §2.1 below).

---

## 2. Architecture

```
                      ┌─────────────────────┐
                      │  Django backend     │
                      └──┬──────────────┬───┘
                         │              │
              WS push    │              │  FCM push
                         ▼              ▼
              ┌──────────────────┐  ┌─────────────────────┐
              │ WsConnection     │  │  FCMHandler         │
              │ Notifier         │  │  + bg-isolate       │
              │  (transport-only:│  │   handler (writes   │
              │   JSON-decode +  │  │   to SharedPrefs)   │
              │   forward)       │  └────────────┬────────┘
              └────┬─────────────┘               │
                   │ decoded                     │ resume drain
                   │ Map<String,dyn>             ▼
                   ▼                 ┌────────────────────┐
        ┌────────────────────────┐   │ EventLocalDataSrc  │
        │  WsFrameDispatcher     │   │ pending_bg_events  │
        │  switch on `kind`:     │   └────────────┬───────┘
        │   "event" → notifier   │                │
        │   "stream" → registry  │                │
        └────┬───────────────┬───┘                │
             │ event         │ stream             │
             │               ▼                    │
             │      per-streamType handler        │
             │      (registered by feature DI)    │
             │      (no concrete handlers ship    │
             │       in this patch — first one    │
             │       will be wallet_balance)      │
             ▼                                    ▼
        ┌────────────────────────────────────────────────┐
        │          SystemEventNotifier                    │
        │    dedup · same-type order guard · cursor       │
        └─────────────────────┬──────────────────────────┘
                              │ latestEvent transitions
                              ▼
                    ┌───────────────────────┐
                    │  EventUrgencyRouter   │
                    │  high → push route    │
                    │  low  → MaterialBanner│
                    │  critical → ack()     │
                    └─────────┬─────────────┘
                              │
                              ▼
                            UI screens

   Recovery path:
   WS connect succeeds  ─►  EventSyncNotifier.syncMissedEvents
                            └─► EventRepository.syncMissedEvents
                                 └─► /api/events/sync/?since=<cursor>
                                 └─► EventLocalDataSource (cache)
                            └─► syncUnacknowledgedCritical
                                 └─► /api/events/unacknowledged/
                            └─► flush pending_acks  → /api/events/ack/
```

### 2.1 WsFrameDispatcher

`lib/core/realtime/presentation/services/ws_frame_dispatcher.dart`

A plain Dart class (intentionally not a Riverpod notifier — no observable
state) that sits between `WsConnectionNotifier` and the rest of the
pipeline. It owns the wire-edge `kind` switch and the per-`streamType`
handler registry.

| Frame `kind` | Routing |
| :--- | :--- |
| `"event"` | Deserialized via `SystemEventModel.fromJson` → mapped to `SystemEventEntity` (mapper drops malformed frames to `null`, dispatcher null-checks before forwarding) → `SystemEventNotifier.processEvent`. |
| `"stream"` | Looked up in `_streamHandlers[streamType]`. If a handler is registered, called with the `payload` map only (envelope stripped). If absent, dropped with a **warning** log — likely a backend-vs-frontend version skew where a new stream type shipped before its handler. |
| `null` (missing field) | **Severe** log + `assert(false)` in debug. The backend wire contract guarantees `kind` on every frame; missing it is a contract violation, not version skew. |
| any other value (e.g. `"telemetry-v2"`) | Dropped with a warning log. Same category as unknown `streamType` — visible but not fatal. |

Streams are deliberately walled off from `SystemEventNotifier`. They have
no `id` to dedupe on, no critical-ACK contract, and would thrash the
`SharedPreferences`-backed event cache if routed through the event funnel.
This is the exact trap the original audit warned about ("is wallet
balance an event?" — no: per-frame, the live balance is a stream, the
`walletLowBalance` notification is an event).

The dispatcher imports nothing feature-specific. Concrete `streamType`
handlers register themselves from each feature's DI file via
`dispatcher.register(streamType, handler)`. No concrete stream types ship
in this patch — the registry is the contract that future stream wirings
hang off.

### Directory Structure

The feature is organized into a modular sub-structure for clean separation of concerns:

```text
lib/core/realtime/
├── data/
│   ├── datasources/       # Http (Remote) and SharedPreferences (Local)
│   ├── mappers/           # Model → Entity conversion
│   ├── models/            # DTOs (Freezed/JSON)
│   └── repositories/      # Repository implementation
├── domain/
│   ├── entities/          # Business objects (EventLog, Type, Urgency)
│   ├── failures/          # Concrete failure classes
│   └── repositories/      # Interface contracts
└── presentation/
    ├── notifiers/         # Riverpod StateNotifiers (SystemEvent, WsConnection, Sync)
    ├── providers/         # DI and global state providers
    ├── router/            # EventUrgencyRouter (navigation logic)
    ├── services/          # FCM Handlers (Isolate-safe)
    └── state/             # AsyncValue state wrappers
```

---

## 3. Domain Entities

`lib/core/domain/entities/`

| Entity | Fields | Source |
| :--- | :--- | :--- |
| `SystemEventEntity` | `id`, `rawType`, `eventType`, `targetRole`, `timestamp`, `payload`, `urgency`, `isCritical` | WS frames + `/api/events/sync/` + `/api/events/unacknowledged/` |
| `SystemEventType` (enum) | 12 known types + `unknown` | Derived from `rawType` string by `SystemEventType.fromRawType` |
| `EventUrgency` (enum) | `highUrgency`, `lowUrgency`, `silent` | Derived per-type by `EventUrgency.of` |
| `EventCriticality` | `criticalTypes` set + `isCritical(type)` | Mirrors backend Event Type Registry |
| `TargetRole` (enum) | `customer`, `technician` | From event's `target_role` string |

`payload` is intentionally opaque to core — only the consuming feature
screen interprets its keys. The router peeks at a single payload key per
event type (`job_id`, `quote_id`, etc.) for the "already on entity" nav
guard.

---

## 4. Sealed Failure Hierarchy

`lib/core/domain/failures/event_failures.dart`

| Class | When thrown | UI response |
| :--- | :--- | :--- |
| `EventSyncNetworkFailure` | Repository: `SocketException`/`TimeoutException` AND no cached events | Snackbar — "No connection. Showing cached events." |
| `EventSyncServerFailure` (carries `message`) | Repository: any non-2xx other than 401 | Snackbar — `message` |
| `EventSyncUnauthorized` | Repository: 401 from `/events/sync/` or `/events/ack/` | Caught by `EventSyncNotifier._runGuarded` → invokes the `onUnauthorized` callback → orchestrator triggers logout |
| `DeviceRegistrationNetworkFailure` | Repository: `SocketException`/`TimeoutException` on `registerDevice` | Logged only — FCM is a fallback channel; WS is primary so registration retries on next token refresh |
| `DeviceRegistrationServerFailure` (carries `message`) | Repository: non-2xx on `registerDevice` | Logged only |

The router and lifecycle orchestrator never see these — they live entirely
inside the data + sync layers.

---

## 5. Repository Interface Contract

`lib/core/data/repositories/event_repository.dart`

| Method | Signature | Throws | Offline-first |
| :--- | :--- | :--- | :--- |
| `syncMissedEvents` | `(String isoTimestamp) → List<SystemEventEntity>` | `EventSyncNetworkFailure`, `EventSyncUnauthorized`, `EventSyncServerFailure` | On `SocketException`/`TimeoutException`: returns cached list; throws `EventSyncNetworkFailure` only if cache empty. |
| `fetchUnacknowledgedCritical` | `() → List<SystemEventEntity>` | `EventSyncNetworkFailure`, `EventSyncUnauthorized`, `EventSyncServerFailure` | Same fallback as above. |
| `acknowledgeEvents` | `(List<String> ids) → void` | never throws | On any failure: merges with existing pending ACKs, dedupes, persists for retry. |
| `registerDevice` | `(String token, String deviceType) → void` | `DeviceRegistrationNetworkFailure`, `DeviceRegistrationServerFailure` | No cache (write-only). |
| `unregisterDevice` | `(String token) → void` | never throws | Best-effort; backend reconciles stale tokens server-side. |

The "never throws" contract on `acknowledgeEvents`/`unregisterDevice` is
load-bearing: both are called from listeners and lifecycle hooks where a
thrown exception would derail the surrounding flow with no value to the
user.

---

## 6. Use Cases

| Scenario | Path |
| :--- | :--- |
| Technician gets a new job notification while the app is open. | WS frame → `SystemEventNotifier` → `EventUrgencyRouter` → `/technician/incoming-job-request` route push. |
| Technician gets a new job notification while the app is closed. | FCM data message → background isolate writes to `pending_bg_events` → app cold start → `FCMHandler.processPendingBackgroundEvents` drains → router pushes `/technician/incoming-job-request`. |
| Customer was offline for an hour, comes back online. | WS reconnect succeeds → `syncMissedEvents` pulls events with `since=<lastSyncTimestamp>` → fed in chronological order → router surfaces each. |
| A critical event was never ACK'd (network died after push, before ACK POST). | Next reconnect cycle calls `syncUnacknowledgedCritical` → backend replies with the same event → router shows it again → user dismisses → ACK posts successfully. |
| Customer receives a chat message while browsing. | Low-urgency banner with the sender name; tap routes to `/shared/chat`. |

---

## 7. Data Sources

`lib/core/data/datasources/`

### `EventRemoteDataSource`

| Endpoint | Method | Used by |
| :--- | :--- | :--- |
| `/api/events/sync/?since=<iso>&limit=<n>` | GET | Recovery on reconnect |
| `/api/events/unacknowledged/` | GET | Critical-event resurfacing |
| `/api/events/ack/` (body `{"event_ids": […]}`) | POST | Debounced ACK batch |
| `/api/devices/register/` | POST | FCM token registration |
| `/api/devices/unregister/` | POST | Logout teardown |

- Timeout: **10 s** on every call (`TimeoutException` is a hard contract
  the repository's catch branch relies on).
- Auth: `Authorization: Token <token>` read per call from
  `FlutterSecureStorage` under the key `auth_token`.
- Errors: parses the project's standard envelope and re-throws `HttpFailure`.

### `EventLocalDataSource`

`SharedPreferences`-backed, with these slots (all prefixed `event_sync_`):

| Key | Purpose |
| :--- | :--- |
| `event_sync_cached_events` | Last-known-good event list for offline fallback. |
| `event_sync_last_sync_timestamp` | ISO cursor for the next `since=` parameter. **Written** by `EventRepository.syncMissedEvents` after every successful, non-empty sync (newest event's timestamp). **Read** by `SystemEventNotifier.build()` on cold start and used to seed `SystemEventState.lastSyncTimestamp`, so a fresh process picks up where the previous session left off instead of falling back to the 24-hour window. |
| `event_sync_pending_bg_events` | Queue written by the FCM background isolate, drained on resume. |
| `event_sync_pending_acks` | Event IDs whose ACK call failed; replayed on next sync. |

Every read method returns `null` / `[]` on absent or corrupt data and
never throws.

### Auth token source (single source of truth)

Both `EventRemoteDataSource` and `AppLifecycleOrchestrator` read the auth
token from `FlutterSecureStorage` under the key **`auth_token`** —
single source of truth across the app. The auth notifier's `UserEntity`
is consulted only for **identity** (id, role, `isTechnician`), never for
credentials. This avoids a divergence window during a future token
rotation in which the WebSocket and REST layers could otherwise carry
different tokens.

---

## 8. Repository Impl Flow (offline-first)

`syncMissedEvents(isoTimestamp)`:

1. **Try remote**: `_remote.fetchEventsSince(isoTimestamp)`.
2. **On success**:
   1. `_local.cacheEventList(models)` — replace the cached list.
   2. If non-empty, `_local.saveLastSyncTimestamp(_newestTimestamp(models))`.
      This persists the cursor for `SystemEventNotifier.build()` to seed
      from on the next cold start (see section 7).
   3. Map to `List<SystemEventEntity>` (mapper drops nulls), return.
3. **On `SocketException` / `TimeoutException`**: `_returnCacheOrThrow()`:
   - If cache present, map and return.
   - If cache absent, throw `EventSyncNetworkFailure`.
4. **On `HttpFailure`**: `_mapFailure(failure)`:
   - 401 → throw `EventSyncUnauthorized`.
   - else → throw `EventSyncServerFailure(failure.message)`.

`fetchUnacknowledgedCritical` follows the identical shape but does **not**
advance the sync cursor — these events were already counted by the main
sync; resurfacing them shouldn't move the cursor backward.

`acknowledgeEvents(ids)`:

1. Merge `ids` with `_local.getPendingAcks()`, dedupe.
2. POST. On success: `_local.clearPendingAcks()`.
3. On any error: `_local.savePendingAcks(merged)` and **swallow** — the
   next sync will retry the merged set.

---

## 9. Error Propagation Pipeline

Concrete trace of an offline sync attempt with no cache:

```
1. EventSyncNotifier.syncMissedEvents()
    └─► EventRepository.syncMissedEvents("2026-04-25T12:00:00Z")
         └─► EventRemoteDataSource.fetchEventsSince(...)
              └─► http.Client.get(...)  ── throws SocketException

2. EventRepository catches SocketException
    └─► _returnCacheOrThrow()
         └─► _local.getCachedEventList()  ── null
         └─► throw EventSyncNetworkFailure()

3. EventSyncNotifier._runGuarded catches EventSyncFailure
    └─► log("sync failure: …")    [logged, not rethrown]

4. UI: no Snackbar fired here (sync is a background concern). The
   connection-status pill — driven by the WS state — is the user-facing
   signal that "we're offline". The cached event list was already showing
   from a prior successful run.
```

If step 1 had returned 401 instead, step 3 would route into the
`EventSyncUnauthorized` arm, which calls the orchestrator-supplied
`onUnauthorized` callback, which calls `AuthNotifier.logout()` —
*without* the core layer ever importing the auth feature.

---

## 10. DI Wiring

`lib/core/presentation/providers/dependency_injection.dart`

| Provider | Type | Depends on |
| :--- | :--- | :--- |
| `eventHttpClientProvider` | `http.Client` | — (closed on dispose) |
| `eventSecureStorageProvider` | `FlutterSecureStorage` | — |
| `eventRemoteDataSourceProvider` | `EventRemoteDataSource` | `eventHttpClient`, `eventSecureStorage` |
| `eventLocalDataSourceProvider` | `EventLocalDataSource` | `sharedPreferencesProvider` (overridden in `main()`) |
| `eventRepositoryProvider` | `EventRepository` | `eventRemoteDataSource`, `eventLocalDataSource` |
| `wsFrameDispatcherProvider` | `WsFrameDispatcher` | `Ref` (used internally to read `systemEventProvider` lazily on each event frame) |
| `fcmHandlerProvider` | `FCMHandler` | `systemEventProvider`, `eventSyncProvider`, `eventRepository`, `eventLocalDataSource` |

`lib/core/presentation/providers/connection_status_provider.dart`

| Provider | Type | Depends on |
| :--- | :--- | :--- |
| `connectionStatusProvider` | `WsConnectionStatus` | `wsConnectionProvider` |

The notifier providers (`systemEventProvider`, `wsConnectionProvider`,
`eventSyncProvider`) auto-register from their `@Riverpod` annotations and
are intentionally **not** repeated in `dependency_injection.dart` —
duplicating a provider here would create two distinct instances and
defeat the single-ingestion guarantee of `SystemEventNotifier`.

> **Generator note**: the `@Riverpod` generator strips the trailing
> `Notifier` from the class name. So `class WsConnectionNotifier` produces
> `wsConnectionProvider` (not `wsConnectionNotifierProvider`). The session
> docs sometimes used the unstripped names — the generated names above
> are authoritative.

All providers are declared `keepAlive: true` because the connection,
dedup map, debounce timer, and FCM stream subscriptions cannot share a
widget lifecycle.

---

## 11. FCM Background Isolate

The `firebaseMessagingBackgroundHandler` top-level function runs in a
**separate Dart isolate**, where:

- Riverpod has not been initialised — `ProviderContainer` is unreachable.
- The main isolate's `FirebaseMessaging` instance, `EventLocalDataSource`,
  and `SystemEventNotifier` do not exist.

The BG isolate has two responsibilities — both of which it discharges
without any shared state from the main isolate.

### 11.1 Pending-event queue (cross-isolate SharedPreferences contract)

The background isolate constructs its **own** `SharedPreferences`
instance and writes JSON-encoded events directly to a known string key.
The main-isolate side reads that same key on resume via
`EventLocalDataSource.consumePendingBackgroundEvents`.

The literal string of `_keyPendingBackgroundEvents`
(`"event_sync_pending_bg_events"`) is therefore part of the public
contract between two files in different isolates:

```
lib/core/realtime/presentation/services/fcm_background_handler.dart   ← writer
lib/core/realtime/data/datasources/event_local_data_source.dart       ← reader
```

**Future contributors: keep the constant in sync between these two
files. Renaming one without the other silently loses every background
event and there is no compile-time check.**

### 11.2 Notification channel registration (Android 8+)

Android 8.0 (API 26) requires every notification to belong to a
registered channel. The FCM SDK auto-displays the system-tray
notification when an incoming message has a `notification` payload (the
backend sends `notification + data` — see `backend/realtime/devices/
tasks.py`). That auto-display routes through the channel id pinned by
the manifest meta-data
(`com.google.firebase.messaging.default_notification_channel_id`).

If the channel doesn't exist when the first notification arrives, Android
falls back to an OS-managed default channel that's silently muted on some
OEM skins (Xiaomi/MIUI, Oppo, Huawei) and visible-but-uncontrollable on
others. To prevent that, the `job_dispatch` channel is registered from
**both** isolates via the shared
`presentation/services/notification_channels.dart::ensureJobDispatchChannel()`
helper:

- **Main isolate**: `FCMHandler.initialize()` calls it as its first step,
  before `requestPermission()`. Covers the dominant case (user has opened
  the app at least once).
- **BG isolate**: `firebaseMessagingBackgroundHandler` calls it at the
  top, right after `Firebase.initializeApp()`. Covers the edge case of a
  fresh-install user receiving a push before ever opening the app.

The Android `createNotificationChannel` call is genuinely idempotent on
the OS side (channels are keyed by id), so dual-isolate registration
converges on a single OS-level `NotificationChannel`. The Dart-side
helper is also intentionally **not** memoized; relying on Android's dedup
keeps the helper trivial and safe under concurrent calls.

The channel definition (`jobDispatchChannel`, `Importance.high`, name
"Job Requests", description for OS Settings) is `const` and lives in one
file so the two registrations cannot drift. **Channel id `job_dispatch`
is wire-frozen** — also referenced from
`AndroidManifest.xml`'s `default_notification_channel_id` meta-data and
`res/values/strings.xml`'s `default_notification_channel_id` string
resource. Renaming requires
`deleteNotificationChannel('job_dispatch')` first, otherwise every
existing install ends up with two visible channels in OS Settings.

---

## 12. Configuration

| Variable | Used by | Notes |
| :--- | :--- | :--- |
| `KARIGAR_API_BASE_URL` | `AppConstants.baseUrl` | Currently hardcoded to `http://127.0.0.1:8000/api` for dev. Tech-debt to migrate to `--dart-define`. |
| `KARIGAR_WS_BASE_URL` | `AppConstants.baseWsUrl` | Currently hardcoded to `ws://127.0.0.1:8000`. WS path `/ws/events/` is mounted at root (no `/api` prefix). |
| `google-services.json` | Firebase Android | Must be present at `frontend/android/app/google-services.json`. |
| `GoogleService-Info.plist` | Firebase iOS | Must be present at `frontend/ios/Runner/GoogleService-Info.plist`. |
| `POST_NOTIFICATIONS` permission | Android 13+ system-tray dialog | Declared in `android/app/src/main/AndroidManifest.xml`. `targetSdk` must be ≥33 (currently `flutter.targetSdkVersion`) for `FirebaseMessaging.requestPermission()` to surface the OS dialog; on lower targetSdk the permission is auto-granted and no dialog shows. |
| FCM defaults meta-data | `AndroidManifest.xml` | Three `<meta-data>` entries (`default_notification_channel_id`, `default_notification_icon`, `default_notification_color`) tell the FCM SDK which channel/icon/color to use for auto-displayed notifications. Backed by `res/drawable/ic_notification.xml` (alpha-only vector), `res/values/colors.xml` (`@color/notification_color`), and `res/values/strings.xml` (`@string/default_notification_channel_id`). |

Token storage: `FlutterSecureStorage` key `auth_token`, set by the auth
feature. The remote data source reads it per call.

---

## 13. Boot & Teardown Integration

The `AppLifecycleOrchestrator` exposes two static helpers that the auth
feature calls at the appropriate lifecycle points. Both take a `Ref`
(not a `WidgetRef`) so they are callable directly from `Notifier.build`.

```dart
// On cold-start with a cached user, or after a successful verifyOtp:
unawaited(
  AppLifecycleOrchestrator.bootAfterAuth(ref, authToken).catchError(log),
);
//   1. wires `eventSyncProvider.notifier.onUnauthorized = … logout()`.
//   2. iterates `realtimeBootHooksProvider` and reads each entry,
//      waking every list-route feature's queue notifier so it
//      subscribes to systemEventProvider before frames arrive.
//   3. fcmHandler.initialize().
//   4. SENTINEL — if `onUnauthorized` is null (teardown ran while
//      FCM init was awaiting), bail before the WS connect.
//   5. wsConnection.connect(authToken) — cascades sync + ack flush.

// On logout (BEFORE clearing cached user / token):
await AppLifecycleOrchestrator.teardownOnLogout(ref);
//   1. wsConnection.disconnect()
//   2. fcmHandler.unregister()
//   3. systemEventNotifier.reset()
//   4. local.clearLastSyncTimestamp()
//   5. local.clearCachedEvents()
//   6. local.clearPendingAcks()
//   7. clear the onUnauthorized callback
```

The auth-side wiring lives in `AuthNotifier` (`features/auth/.../auth_notifier.dart`):

- `build()` and `verifyOtp()` schedule boot via a private `_scheduleBoot(token)` helper. The helper short-circuits on `token == null || token.isEmpty` (symmetry with `_onResumed`) and wraps the `unawaited` future in `.catchError(log)` so failures surface in dev/ops instead of vanishing into the Dart zone.
- `logout()` is `isLoading`-guarded against double-tap and awaits `teardownOnLogout(ref)` BEFORE `repository.logout()` — load-bearing because the FCM device-unregister POST inside teardown reads the token from secure storage that `repository.logout()` is about to clear.

Boot is fire-and-forget for a reason: `bootAfterAuth` can take seconds on slow networks (FCM init + WS handshake). Awaiting it would stall auth state in `AsyncLoading` and the router would route to `/login`. The orchestrator's helpers are idempotent (FCM init guards against double-register; WS connect short-circuits if already connected), so a fast `verifyOtp` → `completeSignup` chain re-firing boot is benign.

Mounting the orchestrator widget itself — covered in the file's dartdoc — is done once in `main.dart` (via `_Bootstrap`), above `MaterialApp.router`, with the shared `navigatorKey` and `scaffoldMessengerKey` resolved through `navigatorKeyProvider` / `scaffoldMessengerKeyProvider`. `main()` itself is a thin shim around `@visibleForTesting Future<Widget> bootApp({...injectable initializers})` so widget tests can pump the real composition tree with mocked Firebase/FCM/SharedPrefs initializers — see `test/main_app_boot_widget_test.dart` (W1–W8). Production behaviour is byte-identical to a non-extracted `main()`.

The boot ordering is deliberate at every step:
- Setting `onUnauthorized` *first* means a stale-token 401 from FCM `registerDevice` is recovered, not swallowed.
- Waking queue subscribers *before* FCM/WS guarantees no list-route event arrives at `SystemEventNotifier` before its feature's listener exists.
- The sentinel after FCM init closes the dominant case of the boot/teardown race (logout-during-FCM). The residual case (logout-during-WS-handshake) is tracked in `flag.md` #9 and is benign — wasted reconnect cycles, no incorrect state.
- Teardown clears `onUnauthorized` *last* so an in-flight 401 cannot trigger a second logout against fresh state.

---

## 14. Known Limitations

- **24-hour backend sync window.** If a user keeps the app closed
  longer than 24 hours AND the persisted cursor is older than 24
  hours, the sync request still uses `now - 24h` as the floor — the
  backend sync endpoint won't return events older than that. This is
  a backend limit, not a client one. Critical events are still
  recovered regardless of the window via
  `syncUnacknowledgedCritical`, so this primarily affects low-urgency
  events (chat messages, arrival pings, payment receipts) older than
  24 hours.
- **Silent FCM background failures.** If the background isolate's
  `SharedPreferences` write fails, the event is dropped with no signal
  to the main isolate. The next WS reconnect's `syncMissedEvents` call
  is the recovery path; if the user never reconnects, the event is
  permanently lost.
- **iOS background WebSocket throttling.** iOS aggressively suspends
  background sockets. FCM is the reliable fallback there, and
  `processPendingBackgroundEvents` on resume is what closes the gap.
- **iOS native push not enabled.** The Dart-side wiring is platform-
  agnostic, but iOS native capabilities (`Info.plist`
  `UIBackgroundModes`, Push Notifications entitlement, APNs `.p8` key
  upload) require macOS/Xcode and have not been done. Tracked as
  `flag.md` #10. Android-only for now.
- **OEM aggressive task-killing.** Killed-state FCM delivery on Xiaomi
  (MIUI), Oppo, Vivo, and some Huawei devices may be unreliable without
  the user manually whitelisting the app in the OEM's autostart /
  battery-optimisation settings. Platform limitation — not fixable in
  app code.
- **No `EventUrgencyRouter` unit tests.** The router's banner/route-push
  decision logic is exercised end-to-end via the events that flow through
  it but has no isolated test. Slated for the integration-test phase
  alongside other UI-coupled coverage.

---

## 15. Status

| Layer | State |
| :--- | :--- |
| Domain | ✅ complete |
| Data | ✅ complete |
| Presentation (notifiers, router, FCM) | ✅ complete |
| Lifecycle (orchestrator + auth boot/teardown wiring) | ✅ complete |
| Android native (manifest permission, channel, icon, color) | ✅ complete (Session 3, 2026-05-01 — closes flag #7 for Android) |
| iOS native (Info.plist, entitlements, APNs key) | ⏳ deferred — tracked as `flag.md` #10 (Mac-equipped sprint) |
| Feature screens consuming these events (per-feature) | n/a — owned by their respective feature directories |
| Tests (data + state + FCM + orchestrator canary) | ✅ complete |
| Auth ↔ orchestrator bridge tests (A1–A10) | ✅ complete — `test/features/auth/presentation/providers/auth_notifier_realtime_bridge_test.dart` |
| Notification channel registration tests (C1–C5) | ✅ complete — `test/core/realtime/presentation/services/notification_channels_test.dart` |
| Boot composition widget tests (W1–W8) | ✅ complete — `test/main_app_boot_widget_test.dart` pumps the real `bootApp` tree; closes the architectural gap that allowed flag #7 to ship |
| `EventUrgencyRouter` unit tests | ⏳ deferred — see §14 |
| Integration / E2E | ⏳ deferred per `CLAUDE.md` |
| Integration / E2E | ⏳ deferred per `CLAUDE.md` |
