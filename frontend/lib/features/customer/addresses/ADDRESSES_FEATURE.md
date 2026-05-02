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
| Update address | `PATCH` | `/api/customers/addresses/{id}/` |
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
| `streetAddress` | `String` | Geocoder's `formatted_address` (display string). |
| `latitude` | `double` | WGS-84 latitude. **Trusted source for distance/matchmaking.** |
| `longitude` | `double` | WGS-84 longitude. **Trusted source for distance/matchmaking.** |
| `isDefault` | `bool` | Source of truth for which address pre-fills on booking. **Never compute locally** — always read from backend. |
| `createdAt` | `String` | ISO 8601 creation timestamp (display only). |
| `neighborhood` | `String?` | Reverse-geocoded structured field (display-only). |
| `suburb` | `String?` | Reverse-geocoded structured field. Wins over `neighborhood` in `localityLabel`. |
| `city` | `String?` | Reverse-geocoded structured field. |
| `state` | `String?` | Reverse-geocoded structured field. |
| `country` | `String?` | ISO-3166 alpha-2 (e.g. `"PK"`). |
| `postalCode` | `String?` | Reverse-geocoded structured field. |
| `localityLabel` | `String?` | Composed display label, e.g. `"Gulshan-e-Iqbal, Karachi"`. |

**Trust boundary**: the 7 nullable structured fields are produced client-side by the configured `GeocodingDataSource` and POSTed to the backend, which stores them verbatim. `latitude`/`longitude` remain the trusted source for distance/matchmaking. See `flag.md #15` for the rationale and the proper-fix path if abuse appears.

**Legacy rows**: addresses created before this rollout have `null` for all 7 structured fields. UI must fall back to `streetAddress` when `localityLabel` is null.

---

### Failures — `AddressFailure` (sealed class)
`lib/features/customer/addresses/domain/failures/address_failure.dart`

All repository methods throw a subclass of `AddressFailure`. The presentation layer switches exhaustively on these. `toString()` is overridden to return only the `message`.

| Class | Trigger |
| :--- | :--- |
| `AddressNetworkFailure` | `SocketException` + local cache empty |
| `AddressServerFailure` | Non-2xx HTTP response (includes field validation details) |
| `AddressParsingFailure` | `FormatException` on JSON decode |
| `AddressNotFoundFailure` | 404 on DELETE/PATCH (IDOR-safe: same response whether missing or owned by another user) |
| `AddressLocationPermissionDenied` | User denied GPS permission |
| `AddressLocationServiceDisabled` | Device GPS is turned off |

---

### Repository Interface — `IAddressRepository`
`lib/features/customer/addresses/domain/repositories/i_address_repository.dart`

