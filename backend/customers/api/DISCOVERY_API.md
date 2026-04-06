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
| `top_technicians[].primary_price` | String | **Dumb UI**: The main price string (e.g., "Rs. 500", "Rs. 1,200", or "Rs. 1k-1.4k"). |
| `top_technicians[].price_context` | String | **Dumb UI**: Label for the price (e.g., "Inspection Fee", "Fixed Price", "Labor Rate"). |
| `top_technicians[].promo_tag` | String? | **Dumb UI**: Optional promo chip text (e.g., "20% Off Final Bill"). |


#### The "Dumb UI" Implementations
This endpoint heavily utilizes the Dumb UI principle to prevent the Flutter frontend from performing complex string concatenation or conditional rendering:
*   `top_technicians[].primary_price`: Automatically formats based on intent. Shows "Inspection Fee" for categories, "Fixed Price" for gigs, and the technician's specific "Labor Rate" (including ranges) for searches.
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
*   `results[].primary_price`: Always returns the **full** mandatory price (Inspection or Gig) or the technician's Labor Rate. 
*   `results[].promo_tag`: Acts as the **Value Booster**. If a promotion is active, it carries the formatted promo description.
*   `top_technicians[].distance_km`: Calculated dynamically in Python memory via the Haversine distance formula based on the `lat`/`lng` query params. Omitted if coordinates are invalid.
*   `top_technicians[].bayesian_score`: Dynamically calculated in memory using a Trust Constant ($m=10$) to prevent lucky 5-star beginners from outranking 4.9-star veterans with hundreds of reviews.
