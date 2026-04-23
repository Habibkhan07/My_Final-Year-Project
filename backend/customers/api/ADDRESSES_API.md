# Customer Addresses API

Base path: `/api/customers/addresses/`
All endpoints require `Authorization: Token <token>`.

---

## GET /api/customers/addresses/

Returns all saved addresses for the authenticated user, ordered default-first.

**Response 200**
```json
[
  {
    "id": 1,
    "label": "Home",
    "street_address": "123 Main St, Lahore",
    "latitude": "31.520400",
    "longitude": "74.358700",
    "is_default": true,
    "created_at": "2026-04-23T12:00:00Z"
  }
]
```

---

## POST /api/customers/addresses/

Creates a new address for the authenticated user. If `is_default` is `true`, all other addresses for this user are atomically set to `false`.

**Request body**
```json
{
  "label": "Office",
  "street_address": "456 DHA Phase 5, Lahore",
  "latitude": "31.4697",
  "longitude": "74.4093",
  "is_default": false
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
