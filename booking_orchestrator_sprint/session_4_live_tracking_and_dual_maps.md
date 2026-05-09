# Session 4 — Live Tracking + Dual-Provider Maps + Foreground GPS Service

> Fourth session of the Booking Orchestrator sprint. Replaces session 3's stub `EnRouteBodyStub` / `ArrivedBodyStub` with a real live-tracking widget. Ships the dual-provider map adapter (`IAppMap` / `IDirectionsService` with Google + OSM/OSRM impls), the Android foreground GPS service that broadcasts the technician's location, the customer-side stream consumer that receives those frames, polyline + ETA on both providers, and the 60-second stream-staleness "Technician offline" banner.
>
> **Out of scope**: iOS foreground service (flag #10), full background geolocation (deferred), quote builder UI (session 5), cancellation/no-show/dispute UIs (session 6).

---

## §0 Sprint context

This is **session 4 of 6**. Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–3 shipped the backend + frontend skeleton; this session lights up live tracking end-to-end.

Session 1+2+3 invariants this session relies on:
- Backend transition endpoints + `tech_gps` stream + WS consumer's dynamic `tracking_job_<id>` subgroup mechanism (session 2 §4.5, §4.10).
- Backend `POST /api/bookings/<id>/tech-location/` ingress endpoint that publishes the stream and calls `auto_transition.evaluate_on_location` (session 2 §4.5).
- Frontend `BookingOrchestratorScreen` with status-driven `BodySlot` and stub bodies (session 3).
- `WsFrameDispatcher.register(streamType, handler)` mechanism in `core/realtime/` for stream consumers (existing per CLAUDE.md, codebase's first stream consumer ships this session).
- Backend `EN_ROUTE`/`ARRIVED` statuses fire `tech_en_route`/`tech_arrived` events; orchestrator screen refreshes via `bookingOrchestratorEventsNotifier` (session 3).
- Existing OSM-based `AppMap` + `LocationPicker` widgets in `lib/core/widgets/map/` (used by address picker; **untouched** by this session).

What sessions 5–6 will add on top:
- **Session 5** — Quote builder + customer approval sheet + cash-collection UIs (replaces `InspectingBodyStub`, `QuotedBodyStub`, `InProgressBodyStub`, `CompletedBodyStub`).
- **Session 6** — Cancel / no-show / dispute / reschedule UIs; flag #26 closure.

This session's deliverables are demo-honest live tracking on Android with the OSM provider (since the Google API key is TBD per `project_maps_strategy.md`). Both adapters are production-polished — OSM is not a stub.

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions in sprint meta §4 + §13. Decisions specific to this session:

1. **Map adapter location: `frontend/lib/core/widgets/map/`** — extends the existing folder. The new files (`i_app_map.dart`, `google_app_map.dart`, `osm_app_map.dart`, `i_directions_service.dart`, `google_directions_service.dart`, `osrm_directions_service.dart`, `map_provider.dart`, `live_tracking_map.dart`) sit alongside the existing `app_map.dart` (untouched). Existing `LocationPicker` keeps using `app_map.dart` directly; new tracking surface uses the adapter abstraction.
2. **Provider selection at app boot, not per-widget**. `--dart-define=MAP_PROVIDER=google|osm` is read once into `appConstants`, exposed via a Riverpod provider, and consumed by the adapter factories. Default = `osm` until a Google Maps API key is provisioned. Per memory `project_maps_strategy.md`.
3. **Both providers must be production-grade** (per memory `feedback_tests_production_close.md`). OSM variant gets the same animation polish, the same marker styling, the same ETA chip layout. The dev variant cannot be a stub.
4. **OSRM as the OSM-side directions provider**. Free, no API key, returns encoded polyline + ETA in seconds. Public OSRM instance (`https://router.project-osrm.org`) for dev/test; flag.md notes that production OSRM should be self-hosted (or paid Mapbox) to avoid rate limits.
5. **Polyline recomputed when tech moves >500m from the polyline's start anchor**. Avoids spamming the directions API on every 5s GPS frame. Recomputation is debounced at 30 seconds minimum between calls.
6. **ETA computed once per polyline fetch, then ticks down client-side**. Server-fetched ETA seconds → renders as `arriving in ~N min`. A `Timer.periodic(const Duration(seconds: 1))` decrements; on next polyline fetch, replaces. Polished display, low API cost.
7. **Foreground service package: `flutter_foreground_task`** (^9.x). Active maintainer, supports Android 12+ properly, isolate-safe communication via `port`. iOS placeholder support exists but we don't use it (flag #10).
8. **Foreground service lifecycle is owned by the technician orchestrator integration**, not by a global controller. When the tech-side `BookingOrchestratorScreen` mounts AND `booking.status ∈ {EN_ROUTE, ARRIVED}` AND `viewerRole == technician` → start the service. When status leaves those OR screen unmounts → stop. Service does not survive screen disposal. Per sprint meta §10 (foreground only, app must stay alive). iOS deferred per flag #10.
9. **Foreground service notification**: persistent, non-dismissable while service runs, copy: "Tracking job to {customer_first_name}". Notification channel `tech_location_tracking` (separate from the existing `job_dispatch` channel).
10. **GPS broadcast cadence: 5 seconds** per sprint meta §10. Implemented via `geolocator.getPositionStream(distanceFilter: 10m, accuracy: high)` running inside the foreground service isolate. Each fix POSTs to `/api/bookings/<id>/tech-location/` over a fresh `http.Client()` constructed inside the isolate (audit C2-P0-04 + §24 isolate exception — Riverpod providers don't cross isolate boundaries).
11. **Backend's 4-second rate limit** (session 2 §4.5) absorbs clock drift; client posts every 5s without client-side throttling.
12. **Customer-side stream subscription**: when `BookingOrchestratorScreen` mounts AND status is `EN_ROUTE` or `ARRIVED` AND `viewerRole == customer` → send `{action: 'subscribe_tracking', booking_id: <id>}` upstream via the WS connection. When status leaves those or screen unmounts → send `{action: 'unsubscribe_tracking', booking_id: <id>}`. **Re-subscribe on WS reconnect (audit P1-06)**: the `TrackingSubscriptionController` listens to `wsConnectionNotifier`'s exposed `connectionEvents` stream (added this session); on every successful reconnect it replays `subscribe_tracking` for any currently-active booking. Without this, a network blip silently freezes the customer's map until they leave and re-enter the screen.
13. **Stream-staleness threshold: 60 seconds without a frame** → soft "Technician offline" banner overlaid on the map. Banner does not flip booking status. Computed client-side via `Timer.periodic` checking `lastFrameTimestamp`. Per sprint meta §10.
14. **Tech-side broadcaster does NOT send frames in terminal statuses** — service stops as soon as the orchestrator screen sees status flip out of `{EN_ROUTE, ARRIVED}`. The backend's ingress also no-ops on terminal status (session 2 §4.5), so a 1-tick race window is safe.
15. **`TechGpsFramePayload` lives in `orchestrator/data/models/`** alongside event payload models, not in `core/realtime/` — per CLAUDE.md "payload model lives with the consumer." It's orchestrator-feature-specific even though tracking is "universal" infra.
16. **`technicianLocationStreamProvider(jobId)` is `family<int>`, `keepAlive: false`**. Scoped to the orchestrator screen lifetime. Holds a `Stream<TechGpsFrame>` and the latest cached frame. Disposed when screen unmounts.
17. **Session 4 does NOT replace `InspectingBodyStub` etc.** — only `EnRouteBodyStub` and `ArrivedBodyStub`. Other stubs remain as-is for session 5.
18. **Tests for the foreground service are limited**: integration tests against a real foreground service would require running on an Android device. Unit-test the `TechLocationRemoteDataSource` (POSTing) and the `ForegroundLocationServiceController` (start/stop logic, lifecycle binding) with mocked `flutter_foreground_task`. Manual smoke covers the actual service behavior on a connected device.

19. **Audit-cycle-1 fixes shipped this session** (see [`AUDIT.md`](./AUDIT.md) and sprint meta §25):
    - **P0-03 / §24 transport**: every "Dio impl" code block in this session is illustrative only. Real implementation uses `package:http`. The Google + OSRM directions services use http; so does the foreground task isolate (which constructs a fresh `http.Client()` because Riverpod providers don't cross isolate boundaries — see §24).
    - **P0-04 path**: `event_urgency_router.dart` lives at `lib/core/realtime/presentation/router/`.
    - **P0-07 dispatcher arity**: `WsFrameDispatcher.unregister(streamType)` is **single-arg, single-handler-per-type**. The notifier calls `unregister('tech_gps')` (no handler arg). Multi-handler refactor deferred — flag `ws-stream-multi-handler-deferred` opens. Document the constraint: only ONE active orchestrator screen consumes `tech_gps` at a time. Two orchestrator screens for two different bookings simultaneously would race; the second screen's `register` overwrites the first's handler. v1 acceptable (UX flow shows one orchestrator at a time).
    - **P1-05 stream notifier state**: `state` mutations in the registered handler use `Future.microtask(() { if (!ref.mounted) return; state = frame; })` to defer past `build()`'s return and guard against post-disposal writes. No dual `_latest` field — `state` IS the latest.
    - **P1-06 WS reconnect re-subscribe**: extends `WsConnectionNotifier` with a `Stream<WsConnectionEvent>` (or `connectedAt` watchable field) so consumers can re-issue `subscribe_tracking` on reconnect. New: `TrackingSubscriptionController` listens to this stream and replays subscriptions for any active booking.

---

## §2 Files this session touches

### Core map adapters (all new in `frontend/lib/core/widgets/map/`)

| File | Purpose |
|---|---|
| `i_app_map.dart` | `IAppMap` interface (widget protocol) + shared `MapMarker` and `MapPolyline` value types. |
| `google_app_map.dart` | Google Maps implementation. |
| `osm_app_map.dart` | OSM (flutter_map) implementation. Wraps the existing `AppMap` with a tracking-friendly facade. |
| `i_directions_service.dart` | `IDirectionsService` interface + `DirectionsResult` value type (polyline + eta_seconds). |
| `google_directions_service.dart` | Google Directions API impl. |
| `osrm_directions_service.dart` | OSRM impl. |
| `directions_failures.dart` | Sealed failure hierarchy for directions calls. |
| `map_provider.dart` | Riverpod providers: `mapProviderTypeProvider` (returns `MapProviderType.google` or `.osm`), `appMapBuilderProvider`, `directionsServiceProvider`. |
| `live_tracking_map.dart` | Composed widget combining map + marker + polyline + ETA chip + offline banner. The single thing the orchestrator body slots use. |

### Customer-side stream consumer (extends `lib/features/orchestrator/`)

| File | Purpose |
|---|---|
| `data/models/tech_gps_frame_model.dart` | DTO for the `tech_gps` stream payload. |
| `data/mappers/tech_gps_frame_mapper.dart` | DTO → domain `TechGpsFrame`. |
| `domain/entities/tech_gps_frame.dart` | `TechGpsFrame` Freezed entity (lat, lng, accuracyMeters, heading, bookingId, timestamp). |
| `presentation/providers/technician_location_stream_notifier.dart` | Stream consumer notifier; registers handler with `WsFrameDispatcher`, holds latest frame. |
| `presentation/providers/tracking_subscription_controller.dart` | Manages WS subscribe/unsubscribe upstream messages based on booking status + role. |
| `presentation/providers/dependency_injection.dart` | **modified** — register the new providers. |

### Tech-side location broadcaster (new feature folder `frontend/lib/features/technician/location_broadcaster/`)

| File | Purpose |
|---|---|
| `data/datasources/tech_location_remote_data_source.dart` | POSTs to `/api/bookings/<id>/tech-location/`. |
| `data/models/tech_location_request_model.dart` | DTO for the POST body. |
| `domain/entities/broadcast_state.dart` | `BroadcastState` enum: `idle`, `running`, `error`. |
| `presentation/providers/dependency_injection.dart` | DI for the feature. |
| `presentation/providers/foreground_location_service_controller.dart` | Notifier that starts/stops the foreground service in response to booking status changes. |
| `presentation/services/foreground_task_handler.dart` | Top-level entry point for the foreground task isolate (`@pragma('vm:entry-point')`). Geolocator stream subscription + `http.Client` POSTs (audit C2-P0-04). |
| `LOCATION_BROADCASTER_FEATURE.md` | Feature doc. |

### Orchestrator screen updates (modified)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | `EnRouteBodyStub` and `ArrivedBodyStub` now use `LiveTrackingMap`. Other 11 stubs unchanged. |
| `frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart` | **modified** | `initState` reads the broadcaster controller (tech) or the stream notifier (customer) based on `viewerRole`. |
| `frontend/lib/features/orchestrator/presentation/providers/dependency_injection.dart` | **modified** | Wire new providers. |
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified** | Update with live tracking integration; mark sessions 5–6 stubs still pending. |

### Realtime layer (touch — first stream consumer in codebase)

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart` | **modified** (if needed) | Confirm the `register(streamType, handler)` mechanism is callable; document the first consumer pattern. Likely no code change — just verifying the existing API works. |
| `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` | **modified** | (a) Add `sendUpstream(Map<String, dynamic>)` method for tracking subscribe/unsubscribe. (b) Audit P1-06: expose `Stream<WsConnectionEvent>` (or `connectedAt: DateTime?` watchable field) so `TrackingSubscriptionController` can re-subscribe on reconnect. |

### Configuration

| File | Status | Purpose |
|---|---|---|
| `frontend/pubspec.yaml` | **modified** | Add packages: `google_maps_flutter`, `google_maps_flutter_android`, `flutter_foreground_task`, `flutter_polyline_points`. Bump existing `geolocator`, `flutter_map`, `latlong2` if needed. |
| `frontend/android/app/src/main/AndroidManifest.xml` | **modified** | Add `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` permissions. Register `flutter_foreground_task` service. Confirm `ACCESS_FINE_LOCATION` and `POST_NOTIFICATIONS` already present (from prior sprints). Add Google Maps API key meta-data placeholder. |
| `frontend/android/app/build.gradle` | **modified** | `minSdkVersion` ≥ 21 (already met); confirm Java/Kotlin versions for foreground task. |
| `frontend/lib/core/constants/app_constants.dart` | **modified** | Read `MAP_PROVIDER` from `--dart-define`. |
| `frontend/.env.example` (or build script) | **modified** | Document `--dart-define=MAP_PROVIDER=osm|google` and (eventually) `--dart-define=GOOGLE_MAPS_API_KEY=...`. |

### Tests (all new)

| File | Purpose |
|---|---|
| `frontend/test/core/widgets/map/google_app_map_test.dart` | Renders correctly with mocked GoogleMap controller; markers + polylines convert to native types. |
| `frontend/test/core/widgets/map/osm_app_map_test.dart` | Renders correctly via flutter_map; marker + polyline layers present. |
| `frontend/test/core/widgets/map/google_directions_service_test.dart` | Mocked HTTP response → `DirectionsResult`; polyline decoded; eta_seconds extracted. Error path: API quota exceeded → `DirectionsApiQuotaExceeded` failure. |
| `frontend/test/core/widgets/map/osrm_directions_service_test.dart` | Mocked OSRM response → `DirectionsResult`. Failure paths: 5xx, no route. |
| `frontend/test/core/widgets/map/live_tracking_map_test.dart` | Widget test: with hardcoded `TechGpsFrame` → marker renders at expected location; with stale frame (>60s) → "Technician offline" banner appears; with directions result → polyline renders. |
| `frontend/test/features/orchestrator/presentation/providers/technician_location_stream_notifier_test.dart` | Stream frame ingestion → state updates; staleness detected via virtual clock. |
| `frontend/test/features/orchestrator/presentation/providers/tracking_subscription_controller_test.dart` | Booking status × role matrix → subscribe/unsubscribe called correctly. |
| `frontend/test/features/orchestrator/data/mappers/tech_gps_frame_mapper_test.dart` | DTO → entity correctness; null/missing optional fields. |
| `frontend/test/features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source_test.dart` | POST shape; auth header; HttpFailure on non-200. |
| `frontend/test/features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller_test.dart` | Booking status × role → service start/stop calls (mocked `FlutterForegroundTask`). |

### Files NOT touched

- All `backend/` — sessions 1–2.
- The session-3 stub bodies for non-EN_ROUTE/ARRIVED statuses.
- Existing `lib/core/widgets/map/app_map.dart` and `location_picker.dart`.
- Existing `lib/features/customer/addresses/` — address picker continues using `LocationPicker` directly.
- `lib/core/realtime/presentation/router/event_urgency_router.dart` — stream events don't route through urgency router.
- iOS plist or Swift code (flag #10).

---

## §3 Pre-flight

```bash
# 1. Repo + branch
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# 2. Confirm sessions 1–3 landed
ls backend/bookings/api/tech_location/views.py
ls frontend/lib/features/orchestrator/presentation/screens/booking_orchestrator_screen.dart
ls frontend/lib/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart

# 3. Confirm backend running
cd backend && python manage.py runserver &
sleep 2
cd ..

# 4. Frontend baseline
cd frontend
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs

# 5. Confirm existing map widgets still functional (we keep these)
grep -n "class AppMap" lib/core/widgets/map/app_map.dart
grep -n "class LocationPicker" lib/core/widgets/map/location_picker.dart

# 6. Confirm WS dispatcher is callable
grep -n "void register" lib/core/realtime/presentation/services/ws_frame_dispatcher.dart

# 7. Confirm Android manifest baseline (POST_NOTIFICATIONS should already be present from session 3 of prior sprint)
grep -n "POST_NOTIFICATIONS" android/app/src/main/AndroidManifest.xml

# 8. Confirm geolocator already in pubspec
grep -n "geolocator:" pubspec.yaml
```

If any pre-flight step fails, fix before proceeding. Especially: the backend's `tech_location` ingress endpoint must respond 200 to a properly-authenticated POST. Test via curl before frontend work.

---

## §4 Per-file detailed changes

### §4.0 Architecture overview

Three independent subsystems wired together by this session:

```
┌─────────────────────────────────────────────────────────────┐
│ Tech-side device (Android, app foreground)                  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ BookingOrchestratorScreen (status=EN_ROUTE)          │  │
│  │  → reads ForegroundLocationServiceController         │  │
│  │       → starts FlutterForegroundTask                 │  │
│  │            → ForegroundTaskHandler isolate           │  │
│  │                 → Geolocator.getPositionStream(5s)   │  │
│  │                      → POST /api/.../tech-location/  │──┼──┐
│  └──────────────────────────────────────────────────────┘  │  │
└─────────────────────────────────────────────────────────────┘  │
                                                                  │
                                                                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Backend                                                      │
│                                                             │
│  POST /api/bookings/<id>/tech-location/                    │
│   → publishes stream frame to tracking_job_<id> group      │
│   → calls auto_transition.evaluate_on_location              │
│      (may flip status → fires events)                       │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼ (WS frame, kind: stream, type: tech_gps)
┌─────────────────────────────────────────────────────────────┐
│ Customer-side device                                         │
│                                                             │
│  WsFrameDispatcher.dispatch(frame)                          │
│   → handler registered by TechnicianLocationStreamNotifier  │
│       → updates state with new TechGpsFrame                 │
│           → BookingOrchestratorScreen rebuilds              │
│              → LiveTrackingMap renders new marker position  │
└─────────────────────────────────────────────────────────────┘
```

The two devices never see each other directly — both touch the backend's stream group `tracking_job_<id>`. WS subscribe/unsubscribe is managed per booking status (only EN_ROUTE / ARRIVED states are interesting).

### §4.1 `IAppMap` interface + adapter abstraction

#### `core/widgets/map/i_app_map.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Provider-agnostic map widget interface.
///
/// Both [GoogleAppMap] and [OsmAppMap] implement this. Consumers depend on
/// [IAppMap], never on a concrete impl. Selection happens at the provider
/// layer (see [map_provider.dart]).
abstract class IAppMap extends Widget {
  const IAppMap({super.key});

  /// Centre the camera on this point when the map first loads.
  LatLng get initialCenter;

  /// Initial zoom (higher = closer).
  double get initialZoom;

  /// Markers to render. Provider impls must support at least 5 markers smoothly.
  List<MapMarker> get markers;

  /// Polylines to render. Typically ≤2 (route + alternate).
  List<MapPolyline> get polylines;

  /// Optional callback for when the user pans the camera.
  void Function(LatLng newCenter)? get onCameraMove;
}

class MapMarker {
  final String id;
  final LatLng position;
  final String? iconAsset;          // path to flutter asset; null → default marker
  final double rotation;            // degrees, for heading indication
  final String? tooltip;

  const MapMarker({
    required this.id,
    required this.position,
    this.iconAsset,
    this.rotation = 0.0,
    this.tooltip,
  });
}

class MapPolyline {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const MapPolyline({
    required this.id,
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
  });
}

enum MapProviderType { google, osm }
```

The `IAppMap` is a `Widget` — concrete impls are `StatelessWidget` or `StatefulWidget` whose `build` produces the provider's actual widget tree. This is a structural protocol via inheritance, not a behavior interface.

### §4.2 `GoogleAppMap` impl

#### `core/widgets/map/google_app_map.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'i_app_map.dart';

class GoogleAppMap extends StatefulWidget implements IAppMap {
  @override
  final LatLng initialCenter;
  @override
  final double initialZoom;
  @override
  final List<MapMarker> markers;
  @override
  final List<MapPolyline> polylines;
  @override
  final void Function(LatLng newCenter)? onCameraMove;

  const GoogleAppMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.0,
    this.markers = const [],
    this.polylines = const [],
    this.onCameraMove,
  });

  @override
  State<GoogleAppMap> createState() => _GoogleAppMapState();
}

class _GoogleAppMapState extends State<GoogleAppMap> {
  gmaps.GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
        zoom: widget.initialZoom,
      ),
      onMapCreated: (c) => _controller = c,
      markers: widget.markers.map(_toGmapsMarker).toSet(),
      polylines: widget.polylines.map(_toGmapsPolyline).toSet(),
      onCameraMove: widget.onCameraMove == null
          ? null
          : (pos) => widget.onCameraMove!(LatLng(pos.target.latitude, pos.target.longitude)),
      myLocationEnabled: false,                      // we render the tech marker explicitly
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  gmaps.Marker _toGmapsMarker(MapMarker m) {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(m.id),
      position: gmaps.LatLng(m.position.latitude, m.position.longitude),
      rotation: m.rotation,
      icon: m.iconAsset == null
          ? gmaps.BitmapDescriptor.defaultMarker
          : gmaps.BitmapDescriptor.defaultMarker, // session 5 polish: load asset
      infoWindow: m.tooltip == null
          ? gmaps.InfoWindow.noText
          : gmaps.InfoWindow(title: m.tooltip),
    );
  }

  gmaps.Polyline _toGmapsPolyline(MapPolyline p) {
    return gmaps.Polyline(
      polylineId: gmaps.PolylineId(p.id),
      points: p.points.map((ll) => gmaps.LatLng(ll.latitude, ll.longitude)).toList(),
      color: p.color,
      width: p.strokeWidth.toInt(),
    );
  }
}
```

### §4.3 `OsmAppMap` impl

#### `core/widgets/map/osm_app_map.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'i_app_map.dart';

