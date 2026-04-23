# Customer Addresses Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ⏳ (pending)

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

`getCurrentLocation()` returns a named record so the save-address form can pre-fill all three GPS fields in a single call.

---

### Use Cases
`lib/features/customer/addresses/domain/use_cases/`

All four are thin delegates — they add no logic, they exist to keep the presentation layer decoupled from the repository interface.

| Use Case | Delegates to |
| :--- | :--- |
| `GetAddressesUseCase` | `repository.getAddresses()` |
| `SaveAddressUseCase` | `repository.saveAddress(...)` |
| `DeleteAddressUseCase` | `repository.deleteAddress(id)` |
| `GetCurrentLocationUseCase` | `repository.getCurrentLocation()` |

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
Notifier (presentation — pending)
  AsyncValue.guard() catches AddressFailure
      ↓
UI (presentation — pending)
  switch (failure) { ... } → Snackbar / form highlight
```

---

## Dependency Injection
`lib/features/customer/addresses/presentation/providers/dependency_injection.dart`

All providers are `keepAlive: true`. Wiring order:

```
addressHttpClient / addressSecureStorage
    ↓
addressRemoteDataSource (http client + secure storage)
addressLocalDataSource  (SharedPreferences — from technician onboarding DI)
addressLocationDataSource
    ↓
addressRepository (all three data sources)
    ↓
getAddressesUseCase / saveAddressUseCase / deleteAddressUseCase / getCurrentLocationUseCase
    ↓
addresses  ← convenience @riverpod fetch provider consumed by SelectTimeSheet
```
