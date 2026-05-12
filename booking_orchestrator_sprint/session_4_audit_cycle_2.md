# Session 4 — Audit Cycle 2 (Post-Batch-A-through-H)

**Date**: 2026-05-10
**Scope**: Full re-audit of session-4 (live tracking + dual-provider maps + foreground GPS service) after the prior `session_4_audit_findings.md` and Batches A→H were closed.
**Method**: 7 parallel deep-read agents, each owning a slice, ~6h cumulative. Total findings: **~190**.

This doc lists what's still wrong NOW. Anything in `session_4_audit_findings.md` that was already closed in Batches A–H is intentionally excluded.

---

## Executive summary

| Slice | Files audited | P1 | P2 | P3 | Total |
|---|---|---:|---:|---:|---:|
| 1 — LiveTrackingMap + AppMap surfaces | live_tracking_map, i_app_map, osm_app_map, google_app_map, app_map, app_map_state_views (+ tests) | 8 | 18 | 12 | 38 |
| 2 — Markers + directions + map DI | live_marker_factory, i_directions_service, directions_failures, google_directions_service, osrm_directions_service, map_provider, url_launcher_port (+ tests) | 5 | 9 | 11 | 25 |
| 3 — Realtime + WS upstream | ws_connection_notifier, ws_frame_dispatcher, system_event_notifier, app_lifecycle_orchestrator (+ tests) | 0 | 8 | 14 | 22 |
| 4 — Customer-side stream consumer | tech_gps_frame entity/model/mapper, technician_location_stream_notifier, tracking_subscription_controller, screen wiring (+ tests) | 1 | 9 | 12 | 22 |
| 5 — Tech-side broadcaster main isolate | foreground_location_service_controller, foreground_location_lifecycle, broadcaster DI, broadcast_state_banner, ports + main-side adapters | 0 | 7 | 19 | 26 |
| 6 — Isolate handler + broadcaster tests | foreground_task_handler, isolate adapters, tech_location_remote_data_source, model, ALL location_broadcaster tests | 3 | 17 | 11 | 31 |
| 7 — Config / Android / docs | pubspec, AndroidManifest, build.gradle.kts, constants, http_failure, .gitignore, MAP_WIDGETS.md, ORCHESTRATOR_FEATURE.md, LOCATION_BROADCASTER_FEATURE.md, flag.md, STREAM_DISPATCH_API.md | 5 | 14 | 11 | 30 |
| **Total** | | **22** | **82** | **90** | **194** |

### Top-10 must-fix (highest blast radius)

These are the items that, if shipped to production, will cause real user-facing failures or compliance breaches:

1. **CTRL-13 (P2)** — JWT auth token written to plain shared-prefs blob via `FlutterForegroundTask.saveData`. CLAUDE.md explicitly mandates `flutter_secure_storage` for JWTs. **This is a CLAUDE.md compliance breach.**
2. **MAN-1 (P1)** — `usesCleartextTraffic="true"` shipped at the application level for release builds; defeats the S-8 release-mode networking guardrail entirely.
3. **CONST-1 (P1)** — `baseUrl`/`baseWsUrl` are compile-time `const`, so `--dart-define=BASE_URL=…` cannot override them. The S-8 StateError message tells operators to use a flag that does nothing.
4. **GRADLE-2 (P2)** — Release build signed with the debug keystore, so the Maps API key SHA-1 restriction can never bind. The S-9 docs walk operators through a release-keystore workflow that doesn't exist.
5. **CTRL-5 + CTRL-6 (P2)** — Notification channel importance not set to LOW (will heads-up alert despite docstring claim) AND the icon falls back to `ic_launcher` (renders as a solid white square at the status bar). The persistent tracking notification looks broken.
6. **T-HND-1 (P1)** — Test file contains raw 0x1F bytes instead of `` escapes — **same regression vector that bit P1-3 in production**. If a tool ever rewrites the test file, the tests collapse silently.
7. **GMAP-3 (P1)** — `_maybeApplyCamera` `await _controllerCompleter.future` never completes in test isolates, hanging the test forever. Production fine; test seam is broken.
8. **HND-3 (P2)** — Auth token persists in shared-prefs config blob across `_stopService` (only cleared on full logout). Couples directly with CTRL-13.
9. **DOC-1 (P1)** — `STREAM_DISPATCH_API.md` cites a non-existent module path for the `tech_gps` Source column.
10. **LTM-1 (P1)** — `_maybeFollowCamera` overwrites user pinch-zoom on every follow tick, violating the M-14 contract.

