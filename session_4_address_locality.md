# Session 4 — Address Locality Structuring (customer-side address save path)

> **STATUS — SHIPPED 2026-05-02.** The plan below was the *initial* design (server-side reverse-geocoder via OSM Nominatim, port-and-adapter, optionally async via Celery). During scratchpad review the user pointed out that **client-side reverse-geocoding already exists** — `frontend/lib/features/customer/addresses/data/data_sources/google_maps_remote_data_source.dart` braided Google + OSM with `if-else`. We pivoted to a different design before writing any code; the actual implementation is summarised in the **"Solution actually implemented"** section at the bottom of this file. The original plan is preserved unedited as historical context.

---

## Intent

Add server-derived structured locality fields (neighborhood, suburb, city, state, postal_code, locality_label) to `CustomerAddress`, populated by a reverse-geocoder when the customer creates or updates an address. Stored once at write time; read forever afterwards.

## Why

`CustomerAddress.street_address` today is an opaque `CharField(max_length=255)`. Downstream consumers that need to display or filter by location have nothing structured to read. The clean fix is to capture structure at the moment we have lat/lng (address creation), persist it on the row, and let every consumer read cached fields directly. No re-geocoding on hot paths.

## Scope (in)

1. Schema additions on `CustomerAddress`: nullable structured fields.
2. Geocoder Port-and-Adapter, mirroring the pattern already in `backend/bookings/services/ports.py` + `backend/bookings/adapters/`.
3. Service wiring: `create_customer_address` and `update_customer_address` invoke the geocoder when lat/lng changes, populate structured fields. Geocoder failure does NOT block the save.
4. Serializer changes: `CustomerAddressReadSerializer` exposes the new fields. `CustomerAddressWriteSerializer` does NOT accept them — server-derived only, backend owns the truth.
5. Migration: additive Django migration; no data migration.
6. Backfill: a management command `backfill_address_localities` for existing rows.
7. Doc update: `backend/customers/api/ADDRESSES_API.md` reflects the new fields.
8. Tests: address service tests get a geocoder mock; new tests cover graceful-degradation; a backfill command test.

## Scope (out — explicitly NOT in this session)

The following are deferred to follow-up sprints. They are listed here so this session does not feature-creep.

- **`job_new_request` event payload.** The dispatch event today carries (verified against `backend/bookings/api/BOOKINGS_API.md` §1.2 lines 244–271): `job_id`, `service_name`, `booking_type`, `scheduled_start_iso`, `payout`, `payout_context`, `expires_in_seconds`. **Not modified in this session.** Adding `ui_location_label` to that envelope is a separate sprint that can read `booking.address.locality_label` once this session ships the field. The user's framing is correct: bookings checkout sends only `address_id` → server JOINs to `CustomerAddress` at dispatch time. None of that wire shape changes here.
- **Frontend changes.** No edits to the incoming-job-request sheet, its entity, its mapper, or any Flutter file. The frontend already has a placeholder slot in plan but does not get wired in this session.
- **Discovery API surface changes.** The `/api/customers/addresses/` GET listing will automatically gain the new fields once `CustomerAddressReadSerializer` exposes them — no separate work needed there. No other discovery endpoints change.

## Current state — verified against code (do not trust earlier summaries)

### Model — `backend/customers/models.py`
```python
class CustomerAddress(models.Model):
    customer       = ForeignKey(CustomerProfile, related_name='addresses')
    label          = CharField(max_length=50, default='Home')
    street_address = CharField(max_length=255)
    latitude       = DecimalField(max_digits=9, decimal_places=6)
    longitude      = DecimalField(max_digits=9, decimal_places=6)
    is_default     = BooleanField(default=False)
    created_at     = DateTimeField(auto_now_add=True)
```

### Endpoints — `backend/customers/api/addresses/`
| Method | URL | View | Serializer (write) | Service entry |
| :--- | :--- | :--- | :--- | :--- |
| GET    | `/api/customers/addresses/`       | `CustomerAddressListCreateView.get`    | —                              | `get_addresses_for_user(user)` |
| POST   | `/api/customers/addresses/`       | `CustomerAddressListCreateView.post`   | `CustomerAddressWriteSerializer` | `create_customer_address(user, validated_data)` |
| PATCH  | `/api/customers/addresses/<id>/`  | `CustomerAddressDetailView.patch`      | `CustomerAddressWriteSerializer` (partial) | `update_customer_address(user, address_id, data)` |
| DELETE | `/api/customers/addresses/<id>/`  | `CustomerAddressDetailView.delete`     | —                              | `delete_customer_address(user, address_id)` |

