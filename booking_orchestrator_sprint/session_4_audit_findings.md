# Session 4 — Live Tracking + Dual Maps + Foreground GPS — Audit Findings

> Aggressive multi-auditor read-only audit conducted 2026-05-10 against commits
> `55f24f6` (map adapter), `878f26c` (customer-side tracking), `871e0c9`
> (tech-side broadcaster), `57524b5` (dart format pass).
> 7 parallel sub-auditors, ~150 distinct findings, every finding cited with `file:line`.

---

## Executive summary

**Total surface**: ~5,000 LOC of feature code + ~1,500 LOC of tests across 4 commits.
**Net new tests +36** (999 → 1035).
**Two production files (`ForegroundLocationServiceController`, `_TechLocationTaskHandler`) ship with zero unit tests** — admitted in the commit message; a real CLAUDE.md violation.

Critical findings cluster around **four themes**:
1. Lifecycle/race correctness in the tech-side broadcaster
2. Realtime subscription contract gaps
3. UX/locale failures for the documented illiterate-user audience
4. Test scaffolding holes preventing half the new code from being unit-verifiable

Finding IDs preserved from sub-auditors:
- `R-*` realtime pipeline / WS / subscription / stream notifier
- `W-*` LiveTrackingMap widget + stub bodies
- `M-*` map adapter (OSM/Google/directions/marker factory)
- `F-*` tech-side foreground service + isolate
- `P-*` Riverpod correctness
- `S-*` security + error pipeline
- `T-*` test coverage
- `H-*/M-*/L-*` (in contract auditor) backend↔frontend contract + docs + flag.md

---

## 🛑 CRITICAL — ship-blockers

### C1. TrackingSubscriptionController never subscribes on the most common entry path
**Findings**: R-1, R-2, R-4
**File**: `frontend/lib/features/orchestrator/presentation/providers/tracking_subscription_controller.dart:53-67`

