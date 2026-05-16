# API CONTRACT & DOCUMENTATION
**Project**: Home Services Marketplace App
**Status**: Living Documentation
**Domain**: Accounts (Authentication)

## Overview

Phone-based OTP authentication. No passwords. Every user (Customer or Technician) goes through the same two-step flow:

1. Submit phone → receive SMS OTP
2. Submit phone + OTP → receive Auth Token + state flags

---

## Phone Number Format

The API accepts Pakistani mobile numbers in **either** format:

| Format | Example | Notes |
|---|---|---|
| Local | `03001234567` | 11 digits, starts with `03` |
| E.164 | `+923001234567` | Country code prefix |

The backend normalises both to E.164 (`+92...`) before storing and sending to Twilio. Flutter can send either — consistent E.164 is recommended.

Valid network prefixes: `030`–`036` only. Landlines and non-PK numbers are rejected.

---

## 1.1 Initiate Phone Login (Request OTP)

**Description**: Validates the phone number, generates a 6-digit OTP, stores it server-side with a **30-second expiry**, and dispatches an SMS via Twilio.

**URL**: `/api/accounts/login-otp/`
**Method**: `POST`
**Auth**: None

### Request Payload
```json
{
  "phone": "03001234567"
}
```

### Response — 200 OK
```json
{
  "message": "OTP sent successfully"
}
```

### Error Envelopes

**400 — Invalid phone format**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid input data.",
  "errors": {
    "phone": ["Enter a valid Pakistani mobile number (e.g. 03001234567 or +923001234567)."]
  }
}
```

**400 — SMS delivery failed** (Twilio error — e.g. unverified number on trial account)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Failed to send OTP via SMS: <twilio error message>",
  "errors": {}
}
```

---

## 1.2 Verify OTP

**Description**: Verifies the 6-digit OTP against the stored record for that phone number. On success, creates a new user (if first time) or logs in the existing one, and returns an Auth Token with UI routing flags.

**Registration Side-Effects**: For new users, this endpoint automatically initializes:
1.  `UserProfile` (accounts app) — holds phone and role info.
2.  `CustomerProfile` (customers app) — required for the booking system.
3.  **Default Address**: A "Home" address (Lahore, Pakistan) is created immediately so that the booking flow ("Confirm & Lock") works without requiring manual address setup in the prototype.

**URL**: `/api/accounts/verify-otp/`
**Method**: `POST`
**Auth**: None

### Request Payload
```json
{
  "phone": "03001234567",
  "otp": "482910"
}
```
> `otp` must be exactly 6 digits.

### Response — 200 OK
```json
{
  "token": "abc123xyz890tokenstring...",
  "is_technician": false,
  "name_required": true,
  "new_user": true
}
```

#### "Dumb UI" State Flags — Flutter Routing Logic

| Field | Type | Meaning |
|---|---|---|
| `token` | `string` | Django Token Auth — store in `flutter_secure_storage`, attach as `Authorization: Token <token>` on all authenticated requests |
| `new_user` | `bool` | `true` = first login; `false` = returning user |
| `name_required` | `bool` | `true` → redirect to Complete Profile screen; `false` → proceed to home |
| `is_technician` | `bool` | `true` → user has a TechnicianProfile (approved or pending); drives bottom nav / home screen variant |

**Routing matrix:**

```
new_user=true  → Complete Profile screen (name_required will also be true)
new_user=false, name_required=true  → Complete Profile screen (edge case: incomplete old account)
new_user=false, name_required=false, is_technician=false → Customer Home
new_user=false, name_required=false, is_technician=true  → Technician Home
```

### Error Envelopes

**400 — OTP field validation (wrong length, missing)**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid input data.",
  "errors": {
    "otp": ["Ensure this field has no more than 6 characters."]
  }
}
```

**400 — No OTP on record (never requested, or all records used)**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "No OTP found for this number. Please request a new one.",
  "errors": {
    "otp": ["No OTP found for this number. Please request a new one."]
  }
}
```

**400 — OTP expired (past 30-second window)**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "OTP has expired. Please request a new one.",
  "errors": {
    "otp": ["OTP has expired. Please request a new one."]
  }
}
```

**400 — Incorrect OTP code**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid OTP.",
  "errors": {
    "otp": ["Invalid OTP."]
  }
}
```

---

## 1.3 Complete Profile

**Description**: Sets the user's first and last name. Only required when `name_required=true` is returned from Verify OTP.

**URL**: `/api/accounts/complete-signup/`
**Method**: `POST`
**Auth**: `Authorization: Token <token>`

### Request Payload
```json
{
  "first_name": "Ali",
  "last_name": "Raza"
}
```

### Response — 200 OK
```json
{
  "message": "Profile updated successfully."
}
```

