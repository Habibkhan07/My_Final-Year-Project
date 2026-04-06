# API CONTRACT & DOCUMENTATION
**Project**: Home Services Marketplace App
**Status**: Living Documentation
**Domain**: Catalog

## 1. CATALOG DOMAIN

### 1.1 Live Search Auto-Suggest
**Description**: The fast, auto-suggest endpoint used by the Customer Home Screen search bar. It scans through categories, sub-services, and hidden colloquial search tags (e.g., "bijli", "pani") to return the most relevant actionable tasks.
**URL**: `/api/catalog/search/` *(Assumed routing based on `catalog/api/search/` app structure)*
**Method**: `GET`

#### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `q` | string | Yes | The search string. If the string is less than 2 characters, the backend safely returns an empty array to prevent unnecessary database scanning. |

#### Response Contract (Happy Path)
```json
{
  "results": [
    {
      "id": 14,
      "name": "Wiring Short Circuit",
      "category_name": "Electrician",
      "category_icon_name": "electrician",
      "icon_name": "electrician",
      "card_image_url": "https://images.unsplash.com/photo-xxxx?w=400&q=80",
      "base_price": "500.00",
      "is_fixed_price": false
    },
    {
      "id": 15,
      "name": "Ceiling Fan Repair",
      "category_name": "Electrician",
      "category_icon_name": "electrician",
      "icon_name": "electrician",
      "card_image_url": "https://images.unsplash.com/photo-xxxx?w=400&q=80",
      "base_price": "800.00",
      "is_fixed_price": true
    }
  ]
}
```

#### The "Dumb UI" Implementations & Backend Logic
* **Colloquial Tag Matching**: The Flutter UI doesn't need to know the user's intent. The backend scans a hidden `JSONField` containing tags. For example, if the user types `q=bijli`, the database matches the tags array and returns "Wiring Short Circuit" directly.
* **Flattened Hierarchy**: The Flutter UI just needs to display a list of strings (e.g., `🔍 Wiring Short Circuit ↗`). The `category_name` is provided in case the UI wants to show a subtitle (e.g., "Wiring Short Circuit • Electrician") without needing a nested object.
* **O(1) Data Resolution**: The `category_name` and `category_icon_url` are resolved safely using `.select_related('service')` in the backend selector, guaranteeing rapid response times for every keystroke without N+1 queries.

#### Error Envelopes (Failure States)
*This is a non-destructive read endpoint. Bad inputs (like empty strings) return empty lists instead of errors.*
*   **500 Internal Server Error**: Catastrophic database failure, wrapped in the standard envelope:
```json
{
  "status": 500,
  "code": "server_error",
  "message": "An unexpected error occurred during search.",
  "errors": {}
}
```