| Method | Returns | Throws |
| :--- | :--- | :--- |
| `getAddresses()` | `List<CustomerAddressEntity>` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure` |
| `saveAddress({label, streetAddress, latitude, longitude, isDefault, neighborhood?, suburb?, city?, state?, country?, postalCode?, localityLabel?})` | `CustomerAddressEntity` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure` |
| `updateAddress({id, label?, streetAddress?, latitude?, longitude?, isDefault?, neighborhood?, suburb?, city?, state?, country?, postalCode?, localityLabel?})` | `CustomerAddressEntity` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure`, `AddressNotFoundFailure` |
| `deleteAddress(int id)` | `void` | `AddressNotFoundFailure`, `AddressNetworkFailure`, `AddressServerFailure` |
| `getCurrentLocation()` | `PlaceDetails` | `AddressLocationPermissionDenied`, `AddressLocationServiceDisabled` |
| `reverseGeocode(double lat, double lng)` | `PlaceDetails` | never throws — falls back to a coord-only `PlaceDetails` on failure |
| `searchPlaces(String query, String sessionToken)` | `List<PlaceSearchEntity>` | `AddressNetworkFailure`, `AddressServerFailure` |
| `getPlaceDetails(String placeId, String sessionToken)` | `PlaceDetails` | `AddressNetworkFailure`, `AddressServerFailure` |

`getCurrentLocation()` and `reverseGeocode()` both return `PlaceDetails` — a Freezed model carrying `formattedAddress`, `latitude`, `longitude`, and the 7 nullable structured fields. The save-address form forwards the structured fields untouched to the backend on `saveAddress(...)`.

`reverseGeocode()` is used by `MapPickerNotifier` after every map-pan gesture. Failures are silently swallowed and replaced with a coord-only `PlaceDetails` so the Confirm button is never blocked.

---

### Use Cases
`lib/features/customer/addresses/domain/use_cases/`

All are thin delegates — they add no logic, they exist to keep the presentation layer decoupled from the repository interface.

| Use Case | Delegates to |
| :--- | :--- |
| `GetAddressesUseCase` | `repository.getAddresses()` |
| `SaveAddressUseCase` | `repository.saveAddress(...)` |
| `UpdateAddressUseCase` | `repository.updateAddress(...)` |
| `DeleteAddressUseCase` | `repository.deleteAddress(id)` |
| `GetCurrentLocationUseCase` | `repository.getCurrentLocation()` |
| `ReverseGeocodeUseCase` | `repository.reverseGeocode(lat, lng)` |

---

## Data Layer

### Models
`lib/features/customer/addresses/data/models/address_model.dart` and `place_details.dart`

**`CustomerAddressModel`** — JSON ↔ Dart mapping for list and creation responses.
- `fromJson()` handles backend snake_case keys (`street_address`, `is_default`, `created_at`, plus the 7 structured fields).
- `_parseDouble()` helper safely coerces backend decimal strings or nums to Dart `double` (backend sends coordinates as strings).
- `toEntity()` produces the clean `CustomerAddressEntity` — the only conversion point.

**`CreateAddressRequest`** — outgoing POST body.
- `toJson()` maps Dart camelCase back to backend snake_case (including all 7 structured fields, sent as null when absent).
- **Precision Guard**: formats `latitude` and `longitude` to 6 decimal places via `toStringAsFixed(6)` to satisfy backend `DecimalField` constraints.

**`PlaceDetails`** — Freezed model returned by every `GeocodingDataSource` call.
- Carries `formattedAddress`, `latitude`, `longitude`, plus the 7 nullable structured fields.
- `localityLabel` getter is the **single source of truth** for the compose rule (`suburb || neighborhood, city`). If product wants a different rule, change it here only — the backend caches whatever the client sends.

---

### Data Sources

#### `AddressRemoteDataSource`
`lib/features/customer/addresses/data/data_sources/address_remote_data_source.dart`

| Method | HTTP | Notes |
| :--- | :--- | :--- |
| `getAddresses()` | `GET /api/customers/addresses/` | Auth token from `flutter_secure_storage` |
| `saveAddress(CreateAddressRequest)` | `POST /api/customers/addresses/` | Auth token + `Content-Type: application/json` |
| `updateAddress(int id, Map data)` | `PATCH /api/customers/addresses/{id}/` | Partial update support |
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
- Uses `geocoding` (`placemarkFromCoordinates`) for reverse geocoding via the **platform-native** geocoder (Apple/Android), which works offline using cached map data.
- Returns a `PlaceDetails` populated with structured fields extracted from the native `Placemark` (`subLocality`, `locality`, `administrativeArea`, `isoCountryCode`, `postalCode`).
- **Empty Guard**: If geocoding returns nothing, falls back to a coord-only `PlaceDetails`.
- Throws `LocationServiceDisabledException` / `PermissionDeniedException` (geolocator types) — the repository maps these to domain failures.

#### `GeocodingDataSource` (port) + adapters
`lib/features/customer/addresses/data/data_sources/geocoding_data_source.dart`

Abstract port for the HTTP-based geocoder used by the map-picker drag and the search flow. Two adapters live behind it:

| Adapter | Used when | Notes |
| :--- | :--- | :--- |
| `GoogleMapsGeocodingDataSource` | `--dart-define=GOOGLE_MAPS_API_KEY=<key>` is set | Production. Parses Google's `address_components` array into the 7 structured fields. Pakistan-relevant type mapping: `locality`→city, `sublocality_level_1`→suburb, `administrative_area_level_1`→state. |
| `NominatimGeocodingDataSource` | dart-define omitted | Dev only. OSM Nominatim — usage policy forbids prod-scale traffic. See `flag.md #16`. |

