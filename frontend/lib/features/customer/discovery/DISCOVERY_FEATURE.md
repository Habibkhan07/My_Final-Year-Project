# Customer Discovery Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
Allows the customer to find technicians based on category filtering or search queries. Includes pagination and location-aware constraints (geofencing and proximity sorting).

**Backend endpoints consumed:**
| Operation | Method | URL |
| :--- | :--- | :--- |
| Discover Technicians | `GET` | `/api/customers/discovery/` |

---

## UX & Location Handling
The Discovery feature relies on the user's active location to provide accurate matching and distance calculations:
- **Fallback Context**: The `DiscoveryNotifier` attempts to use explicitly provided `lat` and `lng` query parameters (e.g., from deep links).
- **Global Context**: If no explicit coordinates are provided, the `DiscoveryNotifier` watches `defaultAddressProvider.future` and injects its coordinates into the backend call.
- **Safety**: `HomeScreen` and `CategoryGrid` prevent navigating to `/discovery` entirely if a default address is not set, meaning the backend will almost always receive valid coordinates.

---

## Domain Layer

### Entities
`lib/features/customer/discovery/domain/entities/discovery_entities.dart`

#### `DiscoveryTechnicianEntity`
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Primary Key. |
| `fullName` | `String` | Display Name. |
| `primaryCategory` | `String` | Display Service Category. |
| `city` | `String` | Operation City. |
| `profilePicture` | `String?` | Absolute URL or null. |
| `ratingAverage` | `double` | Raw rating (0.0–5.0). |
| `reviewCount` | `int` | Number of ratings. |
| `distanceKm` | `double?` | Proximity from the customer (requires `lat`/`lng` query). |
| `bayesianScore` | `double?` | Calculated trust metric. |
| `isActive` | `bool` | Online/Offline status indicator. |
| `uiRatingText` | `String` | Formatted rating string. |
| `primaryPrice` | `String` | Formatted UI pricing tag. |
| `priceContext` | `String` | Display label (e.g., "per visit"). |
| `promoTag` | `String?` | Badge logic. |
| `uiSubtitleText` | `String?` | Dynamic secondary text. |

#### `DiscoveryResultEntity`
| Field | Type | Description |
| :--- | :--- | :--- |
| `count` | `int` | Total matches. |
| `next` | `String?` | Next page URL (for cursor pagination). |
| `previous` | `String?` | Previous page URL. |
| `uiPromoBannerText` | `String?` | List-header banner logic. |
| `results` | `List<DiscoveryTechnicianEntity>` | Current page payload. |
| `isPaginationLoading` | `bool` | Internal mutex for UI loading spinners. |

### Failures — `DiscoveryFailure` (sealed class)
`lib/features/customer/discovery/domain/failures/discovery_failure.dart`

| Class | Trigger |
| :--- | :--- |
| `DiscoveryNetworkFailure` | `SocketException` (No internet). |
| `DiscoveryServerFailure` | 5xx or unhandled code. |
| `DiscoveryParsingFailure` | `FormatException`. |

### Repository Interface
`lib/features/customer/discovery/domain/repositories/i_discovery_repository.dart`

| Method | Returns | Notes |
| :--- | :--- | :--- |
| `getNearbyTechnicians({...})` | `DiscoveryResultEntity` | Uses query params: `query`, `serviceId`, `subServiceId`, `promotionId`, `lat`, `lng`, `page`. |

---

## Data Layer

### Data Source
`lib/features/customer/discovery/data/data_sources/discovery_remote_data_source.dart`

Calls `GET /api/customers/discovery/`.

---

## Presentation Layer

### State & Notifiers
`lib/features/customer/discovery/presentation/providers/discovery_notifier.dart`

- **Type**: `@riverpod class DiscoveryNotifier extends _$DiscoveryNotifier`
- **`build()`**: First step. Resolves coordinates (explicit vs `defaultAddressProvider`), executes `getNearbyTechniciansUseCase`.
- **`refresh()`**: Manual pull-to-refresh. Overwrites state on success, preserves previous state on `AsyncError`.
- **`loadMore()`**: Infinite scrolling paginator. Appends the new page of results to the current list. Resets `isPaginationLoading` mutex on failure/success to prevent UI locks.

### Routing (Router)
`lib/core/routing/app_router.dart`

The `/discovery` route parses incoming URI query parameters (e.g., `?serviceId=2&title=AC+Repair`) and injects them into the `DiscoveryResultsScreen`.