class OsmAppMap extends StatelessWidget implements IAppMap {
  @override
  final LatLng initialCenter;
  @override
  final double initialZoom;
  @override
  final List<MapMarker> markers;
  @override
  final List<MapPolyline> polylines;
  @override
  final void Function(LatLng newCenter)? onCameraMove;

  const OsmAppMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.0,
    this.markers = const [],
    this.polylines = const [],
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onPositionChanged: onCameraMove == null
            ? null
            : (pos, _) => onCameraMove!(pos.center ?? initialCenter),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.karigar.app',
        ),
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: polylines.map((p) => Polyline(
              points: p.points,
              color: p.color,
              strokeWidth: p.strokeWidth,
            )).toList(),
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers.map((m) => Marker(
              point: m.position,
              width: 48,
              height: 48,
              child: Transform.rotate(
                angle: m.rotation * 0.0174533,  // deg → rad
                child: m.iconAsset != null
                    ? Image.asset(m.iconAsset!)
                    : const Icon(Icons.location_on, color: Colors.red, size: 36),
              ),
            )).toList(),
          ),
      ],
    );
  }
}
```

Both impls present the same external Widget shape; consumers don't care which one renders.

### §4.4 `IDirectionsService` + impls

#### `core/widgets/map/i_directions_service.dart`

```dart
import 'package:latlong2/latlong.dart';

