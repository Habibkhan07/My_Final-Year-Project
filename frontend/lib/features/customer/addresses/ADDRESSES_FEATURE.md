# Customer Addresses Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
Manages a customer's saved addresses. Addresses are used as the job location in the instant booking flow. The backend enforces ownership scoping (IDOR-safe) and atomically manages the default address flag.

**Backend endpoints consumed:**
| Operation | Method | URL |
| :--- | :--- | :--- |
| List addresses | `GET` | `/api/customers/addresses/` |
| Save address | `POST` | `/api/customers/addresses/` |
| Delete address | `DELETE` | `/api/customers/addresses/{id}/` |

---

## Domain Layer

### Entity — `CustomerAddressEntity`
`lib/features/customer/addresses/domain/entities/address_entity.dart`

Freezed immutable. Fed by `GET /api/customers/addresses/` (list items) and `POST /api/customers/addresses/` (creation response).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Backend primary key. Used as the `address_id` in `POST /api/bookings/instant-book/`. |
| `label` | `String` | User-facing name (e.g. "Home", "Office"). |
| `streetAddress` | `String` | Human-readable address string. |
| `latitude` | `double` | WGS-84 latitude. Used by the booking geofence check. |
| `longitude` | `double` | WGS-84 longitude. |
| `isDefault` | `bool` | Source of truth for which address pre-fills on booking. **Never compute locally** — always read from backend. |
| `createdAt` | `String` | ISO 8601 creation timestamp (display only). |

---

### Failures — `AddressFailure` (sealed class)
`lib/features/customer/addresses/domain/failures/address_failure.dart`

All repository methods throw a subclass of `AddressFailure`. The presentation layer switches exhaustively on these.

| Class | Trigger |
| :--- | :--- |
| `AddressNetworkFailure` | `SocketException` + local cache empty |
| `AddressServerFailure` | Non-2xx HTTP response |
| `AddressParsingFailure` | `FormatException` on JSON decode |
| `AddressNotFoundFailure` | 404 on DELETE (IDOR-safe: same response whether missing or owned by another user) |
| `AddressLocationPermissionDenied` | User denied GPS permission |
| `AddressLocationServiceDisabled` | Device GPS is turned off |

---

### Repository Interface — `IAddressRepository`
`lib/features/customer/addresses/domain/repositories/i_address_repository.dart`

| Method | Returns | Throws |
| :--- | :--- | :--- |
| `getAddresses()` | `List<CustomerAddressEntity>` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure` |
| `saveAddress({label, streetAddress, latitude, longitude, isDefault})` | `CustomerAddressEntity` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure` |
| `deleteAddress(int id)` | `void` | `AddressNotFoundFailure`, `AddressNetworkFailure`, `AddressServerFailure` |
| `getCurrentLocation()` | `({double latitude, double longitude, String streetAddress})` | `AddressLocationPermissionDenied`, `AddressLocationServiceDisabled` |
| `reverseGeocode(double lat, double lng)` | `String` | never throws — falls back to `"lat, lng"` string on geocoding failure |

`getCurrentLocation()` returns a named record so the save-address form can pre-fill all three GPS fields in a single call.

`reverseGeocode()` is used by `MapPickerNotifier` to resolve arbitrary map-pin coordinates to a human-readable string. Failures are silently swallowed and replaced with the raw coordinate string so the Confirm button is never blocked.

---

### Use Cases
`lib/features/customer/addresses/domain/use_cases/`

All are thin delegates — they add no logic, they exist to keep the presentation layer decoupled from the repository interface.

| Use Case | Delegates to |
| :--- | :--- |
| `GetAddressesUseCase` | `repository.getAddresses()` |
| `SaveAddressUseCase` | `repository.saveAddress(...)` |
| `DeleteAddressUseCase` | `repository.deleteAddress(id)` |
| `GetCurrentLocationUseCase` | `repository.getCurrentLocation()` |
| `ReverseGeocodeUseCase` | `repository.reverseGeocode(lat, lng)` |

---

## Data Layer

### Models
`lib/features/customer/addresses/data/models/address_model.dart`

**`CustomerAddressModel`** — JSON ↔ Dart mapping for list and creation responses.
- `fromJson()` handles backend snake_case keys (`street_address`, `is_default`, `created_at`).
- `_parseDouble()` helper safely coerces backend decimal strings or nums to Dart `double` (backend sends coordinates as strings).
- `toJson()` used by `AddressLocalDataSource` for `SharedPreferences` cache serialization.
- `toEntity()` produces the clean `CustomerAddressEntity` — the only conversion point.

**`CreateAddressRequest`** — outgoing POST body.
- `toJson()` maps Dart camelCase back to backend snake_case.
- Never used for reading; exists only as a typed POST body builder.

