# API CONTRACT & DOCUMENTATION
**Project**: Home Services Marketplace App
**Status**: Living Documentation
**Domain**: Technician Onboarding

## 1. TECHNICIAN ONBOARDING FLOW

The onboarding process transitions a standard `User` into a `TechnicianProfile`. It uses a decoupled upload architecture to handle large media files reliably.

### 1.1 Get Onboarding Metadata
**Description**: Fetches the structured list of all active Services (Categories) and Sub-Services (Gigs) required to build the Skill & Pricing selection screens in Flutter.
**URL**: `/api/technicians/onboarding/metadata/`
**Method**: `GET`
**Headers**: `Authorization: Token <your_token>`

#### Response Contract (Happy Path)
```json
[
  {
    "id": 1,
    "name": "AC Repair",
    "sub_services": [
      {
        "id": 10,
        "name": "General AC Servicing",
        "base_price": "1500.00",
        "max_price": "1500.00",
        "icon_name": "ac_repair"
      },
      {
        "id": 11,
        "name": "Pipe Leak Repair",
        "base_price": "800.00",
        "max_price": "2000.00",
        "icon_name": "pipe_leak"
      }
    ]
  }
]
```

---

### 1.2 Upload Temporary Media
**Description**: Uploads a single media file (Profile Picture, CNIC, or Category License) to temporary staging. Returns a UUID to be used in the final registration payload.
**URL**: `/api/technicians/onboarding/upload-media/`
**Method**: `POST` (Multipart/Form-Data)
**Headers**: `Authorization: Token <your_token>`

#### Request Payload (Multipart)
| Key | Type | Description |
| :--- | :--- | :--- |
| `file` | File | The image file (JPEG/PNG). |

#### Response Contract (Happy Path)
```json
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### 1.3 Finalize Registration
**Description**: Submits the complete JSON payload containing text data, service selections, and the UUIDs of previously uploaded files.
**URL**: `/api/technicians/onboarding/finalize/`
**Method**: `POST`
**Headers**: `Authorization: Token <your_token>`

#### Request Payload
| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `first_name` | String | Yes | |
| `last_name` | String | Yes | |
| `city` | String | Yes | Choices: `LHR`, `KHI`, `ISL`. |
| `cnic_number` | String | Yes | **Format**: `00000-0000000-0`. |
| `experience_years` | Int | Yes | |
| `bio` | String | Yes | |
| `profile_picture_uuid` | UUID | Yes | |
| `cnic_picture_uuid` | UUID | Yes | |
| `category_licenses` | List | No | List of `{service_id, media_uuid}`. |
| `skills` | List | Yes | List of `{sub_service_id, years_of_experience, labor_rate}`. |

#### Skill Object Detail
*   `labor_rate`: Decimal/String (Optional. The technician's labor rate for this sub-service. When null, booking falls back to the platform's per-sub-service base price.)

#### Response Contract (Happy Path)
```json
{
  "profile_id": 45,
  "full_name": "Ali Raza",
  "status": "Pending Approval",
  "city": "Lahore",
  "profile_picture": "https://example.com/media/tech_profiles/ali.png",
  "verification_status": "Documents Received",
  "joined_date": "2024-05-15"
}
```
