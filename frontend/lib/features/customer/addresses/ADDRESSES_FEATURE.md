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
| `streetAddress` | `String` | Human-readable address string. |
| `latitude` | `double` | WGS-84 latitude. Used by the booking geofence check. |
| `longitude` | `double` | WGS-84 longitude. |
| `isDefault` | `bool` | Source of truth for which address pre-fills on booking. **Never compute locally** — always read from backend. |
| `createdAt` | `String` | ISO 8601 creation timestamp (display only). |

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
| `saveAddress({label, streetAddress, latitude, longitude, isDefault})` | `CustomerAddressEntity` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure` |
| `updateAddress({id, label, streetAddress, latitude, longitude, isDefault})` | `CustomerAddressEntity` | `AddressNetworkFailure`, `AddressServerFailure`, `AddressParsingFailure`, `AddressNotFoundFailure` |
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
| `UpdateAddressUseCase` | `repository.updateAddress(...)` |
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
- `toEntity()` produces the clean `CustomerAddressEntity` — the only conversion point.

**`CreateAddressRequest`** — outgoing POST body.
- `toJson()` maps Dart camelCase back to backend snake_case.
- **Precision Guard**: formats `latitude` and `longitude` to 6 decimal places via `toStringAsFixed(6)` to satisfy backend `DecimalField` constraints.

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
- Uses `geocoding` (`placemarkFromCoordinates`) for reverse geocoding to a street string.
- `reverseGeocode(lat, lng)` is the public entry-point used by `MapPickerNotifier`.
- **Empty Guard**: If geocoding returns an empty/null assembled address string, it falls back to raw `"lat, lng"` coordinates to ensure `street_address` is never blank.
- Throws `LocationServiceDisabledException` / `PermissionDeniedException` (geolocator types) — the repository maps these to domain failures.

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

---

## Dependency Injection
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

Wiring order:
```
addressHttpClient / addressSecureStorage
    ↓
addressRemoteDataSource / addressLocalDataSource / addressLocationDataSource
    ↓
addressRepository
    ↓
getAddressesUseCase / saveAddressUseCase / updateAddressUseCase
deleteAddressUseCase / getCurrentLocationUseCase / reverseGeocodeUseCase
    ↓
addressesProvider       ← list fetch
defaultAddressProvider  ← derived filter
mapPickerProvider       ← AsyncNotifier
```
