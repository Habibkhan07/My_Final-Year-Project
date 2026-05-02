# API CONTRACT & DOCUMENTATION
**Project**: Home Services Marketplace App
**Status**: Living Documentation

## 1. CUSTOMER DOMAIN

### 1.1 Customer Home Feed Aggregator
**Description**: The Backend-For-Frontend (BFF) endpoint for the Customer Discovery Home Screen. It aggregates top categories, active promotional banners, featured "Instant Book" fixed-price gigs, and a Bayesian-scored list of nearby top-rated technicians.
**URL**: `/api/customers/home/`
**Method**: `GET`

#### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `lat` | float | No* | The raw latitude string of the user's current GPS location. |
| `lng` | float | No* | The raw longitude string of the user's current GPS location. |
*\*Note: If coordinates are missing, malformed, or invalid (e.g., `"null"`), the server safely swallows the error and falls back to a global top-technician list without crashing.*

#### Response Contract (Happy Path)
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Plumbing",
      "icon_name": "plumbing"
    }
  ],
  "promotions": [
    {
      "id": 1,
      "title": "Summer Promo",
      "banner_image_url": "https://example.com/media/promos/summer.png",
      "promo_description": "Get 20% OFF the total bill for AC Service!", 
      "button_text": "Claim Now" 
    }
  ],
  "fixed_gigs": [
    {
      "id": 1,
      "name": "AC General Wash",
      "base_price": "1500.00",
      "parent_category": "AC Service",
      "image_url": "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80"
    }
  ],
  "top_technicians": [
    {
      "id": 1,
      "full_name": "Ali Raza",
      "primary_category": "Plumbing", 
      "city": "LHR",
      "profile_picture": "https://example.com/media/profiles/ali.png",
      "rating_average": 4.97,
      "review_count": 120,
      "distance_km": 2.4, 
      "bayesian_score": 4.85, 
      "is_active": true,
      "ui_rating_text": "4.97 (120 jobs)",
      "primary_price": "Rs. 500",
      "price_context": "Inspection Fee",
      "promo_tag": null,
      "ui_subtitle_text": "2.4 km away"
    }
  ]
}
```

#### Response Schema (Strict Types)
| Object Path | JSON Type | Description |
| :--- | :--- | :--- |
| `categories[].id` | Number (Int) | Database ID. |
| `categories[].name` | String | Display name. |
| `categories[].icon_name` | String? | Short key (e.g., `"plumbing"`) mapping to Flutter asset at `assets/icons/{icon_name}.svg`. |
| `fixed_gigs[].image_url` | String? | Lifestyle photo URL sourced from `SubService.card_image_url`. Used as the 110px hero image on gig cards. Set by admin via Django Admin (Unsplash/stock photo). |
| `promotions[].promo_description` | String | **Dumb UI**: Fully formatted string. Explains the **Final Bill** discount. |
| `fixed_gigs[].base_price` | **String** | Decimal value as string for precision. |
| `top_technicians[].rating_average` | **Number (Float)** | Range 0.0 - 5.0. |
| `top_technicians[].review_count` | Number (Int) | Total completed jobs. |
| `top_technicians[].distance_km` | **Number (Float)** | Circular distance from user. |
| `top_technicians[].bayesian_score` | **Number (Float)** | Trust-weighted sorting score. |
| `top_technicians[].ui_rating_text` | String | **Dumb UI**: Pre-formatted rating (e.g., "4.9 (120 jobs)"). |
| `top_technicians[].primary_price` | String | **Dumb UI**: The main price string (e.g., "Rs. 500", "Rs. 1,200"). Single value across all scenarios — labor pricing is one `TechnicianSkill.labor_rate`. |
| `top_technicians[].price_context` | String | **Dumb UI**: Label for the price (e.g., "Inspection Fee", "Fixed Price", "Labor Rate"). |
| `top_technicians[].promo_tag` | String? | **Dumb UI**: Optional promo chip text (e.g., "20% Off Final Bill"). |


#### The "Dumb UI" Implementations
This endpoint heavily utilizes the Dumb UI principle to prevent the Flutter frontend from performing complex string concatenation or conditional rendering:
*   `top_technicians[].primary_price`: Automatically formats based on intent. Shows the inspection fee for categories, the fixed price for gigs, and the technician's `labor_rate` (single value) for searches.
*   `top_technicians[].promo_tag`: Carries the formatted discount message ONLY if a promo is active.
*   `top_technicians[].ui_rating_text`: Pre-formatted rating (e.g., "4.9 (120 jobs)").
*   `top_technicians[].distance_km`: Calculated dynamically in Python memory via the Haversine distance formula based on the `lat`/`lng` query params. Omitted if coordinates are invalid.
*   `top_technicians[].bayesian_score`: Dynamically calculated in memory using a Trust Constant ($m=10$) to prevent lucky 5-star beginners from outranking 4.9-star veterans with hundreds of reviews.

#### Error Envelopes (Failure States)
*This is a non-destructive read endpoint. If internal components (like GPS or a missing promo) fail or validate poorly, it falls back gracefully rather than throwing a 400 validation error.* 
*   **500 Internal Server Error**: Catastrophic database failure, wrapped in the standard envelope:
```json
{
  "status": 500,
  "code": "server_error",
  "message": "An unexpected error occurred while loading the home feed.",
  "errors": {}
}
```

---

### 1.2 Nearby Technician List (Paginated)
**Description**: Returns a paginated, Bayesian-sorted list of nearby technicians. It acts as the "See All" target or the search result page for specific categories or queries.
**URL**: `/api/customers/nearby-technicians/`
**Method**: `GET`

#### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `lat` | float | No | The raw latitude string of the user's current GPS location. |
| `lng` | float | No | The raw longitude string of the user's current GPS location. |
| `q` | string | No | Search query for matching against categories/gigs. |
| `service_id` | int | No | Filters results strictly to technicians licensed for a parent category (e.g., all Plumbers). |
| `sub_service_id` | int | No | Filters results strictly to technicians licensed for a specific Gig (e.g., only "Geyser Repair"). |
| `promotion_id` | int | No | Applies promotional discount logic to the returned pricing. |
| `page` | int | No | DRF PageNumberPagination index. |

#### Response Contract (Happy Path)
*Uses standard DRF PageNumberPagination wrapping.*
```json
{
  "count": 45,
  "next": "http://api.example.com/api/customers/nearby-technicians/?page=2",
  "previous": null,
  "ui_promo_banner_text": "PROMO: Get 20% OFF the total bill for AC Service!",
  "results": [
    {
      "id": 1,
      "full_name": "Ali Raza",
      "primary_category": "Plumbing", 
      "city": "LHR",
      "profile_picture": "https://example.com/media/profiles/ali.png",
      "rating_average": 4.97,
      "review_count": 120,
      "distance_km": 2.4, 
      "bayesian_score": 4.85, 
      "is_active": true,
      "ui_rating_text": "4.97 (120 jobs)",
      "primary_price": "Rs. 500",
      "price_context": "Inspection Fee",
      "promo_tag": "PROMO: 20% OFF the total bill!",
      "ui_subtitle_text": "2.4 km away"
    }
  ]
}
```

#### The "Dumb UI" Implementations
This endpoint heavily utilizes the Dumb UI principle to prevent the Flutter frontend from performing complex string concatenation or conditional rendering:
*   `results[].primary_price`: Always returns the **full** mandatory price (Inspection or Gig) or the technician's Labor Fee. 
*   `results[].promo_tag`: Acts as the **Value Booster**. If a promotion is active, it carries the formatted promo description.
*   `top_technicians[].distance_km`: Calculated dynamically in Python memory via the Haversine distance formula based on the `lat`/`lng` query params. Omitted if coordinates are invalid.
*   `top_technicians[].bayesian_score`: Dynamically calculated in memory using a Trust Constant ($m=10$) to prevent lucky 5-star beginners from outranking 4.9-star veterans with hundreds of reviews.

---

### 1.3 Technician Profile Detail
**Description**: Returns the full public profile of a single approved technician. Accepts optional discovery context parameters so that pricing is rendered identically to the card the customer tapped — no context mismatch between list and detail.
**URL**: `/api/customers/technician-profile/{id}/`
**Method**: `GET`

#### URL Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | int | Yes | The primary key of the `TechnicianProfile`. |

#### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `lat` | float | No | Customer's current latitude for Haversine distance. |
| `lng` | float | No | Customer's current longitude for Haversine distance. |
| `service_id` | int | No | Parent category the customer was browsing (Scenario C). |
| `sub_service_id` | int | No | Specific gig the customer tapped (Scenario A or B). |
| `promotion_id` | int | No | Active promo banner the customer arrived from. |

#### Response Contract (Happy Path)
```json
{
  "id": 1,
  "full_name": "Ali Raza",
  "city": "LHR",
  "profile_picture": "https://example.com/media/profiles/ali.png",
  "rating_average": 4.97,
  "review_count": 120,
  "experience_years": 5,
  "bio": "Certified AC technician with 5 years of experience in split and window units.",
  "distance_km": 2.4,
  "bayesian_score": 4.85,
  "is_active": true,
  "ui_rating_text": "⭐ 4.97 (120 jobs)",
  "primary_price": "Rs. 1,200",
  "price_context": "Labor Fee",
  "promo_tag": "20% OFF Final Bill!",
  "skills": [
    { "name": "AC Gas Refill", "icon_name": "ac_repair" },
    { "name": "AC General Wash", "icon_name": "ac_repair" }
  ],
  "recent_reviews": [
    { "reviewer_name": "Sara Khan", "rating": 5, "text": "Excellent work, very professional." },
    { "reviewer_name": "Ahmed Ali", "rating": 4, "text": "Good service, arrived on time." }
  ]
}
```

#### Pricing Scenarios (Contextual Pricing Engine)

| Scenario | Trigger | `primary_price` | `price_context` | `promo_tag` |
| :--- | :--- | :--- | :--- | :--- |
| **A — Fixed-Price Gig** | `sub_service_id` + `SubService.is_fixed_price=True` | `"Rs. X"` (fixed gig price) | `"Fixed Price"` | **Always `null`** — discount stacking forbidden |
| **B — Labor Gig** | `sub_service_id` + `SubService.is_fixed_price=False` | `"Rs. X,XXX"` (technician's `labor_rate`, or sub-service fallback when unset) | `"Labor Fee"` | Promo string if active, else `null` |
| **C — Category Discovery** | `service_id` only | `"Rs. X"` (category inspection fee) | `"Inspection Fee"` | Promo string if active, else `null` |
| **Default** | No context params | `"Rs. 500"` | `"Inspection Fee"` | `null` |

#### The "Dumb UI" Implementations
*   `ui_rating_text`: Pre-formatted with ⭐ prefix (e.g., `"⭐ 4.97 (120 jobs)"`).
*   `primary_price` + `price_context`: Fully resolved by the backend's Contextual Pricing Engine. Flutter renders exactly what it receives.
*   `promo_tag`: **Absolute firewall** — never populated on Scenario A (fixed-price gigs), regardless of any `promotion_id` passed.
*   `distance_km`: Haversine distance in memory. `null` if coordinates are absent or the technician has no GPS coordinates set.
*   `bayesian_score`: Bayesian Average with Trust Constant $m=10$, scoped to the contextual service category when available.
*   `skills[].icon_name`: Maps to `assets/icons/{icon_name}.svg` on the Flutter side.
*   `recent_reviews`: Always the 2 most recent reviews. Empty array `[]` if none exist.

#### Error Envelopes
*   **404 Not Found**: Profile does not exist or is not yet approved (`PENDING`/`REJECTED`).
```json
{
  "status": 404,
  "code": "not_found",
  "message": "Technician profile not found.",
  "errors": {}
}
```
*   **500 Internal Server Error**: Catastrophic database failure.
```json
{
  "status": 500,
  "code": "server_error",
  "message": "An unexpected error occurred.",
  "errors": {}
}
```

---

### 1.4 Technician Availability
**Description**: Returns a flat array of bookable 1-hour time slots for a specific approved technician on a given calendar date. Called immediately after the Profile Detail endpoint (1.3) so the customer can pick a booking time. Slot duration is context-aware — the same `service_id` / `sub_service_id` passed to the profile endpoint should be forwarded here to guarantee pricing and scheduling are in sync.
**URL**: `/api/customers/technicians/{id}/availability/`
**Method**: `GET`

#### URL Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | int | Yes | The primary key of the `TechnicianProfile`. |

#### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `date` | string | **Yes** | Calendar date in `YYYY-MM-DD` format. |
| `service_id` | int | No | Parent service category the customer is booking for (drives job duration — Scenario B). |
| `sub_service_id` | int | No | Specific gig being booked (drives job duration — Scenario A). Takes precedence over `service_id`. |

#### Job Duration Resolution
The slot end-time and end-of-day truncation depend on the estimated job length, resolved in priority order:

| Scenario | Trigger | Duration Source |
| :--- | :--- | :--- |
| **A — Specific Gig** | `sub_service_id` provided | `SubService.estimated_duration_minutes` (falls back to parent `Service.default_duration_minutes` if null) |
| **B — Category** | `service_id` only | `Service.default_duration_minutes` |
| **C — No Context** | Neither param | `default_duration_minutes` of the technician's primary service (service with most registered skills). Defaults to **60 minutes** if no skills exist. Never throws an error. |

#### Slot Generation Rules
- **Interval**: Slots are generated every **60 minutes** (1-hour blocks act as a natural travel buffer between jobs).
- **Truncation**: Any slot whose end time would exceed the technician's `end_time` for that day is dropped.
- **Conflict filter**: Slots that overlap any existing `JobBooking` with `status IN ['PENDING', 'CONFIRMED']` are removed. Overlap uses a half-open interval: `[slot_start, slot_end)` — a slot starting exactly at a booking's end time is **not** a conflict.
- **No schedule**: If the technician has no `TechnicianSchedule` record for the requested weekday, or `is_working=False`, an empty array is returned (not an error).

#### Response Contract (Happy Path)
```json
[
  {
    "time_string": "9:00 AM",
    "iso_start": "2026-04-07T09:00:00+05:00",
    "iso_end": "2026-04-07T10:00:00+05:00",
    "period": "AM"
  },
  {
    "time_string": "10:00 AM",
    "iso_start": "2026-04-07T10:00:00+05:00",
    "iso_end": "2026-04-07T11:00:00+05:00",
    "period": "AM"
  },
  {
    "time_string": "2:00 PM",
    "iso_start": "2026-04-07T14:00:00+05:00",
    "iso_end": "2026-04-07T15:00:00+05:00",
    "period": "PM"
  }
]
```

#### Response Schema (Strict Types)
| Field | JSON Type | Description |
| :--- | :--- | :--- |
| `time_string` | String | **Dumb UI**: Pre-formatted display time (e.g., `"9:00 AM"`, `"2:30 PM"`). Flutter renders this directly. |
| `iso_start` | String (ISO 8601) | Start of the slot in PKT (UTC+5). Use this for the booking request payload. |
| `iso_end` | String (ISO 8601) | End of the slot in PKT (UTC+5). |
| `period` | String | `"AM"` or `"PM"` — useful for grouping slots into morning/afternoon sections in the UI. |

*Empty array `[]` is a valid 200 response when the technician has no slots available (no schedule, day off, or fully booked).*

#### The "Dumb UI" Implementations
- `time_string`: Pre-formatted by the backend — Flutter calls `Text(slot.timeString)` with zero logic.
- `period`: Enables the UI to render morning and afternoon sections without any string parsing.
- `iso_start` / `iso_end`: PKT-aware ISO 8601 strings — passed directly as the booking payload without any timezone conversion on the Flutter side.

#### Error Envelopes
*   **400 Bad Request**: `date` parameter is missing or not in `YYYY-MM-DD` format.
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "The \"date\" query parameter is required (YYYY-MM-DD).",
  "errors": { "date": ["This field is required."] }
}
```
*   **404 Not Found**: Profile does not exist or is not yet approved (`PENDING`/`REJECTED`).
```json
{
  "status": 404,
  "code": "not_found",
  "message": "Technician profile not found.",
  "errors": {}
}
```

