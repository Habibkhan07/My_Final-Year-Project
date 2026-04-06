# Feature Specification & Algorithm Deep Dive

This document maps the business requirements (features) to the technical implementation. It provides the "Deep Dive" logic required for technical reports and project evaluations.

---

## 1. Feature Map (User Stories)

| Feature | Description | Primary Files |
| :--- | :--- | :--- |
| **Unified Auth** | Phone + OTP login for both Customers and Technicians. | `accounts/services/auth_service.py` |
| **Service Discovery** | Nearby technician search with category and gig filtering. | `customers/selectors/discovery_selectors.py` |
| **Technician Onboarding** | Multi-step application flow with document (CNIC) uploads. | `technicians/services/profile_service.py` |
| **Dual-Mode Payments** | Cash for services; Virtual Wallet for platform commission. | `technicians/services/wallet_service.py` |
| **Smart Matchmaking** | Ranking technicians based on distance, rating, and volume. | `customers/selectors/matchmaking_logic.py` |

---

## 2. Technical Deep Dives (The "Hard Parts")

### A. Bayesian Ranking Algorithm
To prevent a "Lucky Beginner" (e.g., one 5-star review) from outranking a "Reliable Veteran" (e.g., 4.9 stars with 200 reviews), we use a Bayesian Weighted Average.

**The Formula:**
$$W = \frac{v \times R + m \times C}{v + m}$$

*   $W$ = Weighted Rating (The final score used for sorting).
*   $v$ = Number of reviews for the technician.
*   $m$ = Trust Constant (we use $m=10$). This acts as a "synthetic" buffer.
*   $R$ = Average rating of the technician.
*   $C$ = The mean rating across the whole platform.

**Why it matters**: A technician needs at least 10+ reviews to "dilute" the trust constant and let their real rating shine. This ensures quality and reliability for the customer.

### B. Haversine Geospatial Logic
We do not use simple Euclidean distance (which is inaccurate on a sphere). We implement the Haversine formula to calculate the "Great Circle" distance between the User and the Technician.

**The Implementation**:
1.  **Bounding Box**: First, we calculate a square "fence" in MySQL using the technician's `max_travel_radius_km` to narrow down the candidates (optimal for performance).
2.  **Haversine**: We then calculate the exact distance in memory for the remaining candidates before sorting.

### C. The "Dumb UI" Principle
We use **Backend-For-Frontend (BFF)** logic. The backend provides pre-formatted strings:
*   Instead of sending `base_price` and `inspection_fee` separately, the backend sends `ui_pricing_tag: "Rs. 500 (Inspection)"`.
*   **Benefit**: If we decide to run a promotion or change the pricing model, we don't have to release a new version of the Flutter app.

---

## 3. Security & Integrity Deep Dive

### I. Race Condition Prevention (Concurrency)
When a Technician's wallet is deducted after a job, two processes could theoretically happen at once.
*   **Solution**: We use `transaction.atomic()` combined with `select_for_update()` in Django. This locks the database row until the subtraction is complete, ensuring the balance never becomes corrupt.

### II. IDOR (Insecure Direct Object Reference)
*   **Problem**: A malicious user could try to view another user's `SavedAddress` by guessing their ID.
*   **Solution**: We never query by ID alone. Every selector is scoped: `SavedAddress.objects.filter(id=pk, user=request.user)`. If the address doesn't belong to the logged-in user, it returns a 404 even if the ID is valid.

---

## 4. Technology Stack Rationale

*   **Flutter (Clean Architecture)**: Chosen for high-performance UI and "Single Codebase" efficiency for the Pakistan mobile market.
*   **Django REST Framework**: Chosen for its robust ORM, security defaults, and "Thin View/Fat Service" maintainability.
*   **MySQL**: Standard relational choice for ACID compliance, critical for the Virtual Wallet financial transactions.
