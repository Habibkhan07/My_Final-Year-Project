# Core Map Widgets

A collection of reusable map components built on top of `flutter_map` and OpenStreetMap.

## Architecture

To ensure the "Dumb UI" principle and reusability, map functionality is split into three layers:
1. **`AppMap`**: The base infrastructure. Handles tiles, user agents, and default configuration.
2. **`LocationPicker`**: A high-level interactive component for selecting coordinates via a fixed center pin.
3. **`AppMapStateViews`**: Standardized loading skeletons and error views for map screens.

---

## `AppMap`

The foundation for all maps in the app. Use this directly for tracking or static previews.

### Usage
```dart
AppMap(
  initialCenter: LatLng(33.6844, 73.0479), // Islamabad
  initialZoom: 15.0,
  children: [
    MarkerLayer(markers: [...]),
  ],
)
```

---

## `LocationPicker`

An "Uber-style" draggable map picker. The pin remains stationary at the screen center while the map pans underneath.

### Usage
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

---

## `AppMapStateViews`

Standardized UI for map-related async states.

### `AppMapSkeleton`
A grey-themed skeleton showing a map placeholder and a bottom card handle.
* **`bottomCardHeight`**: Adjusts the height of the skeleton bottom card to match your feature's UI.

### `AppMapErrorView`
A centered error card with an icon, message, and retry button.

---

## Testing Strategy

1. **Widget Tests**: Verify that `AppMap` renders its `TileLayer` and that `LocationPicker` emits `onLocationChanged` when a `MapEventMoveEnd` is simulated.
2. **Goldens**: (Optional) Recommended for the fixed center pin alignment.
