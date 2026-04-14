# Testing Strategy & Quality Assurance (QA)

This document outlines the professional testing standards and QA philosophy for the Home Services Marketplace. We follow a **High-Fidelity Mirroring** approach to ensure 100% architectural coverage.

---

## 1. The Mirror Principle
To ensure no part of the system is a "black box," the test directory structure must be a **1:1 structural mirror** of the source code.

*   **Backend**: `backend/tests/` mirrors `backend/apps/`.
*   **Frontend**: `frontend/test/` mirrors `frontend/lib/`.

This allows any developer to immediately find the corresponding test for any file (e.g., `lib/features/auth/domain/auth_repository.dart` → `test/features/auth/domain/auth_repository_test.dart`).

---

## 2. Backend Testing Strategy (Django/Pytest)

We use `pytest` + `pytest-django` + `factory_boy`. We **never** use Django's default `TestCase` or JSON fixtures.

### A. The 3-Layer Test Split
1.  **Selectors (Data Layer)**: 
    *   Focus: Database reads and performance.
    *   **Mandatory**: Use `django_assert_num_queries` to verify that `select_related` and `prefetch_related` are preventing N+1 regressions.
2.  **Services (Business Logic Layer)**:
    *   Focus: State changes and side effects (e.g., wallet deductions, status transitions).
    *   **Mandatory**: Mock all external boundaries (`@patch`) like Twilio, JazzCash, and S3.
3.  **API Views (Integration Layer)**:
    *   Focus: The "API Contract."
    *   Assert: HTTP status codes, correct JSON envelopes, and Permission/Auth logic.

### B. Factory-First Data Generation
We use `backend/tests/factories/` to share `DjangoModelFactory` classes across the whole project. This ensures that test data is generated dynamically and accurately reflects the current state of the Models.

---

## 3. Frontend Testing Strategy (Flutter)

We use `flutter_test` + `mocktail`. We **never** use legacy `mockito`.

### A. Error Propagation Pipeline Testing
This is the most critical part of our QA. Every Repository test must simulate a **500 Server Error** or **SocketException** and assert that it correctly translates into a Domain-specific `sealed class Failure`.

### B. State Layer (Modern Riverpod)
We test Riverpod Notifiers **without mounting widgets**.
1.  Initialize a `ProviderContainer`.
2.  Mock the Repository layer.
3.  Trigger a method (e.g., `notifier.login()`).
4.  Assert the exact sequence of state transitions: `AsyncLoading` → `AsyncData` (Success) or `AsyncError` (Failure).

### C. "Dumb UI" Widget Testing
Since our widgets have zero logic, widget tests are simple and robust. We inject a hardcoded `@freezed` model and assert that the strings rendered on the screen exactly match the backend's "Dumb UI" fields (e.g., `ui_pricing_tag`).

---

## 4. The SQA Philosophy (Beyond the Happy Path)

We do not just test if things "work." We test how they **fail**.

### Boundary & Edge Case Testing
*   **Wallet Logic**: What happens if a technician has exactly Rs. 500 in their wallet? What if they have Rs. 499.99?
*   **Matchmaking**: Verify that a technician with 500 reviews and a 4.9 rating correctly outranks a "lucky beginner" with one 5-star review (Bayesian Scoring logic).
*   **Time**: Use `freezegun` (Backend) or `fake_async` (Frontend) to test OTP expiry logic.

### Standardized Failure Assertions
Every failure test, regardless of the app or feature, must assert that the API returns the **Standardized JSON Envelope**:
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "User-friendly message",
  "errors": { "field": ["error details"] }
}
```

---

## 5. Execution Summary
*   **Backend**: Run `pytest` from the `backend/` directory.
*   **Frontend**: Run `flutter test` from the `frontend/` directory.

---

## 6. End-to-End (E2E) & Integration Testing — Deferred

Cross-boundary integration and E2E tests are **not yet active**. They will be introduced once core booking flows are stable and a persistent test environment is available.

### Planned approach (when re-enabled):

**Option A — Full-GUI E2E (Emulator Based)**
*   Framework: Flutter `integration_test` against a live local Django server.
*   Focus: Full user journeys using the **Robot Pattern** (Page Object Model).

**Option B — Headless Notifier-Level (Recommended)**
*   Standard `flutter test` files in `test/integration/` hitting the real Django API.
*   Mocks limited to platform storage only (`FlutterSecureStorage`, `SharedPreferences`).
*   Fixed OTP `123456` (works when `DEBUG=True`).
*   **Warm-up mandate**: always `await container.read(myProvider.future)` before triggering any mutation.

When re-enabled, seeds must be applied first:
```bash
python manage.py seed_test_data
```