---

### Data Sources

#### `AddressRemoteDataSource`
`lib/features/customer/addresses/data/data_sources/address_remote_data_source.dart`

| Method | HTTP | Notes |
| :--- | :--- | :--- |
| `getAddresses()` | `GET /api/customers/addresses/` | Auth token from `flutter_secure_storage` |
| `saveAddress(CreateAddressRequest)` | `POST /api/customers/addresses/` | Auth token + `Content-Type: application/json` |
| `deleteAddress(int id)` | `DELETE /api/customers/addresses/{id}/` | Auth token |

Non-2xx responses are parsed into `HttpFailure(statusCode, code, message, errors)` and re-thrown. The `code` field from the standard error envelope drives failure mapping in the repository.

#### `AddressLocalDataSource`
`lib/features/customer/addresses/data/data_sources/address_local_data_source.dart`

- Backed by `SharedPreferences` (Tier 2 cache — see `CLAUDE.md`).
- `cacheAddresses(List<CustomerAddressModel>)` — serializes to JSON string, stored under `"cached_addresses"`.
- `getCachedAddresses()` — returns `null` on empty or corrupted cache (never throws). The repository treats `null` as cache-miss and throws `AddressNetworkFailure`.

#### `AddressLocationDataSource`
`lib/features/customer/addresses/data/data_sources/address_location_data_source.dart`

- Uses `geolocator` for device GPS (`LocationAccuracy.high`).
- Uses `geocoding` (`placemarkFromCoordinates`) for reverse geocoding to a street string.
- `reverseGeocode(lat, lng)` is the public entry-point used by `MapPickerNotifier` after every completed map pan. Internally delegates to `_reverseGeocode`.
- Reverse geocode failure falls back to raw `"lat, lng"` string — the address is still usable for the booking geofence; display quality degrades gracefully.
- Throws `LocationServiceDisabledException` / `PermissionDeniedException` (geolocator types) — the repository maps these to domain failures.

---

### Repository Implementation — `AddressRepositoryImpl`
`lib/features/customer/addresses/data/repositories/address_repository_impl.dart`

The single arbitration point between all three data sources and the domain.

#### `getAddresses()` — Offline-First
```
remote.getAddresses()
  ✓ success → cache locally → return entities
  ✗ SocketException → getCachedAddresses()
      ✓ cache hit  → return entities
      ✗ cache miss → throw AddressNetworkFailure
  ✗ HttpFailure    → throw AddressServerFailure
  ✗ FormatException → throw AddressParsingFailure
```

#### `saveAddress(...)` — Remote only (no cache write — list refresh handles it)
```
remote.saveAddress(request)
  ✓ success         → return entity
  ✗ SocketException → throw AddressNetworkFailure
  ✗ HttpFailure     → throw AddressServerFailure
  ✗ FormatException → throw AddressParsingFailure
```

#### `deleteAddress(id)`
```
remote.deleteAddress(id)
  ✓ 204 No Content  → void
  ✗ HttpFailure 404 → throw AddressNotFoundFailure  ← specific mapping
  ✗ HttpFailure other → throw AddressServerFailure
  ✗ SocketException → throw AddressNetworkFailure
```

#### `getCurrentLocation()`
```
locationDataSource.getCurrentLocation()
  ✓ success → return named record (lat, lng, streetAddress)
  ✗ LocationServiceDisabledException → throw AddressLocationServiceDisabled
  ✗ PermissionDeniedException       → throw AddressLocationPermissionDenied
  ✗ other                           → throw AddressServerFailure
```

#### `reverseGeocode(lat, lng)` — delegates directly, never throws
```
locationDataSource.reverseGeocode(lat, lng)
  ✓ success → return street string
  ✗ any failure → return "lat, lng" fallback (handled inside data source)
```

---

## Presentation Layer

### Providers

#### `addressesProvider`
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Auto-dispose `@riverpod` `FutureProvider`. Calls `GetAddressesUseCase` on every subscription. Consumed by `AddressSelectorSheet` and `MapPickerNotifier`.

#### `defaultAddressProvider`
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Derived `@riverpod` provider that watches `addressesProvider` and returns the single address where `isDefault == true`, or `null`. Consumed by `_LocationHeader` in `HomeScreen`.

#### `MapPickerState` — `@freezed`
`lib/features/customer/addresses/presentation/providers/map_picker_state.dart`

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `latitude` | `double` | required | Current map-pin latitude |
| `longitude` | `double` | required | Current map-pin longitude |
| `streetAddress` | `String` | required | Reverse-geocoded string for current pin |
| `isGeocoding` | `bool` | `false` | True while a reverse-geocode is in flight |
| `selectedLabel` | `String` | `'Home'` | Active label chip value |
| `saveState` | `AsyncValue<CustomerAddressEntity?>` | `AsyncData(null)` | Tracks the save operation without affecting map state |

