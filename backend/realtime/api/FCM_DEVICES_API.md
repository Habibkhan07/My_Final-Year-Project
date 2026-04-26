# FCM Devices — API Contract

Register and unregister Firebase Cloud Messaging device tokens for the
authenticated user. Tokens are **globally unique** across all users —
logging in with a different account on the same physical device
reassigns the token to the new user (and reactivates it).

All endpoints require `Authorization: Token <key>` (DRF authtoken).

---

## `POST /api/devices/register/`

Register or refresh a device token. Idempotent.

**Request Body**

```json
{
  "device_token": "cz1K…very-long-fcm-token",
  "device_type": "android"
}
```

| Field          | Type   | Constraints                            |
|----------------|--------|----------------------------------------|
| `device_token` | string | ≤ 500 chars, trimmed.                  |
| `device_type`  | enum   | `"android"` \| `"ios"`.                |

**Behaviour**

- Token unknown → created, `is_active=True`.
- Token already owned by the caller → reactivated + `device_type` refreshed.
- Token owned by a **different** user (account switch on same device) →
  reassigned to the caller + reactivated.

**Responses**

- `204 No Content` on success.
- `400 validation_error` — missing/invalid fields.
- `401 unauthorized` — token missing/invalid.

```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Invalid input data.",
  "errors": { "device_type": ["\"macos\" is not a valid choice."] }
}
```

---

## `POST /api/devices/unregister/`

Deactivate a token (does not delete — keeps the audit row).

**Request Body**

```json
{ "device_token": "cz1K…very-long-fcm-token" }
```

**Responses**

- `204 No Content` on success.
- `400 validation_error`.
- `401 unauthorized`.

**Security.** The update is scoped to `(user=request.user, device_token=...)`,
so a hostile caller cannot deactivate another user's token. If the token
does not exist or belongs to someone else the response is still `204` —
we do not leak ownership via error shape.

---

## Dumb-UI Fields

None. These are transport endpoints — the Flutter side issues them from
the push-notification bootstrap flow and displays nothing.

---

## Integration With The Dispatch Hub

`send_fcm_notification` (Celery) fans each `broadcast_event` out to every
**active** device for the recipient user:

```python
from realtime.devices.selectors import active_devices_for_user

devices = active_devices_for_user(user.id)
```

When FCM returns `UNREGISTERED` or `INVALID_ARGUMENT` for a token, the
task flips `is_active=False` automatically — no manual cleanup needed.

---

## Backend Implementation Structure

The `realtime` app is organized into two primary sub-modules for traceability:

- **`realtime.devices`**: Owns FCM device registration (`FCMDevice`) and the Celery background tasks.
- **`realtime.events`**: Owns persistence (`EventLog`), the Dispatch/ACK services, and WebSocket transport.