abstract class IDirectionsService {
  /// Fetch a route from [origin] to [destination].
  ///
  /// Throws [DirectionsFailure] subtypes on failure.
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  });
}

class DirectionsResult {
  final List<LatLng> polyline;          // decoded points
  final int etaSeconds;                  // server-estimated travel time
  final int distanceMeters;              // total route distance
  final DateTime fetchedAt;              // for staleness check / ETA tickdown anchor

  const DirectionsResult({
    required this.polyline,
    required this.etaSeconds,
    required this.distanceMeters,
    required this.fetchedAt,
  });
}
```

#### `core/widgets/map/directions_failures.dart`

```dart
sealed class DirectionsFailure implements Exception {
  const DirectionsFailure();
}

class DirectionsNoRoute extends DirectionsFailure {
  const DirectionsNoRoute();
}

class DirectionsApiQuotaExceeded extends DirectionsFailure {
  const DirectionsApiQuotaExceeded();
}

class DirectionsNetworkFailure extends DirectionsFailure {
  const DirectionsNetworkFailure();
}

class DirectionsServerFailure extends DirectionsFailure {
  final int statusCode;
  const DirectionsServerFailure(this.statusCode);
}

class UnknownDirectionsFailure extends DirectionsFailure {
  final String message;
  const UnknownDirectionsFailure(this.message);
}
```

#### `core/widgets/map/google_directions_service.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/app_constants.dart';
import 'directions_failures.dart';
import 'i_directions_service.dart';

// Audit C2-P0-04: rewritten as `package:http` per §24 (Dio not in pubspec).
class GoogleDirectionsService implements IDirectionsService {
  final http.Client _client;
  static const _kHost = 'maps.googleapis.com';
  static const _kPath = '/maps/api/directions/json';

  GoogleDirectionsService(this._client);

  @override
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty) {
      throw const UnknownDirectionsFailure('Google Maps API key not configured');
    }
    try {
      final uri = Uri.https(_kHost, _kPath, {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': apiKey,
        'mode': 'driving',
        'departure_time': 'now',
      });
      final response = await _client.get(uri);
      if (response.statusCode >= 500) {
        throw DirectionsServerFailure(response.statusCode);
      }
      if (response.statusCode != 200) {
        throw const DirectionsNetworkFailure();
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final apiStatus = data['status'] as String?;
      if (apiStatus == 'OVER_QUERY_LIMIT' || apiStatus == 'OVER_DAILY_LIMIT') {
        throw const DirectionsApiQuotaExceeded();
      }
      if (apiStatus != 'OK') {
        throw const DirectionsNoRoute();
      }
      final routes = data['routes'] as List;
      if (routes.isEmpty) throw const DirectionsNoRoute();
      final firstRoute = routes.first as Map<String, dynamic>;
      final overview = (firstRoute['overview_polyline'] as Map)['points'] as String;
      final legs = firstRoute['legs'] as List;
      final firstLeg = legs.first as Map<String, dynamic>;
      final etaSeconds = (firstLeg['duration_in_traffic']?['value']
                       ?? firstLeg['duration']['value']) as int;
      final distanceMeters = (firstLeg['distance']['value']) as int;
      final decoded = PolylinePoints()
          .decodePolyline(overview)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      return DirectionsResult(
        polyline: decoded,
        etaSeconds: etaSeconds,
        distanceMeters: distanceMeters,
        fetchedAt: DateTime.now(),
      );
    } on SocketException {
      throw const DirectionsNetworkFailure();
    } catch (e) {
      if (e is DirectionsFailure) rethrow;
      throw UnknownDirectionsFailure(e.toString());
    }
  }
}
```

Imports: `import 'dart:convert';` for `jsonDecode`, `import 'dart:io' show SocketException;`, `import 'package:http/http.dart' as http;`.

#### `core/widgets/map/osrm_directions_service.dart`

```dart
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'directions_failures.dart';
import 'i_directions_service.dart';

