# Reviews API

Customer-side technician review surface. Two URL families, three operations.

| Family | Owner module | Mounted from |
|---|---|---|
| `/api/bookings/<booking_id>/review/` | `technicians.api.reviews` (view) | `bookings.api.urls` |
| `/api/technicians/<technician_id>/reviews/` | `technicians.api.reviews` (view) | `technicians.api.urls` |

The booking-scoped endpoint reads as "*a review for this specific job I booked*". The technician-scoped endpoint reads as "*all reviews for this technician*". Each lives under its semantic parent resource.

---

## 1. `GET /api/bookings/<booking_id>/review/`

Fetches the customer's existing review for a booking (or `null` if not yet submitted), plus the predefined tag vocabulary the UI needs to render the rating form.

### Auth
`Authorization: Token <token>` — required. Customer-scoped: a non-owner sees `review: null`, identical to the never-submitted case (no IDOR leak).

### Query params
None.

### Response 200
```json
{
  "review": null,
  "predefined_tags": {
    "positive": [
      {"key": "on_time",      "label": "On time"},
      {"key": "professional", "label": "Professional"},
      {"key": "quality_work", "label": "Quality work"},
      {"key": "clean",        "label": "Clean"},
      {"key": "polite",       "label": "Polite"},
      {"key": "fair_price",   "label": "Fair price"}
    ],
    "constructive": [
      {"key": "late",       "label": "Late"},
      {"key": "messy",      "label": "Messy"},
      {"key": "rude",       "label": "Rude"},
      {"key": "overpriced", "label": "Overpriced"},
      {"key": "incomplete", "label": "Incomplete work"},
      {"key": "unsafe",     "label": "Unsafe"}
    ]
  }
}
```

When a review has been submitted:
```json
{
  "review": {
    "id": 42,
    "rating": 4,
    "tags": ["on_time", "professional"],
    "text": "Solid work.",
    "created_at": "2026-05-18T13:42:11.103Z",
    "reviewer_name": "Hamayon W."
  },
  "predefined_tags": { ... }
}
```

### Dumb-UI fields
- `review` — switch between the rating form (when `null`) and the thank-you recap (when present). Frontend never derives this from the booking status; the GET response is authoritative.
- `predefined_tags.positive` — chip set to render when the customer's selected rating is **≥ 4**.
- `predefined_tags.constructive` — chip set to render when selected rating is **≤ 3**.
- `reviewer_name` — already composed safely as `"First L."` server-side; the frontend renders it as-is. **Never** compose names client-side from a customer's user object — the safe form is the wire contract.

### Errors
- `401 unauthenticated` — token missing or invalid.

No `404` for missing bookings: a non-existent booking returns `review: null` + tag dictionary (the response is fundamentally the same shape for never-reviewed and never-existed cases, by design — no enumeration leak).

---

## 2. `POST /api/bookings/<booking_id>/review/`

Submits the customer's review of a completed booking. Idempotent at the DB layer (`Review.booking` is `OneToOneField`) and at the service layer (typed 409 short-circuits before INSERT).

### Auth
`Authorization: Token <token>` — required. Customer-scoped.

### Body
```json
{
  "rating": 5,
  "tags": ["on_time", "professional"],
  "text": "Optional free-text comment, max 500 chars."
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `rating` | int | yes | 1–5 inclusive |
| `tags` | string[] | no (default `[]`) | Keys MUST be from the `predefined_tags` dictionary returned by the GET. Duplicates are deduped server-side. |
| `text` | string | no (default `""`) | Max 500 chars. |

### Response 201
```json
{
  "id": 42,
  "rating": 5,
  "tags": ["on_time", "professional"],
  "text": "",
  "created_at": "2026-05-18T13:42:11.103Z",
  "reviewer_name": "Hamayon W."
}
```

On 201, the backend has already:
1. Inserted the `Review` row.
2. Recomputed `TechnicianProfile.rating_average` + `review_count` (Bayesian R/v for the profile-level matchmaking fallback).
3. Recomputed `TechnicianServicePerformance.rating_average` + `review_count` for the booking's parent service (the Bayesian R/v matchmaking reads for the service-aware path).

All three writes happen in the same `transaction.atomic` block under `select_for_update` on the booking + technician rows — no partial state is observable.

### Error envelopes

#### 400 — `review_not_eligible`
Booking is not in a terminal-success status.
```json
{
  "status": 400,
  "code": "review_not_eligible",
  "message": "This booking is not eligible for a review yet.",
  "errors": {"booking_status": ["CONFIRMED"]}
}
```
Eligible statuses: `COMPLETED`, `COMPLETED_INSPECTION_ONLY`.

#### 400 — `validation_error` (rating / tag / text shape)
DRF's standard envelope. Field map under `errors`. The `tags` field error names the offending key(s).
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "...",
  "errors": {"tags": ["Unknown tag(s): foo, bar"]}
}
```

