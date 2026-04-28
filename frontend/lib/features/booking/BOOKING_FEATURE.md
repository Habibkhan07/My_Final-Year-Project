# Booking Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
Covers the full customer-side instant booking flow: viewing a technician's profile, browsing available time slots, and confirming a booking. Cash-only payment — no checkout UI. The backend enforces all business rules (geofence, slot race condition, address ownership).

**Backend endpoints consumed:**
| Operation | Method | URL |
| :--- | :--- | :--- |
| Technician profile | `GET` | `/api/customers/technician-profile/{id}/` |
| Available slots | `GET` | `/api/customers/technicians/{id}/availability/` |
| Instant book | `POST` | `/api/bookings/instant-book/` |

Full backend contracts: `backend/bookings/api/BOOKINGS_API.md`

---

## Domain Layer

### Entities
`lib/features/booking/domain/entities/booking_entities.dart`

All entities are Freezed immutable.

#### `TechnicianSkillEntity`
| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | `String` | Display name of the skill/sub-service. |
| `iconName` | `String?` | Nullable key mapping to `assets/icons/{iconName}.svg` via `IconAssets.path()`. Null when `SubService.icon_name` is unset in Django Admin. |

#### `TechnicianReviewEntity`
| Field | Type | Description |
| :--- | :--- | :--- |
| `reviewerName` | `String` | Display name of the reviewer. |
| `rating` | `int` | 1–5 star rating. |
| `text` | `String` | Review body. |

#### `TechnicianProfileEntity`
Fed by `GET /api/customers/technician-profile/{id}/`.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | `TechnicianProfile` pk — passed to all subsequent booking calls. |
| `fullName` | `String` | Display name. |
| `city` | `String` | City of operation. |
| `profilePicture` | `String?` | Absolute URL or null. |
| `ratingAverage` | `double` | Raw rating (0.0–5.0). |
| `reviewCount` | `int` | Total review count. |
| `experienceYears` | `int` | Years of experience. |
| `bio` | `String` | Free-text bio. |
| `distanceKm` | `double?` | Distance from customer's location. Null if no location params passed. |
| `bayesianScore` | `double?` | Backend-computed trust score. Null if no location params passed. |
| `isActive` | `bool` | Online/offline indicator. |
| `uiRatingText` | `String` | Pre-formatted rating string (e.g. `"4.8 (23 reviews)"`). Render directly. |
| `primaryPrice` | `String` | Pre-formatted display price (e.g. `"Rs. 1,500"`). Render directly. |
| `primaryPriceRaw` | `String` | Decimal string (e.g. `"1500.00"`). Pass as `price_amount` to instant-book. |
| `priceContext` | `String` | Server-derived display label (`"Inspection Fee"` / `"Fixed Price"` / `"Labor Fee"`). Render only — no longer sent on the booking write. |
| `promoTag` | `String?` | Promo badge label. Null when no active promotion. |
| `skills` | `List<TechnicianSkillEntity>` | Sub-services the technician offers. |
| `recentReviews` | `List<TechnicianReviewEntity>` | Last few reviews. |

#### `AvailabilitySlotEntity`
Fed by `GET /api/customers/technicians/{id}/availability/`.

| Field | Type | Description |
| :--- | :--- | :--- |
| `timeString` | `String` | Human-readable label (e.g. `"9:00 AM"`). Displayed in the slot picker. |
| `isoStart` | `String` | ISO 8601 PKT-aware start. Pass verbatim as `scheduled_start` — no conversion. |
| `isoEnd` | `String` | ISO 8601 PKT-aware end. Pass verbatim as `scheduled_end` — no conversion. |
| `period` | `String` | `"AM"` or `"PM"` — used to group slots into Morning/Afternoon sections. |

#### `CreatedBookingEntity`
Response from `POST /api/bookings/instant-book/` (201).

| Field | Type | Description |
| :--- | :--- | :--- |
| `bookingId` | `int` | Primary key of the created `JobBooking`. Must be written to Tier 3 (SharedPreferences) immediately by the UI for crash recovery. |

---

### Failures — `BookingFailure` (sealed class)
`lib/features/booking/domain/failures/booking_failure.dart`