#### `MapPickerNotifier` — `AsyncNotifier<MapPickerState>`
`lib/features/customer/addresses/presentation/providers/map_picker_notifier.dart`

| Method | Behaviour |
| :--- | :--- |
| `build()` | Calls `GetCurrentLocationUseCase`; whole screen shows skeleton until GPS resolves. Enters `AsyncError` on permission/service failure. |
| `onMapPanEnd(lat, lng)` | Immediately updates coords + `isGeocoding=true`; schedules debounced (600 ms) reverse-geocode via `Timer`. On completion sets `streetAddress` + `isGeocoding=false`. |
| `setLabel(label)` | Synchronous `copyWith` on `selectedLabel`. |
| `save({isDefault})` | Sets `saveState=AsyncLoading`, calls `SaveAddressUseCase`, sets `saveState=AsyncData(entity)` or `AsyncError`. Map state (coords, label) is preserved on failure. |

The `Timer?` debounce field is cancelled via `ref.onDispose` so no callbacks fire after the notifier is disposed.

---

### Widgets

#### `AddressSelectorSheet`
`lib/features/customer/addresses/presentation/widgets/address_selector_sheet.dart`

Bottom sheet. Watches `addressesProvider`.

**Visual permutations:**
- `loading` → centred `CircularProgressIndicator`
- `error` → grey text `'Could not load addresses.'`
- `data([])` → grey text `'No saved addresses yet.'`
- `data([...])` → `ListView` of `_AddressTile` widgets (label + streetAddress; default address gets a blue "Default" badge)
- Footer (all states) → full-width "Add New Address" `ElevatedButton` → `context.push('/addresses/map-picker')`

#### `MapPickerScreen`
`lib/features/customer/addresses/presentation/screens/map_picker_screen.dart`

Uber-style draggable map picker. Uses `flutter_map` (OpenStreetMap tiles — no API key).

**Visual permutations:**
- `AsyncLoading` (GPS fetch) → `_MapSkeleton` — grey placeholder boxes
- `AsyncError` (GPS permission/service) → `_ErrorCard` — `Icons.location_off` + error message + Retry button (calls `ref.invalidate(mapPickerProvider)`)
- `AsyncData(state)` → `_MapBody`:
  - Full-screen `FlutterMap`; panning fires `onMapPanEnd`
  - Fixed `Icons.location_pin` at `Alignment.center` (pin never moves)
  - Back arrow at top-left
  - `_BottomCard` at bottom:
    - Address text (or inline `CircularProgressIndicator` when `isGeocoding`)
    - Animated label chips: Home / Office / Other
    - `ElevatedButton('Confirm Location')` — calls `save(isDefault: false)`; shows spinner while `saveState=AsyncLoading`; renders error message below button on `saveState=AsyncError`

**Success flow**: `ref.listen` watches `saveState`. On `AsyncData(entity ≠ null)`, invalidates `addressesProvider` (so selector sheet refreshes) then calls `context.pop()`.

**Route**: `/addresses/map-picker` in `app_router.dart`.

---

## Error Propagation Pipeline

```
AddressRemoteDataSource / AddressLocationDataSource
  throws HttpFailure(code, message) or geolocator exceptions
      ↓
AddressRepositoryImpl (_mapFailures pattern)
  switch on exception type → throws specific AddressFailure subclass
      ↓
[Use Case — transparent passthrough]
      ↓
MapPickerNotifier
  build()    → AsyncValue.guard() → AsyncError if GPS fails
  save()     → AsyncValue.guard() → saveState=AsyncError on failure
      ↓
MapPickerScreen
  when(loading/error/data) → _MapSkeleton / _ErrorCard / _MapBody
  _BottomCard: saveState error message below Confirm button
```

---

## Dependency Injection
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

All infrastructure providers are `keepAlive: true`. Feature providers are auto-dispose. Wiring order:

```
addressHttpClient / addressSecureStorage
    ↓
addressRemoteDataSource (http client + secure storage)
addressLocalDataSource  (SharedPreferences — from technician onboarding DI)
addressLocationDataSource
    ↓
addressRepository (all three data sources)
    ↓
getAddressesUseCase / saveAddressUseCase / deleteAddressUseCase
getCurrentLocationUseCase / reverseGeocodeUseCase
    ↓
addressesProvider       ← list fetch; consumed by AddressSelectorSheet + MapPickerNotifier
defaultAddressProvider  ← derived filter; consumed by HomeScreen _LocationHeader
mapPickerProvider       ← AsyncNotifier; consumed by MapPickerScreen
```