The deeper structural issues — flagged for awareness, not bundled into a single fix:
- **S-8 release-mode networking guardrail does not form a closed loop** (CONST-1, CONST-2, CONST-5, DOC-4): hardcoded `const` URLs, missing `--dart-define` plumbing, untested release branch, doc instructs a non-existent build flow.
- **Camera state ownership** in LiveTrackingMap (LTM-1/4/6, GMAP-2/3, OSM-2): same root cause cluster, all five point at the `IMapController` seam (flag #36) being overdue.
- **Markers + directions parsing fragility** (MF-1/2, GD-2/3, OD-1): malformed-body crashes in both directions services, marker cache races, unbounded growth on non-integer DPRs.
- **WS-frame-dispatcher state never cleared on logout** (DISP-3, LIFE-1): multi-account device leak — user A's stream handler can capture user B's frames if the orchestrator screen pop races logout.

---

## P1 findings (22)

### Slice 1 — LiveTrackingMap + AppMap surfaces

**LTM-1 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:308-327`
*`_maybeFollowCamera` silently overrides user pinch-zoom on every follow tick.* `_cameraZoom` is set to `_kFollowZoom = 16.0` on every follow update, violating the M-14 contract documented in `google_app_map.dart:112-117` ("preserve current camera zoom"). Fix: only set `_cameraZoom` on the first follow after recentre/initial fit, then leave it `null` so the adapters preserve the user's manual zoom.

**LTM-2 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:420-433`
*Server-time anchor read inside `build()` causes nondeterministic banner state.* `_quality` calls `ref.read(systemEventProvider.notifier).serverNow()` inside `build()` and the 5s ticker. Combined with the 60Hz tween rebuilds (LTM-7), `_quality` recomputes dozens of times per second. Compute once per build into a local; derive banner state in the ticker only.

**LTM-3 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:384-405`
*`_etaTicker` not cancelled before the polyline `await`; double-decrement on overlap.* Two refetches overlapping by milliseconds can cause a visible "1 → 4 → 3" flicker. Cancel before the await as well as after.

**LTM-4 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:347-381`
*`_polylineAnchor` is the origin the request was made for, not where the tech is when the response lands.* `tech` is captured pre-await; on slow networks (Pakistan mobile) several frames may have arrived by resolution time, and the next 500m refresh predicate compares the new tech to a stale anchor — possibly skipping a refetch that should fire. Fix: set `_polylineAnchor = widget.technicianPosition ?? tech` AFTER the await.

**LTM-5 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:409-415`
*`_fetching = false` reset wrapped in `setState` triggers a needless frame rebuild every fetch attempt.* The flag is not a UI input. Drop the `setState` wrapper.

**LTM-6 (P1)** — `lib/core/widgets/map/live_tracking_map.dart:202-211, 291-306`
*First-frame fit overridden by next-frame follow before the user sees the wide view.* `didUpdateWidget`'s first-frame branch calls `_scheduleInitialFit` but `_autoFollow` is independently true; the very next frame triggers `_maybeFollowCamera` which sets `_cameraTarget` and overrides the bounds-fit. Net result: the customer never sees "tech + customer" wide view, only the close-zoom follow. Fix: hold `_autoFollow = false` until the post-frame "fit done" callback runs.

**OSM-1 (P1)** — `lib/core/widgets/map/osm_app_map.dart:96-112`
*`OsmAppMap.didUpdateWidget` silently ignores bounds when both `cameraTarget` and `cameraBounds` are passed.* The priority is undocumented and there's no log when bounds is dropped. Document the priority or assert the precondition.

**OSM-2 (P1)** — `lib/core/widgets/map/osm_app_map.dart:84-94, 109-112`
*Post-frame `_programmaticMoveInFlight` clear lacks `mounted` guard.* If the widget unmounts before the post-frame callback fires (rare during navigation pop mid-camera-move), the callback writes to a defunct State. Add `if (!mounted) return;` inside both post-frame callbacks.

**GMAP-1 (P1)** — `lib/core/widgets/map/google_app_map.dart:64-67, 87`
*`_resolveMarkers` called from `initState` uses `View.of(context).devicePixelRatio` before `build()`.* `View.of` is documented to be called from `build` or after the inherited tree is mounted. Move the lookup inside `_resolveMarkers` only when `incoming.isNotEmpty` and verify it inside an `addPostFrameCallback`.

**GMAP-2 (P1)** — `lib/core/widgets/map/google_app_map.dart:81-95`
*`_resolveMarkers` race: two rapid prop changes can land out of order.* If a 5s tween triggers two frames within ~50ms and call A is slower than B (slow icon resolve), A's stale marker set overwrites B's fresh one. Add a per-call version int and bail if a newer call has started.

**GMAP-3 (P1)** — `lib/core/widgets/map/google_app_map.dart:97-99`
*`_maybeApplyCamera` doesn't bail if the controller-completer never completes.* In tests where `gmaps.GoogleMap` is not mounted, `await _controllerCompleter.future` never resolves; any setState-calling code hangs forever. Production fine because `onMapCreated` always fires. Add a hard timeout or surface a builder seam for the controller completer.

**TEST-1 (P1)** — `test/core/widgets/map/live_tracking_map_test.dart:792-820`
*`T-2j ETA pill hides when offline` is trivially-passing.* The test mounts with `lastFrameAt: now-90s` so the widget starts in offline state — the pill never rendered in the first place. To meaningfully test "hides when offline," start fresh, render the pill, then transition to offline.

### Slice 2 — Markers + directions + map DI

**GD-1 (P1)** — `lib/core/widgets/map/google_directions_service.dart:66-68` and `osrm_directions_service.dart:58-60`
*Bare `catch` swallows future `DirectionsFailure` subtypes thrown above and rewrites them as `Unknown`.* Tighten to `catch (e) on Exception` so unrelated `Error`s propagate.

**MF-1 (P1)** — `lib/core/widgets/map/live_marker_factory.dart:113-135`
*Async cache populate is racy — duplicate work, possible duplicate descriptors.* Two concurrent callers from `_resolveAllMarkers`'s `Future.wait` both miss the cache, both render to canvas → PNG, and one overwrites the other's entry. Fix: store `Future<BitmapDescriptor>` in the cache, not the resolved descriptor — `_cache.putIfAbsent(key, () => _paintGoogleMarker(kind, dpr))` makes this single-flight.

**MF-2 (P1)** — `lib/core/widgets/map/live_marker_factory.dart:113-114`
*Static cache is process-global, never cleared, grows on non-integer DPRs.* Real Pakistani phones have DPRs like 2.625, 2.75, 1.7333… each device family adds a fresh entry. No LRU bound, no production reset path. Cap to `MarkerKind.values.length × 4` with an LRU, or document the policy.

**GD-2 (P1)** — `lib/core/widgets/map/google_directions_service.dart:121-127`
*`routes.first as Map<String, dynamic>` will TypeError-crash on malformed body.* When `routes[0]` is a String/null (proxy-tampered response), the cast escapes the function entirely rather than turning into `UnknownDirectionsFailure`. Wrap parsing in `try { ... } on TypeError`.

**GD-3 (P1)** — `lib/core/widgets/map/google_directions_service.dart:142-145`
*Empty decoded polyline returns happy `DirectionsResult` instead of `DirectionsNoRoute`.* `decodePolyline` may yield `[]` for malformed `points` while leg still reports non-zero duration. Consumer renders missing polyline + populated ETA pill, breaking visual contract. Add `if (decoded.isEmpty) throw const DirectionsNoRoute();` (OSRM has the equivalent guard; Google does not).

**GD-4 (P1)** — `lib/core/widgets/map/google_directions_service.dart:88-92` and `osrm_directions_service.dart:78-80`
*Dead `statusCode != 200` branch — unreachable, hides intent.* After prior 5xx/429/404/4xx gates, only 1xx-3xx remain; redirects auto-resolve. Either remove or replace with `< 200 || >= 300` upfront.

**OD-1 (P1)** — `lib/core/widgets/map/osrm_directions_service.dart:108-116`
*Missing/null `c[0]` or `c[1]` in geojson coords throws `RangeError`/`TypeError` outside any try/catch.* Filter `c.length >= 2 && c[0] is num && c[1] is num` before the map.

### Slice 4 — Customer-side stream consumer

**SUB-1 (P1)** — `lib/features/orchestrator/presentation/providers/tracking_subscription_controller.dart:99-103`
*Reconnect-replay correctness depends on load-bearing emit-after-`await ready` ordering that isn't pinned by a comment.* If a future refactor moves `WsConnected` emit before `await _channel!.ready` (a common reordering), `sendUpstream` writes to a not-yet-handshaken sink and silently drops. Add a comment in `ws_connection_notifier.dart:170` saying "Order load-bearing: emit AFTER `_channel!.ready` so reconnect-replay subscribers find a writable sink."

### Slice 6 — Isolate handler + broadcaster tests

**T-HND-1 (P1)** — `test/features/technician/location_broadcaster/presentation/services/foreground_task_handler_test.dart:114, 494-501`
*Test source contains raw 0x1F control bytes; same risk that triggered audit P1-3.* If a tool rewrites the test file (which already happened once), `'token-abc<0x1F>42'` collapses to `'token-abc42'` which still parses successfully but exercises a never-hit code path because production is delimited differently. Replace every raw 0x1F byte in the test with ``.

**T-HND-2 (P1)** — `test/features/technician/location_broadcaster/presentation/services/foreground_task_handler_test.dart:200-203`
*F-21 stationary heartbeat (`intervalDuration: 15s`) has no regression test.* T-3e never casts the captured `LocationSettings?` to `AndroidSettings` or asserts the interval. A future refactor that drops the `AndroidSettings` wrapper passes the suite. Add `expect(settings, isA<AndroidSettings>()); expect((settings as AndroidSettings).intervalDuration, const Duration(seconds: 15));`.

**T-HND-3 (P1)** — `test/features/technician/location_broadcaster/presentation/services/foreground_task_handler_test.dart` (whole file)
*P2-4 NaN/Infinity drop has no test.* Searching for `isFinite` / `NaN` / `Infinity` yields zero matches. The guard at `foreground_task_handler.dart:258-260` is a single-line check in a hot path. Add tests for `(NaN, 74.3)`, `(31.5, +∞)`, `(-∞, NaN)` — all three should produce zero requests and zero `sentToMain` envelopes.

### Slice 7 — Config / Android / docs

**MAN-1 (P1)** — `frontend/android/app/src/main/AndroidManifest.xml:39`
*`usesCleartextTraffic="true"` shipped at application level for release.* The S-8 boot-time assertion only catches cleartext on the hardcoded `baseUrl`/`baseWsUrl`; it does NOT close the cleartext attack surface for any third-party HTTP request the app makes (image cache, OSRM directions, Google Static Maps). Ship a `network_security_config.xml` that allows cleartext only to localhost / `10.0.2.2`, drop the manifest flag for release.

**CONST-1 (P1)** — `frontend/lib/core/constants.dart:14-24`
*`baseUrl` and `baseWsUrl` are compile-time `const`, so `--dart-define=BASE_URL=…` cannot override them.* The S-8 release-mode `StateError` message instructs operators to use the flag — but the constants are hardcoded `const String` literals with no `String.fromEnvironment` reader. There is no path to a passing release build today. Convert both URLs to `String.fromEnvironment` mirroring the `MAP_PROVIDER` / `GOOGLE_MAPS_API_KEY` pattern in the same file.

**CONST-2 (P1)** — `frontend/lib/main.dart:107-114`
*Compounding CONST-1 — there is no green release-mode build path provable today.* Even if the assertion succeeds, the test admits it cannot flip `kReleaseMode`. Refactor `assertReleaseSafeNetworking` to accept an optional bool override so the release branch is testable.

**GIT-1 (P1)** — `frontend/.gitignore:25`
*`/frontend/` ignore line is anchored to the gitignore root and only ignores `frontend/frontend/`.* The same `mkdir -p frontend/...` slip from `cwd=$REPO_ROOT` would create `my_fyp_project/frontend/frontend/` and the root `.gitignore` would not catch it. Migrate the defense to the repo root, or drop this line as misleading.

**DOC-1 (P1)** — `backend/realtime/api/STREAM_DISPATCH_API.md:85`
*`tech_gps` "Source" column references non-existent module path.* Cites `bookings.api.tech_location_api.TechLocationIngressView`; actual is `bookings.api.tech_location.views.TechLocationIngressView`. A reader following the doc hits `ModuleNotFoundError`.

---

## P2 findings (82)

### Slice 1 — LiveTrackingMap + AppMap

- **LTM-7** `live_tracking_map.dart:256-279` — `setState` on every tween tick → ~60 rebuilds/sec for 4.8s. Move marker rendering into `AnimatedBuilder` listening to `_markerAnim`.
- **LTM-8** `live_tracking_map.dart:502-515` — ETA pill / polyline mismatch when destination changes between frames (lack of `setState` is fragile).
- **LTM-9** `live_tracking_map.dart:398-404, 597` — `formatDistanceMeters(0)` + `(0/60).ceil() = 0 min` permanently when `etaSeconds: 0` on first response. `math.max(1, mins)` floor.
- **LTM-10** `live_tracking_map.dart:300-305, 315-320, 337-342` — three post-frame callbacks call `setState` to clear transient camera fields, scheduling rebuilds for nothing. Mutate fields directly.
- **LTM-11** `tech_gps_frame.dart:41` vs `live_tracking_map.dart:421-432` — `frameArrivedAt` clock vs `serverNow()` clock mismatch by tz offset if mapper stamps local-zone `DateTime.now()` not `.toUtc()`.
- **LTM-12** `live_tracking_map.dart:365-368` — `_kPolylineMaxStaleSeconds` bypasses cooldown intentionally; document in the constant comment.
- **LTM-13** `live_tracking_map.dart:802-808` — `formatDistanceMeters(999)` returns `'1000 m'`, `formatDistanceMeters(1000)` returns `'1.0 km'`. Round-then-branch.
- **LTM-14** `live_tracking_map.dart:107, 168, 205, 220` — heading 0 ambiguity ("stationary north" vs "no heading"). First marker render shows north regardless. Use `Transform.rotate` only after a real heading observed.
- **LTM-15** `live_tracking_map.dart:215-222` — 200m hard-set vs tween threshold has no anti-flicker hysteresis. Add 25m buffer.
- **LTM-16** `live_tracking_map.dart:337-342` + `google_app_map.dart:97-129` — recentre re-tap during in-flight `animateCamera` is silently dropped (target value identical, `targetChanged` predicate skips). Add a sentinel/version int.
- **LTM-17** `live_tracking_map.dart:194-200` — phase=arrived doesn't stop already-running tween. Marker keeps sliding while customer sees "arrived" badge.
- **LTM-18** `live_tracking_map.dart:551-567` — `Uri.parse('tel:$raw')` injects unsanitized phone number. Strip whitespace at the boundary.
- **LTM-19** `live_tracking_map.dart:135, 158-165` — `_lastQuality` not updated in `didUpdateWidget` when `lastFrameAt` changes; up to 5s stale.
- **OSM-3** `osm_app_map.dart:151-156` — TileLayer subdomain rotation not configured; OSM CDN may rate-limit aggressive single-host pulls. Use `a/b/c.tile.openstreetmap.org` rotation or move to a tile provider with TOS that allows app traffic.
- **OSM-4** `osm_app_map.dart:137-143` — `interactionOptions` omits `pinchMove` while enabling `pinchZoom`; pinch+drag clamps to pure-zoom on small phones.
- **GMAP-4** `google_app_map.dart:163-174` — polylines rebuilt to a new `Set` with new `gmaps.Polyline` per element on every build, ×60Hz during tween.
- **GMAP-5** `google_app_map.dart:171` vs `osm_app_map.dart:165` — strokeWidth quantized to int on Google, double on OSM. Provider parity violation.
- **GMAP-6** `google_app_map.dart:111-128, 181-185` — `_programmaticMoveInFlight` race window with `onCameraMoveStarted` if animation queued.
- **GMAP-7** `google_app_map.dart:132-144` — camera-bounds path doesn't preserve zoom; user pinch lost on second bounds-fit. Document the contract.
- **IAPP-1** `i_app_map.dart:148-157` — `MapPolyline.hashCode` uses only first/last `latitude`. Two polylines with same start/end and length but different middle points hash-equal. Use `Object.hashAll(points)`.
- **TEST-2** `live_tracking_map_test.dart:652-694` — cooldown gate test brittle on slow CI: `Duration.zero` + microtask timing can let 30s elapse on a GC pause. Use a controlled clock.
- **TEST-3** `osm_app_map_test.dart` — zero coverage of `didUpdateWidget` camera-target / camera-bounds branches. Google has extensive helper tests; OSM does not.
- **TEST-4** `live_tracking_map_test.dart:498-510` — tween halfway-point assertion uses linear-lat interpolation but tween position uses controller value influenced by curve. Tighten to `closeTo((start+end)/2, ε)`.

### Slice 2 — Markers + directions + map DI

- **MAP-DI-1** `lib/core/widgets/map/map_provider.dart:111-118` — sharing `eventHttpClient` couples directions to event-subsystem disposal lifecycle. Document.
- **GD-5** `google_directions_service.dart:30-32` — service does not own/close its `http.Client`; contract undocumented.
- **GD-6** `google_directions_service.dart:61` — no cancellation: in-flight call cannot be aborted on screen disposal.
- **MF-3** `live_marker_factory.dart:204-207` — `Uint8List.fromList(bytes)` allocates a redundant copy of the PNG buffer.
- **MF-4** `live_marker_factory.dart:204` — `image.toByteData` runs on platform thread without unawaited yield; 3 cache misses in row blocks UI thread.
- **GD-7** `google_directions_service.dart:66-68` — bare `catch` lets `Error`s become `UnknownDirectionsFailure` (LateInitialization etc).
- **OD-2** `osrm_directions_service.dart:42-44` — coords not URL-encoded; NaN/Infinity longitude builds a malformed URL.
- **MAP-DI-2** `map_provider.dart:39-55` — `developer.log` warning fires every time `mapProviderType` is computed; gate on `kDebugMode`.

### Slice 3 — Realtime + WS upstream

- **WS-3** `ws_connection_notifier.dart:236-240` — `sendUpstream` only checks `_channel == null`, not `state == connected`. Sends during handshake-pending state are racy.
- **DISP-2** `ws_frame_dispatcher.dart:51-56` — last-writer-wins `register()` silently overrides; no warning log when overwriting a different handler. Add `assert(... || identical(existing, handler), ...)`.
- **DISP-3** `services/ws_frame_dispatcher.dart:36-42` + `dependency_injection.dart:80-81` — `_streamHandlers` never cleared on logout. On a multi-account device, user A's stream handler can survive into user B's session if logout fires while orchestrator screen is mounted.
- **LIFE-1** `app_lifecycle_orchestrator.dart:202-219` — `performTeardown` does not call `wsFrameDispatcher.reset()`. Couples with DISP-3.
- **WS-8** `test/.../ws_connection_notifier_test.dart` — no regression test for the R-12 closed-sink race fix. The fake sink never throws `StateError` on `add`.
- **WS-9** `ws_connection_notifier.dart:128-163` — `connect()` re-entrancy unguarded. Concurrent `bootAfterAuth` could close a still-handshaking channel.
- **WS-12** `ws_connection_notifier.dart:100-101, 170, 284` — broadcast `connectionEvents` listener throw aborts the `connect()` cascade. Wrap each listener invocation with try/catch or document that listeners MUST be exception-safe.
- **DISP-7** `ws_frame_dispatcher.dart:97-104` — missing-`kind` debug-asserts but release silently logs+drops. Crash analytics never see this.

### Slice 4 — Customer-side stream consumer

- **MAP-1** `tech_gps_frame_mapper.dart:44-47` — lat/lng validators reject NaN by accident (NaN compares false), not by intent. Add explicit `!v.isFinite ? false : ...` per audit P2-4.
- **MAP-2** `tech_gps_frame_mapper.dart:50-54` — heading validator rejects exactly 360.0; Geolocator on Android occasionally emits 360.0 for due-north. Either normalise `% 360` or accept closed interval `[0, 360]`.
- **MODEL-1** `tech_gps_frame_model.dart:18-23` — required `lat`/`lng` typed `double`; wire integer (lat=31 from a debugging tool) crashes `fromJson` with TypeError. Notifier swallows it. Coerce defensively: `(json['lat'] as num).toDouble()`.
- **STREAM-2** `technician_location_stream_notifier.dart:78` — `frameArrivedAt` sourced from `serverNow()`, not `DateTime.now()`. Entity docstring still says "Wall-clock instant." Update both entity and mapper docs.
- **SUB-2** `tracking_subscription_controller.dart:90-94` — `whenData` ignores AsyncLoading during invalidation refresh. After a status-change event, controller stays subscribed to GPS frames for a booking that has already moved past ARRIVED for 200-500ms.
- **SUB-3** `tracking_subscription_controller.dart:99-103` — WS terminal failure (`_kMaxRetries` exhausted → state `failed`) leaves `_subscribed = true` waiting for a `WsConnected` that may never come. User sees no GPS, no error, no banner.
- **SUB-4** `tracking_subscription_controller.dart:90-94` — status×role matrix excludes INSPECTING/IN_PROGRESS — product call on whether the customer should keep seeing the last-known position during these states.
- **SUB-5** `tracking_subscription_controller.dart:148-150` — `sendUpstream` silently swallowed; controller cannot distinguish "WS accepted my subscribe" from "WS sink threw." Have `sendUpstream` return `bool`.
- **SUB-6** `tracking_subscription_controller.dart:68` — cached `ref.read(wsConnectionProvider.notifier)` assumes keepAlive; no compile-time enforcement of the invariant.

### Slice 5 — Tech-side broadcaster main isolate

- **CTRL-1** `foreground_location_service_controller.dart:461-491` — `permission_lost`/`fatal_auth` envelopes can arrive while `_status == starting`. The else-branch overwrites `state` without stopping the foreground service, leaving service alive while controller thinks it's not running. Gate the stop on `_status != idle && _status != stopping`.
- **CTRL-2** `foreground_location_service_controller.dart:337-351, 460-466` — fatal-auth latch can be cleared mid-flight by tail `_evaluate` after `_stopService`. A token-expired-mid-trip with status flap will re-arm.
- **CTRL-3** `foreground_location_service_controller.dart:477-491` — `permission_lost` handler races with tail `_evaluate` and can immediately restart the service. Test fixture seeds `[always, denied]` to make the test pass; production behavior is brittle.
- **CTRL-5** `foreground_location_service_controller.dart:240-246` — `AndroidNotificationOptions` constructor invoked WITHOUT `channelImportance`. flutter_foreground_task v9 defaults to `DEFAULT` (heads-up alerts on some OEMs), contradicting docstring claim of LOW.
- **CTRL-6** `foreground_location_service_controller.dart:240-246` — no `iconData` override; foreground-service notification falls back to `ic_launcher`, which Android renders as a solid white square in the status bar. **Persistent tracking notification looks broken.**
- **CTRL-7** `foreground_location_service_controller.dart:213-226, 267-270` — auth token read once at `_startService`, encoded into config blob, `saveData`'d. If token rotates mid-trip, isolate keeps using stale value until next status flip. 30-min job with rotated token blacks out tracking.
- **CTRL-8** `foreground_location_service_controller.dart:467-469` — `_handleFatalAuthFromIsolate` else-branch (status != running) doesn't unregister callback. Future emissions keep firing.
- **CTRL-13** `foreground_location_service_controller.dart:12-19, 267-270` — **JWT in shared-prefs blob via `saveData`. CLAUDE.md mandates `flutter_secure_storage` for JWT.** Either mint a per-trip ephemeral token via backend, or have the isolate read directly from `flutter_secure_storage`. **CLAUDE.md compliance breach.**
- **CTRL-20** `foreground_location_service_controller.dart:142-147` — `_status` reset to `idle` synchronously in dispose hook BEFORE `unawaited(stopService())` resolves. A re-mount during the awaiting window starts a second foreground service.
- **BANNER-1b** `broadcast_state_banner.dart:88-100` — CTA uses `MaterialTapTargetSize.shrinkWrap` with `minimumSize: Size(0, 36)`. **36 dp tall is below Material/Android accessibility's 48 dp minimum.** Bump to `Size(0, 44)` or higher.

### Slice 6 — Isolate handler + broadcaster tests

- **HND-2** `foreground_task_handler.dart:235-249` — position-stream non-permission errors logged but subscription stays alive. Hardware fault would spam logs forever. Cancel `_positionSub` in the permission-lost branch.
- **HND-3** `foreground_task_handler.dart:361-367` (and controller-side absence) — auth token persists in shared-prefs config blob across `_stopService`. Only cleared on full logout teardown. Couples directly with CTRL-13.
- **HND-4** `foreground_task_handler.dart:361-367` — `_isolateClient.close()` runs synchronously in `onDestroy`; in-flight POST completes after `_remote` is nulled.
- **HND-5** `foreground_task_handler.dart:225, 251` — verified-correct that `Stream.listen(_onFix)` re-entry works because `_postInFlight` returns synchronously, but a future `.asyncMap(_onFix)` change would silently break the F-20 guard. Add a comment at line 205 saying "do NOT change `.listen(_onFix)` to `.asyncMap`."
- **HND-6** `foreground_task_handler.dart:236, 289, 312` — all `developer.log` calls in the isolate are silent in release. When sending fatal envelopes to main, include a `last_error_log_line` field for main-side persistence.
- **DS-1** `tech_location_remote_data_source.dart:89-90` — only 200 treated as success. 201/202/204 would throw `HttpFailure.fromEnvelope`. Switch to `>= 200 && < 300`.
- **DS-2** `tech_location_remote_data_source.dart:60-72` — no `Idempotency-Key` header. Isolate-restart retry could re-publish to ws subscribers in a different 4s throttle window.
- **DS-3** `tech_location_remote_data_source.dart:37-50` — no client-side range check on lat/lng. Cold-start absurd values (lat=1000) waste a roundtrip.
- **T-HND-4** `foreground_task_handler_test.dart:418-442` — T-3l "non-HttpFailure exceptions" test: MockClient wraps `StateError` so the exception that reaches `_onFix` is NOT bare `StateError`. Test doesn't assert WHICH branch caught it.
- **T-HND-5** `foreground_task_handler_test.dart:447-470` — T-3m onDestroy test doesn't verify position stream subscription was cancelled; could pass spuriously.
- **T-HND-6** `foreground_task_handler_test.dart:499-503` — T-3o "too many delimiters" test uses raw 0x1F bytes, same regression vector as T-HND-1.
- **T-HND-7** `foreground_task_handler_test.dart:632-675` — T-3r covers success-path `_postInFlight` clear; nothing covers the throw-path clear.
- **T-DS-1** `tech_location_remote_data_source_test.dart:131-174` — timeout test wraps in external `.timeout(10s)` which is misleading (not actually race-wrapping for speed).
- **T-DS-2** — missing 409, 422, 502, 504 status code coverage.
- **T-CTRL-1** `foreground_location_service_controller_test.dart:148-153` — `saveData` value asserted via `contains('tok-abc')` + `contains('42')`; would pass on `'42tok-abc'` (reversed) or missing delimiter. Use exact-equality with `encodeConfig(...)`.
- **T-CTRL-2** `foreground_location_service_controller_test.dart:697-733` — cross-controller stale-callback scenario untested.

### Slice 7 — Config / Android / docs

- **MAN-2** `AndroidManifest.xml:34` — `FOREGROUND_SERVICE` permission relies on plugin manifest-merge, not declared at app layer. Plugin upgrade dropping it would silently disable foreground services.
- **MAN-3** `AndroidManifest.xml:39` — `MainActivity` declares `taskAffinity=""`. On MIUI/ColorOS, notification taps may stack a duplicate task and orphan the existing one. Drop the empty `taskAffinity` or set to `"${applicationId}"`.
- **GRADLE-1** `build.gradle.kts:31, 45-46` — `applicationId="com.example.frontend"` is the boilerplate Flutter default. `MAP_WIDGETS.md:228` instructs operators to use this exact value when restricting the Maps API key. Real prod release MUST flip this.
- **GRADLE-2** `build.gradle.kts:50-54` — release built with debug keystore. Maps API key SHA-1 restriction can never bind. The S-9 docs walk through a release-keystore workflow that doesn't exist.
- **CONST-3** `lib/core/constants.dart:32-40` — `MapProviderType.google` reachable with empty `googleMapsApiKey`. Release build with `MAP_PROVIDER=google` and missing key renders blank tiles. Add `mapProvider == osm || googleMapsApiKey.isNotEmpty` to `assertReleaseSafeNetworking`.
- **CONST-4** `lib/core/constants.dart:37-40` — permissive `MAP_PROVIDER` default swallows typos (`Google` capital G → silently OSM). Log warning in debug.
- **HF-1** `lib/core/common/errors/http_failure.dart:32-33` — `body is Map<String, dynamic>` rejects valid `Map<dynamic, dynamic>` from `jsonDecode`. Use `body is Map` then `.cast<String, dynamic>()`.
- **HF-2** `lib/core/common/errors/http_failure.dart:44-47` — `errors` field non-Map-shape silently flattens to empty. Same fix as HF-1.
- **HF-3** `test/core/common/errors/http_failure_test.dart:1-133` — 9 cases, but missing `Map<dynamic, dynamic>` and `Map<String, List<String>>` shapes (the most common real-world divergences).
- **CONST-5** `test/core/constants_test.dart:1-28` — self-admittedly cannot flip `kReleaseMode`; release-mode contract is unverified. Refactor `assertReleaseSafeNetworking` to accept an optional bool override.
- **DOC-2** `LOCATION_BROADCASTER_FEATURE.md:124, 176` — doc cites `HttpFailure(0, 'network_failure')` / `(0, 'network_timeout')` but data source uses `HttpFailure.fromEnvelope` for non-2xx and timeout is in a different branch. Reconcile.
- **DOC-3** `ORCHESTRATOR_FEATURE.md:265-276` — has "Backend tweak (Phase A of session 3)" but no parallel "Backend touch points (session 4)" section. Reader sees zero hint of where GPS frames come from on the backend.
- **DOC-4** `MAP_WIDGETS.md:267-280` — S-9 pre-flight checklist instructs `--dart-define=BASE_URL=...` which doesn't work today (CONST-1).
- **FLAG-1** `flag.md:1196-1234` — flag #36 partial-resolution pattern is the first in flag.md and deviates from the documented "struck through" schema. Either split into #36 (resolved) + #36b (open adapter scope), or move the H14 note into the **Where** section's struck-through line as a sub-bullet.
- **FLAG-2** `flag.md:1238-1269` — flag #37 has no **Search hints** section. Mirror the convention.

---

## P3 findings (90)

Listed terse — file path + one-line description. Severity here is "code-review polish, address organically."

### Slice 1 — LiveTrackingMap + AppMap

- **LTM-20** `live_tracking_map.dart:393-404` — comment claims "cancel BEFORE reaching 0" but code cancels AFTER decrement to 1. Reword.
- **LTM-21** `live_tracking_map.dart:802-808` — `formatDistanceMeters(0)` → `'0 m'` next to `1 min` looks broken. `< 10 m` floor.
- **OSM-5** `osm_app_map.dart:170-186` — `MarkerLayer` rebuilt with new `Marker` instances every parent rebuild.
- **GMAP-8** `google_app_map.dart:59, 64-67` — empty marker init still runs `_resolveMarkers`. Skip if empty.
- **IAPP-2** `i_app_map.dart:67, 108-111` — `MapMarker` / `MapPolyline` documented `@immutable` but `points: List<LatLng>` is mutable. Wrap with `List.unmodifiable`.
- **TEST-5** `app_map_state_views_test.dart:15-21` — `findsAtLeastNWidgets(1)` for `Stack` is too loose.
- **TEST-6** `i_app_map_test.dart` — equality matrix covered, hashCode not.
- **DOC** `app_map.dart:5-8` — comment "consistent base for all maps" is stale; live tracking uses IAppMap not AppMap.
- **DOC** `live_tracking_map.dart:1-16` — docstring claims "rotates to GPS heading" but doesn't mention first-render-north-zero (LTM-14).
- **DOC** `i_app_map.dart:31-32` — `cameraTarget` "wins over `cameraBounds`" — actual behavior depends on `targetChanged` predicate. Reword.

### Slice 2 — Markers + directions + map DI

- **GD-8** `google_directions_service.dart:101-114` — `apiStatus` switch lumps `UNKNOWN_ERROR` (transient, retry-safe) with `REQUEST_DENIED` (deterministic).
- **MF-5** `live_marker_factory.dart:79-92` — heading 360° and 0° render asymmetrically (one uses Transform.rotate, one doesn't).
- **URL-1** `url_launcher_port.dart:25-26` — adapter doesn't catch `PlatformException`; port doc says "returns false otherwise" but contract not honoured.
- **URL-2** `url_launcher_port.dart:14-26` — `up_next_job_card.dart:78,95` still calls `launchUrl` directly, port partially adopted.
- **GD-9** `google_directions_service_test.dart:228-240` — timeout test races on `neverCompletes`; can yield false positive on slow CI.
- **GD-10** `google_directions_service_test.dart:53` — happy-path test doesn't assert `destination` URL parameter shape.
- **OD-3** `osrm_directions_service.dart:38-44` — missing `alternatives=false` and `steps=false` query params.
- **MF-6** `live_marker_factory.dart:204` — `picture.dispose()` not called after `picture.toImage()`.
- **MAP-DI-3** `map_provider.dart:62-105` — two switch arms duplicate the parameter forwarding; new param to one arm silently dropped on the other.

### Slice 3 — Realtime + WS upstream

- **WS-1** `ws_connection_notifier.dart:267-269` — `disconnect()` cancels subscription before `sink.close()`; ordering not commented.
- **WS-2** `ws_connection_notifier.dart:236-259` — `sendUpstream` swallows `jsonEncode` failures with no signal to caller.
- **WS-4** `ws_connection_notifier.dart:284` — `WsConnected.at` UTC stamp uses local clock, not `serverNow()`. Defeats stated cross-frame-correlation purpose.
- **WS-5** `ws_connection_notifier.dart:165-181` — `_announcedConnected` ordering: emit before subscription attached. Currently safe; document.
- **WS-6** `ws_connection_notifier.dart:282-286` — `_announcedConnected` not reset when `_connectionEvents.isClosed`.
- **WS-7** test gap — no test for `connect → disconnect → sendUpstream` (channel nulled).
- **WS-10** `ws_connection_notifier.dart:100-101` — `_connectionEvents` MUST stay instance-scoped; document.
- **WS-11** `ws_connection_notifier.dart:138-163` — `_emitDisconnect` defence-in-depth comment is confusing.
- **DISP-1** `ws_frame_dispatcher.dart:116-141` — `_routeStream` checks `payload is! Map<String, dynamic>`; `_routeEvent` defers to JSON decoder. Asymmetry.
- **DISP-4** test gap — `kind:"stream"` frame with non-Map payload not covered.
- **DISP-5** test gap — `kind:"stream"` frame with no `streamType` not covered.
- **DISP-6** `ws_frame_dispatcher.dart:138-140` — `_ref.read` assumes both providers stay keepAlive; document.
- **DISP-8** `ws_frame_dispatcher.dart:51-56` — flag #34 (multi-handler) has no in-class TODO.
- **SE-1** `system_event_notifier.dart:185-196` — `processEvent` source default `SystemEventSource.unknown`; not enforceable. Make required.
- **LIFE-2** `app_lifecycle_orchestrator.dart:166-201` — teardown-order docstring doesn't mention the WS-frame-dispatcher gap.

### Slice 4 — Customer-side stream consumer

- **STREAM-1** `technician_location_stream_notifier.dart:76-86` — microtask-defer doc-string overstates the protection (build-time-only, not full post-disposal).
- **STREAM-3** `technician_location_stream_notifier.dart:54` — `ref.read(wsFrameDispatcherProvider)` cached in build; mid-test override won't apply.
- **SUB-7** test gap — `(subscribed → AsyncError → WsConnected)` path not exercised.
- **SUB-8** `tracking_subscription_controller.dart:55, 141` — `_subscribed` flag mutated without thread-safety annotation.
- **SUB-9** `tracking_subscription_controller_test.dart:93-169` — status×role matrix missing CANCELLED/COMPLETED/EXPIRED/NO_SHOW/INSPECTING/IN_PROGRESS/QUOTED cells.
- **SUB-10** test gap — `_send`-on-disconnected path; fake never simulates closed sink.
- **SUB-11** `tracking_subscription_controller.dart:55-56` — `_wsEventsSub?.cancel()` not in try/catch; defensive.
- **ENT-1** `tech_gps_frame.dart:24-43` — entity does not document which backend endpoint feeds it (CLAUDE.md mandate).
- **OSCREEN-1** `booking_orchestrator_screen.dart:74-76` — comment claims handler-before-subscribe ordering; code does subscribe-before-handler. Swap.
- **OSCREEN-2** `all_status_stubs.dart:11` — verify `dart:developer` import scope; only `UnknownBodyStub` uses it.
- **O-DI-1** orchestrator `dependency_injection.dart` — no entry for `technicianLocationStreamProvider` or `trackingSubscriptionControllerProvider`. Convention has bent: notifiers live with domain logic.
- **STREAM-4** `technician_location_stream_notifier_test.dart:135-146` — relies on Riverpod `invalidate` running dispose synchronously; not contractually guaranteed. Add a microtask pump.
- **STREAM-5** test gap — frame-burst (10 frames in 200ms) not covered.

### Slice 5 — Tech-side broadcaster main isolate

- **CTRL-4** `foreground_location_service_controller.dart:301-314` — register-after-dispose path is gated but fragile. Add defensive `if (!ref.mounted) return;` immediately before each `_registerIsolateDataCallback`.
- **CTRL-9** `foreground_location_service_controller.dart:325-334, 508-545` — soft-success across token rotation silently keeps old token. Couples with CTRL-7.
- **CTRL-10** `foreground_location_service_controller.dart:132-134, 158-185` — `previous`/`next` from `ref.listen` ignored. Document the design.
- **CTRL-11** `foreground_location_service_controller.dart:280-283` — `firstName` extraction doesn't strip leading punctuation/emoji codepoints.
- **CTRL-12** broadcaster `dependency_injection.dart:84-91` — cold-launch from killed app: `currentContext` null at first frame, deep-link silently dropped. Queue and replay.
- **CTRL-14** `foreground_location_service_controller.dart:556` — `Geolocator.openAppSettings` lands on generic app-settings, not location sub-page (which `permission_handler` exposes).
- **CTRL-15** `foreground_location_service_controller.dart:102, 128` — `late final _jobId` would crash on hot-reload rebuild. Drop `final`.
- **CTRL-16** `foreground_location_service_controller.dart:207-211, 508-525` — `notificationPermissionDenied` has no latch; would re-prompt on every status invalidation.
- **CTRL-17** `foreground_location_service_controller.dart:518-524` — notification permission gate stricter than required (foreground service can start without it on Android 13+).
- **CTRL-18** `foreground_location_service_controller.dart:357-369, 463` — `_isolateDataCallback` field mutation under re-entrancy contained by `_status == stopping` short-circuit. Document.
- **CTRL-19** `foreground_task_handler.dart:251-305` — token-expired-mid-trip leaves "running" notification visible ~5s before first 401 surfaces. flag.md candidate.
- **LIFE-1** broadcaster `dependency_injection.dart:52-54` — `foregroundLocationLifecycleProvider` rebuilds on `foregroundTaskBackendProvider` invalidate. Test-only concern.
- **LIFE-3** `foreground_location_lifecycle.dart:38-41` — `tearDown` doesn't reset latch but logout invalidates scope. Documented.
- **LB-DI-1, LB-DI-2, LB-DI-3** — verified-clean.
- **ADP-1** `flutter_foreground_task_backend.dart:42-54` — adapter narrower than underlying API by design (no `notificationIcon`/`buttons`). Couples with CTRL-6.
- **ADP-2** const-constructor consistency.
- **PORT-1, PORT-2, PORT-3** — informational/documented.
- **BANNER-1** `broadcast_state_banner.dart:61-104` — no semanticsLabel on the icon; TalkBack reads only the visible text.
- **BANNER-3** test gap — `Semantics(liveRegion: true)` not pinned by a test.

### Slice 6 — Isolate handler + broadcaster tests

- **HND-1** `foreground_task_handler.dart:251-326` — verified-correct.
- **HND-7** `foreground_task_handler.dart:357` — `launchApp()` called without route; cold-launch tap goes to home, not directly to booking. Future deep-link work.
- **HND-8** `foreground_task_handler.dart:273-275` — accuracy `> 0` lets negative-`-1.0` "unknown" through. Add `isFinite && > 0`.
- **HND-9** `foreground_task_handler.dart:128` — `decodeConfig` allows `bookingId == 0`. Tighten to `<= 0`.
- **HND-10** `foreground_task_handler.dart:289-294` — 5xx and 401/403 logged at the same SEVERE level. Tier the levels.
- **IADP-1, IPORT-1** — informational/documented.
- **MDL-1** `tech_location_request_model.dart` — `toJson` emits null fields. ~7KB extra per 30-min job. Optional `includeIfNull: false`.
- **T-CTRL-3** `foreground_location_service_controller_test.dart:124-128, 612, 665` — microtask-drain count varies (5 vs 10). Extract a constant.
- **T-FAKE-1, T-FAKE-2** — generic narrowing, broadcast-vs-single-subscription mismatch. Documented.
- **T-CTRL-4** test file header — dispose-mid-`_startService` deferred, verified-by-inspection only.

### Slice 7 — Config / Android / docs

- **PUB-1** `pubspec.yaml:61-66` — caret pins on `google_maps_flutter`, `flutter_polyline_points`, `flutter_foreground_task` admit minor drift.
- **PUB-2** `pubspec.yaml:9-10, 61` — `pubspec.lock` deliberately not committed; for an APP this is non-standard.
- **MAN-4** `AndroidManifest.xml:1` — no `xmlns:tools` declaration. Future `tools:node` directives need a re-edit.
- **MAN-5** `AndroidManifest.xml:35-39` — no `WAKE_LOCK` permission. Pakistan low-end fleet (Android 8/9) Doze-mode killed GPS.
- **GRADLE-3** `build.gradle.kts:34-37` — `targetSdk` not pinned. `FOREGROUND_SERVICE_LOCATION` requires API 34.
- **CONST-6** `lib/core/constants.dart:60-69` — `supportPhoneNumber` empty default makes call-FAB silently disappear in dev. Surface a debug warning.
- **DOC-5** `MAP_WIDGETS.md:228` — S-9 example uses `com.example.fyp_project` but actual `applicationId` is `com.example.frontend`.
- **DOC-6** `ORCHESTRATOR_FEATURE.md:64` — C5 dispatcher 2-arg unregister contract not pinned by a test.
- **DOC-7** `LOCATION_BROADCASTER_FEATURE.md:347` — test paths cited; verify against committed test files.
- **FLAG-3** `osrm_directions_service.dart:14-16` — comment now references "flag #37"; verify text matches flag.md entry resolution actions.
- **SPEC-1** `session_4_audit_findings.md:374` — M4-contract closed (MAP_WIDGETS.md now covers IAppMap stack); no struck-through marker.
- **SPEC-2** `session_4_audit_findings.md:375` — M5-contract (`session_4_implementation_summary.md` missing) — never created. Either ship or strike through.
- **SPEC-3** `session_4_audit_findings.md:377` — M9-contract (`ACCESS_BACKGROUND_LOCATION` gap) closed in C2 batch but doc not updated.

---

## Notes on previously-closed items

The following items from `session_4_audit_findings.md` were verified as **still correctly closed**:
- Batches A–H per the prior run (R-12, R-13, R-15, R-16, R-18, F-5, F-10, F-15, F-20, F-21, F-26, M-1, M-2, M-3, M-4, M-14, P1-1, P1-2, P1-3, P2-2, P2-4, S-8, S-9, S-12, S-14, W-12, W-20, W-25, W-27, W-38, Batch H deep-link wiring + `openBookingKind` envelope + port `launchApp`).
- Audit context items used to dedupe: H6 (W-7 covered), R-15 (Batch A), H5 (correct flag citation).

## Notes on still-deferred items (per prior audit doc)

- **H10** (Urdu localization) — user-deferred for end-of-UI design pass.
- **W-17** (`_programmaticMoveInFlight` race) — flag #36, blocked on `IMapController` seam.
- **W-11** (marker-resolve perf refactor) — would need bitmap-resolve / marker-build split; no user complaints yet.
- **H2-contract** (`transition_fired` discard) — backend coordination needed.
- **S-7** (WS auth via header instead of query string) — backend coordination needed; **real launch obligation**.
- **S-17** (battery-hint UI) — design work.

These remain valid deferrals and are not re-litigated in this audit.

---

*End of session_4_audit_cycle_2.md.*
