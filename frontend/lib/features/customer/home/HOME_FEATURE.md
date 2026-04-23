# Customer Home Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
The primary landing screen for Customers. Displays dynamic, location-aware content including service categories, promotional banners, fixed-price gigs, and top-rated technicians nearby.

**Backend endpoints consumed:**
| Operation | Method | URL |
| :--- | :--- | :--- |
| Fetch Home Feed | `GET` | `/api/customers/home-feed/` |

---

## UX & Location Gating (Progressive Disclosure)
The Home feature implements a "Progressive Disclosure" UX pattern for location handling:
- **Global Context**: `HomeNotifier` automatically watches the `defaultAddressProvider` (from the Addresses feature).
- **Silent Fetch**: If a default address exists, its `lat` and `lng` are silently appended to the backend request to fetch location-specific technicians and promotions.
- **Empty State Guard**: If no default address is set, the static content (categories, banners) still loads to build user intent. However, the `TechnicianCarousel` is replaced by a `LocationRequiredCard` that prompts the user to set their location.
- **Navigation Intercept**: Tapping any service category in the `CategoryGrid` without a set location halts navigation and slides up the `AddressSelectorSheet` instead.

---

## Domain Layer

### Entities
`lib/features/customer/home/domain/entities/home_feed_entity.dart`

All entities are Freezed immutable.

#### `HomeFeedEntity`
| Field | Type | Description |
| :--- | :--- | :--- |
| `categories` | `List<CategoryEntity>` | Grid of available services (e.g., AC Repair, Plumbing). |
| `promotions` | `List<PromotionEntity>` | Hero banners for active discounts. |
| `fixedGigs` | `List<FixedGigEntity>` | Standardized jobs with flat rates (e.g., "1 Ton AC Gas Refill"). |
| `topTechnicians` | `List<TechnicianEntity>` | Nearby highly-rated professionals (requires `lat`/`lng`). |

### Failures — `HomeFailure` (sealed class)
`lib/features/customer/home/domain/failures/home_failure.dart`

| Class | Trigger |
| :--- | :--- |
| `HomeNetworkFailure` | `SocketException` (No internet connection). |
| `HomeServerFailure` | 5xx or unhandled backend error. |
| `HomeParsingFailure` | `FormatException` (Contract mismatch between Dart and JSON). |

### Repository Interface
`lib/features/customer/home/domain/repositories/i_home_repository.dart`

| Method | Returns | Notes |
| :--- | :--- | :--- |
| `getHomeFeed({double? lat, double? lng})` | `HomeFeedEntity` | `lat`/`lng` are optional but required to populate `topTechnicians`. |

---

## Data Layer

### Data Source
`lib/features/customer/home/data/data_sources/home_remote_data_source.dart`

Standard `HttpFailure` propagation. No `LocalDataSource` currently (Tier 2 offline caching is handled at the presentation layer via `AsyncValue` caching and Riverpod state preservation).

---

## Presentation Layer

### State & Notifiers
`lib/features/customer/home/presentation/providers/home_notifier.dart`

- **Type**: `@riverpod class HomeNotifier extends _$HomeNotifier`
- **`build()`**: Watches `defaultAddressProvider.future`. Fetches the initial feed, appending `lat`/`lng` if a default address exists.
- **`fetchHomeFeed()`**: Refreshes the feed manually (e.g., via pull-to-refresh or retry).

### Key Widgets
- **`HomeScreen`**: The main scaffold. Evaluates the `defaultAddressAsync` state to conditionally render the `LocationRequiredCard` instead of the `TechnicianCarousel`.
- **`CategoryGrid`**: Displays the `CategoryEntity` list. Intercepts taps to show the `AddressSelectorSheet` if `defaultAddressProvider` yields `null`.
- **`LocationRequiredCard`**: A Call-To-Action empty state that prompts new users to add an address before exploring location-based content.