// Audit C2-P0-04: rewritten as `package:http`.
class OsrmDirectionsService implements IDirectionsService {
  final http.Client _client;
  final String _baseUrl;

  OsrmDirectionsService(
    this._client, {
    String baseUrl = 'https://router.project-osrm.org',
  }) : _baseUrl = baseUrl;

  @override
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final coords = '${origin.longitude},${origin.latitude}'
                   ';${destination.longitude},${destination.latitude}';
      final uri = Uri.parse('$_baseUrl/route/v1/driving/$coords').replace(
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );
      final response = await _client.get(uri);
      if (response.statusCode >= 500) {
        throw DirectionsServerFailure(response.statusCode);
      }
      if (response.statusCode != 200) {
        throw const DirectionsNetworkFailure();
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') throw const DirectionsNoRoute();
      final routes = data['routes'] as List;
      if (routes.isEmpty) throw const DirectionsNoRoute();
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      final points = coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      final etaSeconds = (route['duration'] as num).round();
      final distanceMeters = (route['distance'] as num).round();
      return DirectionsResult(
        polyline: points,
        etaSeconds: etaSeconds,
        distanceMeters: distanceMeters,
        fetchedAt: DateTime.now(),
      );
    } on SocketException {
      throw const DirectionsNetworkFailure();
    } catch (e) {
      if (e is DirectionsFailure) rethrow;
      throw UnknownDirectionsFailure(e.toString());
    }
  }
}
```

### §4.5 Map provider selection

#### `core/widgets/map/map_provider.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants.dart';
import '../../realtime/presentation/providers/dependency_injection.dart'
    show eventHttpClientProvider;
import 'google_app_map.dart';
import 'google_directions_service.dart';
import 'i_app_map.dart';
import 'i_directions_service.dart';
import 'osm_app_map.dart';
import 'osrm_directions_service.dart';

part 'map_provider.g.dart';

typedef AppMapBuilder = IAppMap Function({
  required LatLng initialCenter,
  double initialZoom,
  List<MapMarker> markers,
  List<MapPolyline> polylines,
  void Function(LatLng)? onCameraMove,
});

@Riverpod(keepAlive: true)
MapProviderType mapProviderType(Ref ref) {
  // Selection at app boot via --dart-define=MAP_PROVIDER=google|osm.
  // Default = osm until Google Maps API key is provisioned (per project_maps_strategy memory).
  return AppConstants.mapProvider;
}

@Riverpod(keepAlive: true)
AppMapBuilder appMapBuilder(Ref ref) {
  final type = ref.watch(mapProviderTypeProvider);
  if (type == MapProviderType.google) {
    return ({
      required initialCenter,
      initialZoom = 14.0,
      markers = const [],
      polylines = const [],
      onCameraMove,
    }) =>
        GoogleAppMap(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          onCameraMove: onCameraMove,
        );
  }
  return ({
    required initialCenter,
    initialZoom = 14.0,
    markers = const [],
    polylines = const [],
    onCameraMove,
  }) =>
      OsmAppMap(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        markers: markers,
        polylines: polylines,
        onCameraMove: onCameraMove,
      );
}

// Audit C2-P0-04: reuse the existing realtime singleton http.Client instead
// of constructing a new one per directions service.
@Riverpod(keepAlive: true)
IDirectionsService directionsService(Ref ref) {
  final client = ref.watch(eventHttpClientProvider);
  final type = ref.watch(mapProviderTypeProvider);
  if (type == MapProviderType.google) {
    return GoogleDirectionsService(client);
  }
  return OsrmDirectionsService(client);
}
```

#### `core/constants.dart` (modified — extends existing file)

```dart
// Add to existing AppConstants class in lib/core/constants.dart.
class AppConstants {
  // ... existing baseUrl, baseWsUrl ...

  static const _mapProviderRaw = String.fromEnvironment('MAP_PROVIDER', defaultValue: 'osm');
  static MapProviderType get mapProvider => switch (_mapProviderRaw) {
    'google' => MapProviderType.google,
    _ => MapProviderType.osm,
  };

  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}
```

### §4.6 `LiveTrackingMap` composed widget

#### `core/widgets/map/live_tracking_map.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'directions_failures.dart';
import 'i_app_map.dart';
import 'i_directions_service.dart';
import 'map_provider.dart';

class LiveTrackingMap extends ConsumerStatefulWidget {
  /// Latest known technician position (null = no frame received yet).
  final LatLng? technicianPosition;

  /// Heading from latest GPS frame (degrees), used to rotate the marker.
  final double? technicianHeading;

  /// Customer destination (the booking's address).
  final LatLng customerPosition;

  /// Timestamp of the latest tech GPS frame; used to compute staleness.
  final DateTime? lastFrameAt;

  /// Whether to show "Tech offline" banner if last frame is >60s ago.
  final bool detectStaleness;

  const LiveTrackingMap({
    super.key,
    required this.technicianPosition,
    required this.customerPosition,
    this.technicianHeading,
    this.lastFrameAt,
    this.detectStaleness = true,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  static const _kStalenessThreshold = Duration(seconds: 60);
  static const _kPolylineRefreshDistanceMeters = 500.0;
  static const _kPolylineMinIntervalSeconds = 30;

  DirectionsResult? _directions;
  LatLng? _polylineAnchor;       // tech position when polyline was last fetched
  bool _fetching = false;
  Timer? _stalenessTicker;
  Timer? _etaTicker;
  int _etaCountdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _maybeFetchDirections();
    _stalenessTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});  // re-evaluate staleness banner
    });
  }

  @override
  void didUpdateWidget(LiveTrackingMap old) {
    super.didUpdateWidget(old);
    _maybeFetchDirections();
  }

  Future<void> _maybeFetchDirections() async {
    final tech = widget.technicianPosition;
    if (tech == null) return;
    if (_fetching) return;
    final shouldFetch = _directions == null
        || _polylineAnchor == null
        || _distance(tech, _polylineAnchor!) > _kPolylineRefreshDistanceMeters
            && DateTime.now()
                .difference(_directions!.fetchedAt)
                .inSeconds >= _kPolylineMinIntervalSeconds;
    if (!shouldFetch) return;
    setState(() => _fetching = true);
    try {
      final svc = ref.read(directionsServiceProvider);
      final result = await svc.getRoute(
        origin: tech,
        destination: widget.customerPosition,
      );
      if (!mounted) return;
      setState(() {
        _directions = result;
        _polylineAnchor = tech;
        _etaCountdownSeconds = result.etaSeconds;
      });
      _etaTicker?.cancel();
      _etaTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _etaCountdownSeconds = (_etaCountdownSeconds - 1).clamp(0, 1 << 30));
      });
    } on DirectionsFailure {
      // Soft-fail: keep last polyline; don't show error to user.
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  void dispose() {
    _stalenessTicker?.cancel();
    _etaTicker?.cancel();
    super.dispose();
  }

  bool get _isStale {
    if (!widget.detectStaleness) return false;
    final last = widget.lastFrameAt;
    if (last == null) return false;
    return DateTime.now().difference(last) > _kStalenessThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(appMapBuilderProvider);
    final tech = widget.technicianPosition;
    final markers = <MapMarker>[
      MapMarker(
        id: 'customer',
        position: widget.customerPosition,
        tooltip: 'Destination',
      ),
      if (tech != null)
        MapMarker(
          id: 'technician',
          position: tech,
          rotation: widget.technicianHeading ?? 0.0,
          tooltip: 'Technician',
        ),
    ];
    final polylines = _directions == null
        ? const <MapPolyline>[]
        : [MapPolyline(
            id: 'route',
            points: _directions!.polyline,
            color: Colors.blue,
            strokeWidth: 5.0,
          )];

    return Stack(
      children: [
        builder(
          initialCenter: tech ?? widget.customerPosition,
          initialZoom: 15.0,
          markers: markers,
          polylines: polylines,
        ),
        if (_directions != null && tech != null)
          Positioned(
            top: 12, left: 12, right: 12,
            child: _EtaChip(seconds: _etaCountdownSeconds),
          ),
        if (_isStale)
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: _OfflineBanner(),
          ),
      ],
    );
  }

  double _distance(LatLng a, LatLng b) {
    // Cheap haversine for change detection. Not for display.
    const R = 6371000.0;
    final phi1 = a.latitude * 3.14159265 / 180;
    final phi2 = b.latitude * 3.14159265 / 180;
    final dphi = (b.latitude - a.latitude) * 3.14159265 / 180;
    final dl = (b.longitude - a.longitude) * 3.14159265 / 180;
    final aa = (sin(dphi / 2)) * (sin(dphi / 2))
        + cos(phi1) * cos(phi2) * (sin(dl / 2)) * (sin(dl / 2));
    final c = 2 * atan2(sqrt(aa), sqrt(1 - aa));
    return R * c;
  }
}