`ref.listen(bookingDetailProvider, ...)` only fires on **future** value transitions. When a customer opens an EN_ROUTE booking from the bookings list (cache hit → AsyncData already settled by the time the controller's `build()` runs), the listener never fires → **no `subscribe_tracking` upstream message** → backend's `tracking_job_<id>` group has no membership → customer sees zero GPS frames forever. The "open the orchestrator screen mid-journey" path is the canonical one.

```dart
ref.listen(bookingDetailProvider(jobId), (previous, next) {
  next.whenData((booking) { … });
});
```

**Fix**: read the current value at the top of `build()`:
```dart
final initial = ref.read(bookingDetailProvider(jobId));
initial.whenData((b) => _evaluate(b, ws, jobId));
```
BEFORE installing the `ref.listen`. OR use `ref.listen(..., fireImmediately: true)`.
Add a regression test (currently absent — see T-5b).

---

### C2. Tech-side foreground service has no `ACCESS_BACKGROUND_LOCATION` permission
**Finding**: F-1
**Files**: `frontend/android/app/src/main/AndroidManifest.xml:1-18`,
`frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart:181-188`

Manifest declares `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_LOCATION` — but **not `ACCESS_BACKGROUND_LOCATION`**. On Android ≥10, the OS silently throttles `getPositionStream` callbacks when the screen sleeps even with a foreground service active.

**Symptom**: notification stays up, customer's marker freezes the moment the tech's screen goes dark. The worst possible failure mode for live tracking — invisible to the tech, devastating to the customer's UX.

**Fix**:
1. Add `<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>` to AndroidManifest.xml.
2. Extend `_ensurePermissions` to detect `LocationPermission.whileInUse` and surface a settings deep-link explainer (Geolocator can't request `BACKGROUND_LOCATION` directly on Android 11+; system policy requires settings).

The doc at `LOCATION_BROADCASTER_FEATURE.md:177-181` lists "True background location when the OS kills the app" as deferred — but the typical failure here isn't OS kill; it's screen-off with the FGS still alive. Manifest gap, not a deferred capability.

---

### C3. Auth token leaks past logout via `FlutterForegroundTask.saveData` blob
**Findings**: S-1, F-3, S-4
**Files**:
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart:140-143`
- `frontend/lib/core/realtime/presentation/app_lifecycle_orchestrator.dart:190-204`
- `frontend/lib/features/auth/data/data_sources/auth_local_data_source.dart:43-46`

`AppLifecycleOrchestrator.performTeardown` does NOT call `FlutterForegroundTask.stopService()` or `removeData(configKey)`. On logout-while-tracking:
- The FG isolate keeps running with user A's token; POSTs into 401/403 forever (silently swallowed by isolate `try/catch (_)`).
- The token blob persists in plaintext SharedPreferences (Tier-2 storage holding a Tier-1 secret — direct CLAUDE.md violation).
- A second `_startService` failure path (S-4) writes the blob *before* `startService`; if `startService` fails, blob is on disk with no live service.

The controller's class doc claims "overwritten on every start" — true only if a different tech later starts tracking on the same device. Forensic-on-device readability + cross-account leak surface remains.

**Fix sketch**:
```dart
// In performTeardown, BEFORE wsConnection.disconnect()
await FlutterForegroundTask.stopService();
await FlutterForegroundTask.removeData(key: TechLocationTaskKeys.configKey);
```
Mirror the FCM-first ordering rationale (`app_lifecycle_orchestrator.dart:170-179`).

Also: in `_startService` failure branch (`foreground_location_service_controller.dart:156-163`), call `FlutterForegroundTask.removeData(...)` before flipping state to error.

---

### C4. `_running` TOCTOU race in `ForegroundLocationServiceController` — five auditors confirmed
**Findings**: F-6, F-7, F-8, P-1-3, S-3
**File**: `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart:60-72, 87-164`

Five distinct race scenarios converging on the same root cause:

- **F-6 (dispose-during-permission)**: dispose during in-flight `_startService` (permission dialog open) — `_running` is still false so dispose's `if (_running)` skip leaves a phantom service post-dispose with no controller alive to stop it. Persistent "Tracking job to X" notification despite logged-out / popped state.
- **F-7 (hot reload)**: hot reload during active tracking → main isolate's `_running=false`, BG isolate still running → next `startService` rejects with `ServiceAlreadyStartedException` → controller flips state to `error` while the service is healthy. UI shows "Tracking unavailable" indefinitely.
- **F-8 (back-and-forth nav)**: `_running=false` set synchronously on dispose; platform `stopService` takes ≤5s; back-then-forward navigation re-enters with stale FGS still being torn down.
- **P-1-3 / S-3 (fast status flip)**: `_running` is set true *after* `await startService` returns; two rapid status flips (e.g., back-to-back booking-detail invalidations) interleave around the await window — `else if (!shouldRun && _running)` runs while `_running` is still false → service ends up running with no tracking-subscribed customer.

**Fix family**:
- Introduce a status enum: `idle | starting | running | stopping | error`.
- Set `starting` *synchronously* before any `await`.
- Track `_isDisposed` flag set inside `ref.onDispose`; short-circuit after each await in `_startService` if disposed (and stop the service if it managed to start).
- Treat `ServiceRequestFailure` whose error is `ServiceAlreadyStartedException` as soft-success (`_running=true`, `state=running`); optionally call `updateService` to refresh callback/notification.
- Dispose hook always issues best-effort `stopService` regardless of flag state.

---

### C5. `tech_gps` stream handler can be silently wiped by provider race
**Findings**: R-3, R-11
**File**: `frontend/lib/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart:77,83`

Sequence:
1. Provider A (booking #5) registers handler-A in dispatcher.
2. User pops + re-pushes (deep link, hot reload, back-and-forth nav) → Provider B registers handler-B → **overwrites handler-A** (last-writer-wins per flag #34).
3. Provider A's pending `onDispose` fires → calls `dispatcher.unregister('tech_gps')` unconditionally → wipes handler-B.
4. Every subsequent `tech_gps` frame is silently dropped. Customer's tracking screen is dead.

**Fix**: capture the handler reference in registration; in `onDispose`, only unregister if `dispatcher._streamHandlers['tech_gps']` is identity-equal to ours. Or fix flag #34 (multi-handler dispatcher) sooner than v2.

---

### C6. `BroadcastState.error / permissionDenied / notificationPermissionDenied` has no UI surface
**Finding**: S-5
**Files**:
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart:106, 162`
- `frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart:76`

The screen `ref.watch`-es the controller purely to wake the keepAlive:false notifier. There is **no consumer** that pattern-matches the state to render a banner. Tech denies location → state flips to `permissionDenied` → silent → tech keeps thinking they're broadcasting → customer sees "offline" 60s later → tech has no idea why.

The class doc (`foreground_location_service_controller.dart:178-179`) explicitly promises "the orchestrator screen is expected to surface a friendly explainer dialog" — the expectation is documented but unimplemented.

**Fix**: render a persistent banner above the map when `state ∈ {error, permissionDenied, notificationPermissionDenied}`. Pattern-match exhaustively per CLAUDE.md.

---

## 🔴 HIGH — real bugs, narrow but reachable

### H1. `heading == 0.0` is ambiguous (north OR "unavailable")
**Finding**: F-4
**File**: `frontend/lib/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart:126`

```dart
heading: position.heading >= 0 ? position.heading : null,
```

Geolocator's docstring: `heading == 0.0` means *both* "facing north" AND "device can't report heading." Because `0.0 >= 0` is true, **null is never sent**. Stationary techs with no compass pin → bike marker always points north regardless of actual orientation.

**Fix**: `position.headingAccuracy <= 0 ? null : position.heading`.

### H2. `WsConnected` / `WsDisconnected` emissions are incomplete
**Findings**: R-5, R-6, R-21
**File**: `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart`

- **R-5**: prior-socket close on token refresh (line 117) doesn't emit `WsDisconnected`. Handshake-throw path (line 134) doesn't emit it.
- **R-6**: manual `disconnect()` always emits `WsDisconnected` even if no prior `WsConnected` was ever emitted.
- **R-21**: `_scheduleReconnect` is invoked from `onError` (line 160-168) but **`onError` does not check `_manualDisconnect`** → reconnect loop on logged-out user.

**Fix**: track `_announcedConnected` flag; gate emissions on it; mirror the manual-disconnect guard from `onDone` into `onError`.

### H3. No HTTP timeout anywhere
**Findings**: M-5, F-19, T-7d
**Files**:
- `frontend/lib/core/widgets/map/osrm_directions_service.dart:46`
- `frontend/lib/core/widgets/map/google_directions_service.dart:58`
- `frontend/lib/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source.dart:50`

`package:http` `Client.get/post` has **no default timeout**. Public OSRM routinely hangs 8-30s. Tech-location: a hung connection blocks subsequent fixes' POSTs forever — Geolocator keeps producing positions, isolate's serial executor stalls, **GPS appears to stop entirely** until OS-level socket timeout (60s+).

**Fix**: `.timeout(Duration(seconds: 8 or 10))` on every external HTTP call. Map timeout → `DirectionsNetworkFailure` for directions; → `HttpFailure(statusCode: 0, code: 'network_failure', ...)` for tech-location.

### H4. `HttpFailure` in the isolate is swallowed — 401/403 silent forever
**Findings**: F-11, S-6
**File**: `frontend/lib/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart:128-132`

```dart
try {
  await _remote.postLocation(...);
} catch (_) { /* drop everything */ }
```

No log call (`developer.log` not even imported). 401 token-expired → keeps firing GPS into a wall. 403 not-the-tech → same. There is no contract bridge from the isolate back to the main isolate (`flutter_foreground_task` has `sendDataToMain` for exactly this purpose, unused).

The data source's docstring at `tech_location_remote_data_source.dart:23-34` describes the elevation contract ("the supervisor (the controller) can decide whether to surface a permission-denied error") — but the contract is **unwired**.

**Fix**: log every failure; on 401/403 send via `sendDataToMain` so controller can flip to `BroadcastState.error` and the (yet-to-build) UI banner from C6 surfaces it.

### H5. `tech_gps` payload has no input validation
**Finding**: S-2
**File**: `frontend/lib/features/orchestrator/data/mappers/tech_gps_frame_mapper.dart:14-27`

Mapper accepts `{lat: 999, lng: -200, heading: 720}` without bounds checks. Stream bypass means CLAUDE.md's pipeline-level filters (recipient/expiry) don't apply. Malformed payload → marker rendered at impossible coordinates → flutter_map may throw, Google clamps. Trust-the-server is fine *until* the server has a bug.

**Fix**: 5-line validator in `TechGpsFrameMapper.toDomain`. Drop frames where `lat ∉ [-90, 90]`, `lng ∉ [-180, 180]`, or `heading ∉ [0, 360)`.

### H6. Polyline never re-fetches on customer address change mid-tracking
**Finding**: W-5
**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart:269-281`

`_maybeFetchDirections` only re-fires on >500m tech movement or 30s cooldown. If `BookingDetail.address` updates (admin reschedule, address correction), stale polyline keeps pointing to old destination. Plan critical-point #7 explicitly called this out as required; it's unaddressed.

**Fix**: in `didUpdateWidget`, compare `oldWidget.destination` vs `widget.destination`; if changed, force-refetch (clear `_directions`, bypass cooldown).

### H7. Polyline cooldown has no max-staleness bound
**Finding**: W-14
**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart:269-283`

30s cooldown is a *minimum*. Stationary tech at a stoplight → never re-fetches → ETA pill shows the original ETA from 5 minutes ago. The "client-side tickdown" partially masks this but counts down regardless of actual traffic.

**Fix**: refetch unconditionally if `now - fetchedAt > 5min`.

### H8. Connection-quality strip uses raw `DateTime.now()` not server-anchored time
**Finding**: W-13
**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart:319-326`

CLAUDE.md realtime contract specifies a server-time anchor seeded from WS frames to defeat device clock skew. `_quality` uses `DateTime.now()` directly. Pakistan-market cheap Androids have notoriously skewed clocks — device clock +2h ahead → every frame instantly appears "offline."

**Fix**: feed `SystemEventNotifier`'s server-time anchor (or equivalent) into `_quality` instead of `DateTime.now()`.

### H9. Battery-drain ticker
**Findings**: W-2, W-3
**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart:136-138, 298-304`

- `_stalenessTicker` `setState(() {})` every 5s for the entire widget lifetime, ungated. When `lastFrameAt == null` (waiting state) it's pure waste.
- `_etaTicker` 1Hz `setState` never cancelled on phase transition (EN_ROUTE → ARRIVED) — countdown stays at 0 forever, rebuild storm continues.

**Fix**:
- Gate `_stalenessTicker` body on a quality-changed check (only setState on transitions).
- Cancel `_etaTicker` in `didUpdateWidget` when phase transitions to `arrived`, or when countdown hits 0.

### H10. English-only UX strings on the load-bearing customer screen
**Findings**: W-26, W-10
**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart:574-585, 444-454`

Connection-quality banner: `"Connection is weak…"` / `"Technician's phone seems to be offline. Last position is shown."`. Phone-call failure snackbar: `"Could not open dialler for {raw_phone}"` (also leaks phone number). **No localization layer is applied.** CLAUDE.md and the plan repeatedly stress illiterate-user audience. Shipping English text on the heart of the customer experience contradicts the documented contract.

**Fix**: route through `AppLocalizations` and add Urdu translations now, before this widget gets fingerprints.

### H11. Customer-side call FAB hidden by design
**Finding**: W-8
**File**: `frontend/lib/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart:50-103`

```dart
callPhone = booking.viewerRole == technician ? booking.customer.phoneNo : null;
```

The customer NEVER gets a call FAB. For illiterate users, "the missing button is intentional because backend doesn't surface technician.phoneNo yet" is meaningless — they'll fail to reach the tech if anything goes wrong. Plan UX #6 mandated a call FAB; ships hidden 50% of the time.

**Fix**: surface the customer-side call FAB now using whatever phone is available (could be a "call support" fallback, or unblock the flag by exposing `technician.phoneNo` via the API).

### H12. GoogleAppMap has zero test coverage
**Findings**: T-1, M-9
**File**: `frontend/lib/core/widgets/map/google_app_map.dart` (215 LOC, no test file)

Untested branches: marker resolution future-merge (`:78-93`), camera-target-vs-bounds priority (`:104-142`), `_programmaticMoveInFlight` flag (`:117-140, :207-211`), `_listsAreSame` / `_markersEqual` short-circuits.

Half the dual-provider abstraction is untested.

### H13. `ForegroundLocationServiceController` and `_TechLocationTaskHandler` have zero unit tests — ✅ Resolved 2026-05-10
**Finding**: T-3, T-22
**Files**:
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart`
- `frontend/lib/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart`

Commit message admits this and waves it off as "manual smoke testing only." That mitigation is **not** accepted by CLAUDE.md ("Frontend Testing Rules" mandates state notifier tests). The static-method coupling (`FlutterForegroundTask.<static>`, `Geolocator.<static>`) is exactly what dependency injection exists to fix.

Six distinct controller paths (status flip, dispose race, permission flow, error flow, retry flow, oscillation) ship unverifiable.

**What changed**:
- **Main side** (commits `73b77d0` + `0df111e`): introduced `IForegroundTaskBackend` + `IGeolocatorBackend` ports with production adapters, refactored controller to consume via Riverpod. 16 controller tests cover the status × role gate, permission flow, settings deep-link, fatal-auth latch. Surfaced + fixed a real production bug along the way (tail `_evaluate()` restart loop on permission-denied paths).
- **Isolate side** (commits `c0e010d` + `8b008da`): introduced parallel `IIsolateForegroundTaskBackend` + `IIsolateGeolocatorBackend` ports for the in-isolate `getData` / `sendDataToMain` / `getPositionStream` surfaces (the docstrings on the main-side ports already scoped them to main-only). Made `_TechLocationTaskHandler` public + constructor-injected. 17 unit tests cover all 15 enumerated T-3 branches (early-return paths, happy-path subscribe + POST, wire-format edge cases for accuracy=0 and headingAccuracy<=0, 401/403 fatal-auth signalling, 5xx/429/non-HttpFailure swallowing, dispose, encode/decode round-trip).
- **Bonus catch**: T-3n round-trip test surfaced that the H13-isolate refactor rewrite had silently dropped the ASCII Unit Separator (0x1F) byte from `_delimiter`. Fixed by switching to the explicit `` escape.

### H14. LiveTrackingMap test coverage ≈ 25% — ✅ Resolved 2026-05-10
**Finding**: T-2
**File**: `frontend/test/core/widgets/map/live_tracking_map_test.dart` — now 799 lines covering all 13 T-2 branches plus 2 call-FAB variants.

13 distinct uncovered branches — all closed:
- T-2a: AnimationController dispose ✅
- T-2b: Hard-jump >200m suppression ✅
- T-2c: Tween path between frames ✅
- T-2d: Auto-follow toggle on user gesture ✅
- T-2e: Recentre FAB tap behavior ✅
- T-2f: Polyline distance-threshold predicate ✅
- T-2g: Polyline cooldown predicate ✅
- T-2h: DirectionsFailure soft-fail ✅
- T-2i: ETA tickdown ✅
- T-2j: ETA pill hidden when offline ✅
- T-2k: Phone-call FAB error path ✅ (required new `IUrlLauncher` port — commit 179b861)
- T-2l: Stale-frame ticker quality-band transitions ✅
- T-2m: First-fit clears bounds ✅

**What changed**: Two-commit pattern matching H13.
1. Refactor (179b861): introduced `IUrlLauncher` port + production adapter so the phone-call FAB can be tested for both launched=true and launched=false paths.
2. Tests (f9dc93d): 15 widget tests using a recording stub `IAppMap` (the existing `appMapBuilderProvider` override is the seam), a sequence-driven `_FakeDirectionsService`, and `_FakeUrlLauncher`.

**Architecture note**: The post-compact handoff suggested an `IMapController` port, but `IAppMap` was already declarative (parent owns `cameraTarget`/`cameraBounds`/`onUserGesture`; adapter animates internally), so no map-controller seam was needed for `LiveTrackingMap`. Flag #36 narrowed to the adapter-side scope only (Google/OSM controller-coupled branches remain).

---

## 🟡 MEDIUM — subtle correctness, polish, hygiene

### Map adapter parity breaks
- **M-1**: `live_marker_factory.dart:67-73` — OSM bubble has drop shadow; Google painter (`:119-168`) has no `Canvas.drawShadow`. Flat vs raised — provider parity claim broken.
- **M-2**: Bubble fill diameter differs ~3 logical pt between OSM (`Container(56,56) + Border.all(3)` → fill=50) and Google (`bubbleRadius=53`).
- **M-3**: `BitmapDescriptor` cache key (`live_marker_factory.dart:98`) only on `MarkerKind` — `devicePixelRatio` is silently ignored. Hardcoded 2.0 everywhere.
- **M-4**: `BitmapDescriptor.bytes(...)` called without `imagePixelRatio`, `width`, or `height` — wrong-size bitmap on 1.5x / 3x devices (most Pakistani phones).
- **M-14**: `OsmAppMap` keeps current zoom on `cameraTarget`-only move; `GoogleAppMap` snaps to `initialZoom` (`google_app_map.dart:122`). Visible divergence after pinch + recentre.

### Realtime / lifecycle smaller cuts
- **R-7 vs P-2-1**: Disagreement on `Future.microtask` necessity. R-7 says overkill (dispatcher is already async). P-2-1 says fine and might be load-bearing if dispatcher ever buffers pre-registration frames. **Resolution**: keep it; rewrite the comment because the doc misdiagnoses the hazard.
- **R-12**: `sendUpstream` race between `_channel` capture and `sink.add` — sink may close mid-call. Caught but logged as generic error.
- **R-14, R-19, R-22**: bare `catch (_) { return; }` swallows version-skew payload parse failures with no log → invisible production failures. Same anti-pattern repeated.
- **R-13**: `unsubscribe_tracking` on dispose is best-effort over a possibly-closed channel; doc claims guarantees it.
- **R-15**: `WsConnected.at` is local-clock timestamp, not UTC; meaningless for cross-frame correlation.
- **R-16**: `ref.read(wsConnectionProvider.notifier)` cached at build-time — stale after logout/login swap.
- **R-18**: `ref.listen` has no `onError`; AsyncError leaves `_subscribed=true` indefinitely (no defensive unsubscribe).
- **R-20**: Tech-viewer also watches `trackingSubscriptionControllerProvider` even though it's a no-op for techs — wasted lifecycle.

### Foreground service polish
- **F-2**: Token transit uses `0x1F` delimiter; brittle if auth token format ever migrates to JWT. Fix: separate `saveData` keys or JSON.
- **F-5**: `AndroidNotificationOptions` defaults — `onlyAlertOnce: false` can heads-up alert on Android 7-8 service restart. Pakistan low-end fleet has Android 8-9 tail.
- **F-9**: Status oscillation EN_ROUTE→ARRIVED→EN_ROUTE not stress-tested.
- **F-10**: `customer.fullName.split(' ').first` fragile against unicode whitespace, leading whitespace, empty names.
- **F-15**: Permission revoked mid-session → Geolocator stream errors → no `onError` handler → silent freeze.
- **F-20**: `Stream.listen(_onFix)` doesn't await async callback → concurrent POSTs possible.
- **F-21**: `LocationSettings` correct, but no `intervalDuration` heartbeat → stationary tech never updates marker.

### Widget UX/correctness
- **W-1**: First-frame branch may skip `_maybeFollowCamera` — auto-follow may never engage.
- **W-7**: Initial fit is one-shot; destination change won't re-fit camera.
- **W-9**: `Uri(scheme:'tel', path: raw)` mangles `+` to `%2B` on some Android dialers (Samsung/Vivo common in Pakistan); use `Uri.parse('tel:$raw')`.
- **W-11**: Marker tween triggers `_resolveMarkers` on Google ~288 frames per tween. `_markersEqual` should short-circuit position-only changes.
- **W-12**: Heading hard-set mid-tween causes visible "snap" — needs shortest-arc lerp.
- **W-15**: `await launchUrl(uri)` then `ScaffoldMessenger.of(context)` — `use_build_context_synchronously` violation.
- **W-17**: Google Maps `await controller.animateCamera(...)` holds `_programmaticMoveInFlight=true` for ~300-1000ms. Real user pinch during that window misclassified as programmatic → auto-follow not disengaged.
- **W-20**: Hardcoded 220px ARRIVED map height; no MediaQuery scaling.
- **W-21**: User pan during waiting state disengages follow; first-fit then overrides user's pan. Tug-of-war.
- **W-24**: ETA pill shows "0 min"/"1 min" for `etaSeconds < 60` instead of "Arriving".
- **W-25**: Distance always shown in km even for <1km routes ("0.3 km" — illiterate users prefer "300 m").
- **W-27**: Color contrast on amber connection strip ~4.6:1 — borderline AA, fails AAA.

### Test gaps (in addition to T-1, T-2, T-3, T-22)
- **T-4** (WS notifier): missing `_emitDisconnect` on `_scheduleReconnect`/`onDone`/`onError`; no test confirming stream is closed on dispose; no fast disconnect→reconnect coalescence test.
- **T-5** (Tracking controller): missing status-flips-OUT test (the symmetric half!); rapid bounce; dispose-when-not-subscribed; AsyncError handling.
- **T-6** (Stream notifier): missing post-disposal `ref.mounted` guard test; missing build-buffer race test.
- **T-7** (Tech-location data source): missing 401, 400, SocketException, timeout, empty-200-body.
- **T-8 / T-9** (Directions): missing SocketException → DirectionsNetworkFailure (the documented mapping is unverified); missing INVALID_REQUEST; missing partial-response shapes.
- **T-17**: `live_tracking_map_test.dart` uses `DateTime.now().subtract(...)` → flaky on slow CI. Need fakeAsync or time-injection point.

### Security / contract
- **S-7**: WS auth token in query string (logged by reverse proxies); should migrate to header.
- **S-8**: `usesCleartextTraffic="true"` + hardcoded `http://` in `AppConstants.baseUrl` — no `kReleaseMode` assert prevents shipping a cleartext release build.
- **S-9**: Google Maps API key shipped in APK manifest; key restriction docs (Android package + SHA-1 fingerprint) absent.
- **S-12**: `subscribe_tracking` upstream not validated against connection state; relies on `connectionEvents` replay discipline.
- **S-14**: `HttpFailure` parsing: malformed `code: 42` (wrong-type) throws `TypeError` not caught → bubbles to isolate `try/catch (_)`. Defensive coercion: `envelope?['code']?.toString()`.
- **S-17**: `LocationAccuracy.high` + 10m filter — no battery hint UI rendered (plan #11 mentioned it).

### Backend contract & docs
- **H2-contract**: `transition_fired` payload from `tech-location` POST is silently discarded by the broadcaster. If backend's auto-transition (`evaluate_on_location`) doesn't fire a follow-on `tech_en_route` event when geofence flips, tech UI lags customer by 5-30s. Worth confirming with backend.
- **H5-contract / H6-contract**: Stale flag citations (`flag #ws-stream-multi-handler-deferred` slug doesn't exist; cross-reference in `LOCATION_BROADCASTER_FEATURE.md:172` cites flag #34 for an unrelated keepAlive concern).
- **M4-contract**: `MAP_WIDGETS.md` covers only pre-session-4 architecture; new `IAppMap`/`OsmAppMap`/`GoogleAppMap`/`LiveTrackingMap`/directions services undocumented.
- **M5-contract**: `session_4_implementation_summary.md` missing (sessions 2 and 3 have one).
- **M6-contract**: OSRM public-instance flag mentioned in plan, not added to `flag.md`. Source comment `osrm_directions_service.dart:14-16` literally says "flag.md will note this" — it doesn't.
- **M7-contract / M8-contract / M9-contract**: No flag for: untested broadcaster, token-in-saveData hygiene, battery-aggressive config, ACCESS_BACKGROUND_LOCATION gap.
- **L2-contract**: `STREAM_DISPATCH_API.md` still says "Currently-supported streamType values: None yet." `tech_gps` ships in this session.

---

## 🟢 NIT / LOW

Drill into the auditor sub-reports for these:
- R-25 to R-30 — comment freshness, dangling flag references, naming
- W-22, W-23, W-28 to W-38 — magic constants, semantic labels, code clones, style
- M-19 to M-27 — fragile state reads, redundant rebuilds, hashCode collisions, hardcoded `pi`
- F-22 to F-30 — log conventions, dead code (`location_broadcaster/dependency_injection.dart:30-35` main-isolate http.Client never used in production), notification deep link
- P-3-1 through P-3-13 — verification-only (codegen sanity, override types, dispose hooks)
- S-13 to S-20 — mass-assignment clean ✓, sealed `DirectionsFailure` exhaustive ✓
- T-13 to T-22 — naming, mock-correctness, determinism, mocktail compliance ✓

A few worth singling out:
- **W-23 / M-26**: Magic constants `3.141592653589793` instead of `dart:math.pi`.
- **W-32**: `(_etaCountdownSeconds - 1).clamp(0, 1 << 30)` — bizarre. Use `math.max(0, ...)`.
- **W-38**: No `Semantics` widgets anywhere — even illiterate users may rely on Urdu TalkBack.
- **F-18**: Test `'omits null optional fields'` actually asserts the field IS PRESENT with value null — name lies about behavior.
- **F-26**: `dependency_injection.dart:30-35` provides a main-isolate `http.Client` only used in tests. Dead code in prod.

---

## ⚖️ Auditor disagreements

1. **R-7 vs P-2-1**: `Future.microtask` necessity. Both agree the dispatcher is already async (so deferral is defensive not load-bearing today). **Resolution**: keep it as a hedge against future synchronous-flush-on-register; rewrite the comment.

2. **F-19 vs T-7c**: F-19 says `SocketException` propagates raw → bug; T-7c says either fix or test the current escape. **Resolution**: wrap it (`HttpFailure(statusCode: 0, code: 'network_failure', ...)` would let isolate's existing `try/catch (_)` handle it identically) and add a test.

3. **R-7's "closure captures `frame`/`ref`" concern**: ref.mounted is checked at fire-time not enqueue-time — correct and benign here. T-6a flags this guard as untested. Both right; add the test.

---

## 📊 Top-10 fix priorities (recommended order)

| # | Finding(s) | Effort | Risk if ignored |
|---|---|---|---|
| 1 | **C1** TrackingSubscriptionController initial-fire (R-1) | 30 min | Customer never sees GPS on common entry path |
| 2 | **C2** ACCESS_BACKGROUND_LOCATION + permission flow (F-1) | 4-6 hrs | GPS dies on screen sleep — invisible failure |
| 3 | **C3** Logout teardown stops FG service + clears blob (S-1) | 1 hr | Token leak across accounts |
| 4 | **C4** `_running` race fix family — status enum (F-6/F-7/F-8) | 4-6 hrs | Phantom services, error banner on healthy state |
| 5 | **C5** Stream handler unregister identity-check (R-3) | 1 hr | Tracking dies after deeplink/back-and-forth nav |
| 6 | **C6** BroadcastState.error UI surface (S-5) | 2 hrs | Tech doesn't know they're not broadcasting |
| 7 | **H1** Heading 0.0 ambiguity (F-4) | 15 min | Marker misorientation for stationary techs |
| 8 | **H3** HTTP timeouts everywhere (M-5/F-19) | 1 hr | GPS appears to stop on bad-network handover |
| 9 | **H10** English → Urdu localization on live map banners (W-26) | 4 hrs | Documented illiterate-user audience contract violation |
| 10 | **H13** ForegroundTaskBackend wrapper + tests (T-3, T-22) | 1-2 days | 2 critical files unverifiable; ships unverifiable |

After that: **H12** GoogleAppMap tests (T-1), **H14** LiveTrackingMap tests (T-2), **H7** polyline staleness (W-14), **H8** connection-quality server-time anchor (W-13), then doc/flag drift items.

---

## 📁 Where to dig in — agent IDs (may be stale post-compact)

Each sub-audit returned ~30-40 numbered findings with `file:line` citations:
- Realtime pipeline (R-*): `a764e07a82b3b7620`
- LiveTrackingMap (W-*): `a7ee4466ce5bc6a89`
- Map adapter (M-*): `a2e013aed47ba7600`
- Foreground service (F-*): `aa4c1168e05f0650f`
- Riverpod (P-*): `ae78ae145f0e63e58`
- Security + errors (S-*): `a78bbba9fd4302bcb`
- Test coverage (T-*): `a4d48978bf2cac5f6`
- Backend contract + docs (H/M/L-*): `ac808da0e3db31a60`

After compact, these IDs will likely return fresh-context responses or gibberish (their state is tied to the parent session). Re-spawn if needed — the prompts in the audit dispatch are reproducible.

---

## Files cited (master list)

**Production**:
- `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` (modified)
- `frontend/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart` (consumed, unchanged)
- `frontend/lib/core/widgets/map/i_app_map.dart`
- `frontend/lib/core/widgets/map/osm_app_map.dart`
- `frontend/lib/core/widgets/map/google_app_map.dart`
- `frontend/lib/core/widgets/map/live_marker_factory.dart`
- `frontend/lib/core/widgets/map/i_directions_service.dart`
- `frontend/lib/core/widgets/map/directions_failures.dart`
- `frontend/lib/core/widgets/map/osrm_directions_service.dart`
- `frontend/lib/core/widgets/map/google_directions_service.dart`
- `frontend/lib/core/widgets/map/map_provider.dart`
- `frontend/lib/core/widgets/map/live_tracking_map.dart` (632 LOC heart)
- `frontend/lib/core/constants.dart`
- `frontend/lib/features/orchestrator/data/mappers/tech_gps_frame_mapper.dart`
- `frontend/lib/features/orchestrator/data/models/tech_gps_frame_model.dart`
- `frontend/lib/features/orchestrator/domain/entities/tech_gps_frame.dart`
- `frontend/lib/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart`
- `frontend/lib/features/orchestrator/presentation/providers/tracking_subscription_controller.dart`
- `frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart`
- `frontend/lib/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart`
- `frontend/lib/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source.dart`
- `frontend/lib/features/technician/location_broadcaster/data/models/tech_location_request_model.dart`
- `frontend/lib/features/technician/location_broadcaster/domain/entities/broadcast_state.dart`
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/dependency_injection.dart`
- `frontend/lib/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart`
- `frontend/lib/features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart`
- `frontend/android/app/src/main/AndroidManifest.xml`
- `frontend/android/app/build.gradle.kts`

**Tests**:
- All test files mirror lib/ paths above; coverage gaps documented in T-* findings.

**Docs**:
- `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` (modified — added live tracking section)
- `frontend/lib/features/technician/location_broadcaster/LOCATION_BROADCASTER_FEATURE.md` (new)
- `frontend/lib/core/widgets/map/MAP_WIDGETS.md` (stale — pre-session-4 only)
- `flag.md` (added flags 34, 35)
- `booking_orchestrator_sprint/session_4_live_tracking_and_dual_maps.md` (the plan)
- `booking_orchestrator_sprint/session_4_implementation_summary.md` (**MISSING**)

---

# POST-COMPACT HANDOFF — H14 starting plan (added 2026-05-10)

This appendix is the durable handoff for the next post-compact session.
The audit work above happened across multiple sessions; this section
captures where we stopped and exactly what to pick up.

## Status as of commit `0df111e`

**Closed (16 commits, branch `main`, ~22 ahead of `origin/main`)**:
- All 6 ship-blockers: C1, C2, C3, C4, C5, C6.
- 12 of 14 HIGHs: H1, H2, H3, H4, H5, H6, H7, H8, H9, H11, H12, H13.
- Doc sync: `LOCATION_BROADCASTER_FEATURE.md`, `ORCHESTRATOR_FEATURE.md`,
  `REALTIME_EVENTS_FEATURE.md`, `MAP_WIDGETS.md` all synced to current
  reality with audit-fix references.
- New flags opened: #36 (map widget dynamic-state coverage gated on
  controller seam — owns the deferred work for H13 isolate-side AND H14).

**Skipped explicitly**:
- H10 (English → Urdu localisation) — user deferred until end-of-UI
  design-system pass.

**Remaining**:
- H14 (next).
- H13 isolate-side (`_TechLocationTaskHandler` unit tests) — deferred
  under flag #36; out of scope unless explicitly requested.

## H14 scope

**File**: `frontend/lib/core/widgets/map/live_tracking_map.dart`
(~700 LOC, current automated coverage ≈ 25%).

**13 untested dynamic branches** (audit T-2a–T-2m, also enumerated in
flag #36):

| ID | Branch |
|---|---|
| T-2a | `AnimationController` dispose path. |
| T-2b | Hard-jump >200m suppression (skip tween, hard-set position). |
| T-2c | Tween path between consecutive GPS frames. |
| T-2d | Auto-follow toggle when user manually pans. |
| T-2e | Recentre FAB tap behaviour (re-engages auto-follow). |
| T-2f | Polyline distance-threshold predicate (>500m moved). |
| T-2g | Polyline cooldown predicate (30s minimum). |
| T-2h | `DirectionsFailure` soft-fail (keep last polyline). |
| T-2i | ETA 1Hz tickdown. |
| T-2j | ETA pill hidden when polyline absent / offline. |
| T-2k | Phone-call FAB error path (`launchUrl` returned false). |
| T-2l | Staleness ticker quality-band transitions (audit H9). |
| T-2m | First-fit camera-bounds clears after one frame. |

## The seam — `IMapController`

Flag #36 documents this. Mirrors H13's port-and-adapter pattern.

**Why a seam is needed**: `gmaps.GoogleMapController` is completed by
`onMapCreated`, which only fires inside the `google_maps_flutter`
host. `flutter_map.MapController` has the same shape. Without a port,
no test can drive `_maybeApplyCamera`, `_programmaticMoveInFlight`,
recentre, or auto-follow — every `_controllerCompleter.future` await
hangs forever in unit tests.

**Sketch**:

```dart
// lib/core/widgets/map/i_map_controller.dart
abstract class IMapController {
  Future<void> animateToTarget({
    required LatLng target,
    required double zoom,
  });
  Future<void> fitBounds(List<LatLng> points, {double padding = 64});
  // Maybe: gesture event stream so the test can simulate user pans.
}
```

Concrete adapters:
- `GoogleMapsControllerAdapter implements IMapController` — wraps
  `gmaps.GoogleMapController`, completed in `onMapCreated`.
- `FlutterMapControllerAdapter implements IMapController` — wraps
  `flutter_map.MapController`.

`LiveTrackingMap` accepts the controller via Riverpod
(`mapControllerProvider` keyed by some scope) or constructor
injection. Tests inject a recording fake.

## Pattern to follow

Two commits, identical shape to H13:

1. **Refactor commit** — port + adapters + provider wiring;
   `LiveTrackingMap` consumes the abstraction. **No behaviour
   change**. Existing tests still pass without edits if the seam
   is invisible to them.
2. **Test commit** — recording fakes + comprehensive widget tests
   covering the 13 branches.

Reference: `73b77d0` (refactor) and `0df111e` (tests) for the H13 shape.

## Local test runner caveat

Dev machine: 7.2 GiB RAM, ~2.5 GiB consumed by VSCode + dart language
server. `flutter test` (no args) running ~1099 tests OOMs at exit
code 137. **Workaround**: run subdirs separately or pass
`--concurrency=1`. Not a code issue. Used during H13:

```bash
flutter test --concurrency=1 test/core/
flutter test --concurrency=1 test/features/ test/main_app_boot_widget_test.dart
```

## Files likely to touch

**Production**:
- `lib/core/widgets/map/live_tracking_map.dart` — refactor to consume
  `IMapController`.
- `lib/core/widgets/map/google_app_map.dart` — provide the
  Google adapter via the new port.
- `lib/core/widgets/map/osm_app_map.dart` — provide the OSM adapter.
- New: `lib/core/widgets/map/i_map_controller.dart` and concrete
  adapters (match the existing dual-provider directory layout —
  `data/adapters/` if such a folder already exists for the
  broadcaster's H13 port pattern; otherwise inline next to the
  widgets they wrap, like the directions services).
- `lib/core/widgets/map/map_provider.dart` — Riverpod provider for
  the controller.

**Tests**:
- New: `test/core/widgets/map/_helpers/fake_map_controller.dart`.
- Extend: `test/core/widgets/map/live_tracking_map_test.dart` to
  cover the 13 branches.

## Stop conditions

Wrap H14 when:
- All 13 branches have direct test coverage OR are explicitly marked
  not-realistically-coverable with a flag note.
- The full test suite (or the appropriate subdirs) passes.
- Doc updates land: `MAP_WIDGETS.md` test-coverage table flips T-2*
  rows from ⏳ to ✅, flag #36 either resolved (`✅ Resolved`) or
  reduced in scope (e.g. now only covers the H13-isolate side).

## Out of scope — do NOT bundle in

- H10 Urdu localisation (deferred).
- H13 isolate-side tests (`_TechLocationTaskHandler`) — separate
  effort, parallel ports for `FlutterForegroundTask.{getData,
  sendDataToMain}` and `Geolocator.getPositionStream`.
- Multi-handler `WsFrameDispatcher` refactor (flag #34).
- Backend changes.
- iOS support (flag #10 / #35).

---

*End of post-compact handoff. Drop "proceed with H14" after compact.*
