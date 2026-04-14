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
*   **E2E Integration**: Run `flutter test integration_test/` with a local Django instance running.

## 6. End-to-End (E2E) & Headless Integration Testing

To validate the "Bridge" and "Dumb UI" contracts, we utilize cross-boundary integration testing to ensure the frontend and backend communicate flawlessly in a real environment.

### A. Full-GUI E2E (Emulator Based)
*   **Framework**: Flutter `integration_test` running against a live, local Django test server (`http://localhost:8000`).
*   **Focus**: User Journeys and Routing Matrix using the **Robot Pattern**.

### B. Headless Notifier-Level Integration (Recommended for Speed/Low RAM)
For environments where emulators are too heavy or for faster CI feedback, we use **Headless Notifier-Level Integration**. These run as standard `flutter test` files in `test/integration/` but hit the **real** Django API.

*   **Logic Stack**: State -> UseCase -> Repository -> RemoteDataSource -> Network -> Django -> DB.
*   **Mocks**: Limited to platform-only storage (`FlutterSecureStorage` and `SharedPreferences`).
*   **The Warm-up Mandate**: Notifiers are `AsyncNotifier`s. You **MUST** await the initial build before calling methods:
    ```dart
    // MUST warm up the provider before triggering mutations
    await container.read(authProvider.future); 
    notifier.requestOtp(...);
    ```

### Data Strategy for All Integration Tests
*   **Deterministic OTP**: In `DEBUG=True`, the backend code is fixed to `123456` for stable testing.
*   **Seeds**: Use `seed_test_data.py` to ensure the DB state matches test expectations.

### The "Journey-Based" File Architecture (Flutter)
Unlike Unit and Widget tests, E2E tests do not follow the 1:1 Mirror Principle because they test cross-boundary user journeys.

`frontend/integration_test/` should mirror the **Core Business Flows**:
```text
integration_test/
├── core/
│   ├── app_startup_test.dart       # Tests bootstrap, offline cache load, etc.
│   └── error_pipeline_test.dart    # Tests 4-Layer error pipeline with forced 500s
├── journeys/
│   ├── auth/
│   │   ├── routing_matrix_test.dart  # Tests new_user and is_technician navigation
│   │   └── session_recovery_test.dart# Tests killing app and reloading active job
│   ├── catalog/
│   │   └── dumb_ui_rendering_test.dart # Asserts backend strings render correctly
│   └── booking/
│       ├── booking_happy_path_test.dart  # Full flow: browse -> book -> confirm
│       └── wallet_lockout_test.dart      # Tests Technician blocked from accepting jobs
└── utils/
    ├── test_seeds.dart             # Helpers to trigger backend DB seeding
    └── test_robots.dart            # Page Object Model (Robot Pattern) helpers
```

### The Robot Pattern (Page Object Model)
To keep E2E tests maintainable, we mandate the **Robot Pattern**. All widget interactions must be abstracted into "Robots" inside the `integration_test/utils/` directory.

*   **Bad (Do not use)**: `await tester.tap(find.byKey('login_btn'));` directly in the test.
*   **Good**: `await loginRobot.enterOtpAndSubmit('123456');`