class _EtaChip extends StatelessWidget {
  final int seconds;
  const _EtaChip({required this.seconds});
  @override
  Widget build(BuildContext context) {
    final mins = (seconds / 60).ceil();
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Arriving in ~$mins min',
            style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.signal_wifi_off_outlined),
            SizedBox(width: 8),
            Expanded(child: Text('Technician offline. Last position shown.')),
          ],
        ),
      ),
    );
  }
}
```

(`sin`, `cos`, `atan2`, `sqrt` imported from `dart:math`.)

### §4.7 Configuration

#### `pubspec.yaml` (modified)

Add:

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  google_maps_flutter_android: ^2.5.0     # platform-specific config support
  flutter_foreground_task: ^9.0.0
  flutter_polyline_points: ^2.1.0
  # existing geolocator, flutter_map, latlong2 already declared
```

Run `flutter pub get` after editing.

#### `android/app/src/main/AndroidManifest.xml` (modified)

Inside `<manifest>` block (alongside existing permissions):

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<!-- ACCESS_FINE_LOCATION already present from prior sprint -->
<!-- POST_NOTIFICATIONS already present from session 3 of prior sprint -->
```

Inside `<application>` block:

```xml
<!-- flutter_foreground_task service registration -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="location"
    android:exported="false" />

<!-- Google Maps API key (placeholder; replace with --dart-define value at build time
     OR via gradle property; key is currently TBD per project_maps_strategy memory) -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```

The `${GOOGLE_MAPS_API_KEY}` is replaced via gradle:

#### `android/app/build.gradle` (modified)

Inside `defaultConfig` block:

```gradle
def googleMapsKey = System.getenv('GOOGLE_MAPS_API_KEY') ?: ''
manifestPlaceholders = [
    GOOGLE_MAPS_API_KEY: googleMapsKey
]
```

Empty key produces a manifest with empty value; Google Maps will fail to render but the app won't crash. OSM provider is the dev default anyway.

#### `frontend/.env.example` (or build script)

```bash
# Map provider selection (sprint v1)
# osm = OpenStreetMap + OSRM (no API key, dev default)
# google = Google Maps + Google Directions (requires API key, prod)
MAP_PROVIDER=osm

# Google Maps API key (required only if MAP_PROVIDER=google)
GOOGLE_MAPS_API_KEY=

# Run with:
# flutter run --dart-define=MAP_PROVIDER=osm
# OR
# flutter run --dart-define=MAP_PROVIDER=google --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...
```

### §4.7.5 `WsConnectionNotifier` reconnect-event exposure (audit P1-06)

The existing `WsConnectionNotifier` has private `_scheduleReconnect` logic but no public way for downstream consumers to learn about a successful (re)connection. `TrackingSubscriptionController` needs that signal to re-issue `subscribe_tracking` after a network blip.

Extend the notifier:

```dart
// frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart
// Add at top of file (alongside existing imports — 'dart:async' is already imported):

sealed class WsConnectionEvent {
  const WsConnectionEvent();
}
class WsConnected extends WsConnectionEvent {
  final DateTime at;
  const WsConnected(this.at);
}
class WsDisconnected extends WsConnectionEvent {
  final DateTime at;
  final int? closeCode;
  const WsDisconnected(this.at, this.closeCode);
}

@Riverpod(keepAlive: true)
class WsConnectionNotifier extends _$WsConnectionNotifier {
  // ... existing fields (channel, subscription, timer, retry counters, etc.) ...

  // Audit P1-06: lifecycle event stream for downstream re-subscribe logic.
  final _connectionEvents = StreamController<WsConnectionEvent>.broadcast();

  /// Broadcast stream of connection lifecycle events. Late subscribers see
  /// only events that fire after they listen (no replay).
  Stream<WsConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  WsConnectionStatus build() {
    // Audit C2-P1-01: register cleanup via ref.onDispose, NOT a dispose()
    // override — Riverpod Notifier classes don't provide a dispose() method
    // to override; the ref.onDispose hook is the correct lifecycle seam.
    ref.onDispose(() {
      _reconnectTimer?.cancel();
      _socketSubscription?.cancel();
      _channel?.sink.close();
      _connectionEvents.close();
    });
    return WsConnectionStatus.disconnected;
  }

  // Existing connect()/disconnect()/_scheduleReconnect() methods stay; the
  // patches below add ONE _connectionEvents.add(...) line in each path.

  // Audit C2-P1-02 — concrete insertion sites for connection lifecycle events:
  //
  // (a) In `connect()`, AFTER the existing line `state = WsConnectionStatus.connected;`
  //     (around line 96 of ws_connection_notifier.dart):
  //       _connectionEvents.add(WsConnected(DateTime.now()));
  //
  // (b) In `disconnect()`, BEFORE the existing line `state = WsConnectionStatus.disconnected;`
  //     (around line 155):
  //       _connectionEvents.add(WsDisconnected(DateTime.now(), null));
  //
  // (c) In the `onDone:` and `onError:` branches inside `connect()`'s
  //     `_socketSubscription = _channel!.stream.listen(...)` (lines 109-122,
  //     just before each `_scheduleReconnect(authToken);` call):
  //       _connectionEvents.add(WsDisconnected(DateTime.now(), null));
  //
  // The current notifier doesn't expose a closeCode; pass null. If the
  // close-code matters later, refactor `_socketSubscription.onDone` to read
  // it from `_channel.closeCode` before scheduling reconnect.

  /// Send an upstream message to the WS. Used for tracking subscribe/unsubscribe
  /// by `TrackingSubscriptionController`. Drops silently if not connected;
  /// the TrackingSubscriptionController's connectionEvents listener re-sends
  /// the subscribe on the next WsConnected event.
  void sendUpstream(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(message));
    } catch (e) {
      log('WS upstream send failed: $e', name: _logName);
    }
  }
}
```

`TrackingSubscriptionController` ships in §4.9 (single canonical definition; see below). This subsection covers only the `WsConnectionNotifier` extension that §4.9's controller depends on.

### §4.8 Customer-side stream consumer

#### `features/orchestrator/domain/entities/tech_gps_frame.dart`

```dart
@freezed
class TechGpsFrame with _$TechGpsFrame {
  const factory TechGpsFrame({
    required int bookingId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? heading,
    required DateTime timestamp,
  }) = _TechGpsFrame;
}
```

#### `features/orchestrator/data/models/tech_gps_frame_model.dart`

```dart
@freezed
class TechGpsFrameModel with _$TechGpsFrameModel {
  const factory TechGpsFrameModel({
    @JsonKey(name: 'booking_id') required int bookingId,
    required double lat,
    required double lng,
    @JsonKey(name: 'accuracy_meters') double? accuracyMeters,
    double? heading,
    required String timestamp,        // ISO-8601 from server
  }) = _TechGpsFrameModel;
  factory TechGpsFrameModel.fromJson(Map<String, dynamic> json) =>
      _$TechGpsFrameModelFromJson(json);
}
```

#### `features/orchestrator/data/mappers/tech_gps_frame_mapper.dart`

```dart
class TechGpsFrameMapper {
  static TechGpsFrame toDomain(TechGpsFrameModel model) {
    return TechGpsFrame(
      bookingId: model.bookingId,
      latitude: model.lat,
      longitude: model.lng,
      accuracyMeters: model.accuracyMeters,
      heading: model.heading,
      timestamp: DateTime.parse(model.timestamp),
    );
  }
}
```

#### `features/orchestrator/presentation/providers/technician_location_stream_notifier.dart`

```dart
@Riverpod(keepAlive: false)
class TechnicianLocationStreamNotifier extends _$TechnicianLocationStreamNotifier {
  @override
  TechGpsFrame? build(int jobId) {
    final dispatcher = ref.read(wsFrameDispatcherProvider);

    void handler(Map<String, dynamic> payload) {
      try {
        final model = TechGpsFrameModel.fromJson(payload);
        if (model.bookingId != jobId) return;   // defensive — late frames after unsubscribe
        final frame = TechGpsFrameMapper.toDomain(model);
        // Audit P1-05: defer state assignment past build()'s return AND guard
        // against post-disposal writes. The handler can fire synchronously
        // during build (rare but possible if a frame is in the channel buffer).
        Future.microtask(() {
          if (!ref.mounted) return;
          state = frame;
        });
      } catch (_) {
        // Malformed frame — log and drop. Don't crash the whole notifier.
      }
    }

    dispatcher.register('tech_gps', handler);
    ref.onDispose(() {
      // Audit P0-07: WsFrameDispatcher.unregister(streamType) is single-arg
      // because the dispatcher is single-handler-per-type. v0.9 plan called
      // unregister('tech_gps', handler) which is wrong arity — won't compile.
      // Documented constraint: only ONE active orchestrator screen consumes
      // tech_gps at a time. Multi-handler refactor deferred via flag
      // `ws-stream-multi-handler-deferred`.
      dispatcher.unregister('tech_gps');
    });
    return null;  // start with no frame
  }
}
```

**Dispatcher constraint (audit P0-07)**: `WsFrameDispatcher` is single-handler-per-type. Calling `register('tech_gps', handlerA)` then `register('tech_gps', handlerB)` silently replaces handlerA. For v1 this is fine (UX shows one orchestrator screen at a time); for production where two browser tabs / two app instances might both watch tracking, a multi-handler refactor (`Map<String, List<Handler>>` + token-based unregister) is needed — flagged.

### §4.9 WS subscribe/unsubscribe lifecycle

**Audit C2-P0-03 + C2-P1-07**: this is the **single canonical** `TrackingSubscriptionController`. The earlier §4.7.5 only adds the `WsConnectionNotifier` extension (`connectionEvents` Stream + `sendUpstream`); it does NOT define a separate controller. Likewise `sendUpstream` is defined exactly once — in §4.7.5 — not redefined here.

The controller listens to two reactive sources:
- `bookingDetailNotifierProvider(jobId)` — gates subscription on `status × role`. Subscribe only when `viewerRole == customer` AND `status ∈ {EN_ROUTE, ARRIVED}`. Unsubscribe when leaving that window.
- `WsConnectionNotifier.connectionEvents` — re-issues `subscribe_tracking` on every successful `WsConnected` event (covers reconnects after a network blip). Filters by `event is WsConnected`; ignores `WsDisconnected` (the next reconnect will re-subscribe).

Why `connectionEvents` Stream instead of `wsConnectionStatusProvider` Riverpod state listener: `wsConnectionStatusProvider` exposes the current status as a value; if a fast disconnect-then-reconnect happens between Riverpod's listener wakeups, the listener may miss the transition (Riverpod debounces equal-value writes). `connectionEvents` is a broadcast Stream — every successful (re)connect emits exactly one `WsConnected`, never elided.

#### `features/orchestrator/presentation/providers/tracking_subscription_controller.dart`

```dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import '../../domain/entities/booking_orchestrator_role.dart';
import '../../domain/entities/booking_status.dart';
import 'booking_detail_notifier.dart';