| Class | Trigger |
| :--- | :--- |
| `BookingNetworkFailure` | `SocketException` — no internet |
| `BookingTechnicianNotFoundFailure` | 404 — technician non-existent, PENDING, or REJECTED |
| `BookingInvalidAddressFailure` | 400 `validation_error` with `address_id` key — IDOR-safe (same shape whether missing or owned by another user) |
| `BookingOutOfServiceAreaFailure` | 400 `out_of_service_area` — `message` is already human-readable from the backend (e.g. `"Your address is 14.2 km away (limit: 10 km)"`) — display directly |
| `BookingSlotUnavailableFailure` | 409 `slot_unavailable` — race condition; UI must pop back to slot picker |
| `BookingValidationFailure` | 400 `validation_error` not covered by a more specific type; carries `errors` map |
| `BookingServerFailure` | 5xx or `server_error` code |
| `BookingUnexpectedFailure` | `FormatException` or any other unhandled exception |

---

### Repository Interface — `IBookingRepository`
`lib/features/booking/domain/repositories/i_booking_repository.dart`

| Method | Returns | Notes |
| :--- | :--- | :--- |
| `getTechnicianProfile({id, lat?, lng?, serviceId?, subServiceId?, promotionId?})` | `TechnicianProfileEntity` | `lat`/`lng` enable distance + contextual pricing. All optional. |
| `getAvailability({technicianId, date, serviceId?, subServiceId?})` | `List<AvailabilitySlotEntity>` | Empty list (not an error) when fully booked or no schedule. `date` is `"YYYY-MM-DD"`. |
| `createInstantBooking({technicianId, addressId, serviceId, subServiceId?, promotionId?, scheduledStart, scheduledEnd, priceAmount})` | `CreatedBookingEntity` | `serviceId` is required and threaded from the discovery URL. `subServiceId` for fixed-price gigs (Scenario A) or labor matches (Scenario B). `promotionId` only on promo-banner arrivals (Scenario D). Pairing `subServiceId` + `promotionId` triggers a local `assert` (server's promo firewall — fail fast to save a round trip). |

---

### Use Cases
`lib/features/booking/domain/use_cases/`

All three are thin delegates — no business logic, just repository delegation.

| Use Case | Delegates to |
| :--- | :--- |
| `GetTechnicianProfileUseCase` | `repository.getTechnicianProfile(...)` |
| `GetAvailabilityUseCase` | `repository.getAvailability(...)` |
| `CreateInstantBookingUseCase` | `repository.createInstantBooking(...)` |

---

## Data Layer

### Models
`lib/features/booking/data/models/booking_models.dart`

All models are Freezed + `json_serializable`. Co-located in one file because they share the same `part` declarations.

**Read models** (JSON → Dart → entity):
- `TechnicianSkillModel` — `@JsonKey(name: 'icon_name')`
- `TechnicianReviewModel` — `@JsonKey(name: 'reviewer_name')`
- `TechnicianProfileModel` — 16 fields; all snake_case backend keys mapped via `@JsonKey`
- `AvailabilitySlotModel` — `iso_start`/`iso_end` stored as raw strings; no datetime parsing
- `InstantBookingResponseModel` — `{"booking_id": 123}` → `CreatedBookingEntity`

**Write model** (Dart → JSON → request body):
- `InstantBookingRequestModel` — outgoing POST body. Carries `service_id` (required), `sub_service_id` / `promotion_id` (optional, `includeIfNull: false` keeps them off the wire when null). `price_context` is no longer on the request — server derives the receipt label from the resolved catalog FKs.

Each model has a `toEntity()` method as the single conversion point. No entity-to-model conversion needed (writes use raw fields directly).

---

### Data Source — `BookingRemoteDataSource`
`lib/features/booking/data/data_sources/booking_remote_data_source.dart`

Backed by `IBookingRemoteDataSource` interface (for test mocking).

| Method | HTTP | Auth |
| :--- | :--- | :--- |
| `getTechnicianProfile({id, lat?, lng?, serviceId?, subServiceId?, promotionId?})` | `GET /api/customers/technician-profile/{id}/` | None (public read) |
| `getAvailability({technicianId, date, serviceId?, subServiceId?})` | `GET /api/customers/technicians/{id}/availability/` | None (public read) |
| `createInstantBooking(InstantBookingRequestModel)` | `POST /api/bookings/instant-book/` | `Authorization: Token <token>` from `flutter_secure_storage` |

**No local data source** — booking data is not cached offline. Availability slots are real-time and caching them would create stale-slot race conditions.

---

### Repository Implementation — `BookingRepositoryImpl`
`lib/features/booking/data/repositories/booking_repository_impl.dart`

All three methods follow the same exception handling pattern:

```
remoteDataSource.method(...)
  ✓ success         → model.toEntity()
  ✗ HttpFailure     → _mapFailure(e)    ← switch on code
  ✗ SocketException → BookingNetworkFailure
  ✗ FormatException → BookingUnexpectedFailure('Parsing error...')
  ✗ other           → BookingUnexpectedFailure(e.toString())
```

**`_mapFailure(HttpFailure)` switch:**
| `failure.code` | Throws |
| :--- | :--- |
| `not_found` | `BookingTechnicianNotFoundFailure` |
| `out_of_service_area` | `BookingOutOfServiceAreaFailure(failure.message)` — message passed through verbatim |
| `slot_unavailable` | `BookingSlotUnavailableFailure` |
| `validation_error` + `errors['address_id']` | `BookingInvalidAddressFailure` |
| `validation_error` (other) | `BookingValidationFailure(message, errors)` — the `errors` map is preserved so the presentation layer can map field-level keys (`sub_service_id` / `promotion_id` / `price_amount`) to specific toasts |
| `server_error` | `BookingServerFailure` |
| default | `BookingUnexpectedFailure(failure.message)` |

---

## Presentation Layer

### State — `AvailabilityState`
`lib/features/booking/presentation/providers/availability_state.dart`

Freezed immutable. Holds the full slot list for one date + the customer's current selection.

| Field | Type | Description |
| :--- | :--- | :--- |
| `slots` | `List<AvailabilitySlotEntity>` | All slots returned by the backend for the selected date. |
| `selectedSlot` | `AvailabilitySlotEntity?` | Null until the customer taps. Drives the "Continue" button enable state and the booking payload. |

---

### Notifiers

#### `TechnicianProfileNotifier` (family)
`lib/features/booking/presentation/providers/technician_profile_notifier.dart`

- **Type**: `AsyncNotifier<TechnicianProfileEntity>`, parameterised by `{id, lat?, lng?, serviceId?, subServiceId?, promotionId?}`
- **Location Aware**: If `lat` and `lng` are not provided explicitly, the notifier automatically watches `defaultAddressProvider.future` and passes the default address coordinates to ensure distance and pricing are dynamically calculated based on the user's active location.
- **`build()`**: calls `GetTechnicianProfileUseCase`, returns entity on success or enters `AsyncError`
- **No mutation methods** — profile data is read-only in this flow

#### `AvailabilityNotifier` (family)
`lib/features/booking/presentation/providers/availability_notifier.dart`

- **Type**: `AsyncNotifier<AvailabilityState>`, parameterised by `{technicianId, date, serviceId?, subServiceId?}`
- **Family design**: changing the date in the UI watches a new provider instance — no explicit refresh needed; stale instances auto-dispose
- **`build()`**: calls `GetAvailabilityUseCase`, initialises with `selectedSlot: null`
- **`selectSlot(slot)`**: mutates `selectedSlot` in-memory only — does **not** re-fetch. No-op if the slot is already selected.

#### `InstantBookingNotifier`
`lib/features/booking/presentation/providers/booking_notifier.dart`

- **Type**: `Notifier<AsyncValue<CreatedBookingEntity?>>`, singleton (not a family)
- **Initial state**: `AsyncData(null)` — no booking attempted yet
- **`book({...})`**: sets `AsyncLoading`, then `AsyncValue.guard(...)` resolves to `AsyncData(entity)` or `AsyncError(failure)`
- **Tier 3 responsibility**: on `AsyncData`, the **UI** (not the notifier) must write `bookingId` to `SharedPreferences` for crash recovery. The notifier only owns the network result.
- **409 UX**: when `AsyncError` contains `BookingSlotUnavailableFailure`, the UI must pop back to the slot picker. The notifier does not navigate.

---

### Screens & Widgets

#### `TechnicianProfileScreen`
`lib/features/booking/presentation/screens/technician_profile_screen.dart`

- **Entry point** to the booking flow. Accepts `technicianId` + optional location/context params.
- Watches `technicianProfileProvider` (family) — renders loading spinner, error with "Go Back", or `_ProfileContent`.
- **Dumb UI fields rendered directly**: `uiRatingText`, `primaryPrice`, `priceContext`, `promoTag` — no formatting in the widget.
- Sticky bottom bar CTA launches `SelectTimeSheet` as a modal bottom sheet.

#### `SelectTimeSheet`
`lib/features/booking/presentation/widgets/select_time_sheet.dart`

- Modal bottom sheet for date + slot selection.
- Horizontal date strip (7 days from today); selecting a date watches a new `availabilityProvider` instance.
- Slots split into Morning (AM) / Afternoon (PM) sections via `_PeriodSection`.
- **Location Guard**: Footer "Continue" button is enabled only when `state.selectedSlot != null`. On tap, it checks `defaultAddressProvider`. If null, it intercepts navigation and pops up the `AddressSelectorSheet`. If valid, it launches `ReviewBookingSheet`.

#### `ReviewBookingSheet`
`lib/features/booking/presentation/widgets/review_booking_sheet.dart`

- Final confirmation sheet. Receives `TechnicianProfileEntity`, `selectedDate`, and `selectedSlot` as constructor params.
- Watches `defaultAddressProvider` to dynamically display the active service address. Includes a "Change" button that opens the `AddressSelectorSheet` to switch addresses mid-flow.
- Listens to `instantBookingProvider` for navigation + error handling:
  - `AsyncData(entity != null)` → close sheet → show "Booking Confirmed!" Snackbar → **(TODO: write `bookingId` to Tier 3)**
  - `AsyncError(BookingSlotUnavailableFailure)` → show Snackbar + close sheet so customer can re-pick
  - `AsyncError(BookingValidationFailure)` with a known field-level key → user-friendly toast via `_resolveErrorPresentation` and pop the sheet (see table below)
  - `AsyncError(other)` → show `error.message` Snackbar
- "Confirm & Lock" button calls `instantBookingProvider.notifier.book(...)`, threading `serviceId` (required), `subServiceId`/`promotionId` (scenario-dependent), `isoStart`/`isoEnd` verbatim, and `defaultAddress.id`.

**Field-level validation_error → user-friendly toast** (BOOKINGS_API.md §2.2). Server returns diagnostic-friendly text; the sheet maps each error key to a fixed user-friendly string via the local dictionary in `_resolveErrorPresentation`:

| `errors` key | Likely cause | Toast |
| :--- | :--- | :--- |
| `sub_service_id` | Stale discovery context — the sub-service no longer belongs to the supplied parent service. | "This gig is no longer available. Refresh and try again." → pop sheet |
| `promotion_id` | Promo applied to a fixed-price gig (server's promo firewall). | "This gig already has a fixed price — promotions don't apply." → pop sheet |
| `price_amount` | Stale cached technician rate; price drifted between profile fetch and book press. | "Pricing has updated. Please refresh and confirm again." → pop sheet |

#### `ModalBottomSheetLayout`
`lib/features/booking/presentation/widgets/modal_bottom_sheet_layout.dart`

Shared chrome for both bottom sheets. Accepts `title`, `child` (scrollable body), and `footer` (sticky CTA area).

---

## Error Propagation Pipeline

```
BookingRemoteDataSource
  throws HttpFailure(statusCode, code, message, errors)
      ↓
BookingRepositoryImpl._mapFailure()
  switch (code) → throws specific BookingFailure subclass
      ↓
[Use Case — transparent passthrough]
      ↓
TechnicianProfileNotifier / AvailabilityNotifier / InstantBookingNotifier
  AsyncValue.guard() wraps the failure as AsyncError(BookingFailure)
      ↓
UI widgets
  ref.listen / profileAsync.when → switch (error) { ... }
  → Snackbar with error.message
  → Navigation: BookingSlotUnavailableFailure → pop to slot picker
```

---

## Dependency Injection
`lib/features/booking/presentation/providers/dependency_injection.dart`

All providers are `keepAlive: true`. Wiring order:

```
bookingHttpClient / bookingSecureStorage
    ↓
bookingRemoteDataSource (http client + secure storage)
    ↓
bookingRepository
    ↓
getTechnicianProfileUseCase / getAvailabilityUseCase / createInstantBookingUseCase
    ↓
technicianProfileProvider (family)   ← watched by TechnicianProfileScreen
availabilityProvider (family)        ← watched by SelectTimeSheet
instantBookingProvider               ← watched by ReviewBookingSheet
```

---

## Known TODOs
- `ReviewBookingSheet`: Tier 3 cache write (`bookingId` → `SharedPreferences`) after confirmed booking is marked `// TODO` — must be implemented before shipping to prevent crash-recovery failures.

---

## Realtime — incoming job requests ⏳ pending

The catalog-FK rollout extends the `job_new_request` event payload with `booking_type` (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`) and `payout_context` (server-picked prose under the headline payout). See BOOKINGS_API.md §2.3–§2.5.

**Out of scope for this sync** — the technician incoming-request screen does not yet exist in `frontend/lib/features/technician/`. When it lands:
- Add `JobNewRequestPayload` Freezed model with `bookingType` and `payoutContext` as **nullable** (older `EventLog` rows replayed via `/api/events/sync/` predate the rollout).
- Route the on-site flow on `bookingType` (Inspection → "Build Quote", Fixed/Labor → "Mark Complete").
- Render `payoutContext` verbatim under the payout figure (Dumb-UI principle).
- Defensive parsing: when `bookingType` is null, default to `LABOR_GIG`-style layout and hide the `payoutContext` line.