The factory in `dependency_injection.dart::geocodingDataSource(Ref ref)` selects the adapter at build time. **Switching to Google in prod is a one-line dart-define change** — no code edit.

---

### Repository Implementation — `AddressRepositoryImpl`
`lib/features/customer/addresses/data/repositories/address_repository_impl.dart`

The single arbitration point between all three data sources and the domain.

#### `saveAddress(...)` / `updateAddress(...)` — Error Propagation
In addition to general HTTP failures, the repository extracts field-specific error messages (e.g., `street_address: This field is required`) and embeds them in the `AddressServerFailure` for direct UI feedback.

---

## Presentation Layer

### Providers

#### `addressesProvider`
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Auto-dispose `@riverpod` `FutureProvider`. Calls `GetAddressesUseCase` on every subscription. Consumed by `AddressSelectorSheet` and `MapPickerNotifier`.

#### `defaultAddressProvider`
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Derived `@riverpod` provider that watches `addressesProvider` and returns the single address where `isDefault == true`, or `null`. Consumed by `_LocationHeader` in `HomeScreen`.

#### `mapPickerProvider` — `AsyncNotifier<MapPickerState>`
`lib/features/customer/addresses/presentation/providers/map_picker_notifier.dart`

Handles map state and location saving. GPS skeleton shown until `build()` resolves. `save()` invalidates `addressesProvider` on success.

#### `locationSearchProvider`
`lib/features/customer/addresses/presentation/providers/location_search_notifier.dart`

Handles the Google Places API search functionality. Manages a debounce timer, session tokens, and the list of `PlaceSearchEntity` results. Consumed by `_SearchOverlay` inside `MapPickerScreen`.

---

### Widgets

#### `AddressSelectorSheet`
`lib/features/customer/addresses/presentation/widgets/address_selector_sheet.dart`

Bottom sheet displaying the list of saved addresses.
- **Visual Logic**:
  - **Icons**: Home icon for "Home", Work icon for "Office", Location icon for others.
  - **Highlights**: The default address gets a blue background (`#F0F6FF`) and a solid blue icon/radio button.
  - **Selection**: Uses a trailing `Radio<bool>` button to indicate the active location.
- **Interaction**: Tapping any `_AddressTile` (that isn't already default) calls `UpdateAddressUseCase(isDefault: true)`.
- **Intent**: 
  - On successful update, it invalidates `addressesProvider` to refresh the Home Screen header.
  - It then calls `Navigator.pop(context)` to automatically return the user to the Home Screen once their selection is confirmed.
- **Error**: Shows a `SnackBar` with the server error message if the update fails.

#### `MapPickerScreen`
`lib/features/customer/addresses/presentation/screens/map_picker_screen.dart`

Uber-style map picker.
- **UI Guard**: The "Confirm Location" button is disabled if `isGeocoding` is true or `saveState` is loading, preventing stale/empty submissions during drags or network flight.
- **_SearchOverlay**: Top overlay containing a `TextField` for searching locations. Displays a dropdown of autocomplete results. Selecting a result fetches details and moves the map camera.

---

## Dependency Injection
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Wiring order:
```
addressHttpClient / addressSecureStorage
    ↓
addressRemoteDataSource / addressLocalDataSource / addressLocationDataSource
    ↓
geocodingDataSource          ← factory: Google (key set) | Nominatim (dev)
    ↓
addressRepository
    ↓
getAddressesUseCase / saveAddressUseCase / updateAddressUseCase
deleteAddressUseCase / getCurrentLocationUseCase / reverseGeocodeUseCase
searchPlacesUseCase / getPlaceDetailsUseCase
    ↓
addressesProvider       ← list fetch
defaultAddressProvider  ← derived filter
mapPickerProvider       ← AsyncNotifier
locationSearchProvider  ← search overlay state
```

### Production swap
- Dev: `flutter run` (no key) → OSM Nominatim, no setup friction.
- Prod: `flutter build ... --dart-define=GOOGLE_MAPS_API_KEY=<key>` → Google Maps Platform.
- See `flag.md #16` for the silent-fallback footgun that should be hardened before first prod build.