part 'tracking_subscription_controller.g.dart';

@Riverpod(keepAlive: false)
class TrackingSubscriptionController extends _$TrackingSubscriptionController {
  bool _subscribed = false;
  StreamSubscription<WsConnectionEvent>? _wsEventsSub;

  @override
  void build(int jobId) {
    final ws = ref.read(wsConnectionProvider.notifier);

    // (1) status × role gate — drives subscribe/unsubscribe transitions.
    ref.listen(bookingDetailNotifierProvider(jobId), (prev, next) {
      next.whenData((booking) {
        final shouldSubscribe = booking.viewerRole == BookingOrchestratorRole.customer
            && (booking.status == BookingStatus.enRoute
                || booking.status == BookingStatus.arrived);
        if (shouldSubscribe && !_subscribed) {
          _send(ws, 'subscribe_tracking', jobId);
          _subscribed = true;
        } else if (!shouldSubscribe && _subscribed) {
          _send(ws, 'unsubscribe_tracking', jobId);
          _subscribed = false;
        }
      });
    });

    // (2) reconnect re-subscribe — replay subscribe on every WsConnected
    // while we're in the "should be subscribed" window. Idempotent at backend.
    _wsEventsSub = ws.connectionEvents.listen((event) {
      if (event is WsConnected && _subscribed) {
        _send(ws, 'subscribe_tracking', jobId);
      }
    });

    ref.onDispose(() {
      _wsEventsSub?.cancel();
      if (_subscribed) {
        _send(ws, 'unsubscribe_tracking', jobId);
        _subscribed = false;
      }
    });
  }

  static void _send(WsConnectionNotifier ws, String action, int jobId) {
    ws.sendUpstream({'action': action, 'booking_id': jobId});
  }
}
```

The orchestrator screen reads `trackingSubscriptionControllerProvider(jobId)` in `initState`. The notifier's `keepAlive: false` ensures it disposes when the screen unmounts (and the disposal hook handles the unsubscribe). Backend's `subscribe_tracking` handler is idempotent (the consumer maintains a `_tracking_subscriptions: set[int]` per-channel and `add()`s the booking_id, which is a no-op if already present).

### §4.10 Stream-staleness "tech offline" banner

Already integrated into `LiveTrackingMap` (§4.6) — the widget checks `widget.lastFrameAt` against a 60s threshold and conditionally renders `_OfflineBanner`. The orchestrator's body slot passes the latest frame's timestamp (from `technicianLocationStreamProvider`) through to the widget.

### §4.11 Tech-side location broadcaster

#### `features/technician/location_broadcaster/data/models/tech_location_request_model.dart`

```dart
@freezed
class TechLocationRequestModel with _$TechLocationRequestModel {
  const factory TechLocationRequestModel({
    required double lat,
    required double lng,
    @JsonKey(name: 'accuracy_meters') double? accuracyMeters,
    double? heading,
  }) = _TechLocationRequestModel;
  factory TechLocationRequestModel.fromJson(Map<String, dynamic> json) =>
      _$TechLocationRequestModelFromJson(json);
}
```

#### `features/technician/location_broadcaster/data/datasources/tech_location_remote_data_source.dart`

**Audit C2-P0-04 + C2-P0-01**: rewritten as `package:http` per §24 canonical pattern (Dio isn't in pubspec); URL drops `/api/` because `AppConstants.baseUrl` already includes it.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/common/errors/http_failure.dart';
import '../../../../core/constants.dart';
import '../models/tech_location_request_model.dart';

class TechLocationRemoteDataSource {
  final http.Client _client;
  TechLocationRemoteDataSource(this._client);

  /// Throttled GPS frame post. Returns true if the frame was published.
  /// Returns false (without throwing) on 429 — backend throttle is expected.
  Future<bool> postLocation({
    required int bookingId,
    required String authToken,
    required double lat,
    required double lng,
    double? accuracyMeters,
    double? heading,
  }) async {
    final body = TechLocationRequestModel(
      lat: lat, lng: lng,
      accuracyMeters: accuracyMeters,
      heading: heading,
    ).toJson();
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId/tech-location/'),
      headers: {
        'Authorization': 'Token $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 429) return false;     // throttled; drop frame
    if (response.statusCode >= 400) {
      Map<String, dynamic>? envelope;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) envelope = decoded;
      } catch (_) {}
      throw HttpFailure(
        statusCode: response.statusCode,
        code: envelope?['code'] as String? ?? 'unknown',
        message: envelope?['message'] as String? ?? 'tech-location post failed',
        errors: (envelope?['errors'] as Map<String, dynamic>?) ?? const {},
      );
    }
    return true;
  }
}
```

### §4.12 Foreground service handler

#### `features/technician/location_broadcaster/presentation/services/foreground_task_handler.dart`

**Audit C2-P0-04**: foreground task isolate constructs a fresh `http.Client()` per §24's "foreground service isolate exception" — Riverpod providers don't cross isolate boundaries.

```dart
import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/tech_location_remote_data_source.dart';

@pragma('vm:entry-point')
void startTechLocationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(TechLocationTaskHandler());
}

class TechLocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;
  late TechLocationRemoteDataSource _remote;
  late http.Client _isolateClient;
  late int _bookingId;
  late String _authToken;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final data = await FlutterForegroundTask.getData<Map<String, dynamic>>(key: 'config');
    _bookingId = data!['booking_id'] as int;
    _authToken = data['auth_token'] as String;
    // Fresh http.Client per isolate; Riverpod's eventHttpClient lives in main.
    _isolateClient = http.Client();
    _remote = TechLocationRemoteDataSource(_isolateClient);

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied
        || permission == LocationPermission.deniedForever) {
      // Service can't proceed; surface via repeat task event for the controller to handle.
      FlutterForegroundTask.sendDataToMain('permission_denied');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onFix);
  }

  Future<void> _onFix(Position position) async {
    try {
      await _remote.postLocation(
        bookingId: _bookingId,
        authToken: _authToken,
        lat: position.latitude,
        lng: position.longitude,
        accuracyMeters: position.accuracy,
        heading: position.heading,
      );
    } catch (e) {
      // Log + continue; transient network failures are expected.
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Not used — geolocator stream drives postings.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isolateClient.close();    // Audit C2-P0-04: free the isolate's http.Client.
  }
}
```

#### `features/technician/location_broadcaster/presentation/providers/foreground_location_service_controller.dart`

```dart
@Riverpod(keepAlive: false)
class ForegroundLocationServiceController
    extends _$ForegroundLocationServiceController {
  bool _running = false;

  @override
  void build(int jobId) {
    ref.listen(bookingDetailNotifierProvider(jobId), (prev, next) {
      next.whenData((booking) async {
        final shouldRun = booking.viewerRole == BookingOrchestratorRole.technician
            && (booking.status == BookingStatus.enRoute
                || booking.status == BookingStatus.arrived);
        if (shouldRun && !_running) {
          await _startService(booking);
          _running = true;
        } else if (!shouldRun && _running) {
          await _stopService();
          _running = false;
        }
      });
    });

    ref.onDispose(() {
      if (_running) {
        FlutterForegroundTask.stopService();
      }
    });
  }

  Future<void> _startService(BookingDetail booking) async {
    // Audit C2-P1-06: per-feature secure-storage provider.
    final token = await ref
        .read(orchestratorSecureStorageProvider)
        .read(key: 'auth_token');
    if (token == null) return;

    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tech_location_tracking',
        channelName: 'Tracking job',
        channelDescription: 'Sends your location to the customer for active jobs.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    final firstName = booking.customer.fullName.split(' ').first;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Tracking job',
      notificationText: 'Sending location to $firstName',
      callback: startTechLocationTaskCallback,
    );

    await FlutterForegroundTask.saveData(key: 'config', value: {
      'booking_id': booking.id,
      'auth_token': token,
    });
  }

  Future<void> _stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
```

