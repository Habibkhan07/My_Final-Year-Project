# Master System Architecture

This is the definitive guide to the Home Services Marketplace architecture, combining high-level flows with granular implementation patterns.

---

## 1. The Master Blueprint
This diagram shows how the Frontend, Backend, and External Services are interconnected.

```mermaid
flowchart TD
    %% --- EXTERNAL LAYER ---
    subgraph External["External Services"]
        Twilio[Twilio SMS<br/>OTP Auth]
        JazzCash[JazzCash Gateway<br/>Wallet Top-ups]
    end

    %% --- FRONTEND LAYER ---
    subgraph Frontend["Frontend (Flutter - Clean Architecture)"]
        UI[Dumb UI Widgets<br/>Renders Backend Strings]
        Notifiers[Riverpod Notifiers<br/>AsyncValue.guard]
        Repos[Repositories<br/>Error Mapping / Offline-First]
        DS[Data Sources<br/>Remote: Dio / Local: Secure Storage]
        
        UI <--> Notifiers
        Notifiers <--> Repos
        Repos <--> DS
    end

    %% --- THE BRIDGE (API CONTRACT) ---
    subgraph Bridge["The API Contract (Standardized JSON)"]
        JSON["Standard Envelope<br/>{status, code, message, errors}"]
        DumbFields["Dumb UI Fields<br/>ui_pricing_tag, ui_button_text"]
    end

    %% --- BACKEND LAYER ---
    subgraph Backend["Backend (Django REST - Thin Views/Fat Services)"]
        Views[API Views<br/>Serializers / Request Parsing]
        Services[Services Layer<br/>Business Logic / Wallet Logic]
        Selectors[Selectors Layer<br/>Complex Reads / Matchmaking]
        Models[Django Models<br/>Unified User Model]
        
        Views <--> Services
        Views <--> Selectors
        Services <--> Models
        Selectors <--> Models
    end

    %% --- DATA LAYER ---
    subgraph Storage["Data & Assets"]
        DB[(MySQL Database)]
        Media[Media Storage<br/>S3 / Local]
        Icons[Flutter Assets<br/>Local SVGs]
    end

    %% --- CROSS-LAYER FLOWS ---
    DS <== REST / HTTP ==> Views
    Views -.-> JSON
    Views -.-> DumbFields
    DumbFields -.-> UI
    
    Services -- Trigger SMS --> Twilio
    Services -- Verify Top-up --> JazzCash
    Models <--> DB
    Services -- Uploads --> Media
    
    %% --- BUSINESS LOGIC ANNOTATIONS ---
    subgraph Logic["Core Business Logic"]
        Auth[Unified Auth: Phone + OTP]
        Payments[Dual Payments: Cash + Wallet]
        Scoring[Bayesian Matchmaking]
    end

    Auth -.-> Models
    Payments -.-> Services
    Scoring -.-> Selectors
```

---

## 2. Functional Patterns (The "Moving Parts")

### A. The "Dumb UI" Sequence
The Backend decides the UI state; the Frontend simply renders strings.

```mermaid
sequenceDiagram
    participant DB as MySQL Database
    participant Ser as Django Serializer
    participant API as REST Endpoint
    participant Repo as Flutter Repository
    participant UI as Flutter Widget

    DB->>Ser: Raw Data (rating: 4.97, count: 120)
    Note over Ser: Logic: Concatenate to "4.97 (120 jobs)"
    Ser->>API: JSON: { "ui_rating_text": "4.97 (120 jobs)" }
    API->>Repo: Fetch JSON
    Repo->>UI: Pass Freezed Model
    Note over UI: Widget: Text(model.uiRatingText)
    UI-->>UI: No formatting logic inside Widget!
```

### B. Unified Auth & Routing Matrix
The **Verify OTP API** flags dictate the Flutter app's navigation path.

| `new_user` | `name_required` | `is_technician` | Destination Screen |
| :--- | :--- | :--- | :--- |
| `true` | `true` | `false` | Complete Profile Screen |
| `false` | `true` | `-` | Complete Profile (Incomplete Account) |
| `false` | `false` | `false` | Customer Home Screen |
| `false` | `false` | `true` | Technician Home Screen |

### C. The 4-Layer Error Pipeline
Ensures type-safe, user-friendly errors across the monorepo.

1.  **Django API**: Returns standard JSON Envelope (`400/401/500`).
2.  **RemoteDataSource**: Parses JSON and throws `HttpFailure`.
3.  **Repository**: Maps `HttpFailure.code` to a **Domain Sealed Class Failure**.
4.  **UI/Notifier**: Pattern matches the failure using `switch` to show a Snackbar.

---

## 3. Engineering & Security Mandates

*   **Concurrency**: Wallet operations and job status changes use `transaction.atomic()` + `select_for_update()` in the **Services Layer**.
*   **IDOR**: All Selectors and Services are scoped to `request.user` to prevent unauthorized data access.
*   **Offline-First**: Every read operation in Flutter follows: `Remote Fetch` → `Update Local Cache` → `Fallback to Local on Network Failure`.
*   **Matchmaking**: Uses a **Bayesian Average** (Trust Constant $m=10$) and **Haversine Distance** to prioritize technicians.

---

## 4. Documentation Index (Source of Truth)
For exact JSON schemas, refer to the feature-specific contracts:
*   **Authentication**: `backend/accounts/api/AUTH_API.md`
*   **Service Discovery**: `backend/customers/api/DISCOVERY_API.md`
*   **Search & Catalog**: `backend/catalog/api/SEARCH_API.md`
*   **Technician Onboarding**: `backend/technicians/api/ONBOARDING_API.md`