### Serializers — `backend/customers/api/addresses/serializers.py`
- `CustomerAddressReadSerializer.Meta.fields = ['id', 'label', 'street_address', 'latitude', 'longitude', 'is_default', 'created_at']` (all read-only).
- `CustomerAddressWriteSerializer.Meta.fields = ['label', 'street_address', 'latitude', 'longitude', 'is_default']`.

### Service — `backend/customers/services/address_service.py`
- `create_customer_address(*, user, validated_data) -> CustomerAddress` — atomic `is_default` toggle via `select_for_update`.
- `update_customer_address(*, user, address_id, data) -> CustomerAddress`.
- `delete_customer_address(*, user, address_id) -> None`.

### Selector — `backend/customers/selectors/address_selectors.py`
- `get_addresses_for_user(*, user)` — `select_related('customer__user')`.

### Tests — `backend/tests/customers/services/test_address_service.py`
Existing coverage: create, update, delete, IDOR, default-toggle atomicity. Will need geocoder-mock additions; existing tests stay green because the geocoder parameter is optional and tests can pass `geocoder=None` (or a no-op fake).

### No existing geocoder code
`grep -r "Geocoder|geocode|nominatim|reverse_geocode" --include="*.py"` returns zero hits. Clean slate.

### Existing Port-and-Adapter pattern to mirror — `backend/bookings/`
- `bookings/services/ports.py` declares `class JobDispatchScheduler(Protocol)`.
- `bookings/adapters/__init__.py` exposes `get_default_scheduler()` with a **lazy import** of the concrete adapter inside the function body (preserves the boundary that `bookings.services.*` modules don't transitively pull in Celery).
- `bookings/adapters/celery_scheduler.py` is the concrete implementation.

The geocoder version mirrors this exactly. Same lazy-import discipline.

### Doc-drift sanity check (do not silently fix mid-session)
`backend/customers/api/DISCOVERY_API.md §1.5 Saved Addresses` (lines 346–383) describes the same `/api/customers/addresses/` endpoint but uses the field name `address_text`. The actual API returns `street_address` (verified against `CustomerAddressReadSerializer`). This is a pre-existing doc drift, **not introduced by this session**. Optional one-line cleanup at end of session — flag it but do not bundle into the structuring commit.

## Plan — step by step

### Step 1 — schema migration

In `backend/customers/models.py`, append to `CustomerAddress`:
```python
neighborhood   = CharField(max_length=120, null=True, blank=True)
suburb         = CharField(max_length=120, null=True, blank=True)
city           = CharField(max_length=120, null=True, blank=True)
state          = CharField(max_length=120, null=True, blank=True)
country        = CharField(max_length=8,   null=True, blank=True)   # ISO-3166 alpha-2 e.g. "PK"
postal_code    = CharField(max_length=20,  null=True, blank=True)
locality_label = CharField(max_length=200, null=True, blank=True)
```

All nullable. Existing rows have nothing to populate; the geocoder may fail for some new rows; both are non-fatal. Serializer treats `null` as "not yet known".

Run: `python manage.py makemigrations customers`. Migration is purely additive — no data migration in this step.

### Step 2 — define the Geocoder Port

New file: `backend/customers/services/ports.py`
```python
from __future__ import annotations
from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol


@dataclass(frozen=True)
class GeocodedLocality:
    neighborhood: str | None
    suburb: str | None
    city: str | None
    state: str | None
    country: str | None       # ISO-3166 alpha-2
    postal_code: str | None


class Geocoder(Protocol):
    """Reverse-geocode a coordinate to structured locality fields.

    Implementations MUST be safe to call repeatedly for the same coordinate
    (idempotent). On network/parse failure, return None — caller decides
    whether to fail-soft. Do not raise on transient failures.
    """
    def reverse_geocode(
        self, *, lat: Decimal, lng: Decimal
    ) -> GeocodedLocality | None: ...
```

### Step 3 — OSM Nominatim adapter + factory

New file: `backend/customers/adapters/__init__.py`
```python
from __future__ import annotations
from customers.services.ports import Geocoder


def get_default_geocoder() -> Geocoder:
    """Production wiring. The OSM HTTP-client import is deferred to
    function body so customers.services.* modules don't transitively pull
    in `requests` at import time. Tests inject a fake instead of calling
    this factory."""
    from customers.adapters.osm_geocoder import OSMNominatimAdapter
    return OSMNominatimAdapter()
```

New file: `backend/customers/adapters/osm_geocoder.py`
```python
from __future__ import annotations
from decimal import Decimal
import logging
import requests

from customers.services.ports import GeocodedLocality

logger = logging.getLogger(__name__)


class OSMNominatimAdapter:
    """Hits OSM Nominatim's reverse endpoint.

    Free-tier policy:
      - 1 req/sec hard cap (do not burst).
      - Mandatory descriptive User-Agent.
      - Cache results — re-querying the same coordinate is wasteful and
        rude.

    For production scale, options are:
      (a) self-host a Nominatim instance, (b) move to a paid provider via
      a sibling adapter (e.g. GoogleGeocoderAdapter), (c) cache aggressively.
      None required for this session — flag for ops follow-up.
    """
    BASE_URL = "https://nominatim.openstreetmap.org/reverse"
    USER_AGENT = "fyp-marketplace/1.0 (contact: <maintainer-email>)"
    TIMEOUT_SECONDS = 5.0

    def reverse_geocode(
        self, *, lat: Decimal, lng: Decimal
    ) -> GeocodedLocality | None:
        try:
            response = requests.get(
                self.BASE_URL,
                params={
                    "lat": str(lat),
                    "lon": str(lng),
                    "format": "json",
                    "zoom": 14,
                    "addressdetails": 1,
                },
                headers={
                    "User-Agent": self.USER_AGENT,
                    "Accept-Language": "en",
                },
                timeout=self.TIMEOUT_SECONDS,
            )
            response.raise_for_status()
            data = response.json()
        except (requests.RequestException, ValueError) as exc:
            logger.warning(
                "OSM reverse geocode failed for (%s, %s): %s", lat, lng, exc,
            )
            return None

        addr = data.get("address", {})
        country_code = (addr.get("country_code") or "").upper() or None
        return GeocodedLocality(
            neighborhood=addr.get("neighbourhood") or addr.get("residential"),
            suburb=addr.get("suburb") or addr.get("city_district"),
            city=addr.get("city") or addr.get("town") or addr.get("municipality"),
            state=addr.get("state"),
            country=country_code,
            postal_code=addr.get("postcode"),
        )
```

The future Google adapter lands as `customers/adapters/google_geocoder.py` with a structurally identical class. `get_default_geocoder()` swaps the import. Service code unchanged. Tests unchanged.

### Step 4 — wire the service

Modify `backend/customers/services/address_service.py`:

- Add a private helper:
  ```python
  def _compose_locality_label(loc: GeocodedLocality) -> str | None:
      """The ONLY place that knows the composition rule. v1:
        - suburb + city  → "{suburb}, {city}"
        - neighborhood + city → "{neighborhood}, {city}"
        - city only      → "{city}"
        - else           → None
      If the rule needs to change, change it here and re-run backfill.
      """
      area = loc.suburb or loc.neighborhood
      if area and loc.city:
          return f"{area}, {loc.city}"
      return loc.city
  ```

- Modify `create_customer_address(*, user, validated_data, geocoder: Geocoder | None = None)`:
  1. Resolve geocoder: `geocoder = geocoder or get_default_geocoder()` (lazy import inside the factory keeps the boundary).
  2. Atomic create as today (default-toggle logic unchanged).
  3. After `.create(...)`, call `geocoder.reverse_geocode(lat=address.latitude, lng=address.longitude)`.
  4. On result: assign neighborhood/suburb/city/state/country/postal_code; assign `locality_label = _compose_locality_label(result)`; `address.save(update_fields=[...])`.
  5. On `None`: leave nulls; do not raise; the address is still successfully created.

- Modify `update_customer_address(*, user, address_id, data, geocoder: Geocoder | None = None)`:
  - Re-geocode **only** when `latitude` or `longitude` is in the partial-update payload (`data`). Otherwise locality is unchanged.
  - Same write order as create: row update first, geocode second, save second.

`delete_customer_address` is unchanged.

The view layer (`addresses/views.py`) does not change — it calls the service with no geocoder, and the service resolves the default. Lazy default-resolution preserves testability.

### Step 5 — serializer changes

`backend/customers/api/addresses/serializers.py`:
- `CustomerAddressReadSerializer.Meta.fields` becomes:
  ```python
  fields = [
      'id', 'label', 'street_address',
      'latitude', 'longitude', 'is_default', 'created_at',
      'neighborhood', 'suburb', 'city',
      'state', 'country', 'postal_code',
      'locality_label',
  ]
  ```
  All read-only (already covered by `read_only_fields = fields`).
- `CustomerAddressWriteSerializer.Meta.fields` is unchanged. The new fields are NEVER accepted from the client. Backend-derived only.

### Step 6 — backfill management command

New file: `backend/customers/management/__init__.py` (if missing).
New file: `backend/customers/management/commands/__init__.py`.
New file: `backend/customers/management/commands/backfill_address_localities.py`.

Behavior:
- Iterate `CustomerAddress.objects.filter(locality_label__isnull=True).order_by('id')`.
- For each, call `get_default_geocoder().reverse_geocode(lat=address.latitude, lng=address.longitude)`.
- On result: populate fields and `locality_label` via `_compose_locality_label`, save.
- On `None`: skip and log at INFO.
- `time.sleep(1.1)` between calls — respect Nominatim's 1 req/sec free-tier cap.
- Log progress every 50 rows. Print final summary (populated / skipped / total).
- Argparse flag `--limit N` for partial runs and `--dry-run` for read-only previews.

### Step 7 — tests

Update `backend/tests/customers/services/test_address_service.py`:
- New `class TestGeocoderIntegration`:
  - `test_create_populates_structured_fields_when_geocoder_returns_locality` — inject a fake `Geocoder` returning a known `GeocodedLocality`. Assert `address.suburb`, `address.city`, `address.locality_label` match.
  - `test_create_succeeds_when_geocoder_returns_none` — fake returns `None`. Assert address row is created, structured fields are null.
  - `test_create_succeeds_when_geocoder_raises` — fake raises. (Decision: Adapter contract says don't raise; defensive depth-test verifies the service doesn't crash if it does.)
  - `test_update_skips_geocoder_when_coords_unchanged` — fake records calls. PATCH only `is_default`. Assert fake never called.
  - `test_update_calls_geocoder_when_coords_change` — PATCH lat/lng. Assert fake called with new coords; structured fields refreshed.

New file: `backend/tests/customers/management/__init__.py`.
New file: `backend/tests/customers/management/test_backfill_address_localities.py`:
- Create rows with null `locality_label`. Run command with an injected fake geocoder (use `monkeypatch` on `get_default_geocoder`). Assert all rows populated.
- Test `--limit` honors the cap. Test `--dry-run` makes no DB writes.

Test factories: extend `tests/factories/customers.py` `CustomerAddressFactory` if needed to set the new fields explicitly for tests that don't go through the service layer. Default values: all nulls (matches the migration default).

### Step 8 — doc update

`backend/customers/api/ADDRESSES_API.md`:
- GET response example: append the new fields to the JSON body and the schema table.
- POST/PATCH request body: NO new fields (server-derived).
- New section "Server-derived locality fields": one paragraph explaining the backend reverse-geocodes at write time, fields may be `null` if the geocoder failed.

Optional cleanup commit at end (separate from the structuring commit so it can be reviewed independently): `backend/customers/api/DISCOVERY_API.md §1.5` — change `address_text` → `street_address` to match the actual API. This is a pre-existing doc drift; flagged here, not introduced.

## Decisions to confirm before coding

1. **`locality_label` stored as a column vs computed via `@property`?**
   Recommendation: stored. Reads dominate (every booking, every dispatch event eventually). Composition rule is unlikely to change. Storage cost is ~200 bytes per address.
   Alternative: `@property` on the model that calls `_compose_locality_label`. Avoids migration if composition changes; pays composition cost on every read.

2. **Composition rule for `locality_label`** — confirm with concrete examples:
   - Gulberg III, Block C, Lahore → `"Gulberg, Lahore"` (suburb wins over neighborhood)
   - F-7, Islamabad → `"F-7, Islamabad"` (suburb)
   - Rural area without a suburb → `"Sialkot"` (city only)
   - Gulshan-e-Iqbal, Karachi → `"Gulshan-e-Iqbal, Karachi"`

3. **Geocoder failure behavior** — recommendation: log at WARNING, save row with locality fields null, return success to client. Address creation must not depend on Nominatim availability.

4. **Re-geocode policy on update** — recommendation: only when `latitude` OR `longitude` is in the partial-update payload. Pure label / is_default updates skip the geocoder.

5. **Nominatim User-Agent** — set a real maintainer email before merging. Free-tier policy requires identifying contact info.

## Files

**Create**
- `backend/customers/services/ports.py`
- `backend/customers/adapters/__init__.py`
- `backend/customers/adapters/osm_geocoder.py`
- `backend/customers/management/__init__.py` (if missing)
- `backend/customers/management/commands/__init__.py`
- `backend/customers/management/commands/backfill_address_localities.py`
- `backend/customers/migrations/000X_customeraddress_locality_fields.py` (auto-generated)
- `backend/tests/customers/management/__init__.py`
- `backend/tests/customers/management/test_backfill_address_localities.py`

**Modify**
- `backend/customers/models.py` — add 7 nullable fields
- `backend/customers/services/address_service.py` — wire geocoder + helper
- `backend/customers/api/addresses/serializers.py` — extend Read serializer
- `backend/customers/api/ADDRESSES_API.md` — document new fields
- `backend/tests/customers/services/test_address_service.py` — new test class
- `backend/tests/factories/customers.py` — optional, if test setup needs structured-field defaults

**Optional cleanup (separate commit)**
- `backend/customers/api/DISCOVERY_API.md` — fix `address_text` → `street_address` field name in §1.5

## Notes for the *next* session (post-this-session)

After this session ships, the address structuring is complete but no event payload or frontend has been touched. The natural next steps are independent sprints:

1. **Wire `ui_location_label` into the `job_new_request` payload.** Read `booking.address.locality_label` in `bookings/services/event_dispatch.py` (or wherever the broadcast envelope is built; verify before assuming). Add the field to `BOOKINGS_API.md §1.2`. Backwards-compatible (nullable on the wire model).
2. **Frontend**: extend `JobNewRequest` entity with optional `locationLabel`; mapper consumes the wire field; UI renders the address row in the incoming-job sheet (the placeholder slot already in plan).
3. Update `flag.md` to record the rollout if any flag was opened for this work.

Each is its own session. None blocks this one.

---

# Solution actually implemented (2026-05-02)

## What changed vs. the plan above
The pivot: **the client already had Google/OSM reverse-geocoding** (in `google_maps_remote_data_source.dart`), it just threw away the structured pieces and only kept the `formatted_address` string. So instead of building a *second* geocoder on the backend, we:

1. **Stopped throwing away the structured data on the client.** Extract `address_components` (Google) / the OSM `address` block (Nominatim), pass them all the way through the save flow.
2. **Made the backend a dumb storage layer** for those fields. No backend geocoder, no Celery task, no port-and-adapter on the server, no `requests` dependency, no backfill command, no rate-limit problem. Backend trusts the client for these display-only fields. (Recorded in `flag.md #15` with the proper-fix path if abuse appears.)
3. **Cleaned up the braided client-side code into a proper port-and-adapter** — one abstract `GeocodingDataSource` with `GoogleMapsGeocodingDataSource` (prod) and `NominatimGeocodingDataSource` (dev) behind it. Production swap to Google is a one-line `--dart-define=GOOGLE_MAPS_API_KEY=<key>` build flag. (Silent-fallback footgun recorded in `flag.md #16`.)

## Architecture (final)

```
Flutter map-picker
        │ user drags pin (lat, lng)
        ▼
GeocodingDataSource port
        │   ├─ GoogleMapsGeocodingDataSource (prod, dart-define key set)
        │   └─ NominatimGeocodingDataSource  (dev fallback)
        ▼
PlaceDetails Freezed model
   { formattedAddress, lat, lng,
     neighborhood?, suburb?, city?, state?, country?, postalCode?,
     localityLabel (computed getter) }
        │
        ▼
SaveAddressUseCase → Repository → AddressRemoteDataSource
        │
        ▼
POST /api/customers/addresses/  { ...all 7 structured fields }
        │
        ▼
CustomerAddressWriteSerializer (accepts the 7 fields, optional+nullable)
        │
        ▼
create_customer_address(...)  ← unchanged service, just passes **validated_data
        │
        ▼
DB row with cached structured fields
```

The compose rule for `locality_label` (`"{suburb || neighborhood}, {city}"`) lives in **one place**: `PlaceDetails.localityLabel` getter in `frontend/lib/features/customer/addresses/data/models/place_details.dart`. Backend stores whatever the client computed; consumers (e.g. future `job_new_request` payload) read the cached column rather than re-composing.

## Backend changes

| File | Change |
| :--- | :--- |
| `customers/models.py` | Added 7 nullable `CharField`s on `CustomerAddress`: `neighborhood`, `suburb`, `city`, `state`, `country` (max_length=8 for ISO-2), `postal_code`, `locality_label`. |
| `customers/migrations/0004_customeraddress_city_customeraddress_country_and_more.py` | Auto-generated additive migration. Applied to dev DB. |
| `customers/api/addresses/serializers.py` | `CustomerAddressReadSerializer.fields` exposes all 7. `CustomerAddressWriteSerializer.fields` **accepts** all 7, marked `required=False, allow_null=True` via `extra_kwargs`. |
| `customers/services/address_service.py` | **Unchanged.** `**validated_data` already passes the new fields through `.create()` and the update `setattr` loop. |
| `customers/api/ADDRESSES_API.md` | Rewritten with the new request/response shape, trust-boundary note, legacy-row null-fallback callout. |
| `customers/api/DISCOVERY_API.md` | Pre-existing `address_text` → `street_address` field-name drift fixed in §1.5. Added a pointer to `ADDRESSES_API.md` for the full schema. |
| `tests/customers/api/addresses/test_api.py` | New `TestStructuredLocalityFields` class (4 tests): full round-trip persistence, back-compat for clients that don't send the fields, PATCH on re-pick, GET surfaces nulls for legacy rows. Existing key-set assertions updated to include the new fields. |

What we explicitly did **not** build (saved net effort vs. original plan):
- ❌ `customers/services/ports.py` Geocoder Protocol — deleted from scope.
- ❌ `customers/adapters/osm_geocoder.py` — deleted from scope.
- ❌ `customers/management/commands/backfill_address_localities.py` — deleted from scope (legacy rows have nulls; UI falls back to `street_address`).
- ❌ `requests` dependency in `requirements.txt` — not needed.
- ❌ Sync-vs-async-Celery debate — moot.

## Frontend changes

**Created**
- `data/models/place_details.dart` — Freezed model carrying all geocoder output, with `localityLabel` getter as the single source of truth for the compose rule.
- `data/data_sources/geocoding_data_source.dart` — abstract port.
- `data/data_sources/google_maps_geocoding_data_source.dart` — prod adapter. Asks Google for `address_components` (the previous code only requested `geometry,formatted_address` and threw away the structured data Google was already returning). Pakistan-relevant component-type mapping: `locality`→city, `sublocality_level_1`→suburb, `administrative_area_level_1`→state, `country.short_name`→country (ISO-2).
- `data/data_sources/nominatim_geocoding_data_source.dart` — dev-only adapter. Maps OSM `address` block (`neighbourhood`, `suburb`, `city`/`town`/`village`, `state`, `country_code`, `postcode`).

**Deleted**
- `data/data_sources/google_maps_remote_data_source.dart` — the old braided Google+OSM `if-else` class.

**Modified (signature changes)**
- `domain/entities/address_entity.dart` — added 7 nullable fields.
- `data/models/address_model.dart` — `CustomerAddressModel.fromJson/toJson` and `CreateAddressRequest.toJson` extended.
- `domain/repositories/i_address_repository.dart` — `saveAddress`/`updateAddress` take 7 nullable extras; `getCurrentLocation`, `reverseGeocode`, `getPlaceDetails` now return `PlaceDetails` instead of an ad-hoc record.
- `data/repositories/address_repository_impl.dart` — depends on `GeocodingDataSource` instead of the deleted class. `getCurrentLocation` resolves device GPS via native placemark, then layers the HTTP geocoder on top to enrich structured fields; falls back to the native result if the HTTP call fails.
- `data/data_sources/address_location_data_source.dart` — `Placemark` extraction expanded to populate the structured fields the platform geocoder already provides (`subLocality`, `locality`, `administrativeArea`, `isoCountryCode`, `postalCode`).
- All 5 use cases (`save`, `update`, `get_current_location`, `reverse_geocode`, `get_place_details`) — pass-through plumbing.
- `presentation/providers/map_picker_state.dart` — added `details: PlaceDetails?` to state.
- `presentation/providers/map_picker_notifier.dart` — `onMapPanEnd` and `updateLocation` store the full `PlaceDetails`. `save()` pulls structured fields off `details` and forwards them to `SaveAddressUseCase`.
- `presentation/providers/location_search_notifier.dart` — `selectPlace` calls `mapPickerProvider.notifier.updateLocation(details)` with the new signature.
- `presentation/providers/dependency_injection.dart` — added `geocodingDataSource(Ref ref)` factory that picks `Google` or `Nominatim` based on `String.fromEnvironment('GOOGLE_MAPS_API_KEY')`.

**Tests**
- `test/features/customer/addresses/data/repositories/address_repository_impl_test.dart` — `MockGoogleMapsRemoteDataSource` → `MockGeocodingDataSource`.
- `test/features/customer/addresses/presentation/providers/map_picker_notifier_test.dart` — record literals replaced with `PlaceDetails`. `verify()` now asserts the structured fields propagate (`suburb: 'Gulberg III'`, `city: 'Lahore'`, `country: 'PK'`, `localityLabel: 'Gulberg III, Lahore'`).
- `lib/features/customer/addresses/ADDRESSES_FEATURE.md` — entity table extended, repo signatures updated, port-and-adapter section added, prod swap documented.

## Verification

| What | Result |
| :--- | :--- |
| Backend: `pytest tests/customers/` | ✅ 103/103 |
| Backend: `pytest tests/bookings/` | ✅ 99/99 (sanity — they read `CustomerAddress`) |
| Backend: `pytest tests/technicians/` | ✅ 53/53 (dashboard reads `street_address`/`lat`/`lng` only — untouched columns) |
| Frontend: `flutter test test/features/customer/addresses/` | ✅ 29/29 |
| Frontend: `flutter analyze lib test` | ✅ 0 new errors/warnings on changed files |
| Migration applied to dev DB | ✅ `0004_customeraddress_city_customeraddress_country_and_more` |
| 5 pre-existing realtime test failures (`event_remote_data_source_test.dart`, `ws_connection_notifier_test.dart`) | ⏸ unchanged from `main`. Confirmed pre-existing by stashing the diff and re-running. |
| On-device smoke test | ❌ **NOT performed.** User to verify the map picker save flow end-to-end before pushing to prod. |

## Tech-debt logged

Two flags written into `flag.md` at task wrap-up, both proposed to user before writing:

- **`flag.md #15` — Backend trusts client-supplied locality fields.** Departure from CLAUDE.md "never trust Flutter input" rule, justified for display-only data. Proper-fix path = server-side `verify_locality_consistency` selector + Celery on-commit verification, only if abuse appears.
- **`flag.md #16` — `GOOGLE_MAPS_API_KEY` absent silently falls back to Nominatim.** TOS-violation footgun in prod. Proper fix = release-mode hard assertion or explicit `GEOCODING_PROVIDER` dart-define. Must be closed before first prod build.

## Carry-overs that remain valid

The "Notes for the *next* session" section above (the `job_new_request` payload, frontend rendering of the new `locationLabel`, this-session flag rollout note) is **still the right next-step list**. The pivot didn't change what comes after — only how this session shipped the underlying schema and wire shape.