### §4.13 Orchestrator screen integration

#### `features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart` (modified)

Replace `EnRouteBodyStub` and `ArrivedBodyStub`:

```dart
class EnRouteBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const EnRouteBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addr = booking.address;
    if (addr == null) {
      return _NoAddressFallback(text: booking.ui.bodyText);
    }
    final liveFrame = ref.watch(technicianLocationStreamNotifierProvider(booking.id));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LiveTrackingMap(
                technicianPosition: liveFrame == null
                    ? null
                    : LatLng(liveFrame.latitude, liveFrame.longitude),
                technicianHeading: liveFrame?.heading,
                customerPosition: LatLng(addr.latitude, addr.longitude),
                lastFrameAt: liveFrame?.timestamp,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(booking.ui.bodyText),
        ],
      ),
    );
  }
}

class ArrivedBodyStub extends ConsumerWidget {
  final BookingDetail booking;
  const ArrivedBodyStub({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // After arrival, the map is still useful (tech may move briefly),
    // but the body emphasis switches to "What's next" prose from server.
    final addr = booking.address;
    final liveFrame = ref.watch(technicianLocationStreamNotifierProvider(booking.id));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (addr != null)
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LiveTrackingMap(
                  technicianPosition: liveFrame == null
                      ? null
                      : LatLng(liveFrame.latitude, liveFrame.longitude),
                  technicianHeading: liveFrame?.heading,
                  customerPosition: LatLng(addr.latitude, addr.longitude),
                  lastFrameAt: liveFrame?.timestamp,
                  detectStaleness: true,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(booking.ui.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### `features/orchestrator/presentation/screens/booking_orchestrator_screen.dart` (modified)

Extend `initState`:

```dart
@override
void initState() {
  super.initState();
  ref.read(bookingOrchestratorEventsNotifierProvider(widget.jobId));
  ref.read(bookingRescheduledNotifierProvider(widget.jobId));
  // Tracking infrastructure: customer-side subscription, tech-side broadcaster.
  ref.read(trackingSubscriptionControllerProvider(widget.jobId));
  ref.read(foregroundLocationServiceControllerProvider(widget.jobId));
}
```

Both controllers self-arm based on `viewerRole` and `status`; reading them once at screen init starts the listener chains.

### §4.14 Tests

#### Map adapter widget tests

`google_app_map_test.dart` — pumpWidget with mock GoogleMap channel; assert markers/polylines passed correctly.

`osm_app_map_test.dart` — pumpWidget; assert FlutterMap children include MarkerLayer + PolylineLayer with correct counts.

#### Directions service tests

`google_directions_service_test.dart` (audit C2-P0-04 — `MockClient` from `package:http/testing.dart`):

```dart
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

test('decodes polyline + extracts ETA from valid response', () async {
  final client = MockClient((request) async {
    expect(request.url.host, 'maps.googleapis.com');
    return http.Response(_validGoogleDirectionsResponseJson, 200);
  });
  final svc = GoogleDirectionsService(client);
  final result = await svc.getRoute(
    origin: const LatLng(31.5204, 74.3587),
    destination: const LatLng(31.5497, 74.3436),
  );
  expect(result.polyline, isNotEmpty);
  expect(result.etaSeconds, greaterThan(0));
});

