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
