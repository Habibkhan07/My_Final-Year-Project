# Customer Addresses API

Base path: `/api/customers/addresses/`
All endpoints require `Authorization: Token <token>`.

---

## Address shape — fields

| Field | Type | Source | Notes |
| :--- | :--- | :--- | :--- |
| `id` | int | server | |
| `label` | string | client | "Home", "Office", … |
| `street_address` | string | client | The geocoder's `formatted_address` (display string) |
| `latitude` | string (decimal) | client | Trusted source for distance/matchmaking |
| `longitude` | string (decimal) | client | Trusted source for distance/matchmaking |
| `is_default` | bool | client | Server enforces "exactly one default per user" |
| `created_at` | ISO datetime | server | |
| `neighborhood` | string \| null | client | Reverse-geocoded |
| `suburb` | string \| null | client | Reverse-geocoded |
| `city` | string \| null | client | Reverse-geocoded |
| `state` | string \| null | client | Reverse-geocoded |
| `country` | string \| null | client | ISO-3166 alpha-2, e.g. `"PK"` |
| `postal_code` | string \| null | client | Reverse-geocoded |
| `locality_label` | string \| null | client | Composed display label, e.g. `"Gulshan-e-Iqbal, Karachi"` |

> **Geocoding boundary**: the Flutter map-picker reverse-geocodes the picked coordinate (Google Maps in prod, OSM Nominatim in dev) and POSTs the structured fields. The backend stores them verbatim — it does **not** re-derive them. `latitude`/`longitude` remain the trusted source for distance/matchmaking; the structured fields are display-only and may be stale or partially populated.

---

## GET /api/customers/addresses/

Returns all saved addresses for the authenticated user, ordered default-first.

**Response 200**
```json
[
  {
    "id": 1,
    "label": "Home",
    "street_address": "Block 4, Gulshan-e-Iqbal, Karachi, Pakistan",
    "latitude": "24.917000",
    "longitude": "67.097000",
    "is_default": true,
    "created_at": "2026-04-23T12:00:00Z",
    "neighborhood": null,
    "suburb": "Gulshan-e-Iqbal",
    "city": "Karachi",
    "state": "Sindh",
    "country": "PK",
    "postal_code": "75300",
    "locality_label": "Gulshan-e-Iqbal, Karachi"
  }
]
```

Legacy rows created before this rollout have `null` for every structured field. UI should fall back to `street_address` when `locality_label` is null.

---

## POST /api/customers/addresses/

Creates a new address for the authenticated user. If `is_default` is `true`, all other addresses for this user are atomically set to `false`.

The 5 original fields (`label`, `street_address`, `latitude`, `longitude`, `is_default`) are **required**. The 7 structured locality fields are **optional** and **nullable** — older clients during rollout may omit them entirely; rural locations may have only a `city` populated, etc.

**Request body**
```json
{
  "label": "Office",
  "street_address": "F-7 Markaz, Islamabad, Pakistan",
  "latitude": "33.7167",
  "longitude": "73.0588",
  "is_default": false,

  "neighborhood": null,
  "suburb": "F-7",
  "city": "Islamabad",
  "state": "Islamabad Capital Territory",
  "country": "PK",
  "postal_code": "44000",
  "locality_label": "F-7, Islamabad"
}
```

**Response 201** — same shape as GET list item.

**Error 400**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Please fix the errors below.",
  "errors": {
    "street_address": ["This field is required."]
  }
}
```

---

## PATCH /api/customers/addresses/<id>/

Updates an existing address. Used to toggle `is_default: true` or to re-supply structured locality fields when the user re-picks a location on the map.

**Request body (partial)**
```json
{
  "is_default": true
}
```

When the user re-picks a location, the client should PATCH lat/lng **and** the structured fields together so the cached label stays consistent with the coordinates:

```json
{
  "latitude": "31.469700",
  "longitude": "74.409300",
  "street_address": "DHA Phase 5, Lahore",
  "suburb": "DHA Phase 5",
  "city": "Lahore",
  "state": "Punjab",
  "country": "PK",
  "postal_code": null,
  "locality_label": "DHA Phase 5, Lahore"
}
```

**Response 200** — same shape as GET list item.

---

## DELETE /api/customers/addresses/<id>/

Deletes a saved address owned by the authenticated user.

**Response 204** — no body.

**Error 404**
```json
{
  "status": 404,
  "code": "not_found",
  "message": "Address not found.",
  "errors": {}
}
```

> **Dumb UI note**: Flutter should not compute which address is "default" — read `is_default` from the API. To change the default, POST a new address with `is_default: true`; the backend clears the old one atomically.
>
> **Locality label composition** lives on the client (one source of truth with the geocoder that produced the structured fields). If the rule changes, only the Flutter mapper is updated; backend stores the new label on next save.