test('raises ApiQuotaExceeded on OVER_QUERY_LIMIT', () async { ... });
test('raises NoRoute on ZERO_RESULTS', () async { ... });
```

`osrm_directions_service_test.dart` — same shape, `MockClient` returning the OSRM JSON fixture.

#### `live_tracking_map_test.dart`

```dart
testWidgets('renders staleness banner when last frame is >60s old', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appMapBuilderProvider.overrideWithValue((/* args */) => const SizedBox()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LiveTrackingMap(
            technicianPosition: const LatLng(31.5204, 74.3587),
            customerPosition: const LatLng(31.5497, 74.3436),
            lastFrameAt: DateTime.now().subtract(const Duration(seconds: 90)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();        // tick for the staleness ticker
  expect(find.text('Technician offline. Last position shown.'), findsOneWidget);
});
```

#### `technician_location_stream_notifier_test.dart`

```dart
test('updates state on tech_gps frame matching jobId', () async {
  final dispatcher = MockWsFrameDispatcher();
  final container = ProviderContainer(overrides: [
    wsFrameDispatcherProvider.overrideWithValue(dispatcher),
  ]);
  await container.read(technicianLocationStreamNotifierProvider(123).future);
  // Simulate a frame
  final handler = capturedHandler;     // captured via dispatcher.register stub
  handler({
    'booking_id': 123,
    'lat': 31.5,
    'lng': 74.3,
    'timestamp': DateTime.now().toIso8601String(),
  });
  await Future.microtask(() {});
  expect(container.read(technicianLocationStreamNotifierProvider(123))!.bookingId, 123);
});
```

#### `tracking_subscription_controller_test.dart`

```dart
test('subscribes when status flips to EN_ROUTE for customer viewer', () async {
  final wsNotifier = MockWsConnectionNotifier();
  final container = ProviderContainer(overrides: [
    wsConnectionProvider.overrideWith(() => wsNotifier),
    bookingDetailNotifierProvider(123).overrideWith(() => _stubBookingDetail(
      status: BookingStatus.enRoute,
      role: BookingOrchestratorRole.customer,
    )),
  ]);
  container.read(trackingSubscriptionControllerProvider(123));
  await Future.microtask(() {});
  verify(() => wsNotifier.sendUpstream({
    'action': 'subscribe_tracking',
    'booking_id': 123,
  })).called(1);
});
```

#### `foreground_location_service_controller_test.dart`

Mock `FlutterForegroundTask.startService` / `stopService` (use a wrapper class — the package's static API is hard to mock directly). Verify start called with right config when status=enRoute && role=technician; stop called when status flips out.

---

## §5 Gotchas

1. **Foreground service permission flow**: on Android 13+, `POST_NOTIFICATIONS` runtime permission must be granted before the service can show its notification. Existing session-3-of-prior-sprint already added the request flow; verify it covers the path where the user denies the permission and tries to start the service. Surface a pre-flight permission-check at the orchestrator-screen level and snackbar `'Enable notifications to track jobs'` on denial.
2. **`flutter_foreground_task` requires a top-level entry point** marked `@pragma('vm:entry-point')`. Per the package, the function name doesn't matter but it must be top-level (not class method). Hence `startTechLocationTaskCallback` lives at file scope in `foreground_task_handler.dart`.
3. **Geolocator's `getPositionStream` runs in the foreground service isolate** — that isolate has no access to the main isolate's Riverpod containers, providers, or shared state. Pass `bookingId` and `authToken` via `FlutterForegroundTask.saveData(...)` and read in the isolate. This is why the controller's `_startService` saves data BEFORE `startService`.
4. **`Geolocator.getPositionStream` requires `LocationSettings` (Android-specific)** — use `AndroidSettings(...)` or fall back to `LocationSettings(...)`. For v1 use the cross-platform `LocationSettings` (which works on Android and iOS, even though we don't ship iOS this sprint). Distance filter 10m, accuracy high.
5. **Battery cost**: foreground service + 5s GPS = significant battery draw. Acceptable for active jobs (≤2 hours typically), but flag.md should note "service auto-stops on terminal status; if tech keeps app open after job completion, no further GPS." Verified at session 4 DoD.
6. **Google Maps with empty API key crashes silently on first render** — the map widget shows blank tiles but doesn't throw. Hence the OSM default — the dev build always works. When `MAP_PROVIDER=google` and key is empty, log a clear warning at app start.
7. **OSRM rate limiting**: the public instance `router.project-osrm.org` has soft rate limits; for >50 demos it can throttle. Production must self-host OSRM or pay for Mapbox. Logged in flag.md.
8. **`flutter_polyline_points` decodes Google's polyline encoding format** — Google returns `overview_polyline.points` as encoded string. OSRM with `geometries=geojson` returns LatLng arrays directly (no decoding needed). Both impls match the same `DirectionsResult` shape.
9. **Polyline refresh debounce**: the 30s minimum + 500m distance combination prevents spamming the directions API. Without it, every 5s GPS frame would trigger a fetch. Test by simulating rapid GPS frames.
10. **ETA tickdown vs. recomputation**: client-side decrement is approximate (it doesn't account for speed changes or traffic). Server-fetched ETA from the next polyline call corrects drift. Acceptable for v1; finer-grained ETA is a sprint past this one.
11. **`MapProviderType` is selected at app boot via `--dart-define`** — runtime flipping is NOT supported. If a user has the app open and an admin reconfigures `MAP_PROVIDER`, the app needs a restart. This is intentional — runtime swap would require widget tree rebuild on every screen. Documented.
12. **Stream subscription on WS reconnect**: `TrackingSubscriptionController` listens to `wsConnectionStatusProvider` and re-sends `subscribe_tracking` on `connected` events. Backend's subscribe is idempotent. Without this, a brief WS drop breaks tracking until status flips again.
13. **Tracking frames during the session-2 backend's 4s throttle**: backend rejects with 429. Client treats 429 as "drop this frame" — no error displayed. Verified in `tech_location_remote_data_source.dart`.
14. **Marker rotation semantics**: `MapMarker.rotation` is degrees clockwise from north. Geolocator's `heading` is also degrees clockwise from north (when available — may be `null` for stationary positions). Pass through directly. When `heading == null`, marker has no rotation (default 0).
15. **`ClipRRect` around `LiveTrackingMap`** is necessary because Google Maps doesn't respect `BorderRadius.circular(...)` on its container — the native view ignores it. ClipRRect forces visual clipping. OSM's flutter_map respects border radius, but for adapter parity, always wrap.
16. **`LiveTrackingMap.detectStaleness`** can be disabled per use case. On `ARRIVED`, the tech may stop moving (parked at customer's house) — but they're not "offline." Decision: keep staleness ON for `ARRIVED` for v1 (tech going inside the house and the GPS losing signal IS a useful signal); revisit if the banner is too noisy.
17. **`FlutterForegroundTask.init` MUST be called from main isolate, not from the task handler**. The controller does this in `_startService`. Don't move `init` into the handler's `onStart`.
18. **`google_maps_flutter_android`** dependency is needed alongside `google_maps_flutter` to allow setting `AndroidGoogleMapsFlutter.useAndroidViewSurface = true` if rendering issues appear. Current versions handle this automatically; document in case a future upgrade needs it.
19. **iOS placeholder in `flutter_foreground_task` config**: the package requires an `iosNotificationOptions` even when not deploying to iOS. Pass `const IOSNotificationOptions()` (defaults). When iOS support lands (post flag #10), revise.
20. **WebSocket `sendUpstream` contract**: the WS connection is JSON-encoded; `sendUpstream` does `jsonEncode(message)` before sending. Backend decodes as JSON in `consumers.py::receive_json`. Mismatched encoding (e.g., raw text) silently drops on backend side.

---

## §6 Verification

### Static checks

```bash
cd frontend
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
```

### Manual end-to-end (Android device required)

1. Backend running: `cd backend && python manage.py runserver 0.0.0.0:8000`.
2. Frontend, OSM provider:
   ```bash
   cd frontend
   flutter run --dart-define=MAP_PROVIDER=osm
   ```
   On a physical Android device (foreground service requires an actual device — emulator works but GPS feed is less realistic).
3. Walk happy path: customer books → tech accepts → tech opens orchestrator screen at status CONFIRMED.
4. Tech taps "Start journey" (manual override, since auto requires GPS movement) — status flips to EN_ROUTE.
5. Tech grants location + notification permissions when prompted.
6. Persistent notification "Tracking job to <Customer>" appears.
7. On the customer device, open the same booking — `LiveTrackingMap` renders the destination marker. Within 10–15s, the tech's marker appears (after first stream frame).
8. Move the tech device physically (or simulate via `geolocator` mock); customer sees marker move every 5s.
9. Verify the polyline appears (gross route from tech → customer).
10. Verify ETA chip displays "Arriving in ~N min" and ticks down each second.
11. Kill the network on the tech device for 60s — customer sees "Technician offline" banner appear.
12. Restore network — banner disappears within ~5s of next frame.
13. Tech taps "Mark Arrived" — service stops; customer's banner stays gone.
14. Walk through to COMPLETED via cash collection — service does not restart.

### Provider switch smoke

```bash
# Same demo with Google Maps, IF you have an API key:
flutter run \
  --dart-define=MAP_PROVIDER=google \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...
```

Expected: visually different tiles, otherwise identical UX.

### Constraint checks

```bash
# Confirm widgets don't construct API URLs
grep -rn "googleapis.com\|project-osrm.org" frontend/lib/features/orchestrator/
# Expected: empty (URLs live in core/widgets/map/ implementations)

# Confirm only ONE foreground task entry point
grep -rn "@pragma('vm:entry-point')" frontend/lib/features/technician/location_broadcaster/
# Expected: exactly 1 (startTechLocationTaskCallback)

# Confirm no direct geolocator imports outside the broadcaster feature
grep -rn "import 'package:geolocator" frontend/lib/features/orchestrator/
# Expected: empty
```

### Battery / background behavior

- Tech goes EN_ROUTE; lock device screen; verify notification persists and stream frames continue (backend logs show frames arriving).
- Tech swipes app away from recents; verify service stops (foreground service is bound to app lifecycle in current config).
- After 30 min of EN_ROUTE, check battery usage in device settings — should be moderate (location-tracking apps consume 5–15% per hour).

---

## §7 What this session does NOT fix

- iOS foreground location service — flag #10 deferred.
- Full background geolocation when app is killed by OS — requires `flutter_background_geolocation` (paid) or equivalent; sprint v2.
- Self-hosted OSRM instance — public OSRM works for dev/test; production rate-limited (flag noted).
- Google Maps API key provisioning — TBD per memory; orchestrator works on OSM until then.
- Quote builder UI — session 5.
- Cash collection screen — session 5.
- Cancellation / no-show / dispute UIs — session 6.
- Marker icon assets (custom truck icon for tech, pin for customer) — placeholder default markers this session; design polish later.
- Smooth marker interpolation between GPS frames — frames jump every 5s; smoothing animation deferred.
- Map heat-tile / traffic overlays — neither provider configured for it this sprint.
- Distance-aware geofence radius (currently fixed at 100m for ARRIVED auto-trigger per session 1) — per-tech / per-service config deferred.
- Multi-tenant directions caching (e.g., Redis on backend) — every client fetches its own; backend has no involvement.

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All new files under `frontend/lib/core/widgets/map/` created.
- [ ] All new files under `frontend/lib/features/orchestrator/` (data + presentation extensions) created.
- [ ] All new files under `frontend/lib/features/technician/location_broadcaster/` created.
- [ ] `EnRouteBodyStub` and `ArrivedBodyStub` in `all_status_stubs.dart` updated to use `LiveTrackingMap`.
- [ ] `BookingOrchestratorScreen.initState` reads the tracking subscription controller and the foreground service controller.
- [ ] `WsConnectionNotifier.sendUpstream` method added.
- [ ] `pubspec.yaml` updated with `google_maps_flutter`, `google_maps_flutter_android`, `flutter_foreground_task`, `flutter_polyline_points`.
- [ ] `AndroidManifest.xml` updated with `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` permissions, the foreground service registration, and the Google Maps API key meta-data placeholder.
- [ ] `build.gradle` reads `GOOGLE_MAPS_API_KEY` env var.
- [ ] `app_constants.dart` reads `MAP_PROVIDER` and `GOOGLE_MAPS_API_KEY` from `--dart-define`.
- [ ] `.env.example` documents the new env vars.

### Tests

- [ ] `flutter test` green on the full suite.
- [ ] Map adapter widget tests (Google + OSM) pass.
- [ ] Directions service tests (Google + OSRM, mocked HTTP) cover happy path + each failure branch.
- [ ] `LiveTrackingMap` widget test asserts: marker renders at expected location, polyline renders when directions present, staleness banner appears when `lastFrameAt` is >60s old.
- [ ] `TechnicianLocationStreamNotifier` tests assert: state updates on matching frame, ignores frames with mismatched jobId.
- [ ] `TrackingSubscriptionController` tests assert: subscribe on EN_ROUTE+customer, unsubscribe on status leave, re-subscribe on WS reconnect.
- [ ] `TechLocationRemoteDataSource` tests cover: 200 → no-op, 429 → no-op (drop), 4xx → HttpFailure, 5xx → HttpFailure.
- [ ] `ForegroundLocationServiceController` tests (with mock `FlutterForegroundTask` wrapper) assert: start called with correct config when status=enRoute+technician, stop called on status leave.

### Manual smoke

- [ ] OSM provider: customer sees tech's marker move on map, polyline draws, ETA ticks down.
- [ ] Network drop: "Technician offline" banner appears after 60s.
- [ ] Google provider (if API key available): same UX with Google tiles.
- [ ] Tech device's persistent notification persists with screen locked.
- [ ] Service stops on status flip to terminal (tech ends job).

### Constraints

- [ ] Single map adapter abstraction; consumers depend on `IAppMap` / `IDirectionsService`, not on Google or OSM directly.
- [ ] No `googleapis.com` or `project-osrm.org` URL strings outside `core/widgets/map/`.
- [ ] No direct `geolocator` imports outside `features/technician/location_broadcaster/`.
- [ ] Single `@pragma('vm:entry-point')` function for the foreground task.
- [ ] WS upstream messages limited to `subscribe_tracking` / `unsubscribe_tracking` (no other client → server messages added).
- [ ] Stream consumer pattern documented in `ORCHESTRATOR_FEATURE.md` for future stream consumers (the codebase's first).

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` updated to describe the live tracking integration, the WS subscription lifecycle, and the stream consumer pattern (codebase's first).
- [ ] `LOCATION_BROADCASTER_FEATURE.md` written (covers domain, foreground service handler, data source, controller, lifecycle binding).
- [ ] CLAUDE.md may need a small note on stream consumer template (mirror of the existing per-event template). One paragraph addition.

### flag.md

- [ ] Per sprint meta §20: opens `ios-foreground-service-deferred` (iOS variant of the foreground location service, requires Mac).
- [ ] Touches flag #16: "Maps API key absence" — adapter shipped; the warning + dev fallback to OSM remains the documented behavior. Update the flag's notes to reference this session's adapter.
- [ ] (Optional) flag noting OSRM public instance rate limits — production must self-host.

### Git

- [ ] Single commit (or small chain): `feat(orchestrator): live tracking with dual-provider maps + Android foreground GPS service (sprint v1, session 4)`.
- [ ] `flutter analyze` clean.
- [ ] `dart format` applied.
- [ ] `git status` clean after commit.
