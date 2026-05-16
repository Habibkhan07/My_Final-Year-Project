# Technician Skills CRUD API
**Base URL**: `/api/technicians/me/skills/`

Backs the Profile tab's "My Skills" surface. The URL never carries a `technician_id` — every operation scopes to `request.user.tech_profile`. IDOR-impossible by design.

**Auth** — JWT (`IsAuthenticated`). Anonymous → `401 unauthorized`. Logged-in user without a `TechnicianProfile` → `403 permission_denied`.

**Category gate** — `POST` enforces that the parent service of the requested sub-service is in the tech's onboarded categories — i.e. they hold a `TechnicianServiceLicense` row for that service. Onboarding finalize auto-creates one license row per parent service the tech picks skills under (the `license_picture` field is optional; the *row* is the gate), so every approved tech has a non-empty license set. Without this gate, an approved plumber could silently start taking AC Repair jobs by adding the skill post-approval, with no admin re-evaluation. See `category_not_allowed` below.

We anchor on `TechnicianServiceLicense` (the table) rather than `TechnicianSkill` parent-service derivation: this lets a tech drop every skill under a category and still re-add later — the license row survives skill churn, so "what categories did I opt into at onboarding" is decoupled from "what skills do I currently offer."

---

## GET `/api/technicians/me/skills/`

Returns the caller's skill rows, ordered by parent service name (asc) then sub-service name (asc) so the FE can render a service-grouped list without a second pass.

### 200 OK
```json
[
  {
    "id": 17,
    "sub_service": {
      "id": 5,
      "name": "AC Repair",
      "icon_name": "ac_repair",
      "is_fixed_price": false,
      "service": {
        "id": 2,
        "name": "HVAC",
        "icon_name": "hvac"
      }
    }
  }
]
```

**Dumb-UI fields:**
- `sub_service.icon_name` → maps to `assets/icons/<icon_name>.svg` on the FE via `IconAssets.path()`. SVG ships with the Flutter app, not the backend.
- `sub_service.is_fixed_price` → optional "Fixed-price gig" sub-label on each row.

**No N+1** — selector uses `select_related('sub_service__service')`. Tested via `django_assert_max_num_queries(5)` on a 20-row list.

---

## POST `/api/technicians/me/skills/`

Add a sub-service to the caller's skill set.

### Request
```json
{ "sub_service_id": 5 }
```

The endpoint deliberately accepts only `sub_service_id`. The service writes:
- `years_of_experience = 0`
- `labor_rate = NULL`

The `labor_rate` column stays on the model for back-compat with `bookings.pricing_selector`; the onboarding-refactor session will decide whether to drop it.

### 201 Created
Same shape as one element of the GET response.

### 400 `validation_error`
Missing or non-integer `sub_service_id`.

### 404 `not_found`
The `sub_service_id` does not resolve to a catalog row. Returned by the service, not the FK constraint, so the message is a clean envelope.

### 409 `duplicate_skill`
The caller already has this sub-service in their skill set.

```json
{
  "status": 409,
  "code": "duplicate_skill",
  "message": "You already have this skill.",
  "errors": { "sub_service_id": ["5"] }
}
```

### 403 `category_not_allowed`
The caller is approved as a technician but has no `TechnicianServiceLicense` row for the parent service of the requested sub-service — i.e. they didn't opt into this category at onboarding. The category gate fires before the duplicate check and before the create, so the bridge row is never written. `service_name` in the `errors` map carries the parent service's display name so the FE can name the category in the snackbar.

The message is intentionally neutral — it states the rule rather than promising a "contact support" flow the platform doesn't yet implement.

```json
{
  "status": 403,
  "code": "category_not_allowed",
  "message": "HVAC is not in the categories you chose at onboarding.",
  "errors": { "service_name": ["HVAC"] }
}
```

---

## GET `/api/technicians/me/service-categories/`

Returns the service tree filtered to the categories the caller opted into at onboarding — i.e. services for which they hold a `TechnicianServiceLicense` row. The Add Skill picker hits this instead of the broader `/onboarding/metadata/` endpoint so the tech only sees sub-services they're qualified to add.

The wire shape is identical to `/onboarding/metadata/` — the FE reuses the `AvailableServiceModel` parser.

### 200 OK
```json
[
  {
    "id": 2,
    "name": "HVAC",
    "icon_name": "hvac",
    "sub_services": [
      {
        "id": 5,
        "name": "AC Repair",
        "base_price": "1500.00",
        "max_price": "3000.00",
        "icon_name": "ac_repair",
        "is_fixed_price": false
      }
    ]
  }
]
```

A tech with zero `TechnicianServiceLicense` rows would see `[]`, but this state is unreachable in practice: onboarding finalize auto-creates one row per parent service the tech picks skills under, and the migration backfilled existing techs accordingly. The state is only reachable via out-of-band admin intervention (manually deleting every license row for a tech). The backend write path (`POST /me/skills/`) enforces the same gate independently, so this filter is defence-in-depth rather than the sole check.

---

## DELETE `/api/technicians/me/skills/<sub_service_id>/`

Remove a sub-service from the caller's skill set. Keyed by `sub_service_id` (the catalog row), not by the bridge-row PK — semantically the operation is "remove this specialty from my skills".

### 204 No Content
Row removed.

### 404 `not_found`
No bridge row exists for this `(caller, sub_service_id)` pair. IDOR-safe: passing another tech's `sub_service_id` also returns 404 (their bridge row exists but not for the caller).

### 400 `last_skill_required`
Removing this row would leave the caller with zero skills. A skill-less technician is invisible to the matchmaker, so the operation is rejected.

```json
{
  "status": 400,
  "code": "last_skill_required",
  "message": "You must keep at least one skill. Add a new skill before removing this one.",
  "errors": {}
}
```

The guard fires before the delete; the row is preserved on rejection. Wrapped in `transaction.atomic()` + `select_for_update()` on the target skill so two concurrent removes cannot race past the count check.

---

## Security notes

- **IDOR** — every query in the selector and service is scoped to `technician=request.user.tech_profile`. No path parameter takes a `technician_id`. The DELETE detail route accepts a `sub_service_id` but resolves the bridge row by `(caller_tech, sub_service)`.
- **Race conditions** — DELETE uses `transaction.atomic()` + `select_for_update()` on the skill row to serialise the count guard.
- **Mass assignment** — POST serializer accepts only `sub_service_id`. `years_of_experience` and `labor_rate` are server-controlled.
- **Catalog validation** — POST resolves `SubService.objects.get(...)` before writing, so an invalid id produces a 404, not a 500 from an FK violation.
