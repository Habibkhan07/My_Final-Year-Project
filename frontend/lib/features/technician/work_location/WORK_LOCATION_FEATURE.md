# Technician Work Location — Feature Brief

> One technician, one work area. Without it the matchmaker silently excludes the tech from every customer search.

## Why it exists

`TechnicianProfile.base_latitude` / `base_longitude` already existed, but onboarding never collected them. The matchmaker (`technicians/selectors/matchmaking_selectors.py`) filters via `base_latitude__range` and skips null-coord rows, so newly-onboarded techs were silently invisible. This feature is the only path that makes a tech discoverable on the customer side.

## Backend contract

`GET / PATCH /api/technicians/me/work-location/`

### GET — response

```json
{
  "has_profile": true,
  "is_set": true,
  "latitude": 31.5204,
  "longitude": 74.3587,
  "max_travel_radius_km": 12,
  "work_address_label": "Gulberg, Lahore"
}
```

- `has_profile=false` → pure customer (no `TechnicianProfile`). Other fields are defaulted; FE routes elsewhere.
- `is_set=false` → tech exists but has no lat/lng. Banner renders.

### PATCH — request

```json
{
  "latitude": 31.5204,           // required, [-90, 90]
  "longitude": 74.3587,          // required, [-180, 180]
  "max_travel_radius_km": 12,    // optional, [1, 100]
  "work_address_label": "..."    // optional, max 200 chars, null clears it
}
```

Returns the same shape as GET. 401 / 400 / 404 follow the project error envelope.

## Domain entity

`WorkLocationEntity` (Freezed) — `lib/features/technician/work_location/domain/entities/work_location_entity.dart`

| Field                 | Type      | Source                                                  |
| --------------------- | --------- | ------------------------------------------------------- |
| `isSet`               | `bool`    | `is_set` (server-derived: both coords non-null)         |
| `maxTravelRadiusKm`   | `int`     | `max_travel_radius_km`                                  |
| `latitude`            | `double?` | `latitude` (null until set)                             |
| `longitude`           | `double?` | `longitude`                                             |
| `workAddressLabel`    | `String?` | `work_address_label` (display only; lat/lng is trusted) |

## Failure hierarchy

Sealed `WorkLocationFailure` in `domain/failures/work_location_failure.dart`:

- `WorkLocationNetworkFailure` — no internet.
- `WorkLocationValidationFailure(message)` — 4xx with field-level errors; surfaces the first field name in the message.
- `WorkLocationProfileMissingFailure` — 404; user has no `TechnicianProfile`.
- `WorkLocationUnauthorizedFailure` — 401; token expired.
- `WorkLocationServerFailure` — 5xx or anything unclassifiable.
- `WorkLocationParsingFailure` — JSON shape drift.

## Repository contract

`IWorkLocationRepository` in `domain/repositories/`. Two methods, both throw a `WorkLocationFailure` subclass on failure (CLAUDE.md error-propagation rule):

- `getWorkLocation()` → `WorkLocationEntity`
- `saveWorkLocation({ latitude, longitude, maxTravelRadiusKm?, workAddressLabel? })` → `WorkLocationEntity`

## Use cases

- `GetWorkLocationUseCase` — thin wrapper around `getWorkLocation`.
- `SaveWorkLocationUseCase` — thin wrapper around `saveWorkLocation`.

## Data layer

- `WorkLocationModel.fromJson` — defensive parser; defaults missing keys so older cached payloads deserialise cleanly.
- `WorkLocationRemoteDataSource` — `Bearer`-style token auth via `AuthLocalDataSource`; raises `HttpFailure` on non-2xx.
- `WorkLocationRepositoryImpl` — 4-step error pipeline: `HttpFailure` → `_mapFailure` → sealed `WorkLocationFailure`. No offline cache (picker needs map tiles which need connectivity; the dashboard's `has_work_location` field caches the banner-gate flag).

## Presentation layer

`presentation/notifiers/work_location_picker_notifier.dart` — `WorkLocationPickerNotifier` (`@riverpod`):

- `build()` priority: saved row → device GPS → Lahore fallback (31.5204, 74.3587).
- `onMapPanEnd(lat, lng)` — debounced reverse-geocode (600ms) mirroring the customer picker.
- `updateLocation(PlaceDetails)` — called by the search overlay on prediction tap.
- `setRadius(int)` — bottom-card slider.
- `save()` — `AsyncValue.guard` around `SaveWorkLocationUseCase`. On success the screen pops; banner re-evaluates from the dashboard's refreshed payload.

`presentation/screens/work_location_picker_screen.dart` reuses:

- `core/widgets/map/location_picker.dart` (centre-pin map shell).
- `customer/addresses` geocoding use cases (search, place-details, reverse-geocode). These are effectively generic location utilities that happen to ship under the customer addresses feature — importing them is intentional, not a layering accident; duplicating the geocoding stack would inflate the binary.

The search overlay owns its own debounce + state rather than reusing `LocationSearchNotifier`, because that notifier hardcodes a write into the customer-side `mapPickerProvider`. Reaching across feature boundaries to mutate a sibling feature's notifier is the kind of coupling the per-event wiring rule in CLAUDE.md forbids.

## Dashboard banner

`features/technician/dashboard/presentation/widgets/work_location_banner.dart`:

- `hasWorkLocation == false` → call-to-action card with "Set your work area" + nudge copy.
- `hasWorkLocation == true` → quiet summary row with the saved label (re-edit affordance; never hidden once set).

Both tap to `/technician/work-location`. The dashboard payload now carries `has_work_location` + `work_address_label` so the banner renders without a second round-trip.

## Routing

`/technician/work-location` → `WorkLocationPickerScreen()` (`core/routing/app_router.dart`).

## DI

`presentation/providers/dependency_injection.dart` — all providers `@Riverpod(keepAlive: true)`:

- `workLocationHttpClientProvider`
- `workLocationRemoteDataSourceProvider` (uses `authLocalDataSourceProvider` from auth)
- `workLocationRepositoryProvider`
- `getWorkLocationUseCaseProvider`
- `saveWorkLocationUseCaseProvider`

## Test coverage

| Layer       | File                                                                                                            | Cases                                                                              |
| ----------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Data: model | `test/features/technician/work_location/data/models/work_location_model_test.dart`                              | fromJson shapes (`is_set` true/false, missing keys, integer coords); `toEntity()`. |
| Data: repo  | `test/features/technician/work_location/data/repositories/work_location_repository_impl_test.dart`              | Full 4-step pipeline: 200, 401, 404, 5xx, `SocketException`, `FormatException`, 400-with-errors. |
| Widget      | `test/features/technician/dashboard/presentation/widgets/work_location_banner_test.dart`                        | Unset CTA copy, set summary row, fallback label, navigation on tap.                |
| Backend api | `backend/tests/technicians/api/work_location/test_views.py`                                                     | GET/PATCH happy paths, validation envelopes (lat/lng/radius bounds), 401, 404, IDOR negative, REJECTED-status path. |
| Backend svc | `backend/tests/technicians/services/test_work_location_service.py`                                              | Writes; omitted radius preserved; empty label normalised to null; NotFound for pure customer. |

Presentation-layer notifier tests are **deferred** — the picker notifier depends on the customer-addresses geocoding stack, which would balloon the mock surface beyond viva-budget. The repository's pipeline is fully covered, and the picker's pop-on-save behaviour is exercised manually before viva.

## Out of scope (intentional)

- Multiple work areas per tech.
- Offline cache of the work-location response (the dashboard already caches the gate flag).
- Onboarding-time mandatory location capture (parked behind the onboarding refactor item in `project_tech_onboarding_refactor`).
