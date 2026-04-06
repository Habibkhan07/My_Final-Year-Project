# Backend Entity Relationship Diagram (ERD)

This diagram represents the core entities and their relationships in the Django backend.

```mermaid
erDiagram
    %% Core User Entities
    User ||--o| UserProfile : "1:1"
    User ||--o| CustomerProfile : "1:1"
    User ||--o| TechnicianProfile : "1:1"
    User ||--o{ SavedAddress_Legacy : "M:1 (accounts)"
    User ||--o{ Token : "1:1 (auth_token)"

    %% Account App
    UserProfile {
        string phone
        bool is_technician
    }

    OTPRecord {
        string phone
        string code
        datetime expires_at
        bool is_used
    }

    %% Customer App
    CustomerProfile ||--o{ SavedAddress : "M:1 (customers)"
    SavedAddress {
        string label
        decimal latitude
        decimal longitude
        text address_text
    }

    %% Catalog App
    Service ||--o{ SubService : "1:M"
    Service {
        string name
        decimal base_inspection_fee
    }
    SubService {
        string name
        decimal base_price
        json search_tags
    }

    %% Technician App
    TechnicianProfile ||--o{ TechnicianSkill : "M:1"
    SubService ||--o{ TechnicianSkill : "M:1"
    TechnicianSkill {
        decimal base_rate
        int years_of_experience
    }

    TechnicianProfile ||--o{ TechnicianServiceLicense : "M:1"
    Service ||--o{ TechnicianServiceLicense : "M:1"

    TechnicianProfile ||--o{ TechnicianServicePerformance : "M:1"
    Service ||--o{ TechnicianServicePerformance : "M:1"
    TechnicianServicePerformance {
        float rating_average
        int review_count
    }

    %% Marketing App
    Service ||--o{ Promotion : "M:1"
    Promotion {
        string name
        string discount_type
        decimal discount_value
        datetime valid_until
    }
```

## Key Architectural Notes

1.  **User Roles**: The system uses a "One-to-One Profile" pattern. Every `User` can have a `UserProfile` (basic info), a `CustomerProfile` (role-specific), and/or a `TechnicianProfile` (role-specific).
2.  **Service Catalog**: 
    - `Service` is the top-level category (e.g., Plumbing).
    - `SubService` is the specific task (e.g., Leak Repair).
3.  **Technician Skills**: Technicians link to `SubServices` via the `TechnicianSkill` junction table, which allows them to set their own rates per skill.
4.  **Performance & Trust**: 
    - `TechnicianServicePerformance` tracks metrics per service for matchmaking.
    - `TechnicianServiceLicense` stores verification documents.
5.  **Redundancy Check**: Note that `SavedAddress` exists in both `accounts` and `customers`. Based on the models, `customers.SavedAddress` is linked to `CustomerProfile`, while `accounts.SavedAddress` is linked directly to `User`.
