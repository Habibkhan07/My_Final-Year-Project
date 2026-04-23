# BOOKINGS API CONTRACT
**Project**: Home Services Marketplace App
**Status**: Living Documentation

---

## 1. INSTANT BOOKING

### 1.1 Create Instant Booking
**Description**: The checkout endpoint. Creates a `CONFIRMED` `JobBooking` after passing four sequential defensive checks: address ownership, technician approval status, geofence, and an atomic race-condition lock on the technician's schedule. Called immediately after the customer selects a time slot from the Availability endpoint (`/api/customers/technicians/{id}/availability/`).

**URL**: `/api/bookings/instant-book/`
**Method**: `POST`
**Auth**: Required (`IsAuthenticated`). Send token in the `Authorization: Token <token>` header.

---

#### Request Body (`application/json`)

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `technician_id` | int | **Yes** | Primary key of the `TechnicianProfile` to book. |
| `address_id` | int | **Yes** | Primary key of the `CustomerAddress` for the job location. Must belong to the authenticated user. |
| `scheduled_start` | string (ISO 8601) | **Yes** | Job start time. Must be a timezone-aware datetime (e.g., PKT `+05:00` from the slot's `iso_start` field). |
| `scheduled_end` | string (ISO 8601) | **Yes** | Job end time. Must be strictly after `scheduled_start`. Pass the slot's `iso_end` field directly. |
| `price_amount` | string (Decimal) | **Yes** | The agreed price in PKR, as a decimal string (e.g., `"1500.00"`). |
| `price_context` | string | No | Short display label for the UI receipt (max 50 chars, e.g., `"AC Repair — 2 hrs"`). Defaults to empty string. |

**Flutter integration note**: `scheduled_start` and `scheduled_end` should be taken directly from the `iso_start` / `iso_end` fields returned by the Availability endpoint — no timezone conversion needed.

#### Sample Request
```json
{
  "technician_id": 42,
  "address_id": 7,
  "scheduled_start": "2026-04-08T10:00:00+05:00",
  "scheduled_end": "2026-04-08T11:00:00+05:00",
  "price_amount": "1500.00",
  "price_context": "AC Repair"
}
```

---

#### Response Contract (201 Created)
```json
{
  "booking_id": 123
}
```

| Field | Type | Description |
| :--- | :--- | :--- |
| `booking_id` | int | Primary key of the newly created `JobBooking`. Store this for the Active Job Screen and crash recovery (Tier 3 cache). |

---

#### Defensive Check Pipeline

The service runs these checks in strict order. The first failure short-circuits and returns the appropriate error — no check is skipped.

| # | Check | Implementation | Failure Response |
| :--- | :--- | :--- | :--- |
| 1 | **Address Ownership** | `CustomerAddress.objects.get(id=address_id, customer__user=request.user)` | 400 `validation_error` |
| 2 | **Technician Status** | `TechnicianProfile.objects.filter(status='APPROVED').get(pk=technician_id)` | 404 `not_found` |
| 3 | **Geofence** | Haversine distance ≤ `tech.max_travel_radius_km` | 400 `out_of_service_area` |
| 4 | **Slot Race Lock** | `transaction.atomic()` + `select_for_update()` + overlap query | 409 `slot_unavailable` |

**Why this order?** Address check is cheapest (single indexed lookup). Technician fetch is next. Geofence requires both models to be loaded. The DB lock is last because acquiring it is the most expensive operation.

#### Geofence Detail
- Distance is calculated using the **Haversine formula** (great-circle distance).
- The cap is `tech.max_travel_radius_km` — set per-technician during onboarding.
- If the technician has no `base_latitude` / `base_longitude` set, the check always fails with `out_of_service_area`.
- The error message includes the actual distance and the technician's radius for Flutter to display (e.g., *"Your address is 14.2 km away (limit: 10 km)"*).

#### Race Condition Detail
- Uses `transaction.atomic()` + `SELECT FOR UPDATE` on the technician row to serialize concurrent booking attempts.
- Overlap check uses **half-open interval semantics**: `existing.scheduled_start < new.scheduled_end AND existing.scheduled_end > new.scheduled_start`. A booking starting exactly when another ends is **not** a conflict.
- Only `PENDING` and `CONFIRMED` bookings block a slot. `CANCELLED`, `REJECTED`, and `COMPLETED` do not.

---

#### Error Envelopes

All errors follow the standard envelope contract.

**401 — Unauthenticated**
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Unauthorized.",
  "errors": {}
}
```

**400 — Validation Error** (missing / invalid field)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid booking data.",
  "errors": {
    "scheduled_end": ["scheduled_end must be after scheduled_start."]
  }
}
```

**400 — Invalid Address** *(IDOR-safe: same response whether address doesn't exist or belongs to another user)*
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid address.",
  "errors": {
    "address_id": ["No matching address found for this account."]
  }
}
```

**404 — Technician Not Found** (non-existent, PENDING, or REJECTED)
```json
{
  "status": 404,
  "code": "not_found",
  "message": "Technician not found.",
  "errors": {}
}
```

**400 — Out of Service Area**
```json
{
  "status": 400,
  "code": "out_of_service_area",
  "message": "This technician does not service your area. Your address is 14.2 km away (limit: 10 km).",
  "errors": {}
}
```

**409 — Slot Unavailable** *(another customer booked this slot between your availability check and this request)*
```json
{
  "status": 409,
  "code": "slot_unavailable",
  "message": "This time slot was just booked. Please choose another.",
  "errors": {}
}
```

---

#### Flutter Integration Guide

```
Availability Screen (Endpoint 1.4)
  ↓  customer taps a slot
  slot.iso_start → scheduled_start
  slot.iso_end   → scheduled_end

Checkout Screen
  ↓  customer confirms price + address
  POST /api/bookings/instant-book/
  
On 201 → store booking_id in Tier 3 cache (crash recovery)
       → navigate to Active Job Screen

On 409 → show "This slot was just taken" Snackbar
       → pop back to Availability Screen so customer can pick again

On 400 out_of_service_area → show error.message directly (already human-readable)
On 400 validation_error    → highlight error.errors fields in the form
On 404                     → show generic "Technician not available" and navigate back
```
