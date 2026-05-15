# Technician Work Location — API

> One endpoint, one record. PATCH writes the matchmaker's discovery anchor; GET reads it for the picker screen's pre-fill.

## URLs

| Method | Path                                          | Name                  |
| ------ | --------------------------------------------- | --------------------- |
| GET    | `/api/technicians/me/work-location/`          | `tech-work-location`  |
| PATCH  | `/api/technicians/me/work-location/`          | `tech-work-location`  |

No PK in the URL — both methods operate on `request.user`'s `TechnicianProfile`. IDOR-impossible by design.

## Auth

`IsAuthenticated`. Anonymous → 401 with the standard error envelope.

## GET /api/technicians/me/work-location/

Returns the caller's work location (or the no-profile shape for pure customers).

### 200 — Approved/Pending/Rejected tech with location set

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

### 200 — Tech with no location yet

```json
{
  "has_profile": true,
  "is_set": false,
  "latitude": null,
  "longitude": null,
  "max_travel_radius_km": 10,
  "work_address_label": null
}
```

### 200 — Pure customer (no TechnicianProfile)

```json
{
  "has_profile": false,
  "is_set": false,
  "latitude": null,
  "longitude": null,
  "max_travel_radius_km": 10,
  "work_address_label": null
}
```

Returning 200 (not 404) here lets the FE router branch without a failure-path round-trip.

## PATCH /api/technicians/me/work-location/

Persists the caller's work location and travel radius.

### Request

```json
{
  "latitude": 31.5204,
  "longitude": 74.3587,
  "max_travel_radius_km": 12,
  "work_address_label": "Gulberg, Lahore"
}
```

| Field                  | Type    | Required | Constraints                |
| ---------------------- | ------- | -------- | -------------------------- |
| `latitude`             | float   | yes      | `-90 ≤ x ≤ 90`             |
| `longitude`            | float   | yes      | `-180 ≤ x ≤ 180`           |
| `max_travel_radius_km` | int     | no       | `1 ≤ x ≤ 100` (omit to keep existing) |
| `work_address_label`   | string  | no       | max 200 chars; null/"" clears it |

### 200 — Returns the same shape as GET

The FE re-reads through the selector after the write, so the response is identical to a fresh GET. This lets the picker cache the saved row with one PATCH and no follow-up GET.

### 400 — Validation envelope

```json
{
  "status": 400,
  "code": "validation_error",
  "message": "...",
  "errors": {
    "latitude": ["Ensure this value is greater than or equal to -90."]
  }
}
```

### 401 — Unauthenticated

Standard DRF 401; envelope's `code` is `not_authenticated`.

### 404 — Pure customer attempting PATCH

```json
{
  "status": 404,
  "code": "not_found",
  "message": "No technician profile for this user."
}
```

Returned because PATCH semantically modifies a resource that does not exist for this caller. (GET returns 200 with `has_profile: false` instead — it's a read.)

## Dumb UI fields

- `is_set` — the FE branches on this; never recomputes from lat/lng locally.
- `has_profile` — exists so the router can skip the picker entirely for pure customers without a 404 round-trip.
- `work_address_label` — display-only string; lat/lng remains the trusted source for distance/matchmaking.

## Side effects

After a successful PATCH, the matchmaker's bounding-box filter (`technicians/selectors/matchmaking_selectors.py`) starts returning this tech for customer searches within the radius. There is no separate "enable discovery" toggle — the row's presence in the discoverable set is exactly `base_latitude IS NOT NULL AND base_longitude IS NOT NULL AND status='APPROVED' AND is_online=True AND is_active=True`.

## Related

- `TechnicianProfile.{base_latitude, base_longitude, max_travel_radius_km, work_address_label}` — the row touched.
- `GET /api/technicians/dashboard/` — surfaces `has_work_location` (mirrors `is_set` from this endpoint) so the dashboard banner can render without a second call.
- `WORK_LOCATION_FEATURE.md` (Flutter) — frontend brief.
