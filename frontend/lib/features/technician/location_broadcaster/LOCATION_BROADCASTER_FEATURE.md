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
| [`BroadcastState`](domain/entities/broadcast_state.dart) | `idle / running / permissionDenied / notificationPermissionDenied / error`. Surfaced by the controller; orchestrator screen renders permission-explainer dialogs based on it. |

No domain failures sealed family — the controller communicates
exclusively via [`BroadcastState`] enum changes.

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
| [`TechLocationRemoteDataSource`](data/datasources/tech_location_remote_data_source.dart) | `package:http`-based POST. Handles `200 → true`, `429 → false (drop)`, `4xx/5xx → HttpFailure`. URL constructed with `${AppConstants.baseUrl}/bookings/$id/tech-location/` (no `/api/` prefix in path; sprint meta §24). |

No local data source (the foreground service has no offline cache —
GPS frames are transient state, not facts to replay).

---

## Repository impl flow

N/A (no repository). The flow is:

1. Controller's `_startService` writes
   `{authToken, bookingId}`-encoded blob via
   `FlutterForegroundTask.saveData`.
2. Foreground task isolate boots; `TaskHandler.onStart` reads the
   blob, decodes via `TechLocationTaskKeys.decodeConfig`.
3. `Geolocator.getPositionStream(distanceFilter: 10, accuracy: high)`
   subscription; each `Position` flows through `_onFix`.
4. `_onFix` calls
   `TechLocationRemoteDataSource.postLocation(..., authToken: ...)`.
5. Failures swallowed (transient network blips). 429 dropped. Other
   4xx/5xx logged-only — no UI surfacing because the user has no way
   to act on them mid-drive.
6. Controller's dispose hook calls `stopService`.

---

## Error propagation pipeline

Per CLAUDE.md the four-step pipeline applies; here the layers
collapse because the consumer (the isolate) cannot bubble Domain
exceptions to the UI.

| Layer | Behaviour |
|---|---|
| Data Source | 200 → `true`. 429 → `false`. 4xx/5xx → throws `HttpFailure(code, message, errors)`. |
| Isolate task handler | Catches all exceptions and logs. Service stays alive; next fix retries. |
| Controller (main isolate) | Watches `bookingDetailProvider` and own `BroadcastState`. Surfaces `permissionDenied` / `notificationPermissionDenied` / `error` via state changes the orchestrator screen reads. |
| Presentation | Permission explainer dialog when state hits a denied variant. No user-facing surface for transient HTTP errors — the live tracking marker on the customer's side is what tells you whether GPS is flowing. |

---

## DI wiring

| Provider | Lifetime | Purpose |
|---|---|---|
| `locationBroadcasterSecureStorageProvider` | keepAlive: true | `FlutterSecureStorage` instance for reading the auth token before saveData. |
| `locationBroadcasterHttpClientProvider` | keepAlive: true | Main-isolate `http.Client`. Used by tests + future tech-side admin actions; the foreground task isolate constructs its OWN client because Riverpod doesn't cross isolates. |
| `techLocationRemoteDataSourceProvider` | keepAlive: true | Wraps the http client. Same caveat: the FG isolate makes its own. |
| `foregroundLocationServiceControllerProvider(int jobId)` | keepAlive: false (family) | The notifier. Watched by `BookingOrchestratorScreen.build`. |

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
| `ARRIVED → INSPECTING/QUOTED/...` | service stops | unsubscribe_tracking |
| `... → CANCELLED/REJECTED/NO_SHOW/COMPLETED/COMPLETED_INSPECTION_ONLY/DISPUTED` | service stops | unsubscribe_tracking |
| Screen pop while EN_ROUTE | service stops (keepAlive: false on the controller) | (handled identically by `TrackingSubscriptionController`) |

The "service stops on screen pop" behaviour is a v1 limitation —
acceptable because the foreground service is by design tied to app
foreground state. A sprint-v2 promotion of the controller to
keepAlive: true (or a global LocationBroadcasterCoordinator that
listens to a tech-active-booking provider) would let the tech briefly
navigate away without losing tracking. Tracked in
`flag.md::ws-stream-multi-handler-deferred` adjacent.

---

## What this feature does NOT include

- iOS variant — flag #10 deferred (no Mac in pipeline).
- True background location when the OS kills the app — would need
  `flutter_background_geolocation` (paid) or an Android service set
  to `START_STICKY` with a different host plugin.
- Auth-token rotation handling — the token is read once per service
  start. If the backend rotates tokens mid-session (flag #8), the
  next service stop/start cycle picks up the new one.
- Distributed throttle — the backend's process-local 4s throttle is
  per-Daphne-worker (flag #33). Multi-worker production deployments
  may surface a 4N s effective floor.
- Custom marker icons / tech-side UI polish — the orchestrator screen
  renders the same `LiveTrackingMap` for both audiences (with the
  same procedural marker bubbles); a tech-specific overlay (e.g.
  bigger "I have arrived" CTA) is sprint-v2 polish.

---

## Tests

| File | Coverage |
|---|---|
| `test/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source_test.dart` | URL + auth header + body shape; 200/429/403/5xx response handling. |

The `ForegroundLocationServiceController` and the
`TechLocationTaskHandler` are NOT unit-tested — both depend on
`FlutterForegroundTask` static method calls which require a wrapper
abstraction to mock. The plan accepts this; the controller's logic
(status × role → start/stop) is small enough to verify by inspection
and the manual smoke checklist in `booking_orchestrator_sprint/
session_4_live_tracking_and_dual_maps.md §6`.

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
