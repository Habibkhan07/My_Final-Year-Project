# Core Map Widgets

Reusable map components. Two generations coexist:

1. **Legacy single-provider widgets** (`AppMap`, `LocationPicker`,
   `AppMapStateViews`) — pre-session-4. Built directly on
   `flutter_map` + OpenStreetMap. Used by location-picking flows that
   don't need the dual-provider abstraction.
2. **Session 4 dual-provider stack** (`IAppMap`, `OsmAppMap`,
   `GoogleAppMap`, `LiveTrackingMap`, `IDirectionsService`,
   `LiveMarkerFactory`, `MapProviderType`) — added for the booking
   orchestrator's live-tracking screen. Provider-agnostic at compile
   time via `--dart-define=MAP_PROVIDER=osm|google`.

---

## Session 4 dual-provider stack

### `IAppMap` (protocol)

`i_app_map.dart` defines the abstract contract every provider implements:

```dart
abstract class IAppMap {
  LatLng get initialCenter;
  double get initialZoom;
  List<MapMarker> get markers;
  List<MapPolyline> get polylines;
  LatLng? get cameraTarget;
  double? get cameraZoom;
  List<LatLng>? get cameraBounds;
  VoidCallback? get onUserGesture;
}
```

Plus the value classes:
- **`MapMarker`** — `id`, `position`, `kind` (one of `customer`,
  `technicianMoving`, `technicianStopped`), optional `rotationDegrees`.
  Value-equality on every field — important for marker-resolve
  short-circuiting (audit T-1).
- **`MapPolyline`** — `id`, `points`, `color`, `strokeWidth`.
- **`MarkerKind`** — drives `LiveMarkerFactory`'s icon/colour switch.

### `OsmAppMap` and `GoogleAppMap`

Concrete `IAppMap` implementations. Both are `StatefulWidget`s that mount
the underlying provider's map widget (`flutter_map.FlutterMap` for OSM,
`google_maps_flutter.GoogleMap` for Google). They share:

- `_programmaticMoveInFlight` flag so programmatic camera moves don't
  fire the user-gesture callback.
- Marker resolution pipeline: incoming `List<MapMarker>` → resolved
  set of native markers (Widget for OSM, `BitmapDescriptor` for
  Google), with `Future.wait` ensuring the rendered set is only
  emitted when EVERY descriptor is ready (audit T-1).
- Camera-target-vs-bounds priority: `cameraTarget` wins when both
  are set; bounds-fit only fires when `cameraTarget == null`.

`GoogleAppMapInternals` (audit C12 / `@visibleForTesting` companion
class) hoists the pure helpers out of `_GoogleAppMapState`:
- `markersEqual(a, b)` — short-circuit + ordered field-equal compare.
- `listsAreSame(a, b)` — null-handling + per-point compare for `cameraBounds`.
- `computeBounds(points)` — min/max sweep → `gmaps.LatLngBounds`.
- `resolveAllMarkers(incoming, {resolveIcon})` — `Future.wait` merge
  with an injectable `resolveIcon` so tests don't hit the
  `LiveMarkerFactory` canvas pipeline.

### `LiveTrackingMap`

`live_tracking_map.dart` — the customer/tech live tracking screen body.
Composed of:
- The `IAppMap` builder (resolved by `appMapBuilderProvider`).
- A 56dp circular marker bubble per `MarkerKind` (programmatic, no PNG
  assets — see `LiveMarkerFactory`).
- An ETA pill driven by the `directionsServiceProvider` (OSRM by
  default, Google when `MAP_PROVIDER=google`).
- A polyline of the route, refreshed when the tech moves >500 m, the
  destination changes (audit H6), or the result is older than 5 min
  regardless of movement (audit H7).
- A connection-quality strip computed against
  `SystemEventNotifier.serverNow()` (audit H8) so device-clock skew
  cannot falsely flip a fresh frame to "offline".
- A phone-call FAB resolving its target via
  `resolveLiveCallTarget(booking)` (audit H11 — tech dials customer;
  customer dials configured `AppConstants.supportPhoneNumber`).
- A staleness ticker that only `setState`s on a quality-band
  transition + an ETA tickdown that auto-cancels at zero or on
  `EN_ROUTE → ARRIVED` (audit H9 — both eliminated battery-drain
  unconditional 1 Hz / 5 s rebuild loops).

### `IDirectionsService` + concrete impls