---

### 1.5 Saved Addresses
**Description**: Returns a list of all saved addresses for the authenticated customer. Used by the checkout flow to determine the job location. The full schema is documented in `ADDRESSES_API.md` — the snippet below shows only the fields the discovery/checkout flow consumes.
**URL**: `/api/customers/addresses/`
**Method**: `GET`
**Auth**: Required (`IsAuthenticated`). Send token in `Authorization: Token <token>` header.

#### Response Contract (Happy Path)
```json
[
  {
    "id": 1,
    "label": "Home",
    "street_address": "Block 4, Gulshan-e-Iqbal, Karachi, Pakistan",
    "latitude": "31.520400",
    "longitude": "74.358700",
    "is_default": true,
    "locality_label": "Gulshan-e-Iqbal, Karachi"
  }
]
```

#### Response Schema (Strict Types)
| Field | JSON Type | Description |
| :--- | :--- | :--- |
| `id` | Number (Int) | Primary key — pass this as `address_id` to the booking endpoint. |
| `label` | String | Friendly name (e.g. "Home", "Office"). |
| `street_address` | String | Geocoder's `formatted_address` (display string). |
| `latitude` | String (Decimal) | GPS latitude — trusted source for distance/matchmaking. |
| `longitude` | String (Decimal) | GPS longitude — trusted source for distance/matchmaking. |
| `is_default` | Boolean | True iff this is the user's default address. |
| `locality_label` | String \| null | Composed display label, e.g. `"Gulshan-e-Iqbal, Karachi"`. Null on legacy rows; UI falls back to `street_address`. |

> The full response also includes `created_at`, `neighborhood`, `suburb`, `city`, `state`, `country`, `postal_code`. See `ADDRESSES_API.md` for the complete contract.

#### Error Envelopes
*   **401 Unauthorized**: User is not logged in.
```json
{
  "status": 401,
  "code": "unauthorized",
  "message": "Authentication credentials were not provided.",
  "errors": {}
}
```
