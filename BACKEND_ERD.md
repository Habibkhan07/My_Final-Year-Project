# Backend Entity Relationship Diagram (ERD)

This diagram represents the core entities and their relationships in the Django backend.

```mermaid
erDiagram
    %% Core User Entities
    User ||--o| UserProfile : "1:1"
    User ||--o| CustomerProfile : "1:1"
    User ||--o| TechnicianProfile : "1:1"
    User ||--o{ Token : "1:1 (auth_token)"
    User ||--o{ JobBooking : "M:1 (customer)"
    User ||--o{ Review : "M:1 (reviewer)"

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
    CustomerProfile ||--o{ SavedAddress : "M:1"
    SavedAddress ||--o{ JobBooking : "M:1"
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
        string icon_name
        decimal base_inspection_fee
        int default_duration_minutes
    }
    SubService {
        string name
        decimal base_price
        decimal max_price
        bool is_fixed_price
        bool is_featured
        json search_tags
        int estimated_duration_minutes
    }

    %% Technician App
    TechnicianProfile ||--o{ TechnicianSkill : "M:1"
    SubService ||--o{ TechnicianSkill : "M:1"
    TechnicianSkill {
        decimal labor_rate
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

    TechnicianProfile ||--o{ TechnicianSchedule : "M:1"
    TechnicianSchedule {
        int day_of_week
        time start_time
        time end_time
        bool is_working
    }

    TechnicianProfile ||--o{ Review : "M:1"
    Review {
        int rating
        text text
        datetime created_at
    }

    TechnicianProfile {
        string city
        string cnic_number
        int experience_years
        text bio
        string status
        float base_latitude
        float base_longitude
        int max_travel_radius_km
        bool is_onboarding_complete
        float rating_average
        int review_count
    }

    %% Bookings App
    TechnicianProfile ||--o{ JobBooking : "M:1"
    JobBooking {
        datetime scheduled_start
        datetime scheduled_end
        string status
        decimal price_amount
        string price_context
    }

    %% Marketing App
    Service ||--o{ Promotion : "M:1"
    Promotion {
        string name
        string discount_type
        decimal discount_value
        string funded_by
        datetime valid_from
        datetime valid_until
        bool is_active
        bool is_featured_on_home
    }
```

## Key Architectural Notes

1.  **User Roles**: The system uses a "One-to-One Profile" pattern. Every `User` can have a `UserProfile` (basic info), a `CustomerProfile` (role-specific), and/or a `TechnicianProfile` (role-specific).
2.  **Service Catalog**: 
    - `Service` is the top-level category (e.g., Plumbing).
    - `SubService` is the specific task (e.g., Leak Repair).
3.  **Technician Skills**: Technicians link to `SubServices` via the `TechnicianSkill` junction table, which allows them to set their own rates per skill.
4.  **Performance & Trust**: 
    - `TechnicianServicePerformance` tracks metrics per service for matchmaking using a Bayesian approach.
    - `TechnicianServiceLicense` stores verification documents per service.
    - `Review` stores customer feedback which feeds into performance metrics.
5.  **Availability**: `TechnicianSchedule` defines weekly working hours, while `JobBooking` records actual appointments to calculate real-time availability.
6.  **Bookings**: `JobBooking` connects a `Customer` (User), a `TechnicianProfile`, and a `SavedAddress`.