`i_directions_service.dart` defines the route-fetch protocol:

```dart
abstract class IDirectionsService {
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  });
}
```

Concrete:
- `OsrmDirectionsService` — public OSRM by default
  (`router.project-osrm.org`, flag deferred for self-hosted).
- `GoogleDirectionsService` — Google Directions API.

Both wrap `package:http`, both `.timeout(Duration(seconds: 8))` per
call (audit H3), both throw a typed `DirectionsFailure` sealed family
(`DirectionsNetworkFailure`, `DirectionsServerFailure`,
`DirectionsNoRoute`, `DirectionsApiQuotaExceeded`,
`UnknownDirectionsFailure`).

### `LiveMarkerFactory`

Programmatic icon factory shared by both providers. `buildOsmMarker`
returns a `Widget`; `buildGoogleMarker` returns a cached
`BitmapDescriptor` painted to PNG bytes via Canvas. Identical visual
across providers — single source of truth for colours / icons / sizes.
`@visibleForTesting clearCache()` resets the descriptor cache between
tests.

### Provider config

`map_provider.dart` reads `--dart-define=MAP_PROVIDER` once at boot
(`AppConstants.mapProvider`, with OSM as the permissive fallback) and
exposes:

- `mapProviderTypeProvider` — `MapProviderType.osm | MapProviderType.google`.
- `appMapBuilderProvider` — a builder that constructs the right
  `IAppMap` for the selected provider.
- `directionsServiceProvider` — `OsrmDirectionsService` or
  `GoogleDirectionsService`.

Runtime flipping is intentionally not supported — would require a
widget-tree rebuild on every screen.

### Test coverage

| Surface | Coverage |
|---|---|
| `IAppMap` value classes (MapMarker / MapPolyline equality) | ✅ |
| `OsmAppMap` (renders TileLayer, MarkerLayer, PolylineLayer; resolves markers via factory) | ✅ |
| `GoogleAppMap` pure helpers + marker-resolution future-merge (audit H12) | ✅ via `GoogleAppMapInternals` |
| `GoogleAppMap` controller-dependent branches (programmatic-move flag, camera priority, mounted guard) | ⏳ deferred via flag #36 — needs an `IMapController` injection seam |
| `LiveTrackingMap` connection-quality, waiting pill, phone-FAB happy path | ✅ ~25% |
| `LiveTrackingMap` 13 dynamic branches (T-2a–T-2m: tween, hard-jump, cooldown, ETA tickdown lifecycle, recentre FAB, etc.) | ⏳ deferred via flag #36 — same `IMapController` seam |
| `OsrmDirectionsService` / `GoogleDirectionsService` happy path + each failure branch | ✅ |
| `LiveMarkerFactory` Widget build + BitmapDescriptor cache hit | ✅ |

---

## Legacy single-provider widgets

Pre-session-4 widgets, still used by the address-picker flow.

### `AppMap`

The foundation for all maps in the app. Use this directly for tracking or static previews.

```dart
AppMap(
  initialCenter: LatLng(33.6844, 73.0479), // Islamabad
  initialZoom: 15.0,
  children: [
    MarkerLayer(markers: [...]),
  ],
)
```

### `LocationPicker`

An "Uber-style" draggable map picker. The pin remains stationary at the screen center while the map pans underneath.

```dart
LocationPicker(
  initialCenter: currentLatLng,
  onLocationChanged: (LatLng newLocation) {
    // Fired when the user stops panning
    print("New location: ${newLocation.latitude}, ${newLocation.longitude}");
  },
  bottomCard: MyFeatureSpecificCard(),
  overlay: MyBackButton(),
  showCenterPin: true, // Default
  pin: Icon(Icons.location_pin), // Optional custom pin
)
```

### `AppMapStateViews`

Standardized UI for map-related async states.

- **`AppMapSkeleton`** — grey-themed skeleton showing a map
  placeholder and a bottom card handle. `bottomCardHeight` adjusts
  the skeleton height to match your feature's UI.
- **`AppMapErrorView`** — centered error card with an icon, message,
  and retry button.

### Testing strategy (legacy)

1. Widget tests verify that `AppMap` renders its `TileLayer` and that
   `LocationPicker` emits `onLocationChanged` when a `MapEventMoveEnd`
   is simulated.
2. Goldens (optional) — recommended for the fixed center pin alignment.