### Error Envelopes

**401 — Missing or invalid token**
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Unauthorized.",
  "errors": {
    "detail": "Authentication credentials were not provided."
  }
}
```

**400 — Missing name fields**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "First and last name are required.",
  "errors": {}
}
```

---

## 1.4 Logout

**Description**: Invalidates the caller's auth token **server-side**. After this call returns, the token bytes that authenticated this request are dead — any further requests carrying them get a 401. The Flutter app calls this BEFORE clearing local secure storage (so the token is still attached to this request), then clears storage regardless of the response so the user always lands at `/login`.

**URL**: `/api/accounts/logout/`
**Method**: `POST`
**Auth**: `Authorization: Token <token>`

### Request Payload
_None._

### Response — 204 No Content
Empty body. Do not attempt to JSON-decode.

### Behaviour Notes

- **Idempotent at the service layer**: `auth_service.logout(user=...)` is `Token.objects.filter(user=user).delete()`, which is a 0-row no-op when nothing matches. This protects the FE's retry-after-network-blip path.
- **Token row is gone**: the same token bytes return `401` on the very next request. There is no soft-expire / grace window.
- **All-sessions revoke is implicit**: DRF's default `Token` model is one-token-per-user, so logging out on one device kills every session. This is *too* aggressive but defensible — lost-phone scenarios kill all sessions, which is the safer property at the cost of UX. Per-device tokens land with `knox` in v1.1.

### Error Envelopes

**401 — Missing, invalid, or already-revoked token**
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Unauthorized.",
  "errors": {
    "detail": "Invalid token."
  }
}
```

---

## 2. Profile (`/me/`)

The "me" surface is the authenticated user's own profile — name, phone (read-only), and the `is_technician` flag (read-only, flips only through admin approval of a TechnicianProfile). All edits flow through `PATCH`.

### Authorization model

Every call requires `Authorization: Token <token>`. The view resolves `request.user` from the header — there is **no** `user_id` in the URL, body, or query. The endpoint can only ever read or write the caller's own row.

---

## 2.1 Get Me

**Description**: Returns the current user's profile in a single response. The FE caches this under `cached_profile_me` (Tier 2) for offline-first.

**URL**: `/api/accounts/me/`
**Method**: `GET`
**Auth**: `Authorization: Token <token>`

### Response — 200 OK
```json
{
  "id": 17,
  "first_name": "Ali",
  "last_name": "Raza",
  "phone": "+923001234567",
  "is_technician": false
}
```

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | `auth.User.id`. Powers the realtime recipient filter (flag #19). |
| `first_name` | `string` | Editable via PATCH. |
| `last_name` | `string` | Editable via PATCH. |
| `phone` | `string` | E.164 PK number. **Read-only here** — changing requires the re-OTP flow. |
| `is_technician` | `bool` | Sourced from `UserProfile.is_technician`. **Read-only here** — flips only when admin approves a TechnicianProfile. |

### Error Envelopes

**401 — Missing or invalid token** — same shape as section 1.4.

---

## 2.2 Update Me

**Description**: Partial profile update. The serializer whitelists exactly `first_name` and `last_name`; any other fields in the request body are silently dropped before reaching the service (mass-assignment guard). Response body is the **full fresh state**, not just the patched fields — the FE notifier swaps its cached row directly from this response.

**URL**: `/api/accounts/me/`
**Method**: `PATCH`
**Auth**: `Authorization: Token <token>`

### Request Payload
```json
{
  "first_name": "Hamza",
  "last_name": "Khan"
}
```

Both fields are required by the serializer. If you only want to change one, send the other one back with its current value (the FE does this — it pre-fills both fields from the GET response and submits both on save).

### Response — 200 OK
Same shape as `GET /me/`, reflecting the post-update state:
```json
{
  "id": 17,
  "first_name": "Hamza",
  "last_name": "Khan",
  "phone": "+923001234567",
  "is_technician": false
}
```

### Error Envelopes

**400 — Empty or missing name field**
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid input data.",
  "errors": {
    "first_name": ["This field may not be blank."]
  }
}
```

The FE error pipeline reads `errors.first_name[0]` and `errors.last_name[0]` for field-level highlighting on the edit screen.

**401 — Missing or invalid token** — same shape as section 1.4.

### Fields that look writeable but are NOT

Sending these in the PATCH body is harmless — they are dropped at the serializer boundary and never reach the service:

| Field | Why blocked |
|---|---|
| `phone` | Auth identity. Changes require re-OTP. |
| `is_technician` | Flips only through admin approval of a TechnicianProfile. |
| `is_staff`, `is_superuser` | Privilege-escalation surface. Admin-only via Django Admin. |
| `id` | Primary key. Immutable. |
