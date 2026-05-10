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
| `LiveTrackingMap` connection-quality, waiting pill, phone-FAB happy path | ✅ |
| `LiveTrackingMap` 13 dynamic branches (T-2a–T-2m: tween, hard-jump, cooldown, ETA tickdown lifecycle, recentre FAB, etc.) | ✅ via `IUrlLauncher` port + recording stub `IAppMap` (audit H14) |
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

---

## Google Maps API key — production restrictions (audit S-9)

The Google Maps API key shipped via `--dart-define=GOOGLE_MAPS_API_KEY=...`
is embedded in the Android APK manifest as a `meta-data` entry; it is
**not a secret** in the cryptographic sense — anyone who can install
the APK can extract the key. Google's intended security model for Maps
keys is **server-side restrictions**, not key obscurity.

Before shipping a Google-flavoured production build, the deploying
operator MUST configure the following in the Google Cloud Console
(Maps Platform → Credentials → API key → Edit):

### 1. Application restriction — Android apps

Restrict the key to the production Android package + signing-key SHA-1
fingerprint pair so an attacker who extracts the key from a stolen APK
cannot reuse it from a different package or unsigned build:

- **Package name**: the value of `applicationId` in
  `frontend/android/app/build.gradle.kts` (e.g.
  `com.example.fyp_project`).
- **SHA-1 fingerprint**: the production signing key's fingerprint
  obtained via:
  ```bash
  keytool -list -v -keystore <release-keystore.jks> -alias <alias>
  ```
  Add **both** the release fingerprint AND the upload fingerprint
  (Google Play App Signing re-signs your APK on the Play Store, so
  the fingerprint observed by the Maps API at runtime is Google's
  upload-key fingerprint, NOT your own). The Play Console exposes
  both under **Setup → App integrity → App signing key certificate**
  and **Upload key certificate**.

For the OSM build (`MAP_PROVIDER=osm`, no API key needed) this
section does not apply — `OsrmDirectionsService` hits the public
OSRM demo instance (see flag #37) and `flutter_map` reads OSM tiles
directly without authentication.

### 2. API restriction — least privilege

Restrict the key to ONLY the APIs the app actually consumes:

- **Maps SDK for Android** (renders `GoogleAppMap` tiles).
- **Directions API** (consumed by `GoogleDirectionsService`).

Do NOT enable Geocoding API, Roads API, Places API, or any other
Maps Platform service unless this app starts using them. Each enabled
API on a leaked key is a separate billable surface for an attacker.

### 3. Quota + budget alerts

Set a hard daily quota slightly above expected production traffic
(e.g. expected DAU × 200 directions calls per booking) plus a budget
alert at 50% of monthly spend. A misconfigured app that retries
directions on every frame would otherwise burn the entire monthly
budget in hours.

### 4. Pre-flight check

Before submitting a Google-flavoured release to the Play Store:

1. Verify `GOOGLE_MAPS_API_KEY` is set in CI's secret store, NOT
   committed to the repo.
2. Verify the build command propagates it:
   `flutter build apk --release --dart-define=MAP_PROVIDER=google
   --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY`.
3. Verify the Console's API restrictions are saved (changes take
   ~5 min to propagate).
4. Verify `--dart-define=BASE_URL=https://...` and
   `--dart-define=BASE_WS_URL=wss://...` are set — the S-8 boot-time
   assertion will throw `StateError` on a cleartext release build.

### 5. What still needs a runtime fix

Even with all four steps above, the API key is observable by anyone
running mitmproxy against an Android emulator. The real defence is
the application-restriction signature check + the per-API quota — not
the key itself. Treat the key as a public identifier, not a secret.