#### 401 — `unauthenticated`

#### 404 — `booking_not_found`
Booking does not exist OR is owned by a different customer (indistinguishable — IDOR-safe).
```json
{
  "status": 404,
  "code": "booking_not_found",
  "message": "Booking not found.",
  "errors": {}
}
```

#### 409 — `review_already_submitted`
A review already exists for this booking. The first-write rating wins; this is not an upsert.
```json
{
  "status": 409,
  "code": "review_already_submitted",
  "message": "You've already reviewed this booking.",
  "errors": {}
}
```

---

## 3. `GET /api/technicians/<technician_id>/reviews/`

Public paginated list of all reviews for a technician. Surfaces the "All reviews" sheet on the customer-facing tech profile screen.

### Auth
Not required. Public read so customers can read reviews pre-booking.

### Query params
| Param | Type | Default | Notes |
|---|---|---|---|
| `page_size` | int | 20 | Clamped to `[1, 100]`. |
| `cursor` | int | null | `id` of the last row from the previous page. |

### Response 200
```json
{
  "reviews": [
    {
      "id": 42,
      "rating": 5,
      "tags": ["on_time", "professional"],
      "text": "Solid work.",
      "created_at": "2026-05-18T13:42:11.103Z",
      "reviewer_name": "Hamayon W."
    },
    ...
  ],
  "next_cursor": 38,
  "has_more": true
}
```

### Dumb-UI fields
- `reviewer_name` — composed safely server-side. Never the full last name. Frontend renders as-is.
- `next_cursor` / `has_more` — frontend's infinite-scroll loader: `if (has_more) loadMore(cursor: next_cursor)`. Both fields are authoritative; do not derive `has_more` from `reviews.length`.

### Errors
- Malformed `cursor` / `page_size` — silently degraded to defaults (`cursor=null`, `page_size=20`). Selector clamps `page_size` to `[1, 100]`.

---

## How reviews feed matchmaking

`technicians.selectors.matchmaking_selectors._calculate_bayesian_score(v, R, C, m=10.0)` reads:
- `R` = raw running average from `TechnicianServicePerformance.rating_average` (service-aware path) or `TechnicianProfile.rating_average` (general nearby listing fallback).
- `v` = `review_count` from the same row.
- `C` = platform-wide average via `aggregate(Avg('rating_average'))` over all matching performance rows.
- `m=10` is the trust prior — caps the influence of low-review-count techs.

The review service writes `R` + `v` as **raw running averages**, never the Bayesian-computed value. The selector applies the formula on read. This means a freshly-submitted review is reflected in the next dispatch with **zero additional wiring** — no signal, no Celery task, no cache invalidation.

The atomic transaction in `submit_review` guarantees that a customer reading the tech's profile immediately after submitting their review sees the updated `rating_average` (no read-your-write skew).

---

## Frontend wire contract

The frontend's `BookingReviewBody` widget consumes the GET response and switches between:
- **Form body** (`review: null`) — renders stars, tag chips swapped by selected rating, optional comment field, submit button.
- **Recap body** (`review` populated) — renders the submitted review as a static card with a "Thank you" affordance.

After a successful POST, the frontend invalidates the GET provider so the screen flips to the recap body without a manual reload.

Adding a new tag key:
1. Append to `technicians/constants/review_tags.py`.
2. Restart Django/Celery — no migration needed (`Review.tags` is a JSON column).
3. Frontend picks up the new chip on the next GET request to `/api/bookings/<id>/review/`.
