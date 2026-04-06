# SYSTEM ARCHITECTURE & BUSINESS LOGIC BLUEPRINT
**Project**: Home Services Marketplace App (Pakistan Market focus, similar to InDrive).
**Stack**: Flutter (Frontend), Django REST Framework (Backend).

## 0. PROJECT BACKGROUND & EVOLUTION
**The App Concept**: A hyper-local marketplace connecting customers with home service professionals (plumbers, electricians, etc.). 
**Important Deviation from Initial Requirements**: We are NO LONGER using strictly separate, isolated roles for Customers and Technicians. Do NOT build separate authentication flows or base user models.

* **Unified User Journey**: EVERY person who downloads the app registers as a standard `User` (Customer screen). If they want to offer services, they go through an "Apply to be a Technician" onboarding flow. 
* **Database Reflection**: This creates a `TechnicianProfile` linked via One-to-One to the base `User` model. This profile remains `status: PENDING` until an Admin approves it.
* **The Dual Payment System**: 
  1. **Customer <-> Technician**: STRICTLY CASH. The customer hands physical cash to the technician after the job. Do not build a checkout screen for the customer.
  2. **Technician <-> Platform**: VirtuaShow me your <scratchpad> execution plan before modifying any Python files."l Wallet "Escrow-Lite". The platform deducts its commission from the technician's virtual wallet. Technicians top up this wallet exclusively using **JazzCash**.

## 1. CORE BUSINESS RULES
* **The "Deduction" Model**: 
  * Visits have a Base Inspection Fee (default: Rs. 500).
  * If the repair quote is ACCEPTED: Rs. 500 is DEDUCTED from the final bill.
  * If the repair quote is DECLINED: Customer pays Rs. 500 cash for the visit.
* **Wallet Lockout**: If a technician's wallet balance drops below the required commission threshold, they are blocked from accepting new jobs until they perform a JazzCash top-up.

## 2. BACKEND ARCHITECTURE (DJANGO)
Follow the strict "Thin Views, Fat Services" pattern. Never put business logic or DB queries directly in `views.py`.

### A. The 4-Layer Separation
1. **Views (`views.py`)**: Only handle HTTP request/response, call serializers, and delegate to services or selectors.
2. **Services (`services/`)**: Core business logic (e.g., `finalize_registration`). Handle `transaction.atomic()`, UUID-to-File migrations, wallet deductions, and model writes. No HTTP request objects allowed here.
3. **Selectors (`selectors/`)**: All database reads. Must use `prefetch_related`/`select_related` to prevent N+1 queries. Heavy matchmaking logic (Bounding-box filtering, Haversine distance, Bayesian scoring with m=10) happens here.
4. **Serializers (`serializers.py`)**: Strict data contracts. Transform Ingress data (UUIDs to files) and format Egress data for Flutter.

### B. Global Exception Handling (`exception.py`)
All API errors MUST be caught by the custom DRF exception handler and returned in this exact JSON envelope:
{
  "status": 400,
  "code": "validation_error",
  "message": "Human readable string for UI Toasts",
  "errors": {"field_name": ["Specific error"]}
}

## 3. FRONTEND ARCHITECTURE (FLUTTER)
Strict adherence to Clean Architecture and **Modern Riverpod (v2/v3 Generator syntax)**. 

### A. "Dumb UI" Principle
* Widgets must be purely presentational. They do NOT calculate logic, format prices, or decide button states.
* For the Discovery Phase, use ONE `ResultsScreen` and ONE `TechnicianCard` widget. The Django Backend Serializer dictates the UI by passing `ui_pricing_tag` and `ui_button_text` based on whether the search is a Query, Category, Promo, or Fixed-Price Gig. The UI simply renders these strings.

### B. Strict Error Propagation Pipeline
Errors must bubble up and transform sequentially at each layer. AI must NOT skip layers.
1. **Data Source Layer**: Parses non-200 responses. Throws a generic `HttpFailure(code, message, errors)`.
2. **Repository Layer (`_mapFailures` helper)**: Catches `HttpFailure` and network exceptions (e.g., `SocketException`). Uses a `switch` statement on the `HttpFailure.code` to throw a specific Domain `sealed class` Exception (e.g., `InvalidOnboardingInput`, `OnboardingNetworkFailure`).
3. **Domain Layer**: Defines errors as `sealed class Failure` (e.g., `sealed class TechnicianFailure implements Exception`).
4. **Presentation Layer (UI)**: The UI catches the sealed class error and MUST use a Dart `switch` expression (pattern matching) on the sealed class to extract the payload and display a user-friendly Snackbar message. 

### C. Presentation Layer (Strict Modern Riverpod Rules)
* **Code Generation is Mandatory**: NEVER use legacy `StateNotifierProvider` or `NotifierProvider` manually. ALWAYS use `@riverpod` code generation (e.g., `@riverpod class MyNotifier extends _$MyNotifier`).
* **State Definition (`.freezed.dart`)**: Use immutable Freezed classes. 
* **Form Submissions**: Use `@Default(AsyncValue.data(null))` for tracking submission states so you don't overwrite the form's local state data when loading.
* **The `AsyncValue.guard` Rule**: NEVER write manual `try/catch` blocks that emit `AsyncLoading()` followed by `AsyncError()`. You MUST use `state = await AsyncValue.guard(() async { ... })` for all asynchronous mutations to automatically preserve `requireValue` while loading.
* **Safe Data Access**: ALWAYS use `state.requireValue` instead of `state.value!` when modifying local state within the Notifier to guarantee safety.

### D. Local Storage & Caching Strategy
* **Strict Abstraction**: UI and Riverpod Notifiers MUST NEVER import storage packages directly. All storage must be abstracted behind a `LocalDataSource` interface. The Repository arbitrates between the Remote and Local Data Sources.
* **Mandatory Offline Caching Rule (Tier 2)**: Every time the AI generates a read operation (e.g., fetching a feed, list, or profile), it MUST automatically generate a `LocalDataSource` using `shared_preferences`. Models MUST include `toJson()` and `fromJson()` methods. The Repository MUST implement the following offline-first fallback pattern:
  1. Try to fetch from `RemoteDataSource`.
  2. If successful, cache the data immediately in the `LocalDataSource`.
  3. If `RemoteDataSource` throws a `SocketException` (Network error), attempt to retrieve the data from `LocalDataSource`.
  4. If cached data exists, return it (Fast Offline Load). Only throw the Domain `NetworkFailure` if the cache is empty.
* **Tiered Storage**: 
  * *Tier 1 (Secure Storage)*: Use `flutter_secure_storage` exclusively for Auth Tokens.
  * *Tier 2 (Key-Value/Cache)*: Use `shared_preferences` for App Settings, Recent Searches, and mandatory offline caching of API responses.
  * *Tier 3 (Session Recovery)*: Cache `active_job_id` and `job_status` locally. If the app crashes during a live service visit, it must reload the user directly into the Active Job Screen.
* **Class Definitions**: Use `@freezed` ONLY for State classes and Data Models. DataSources and Repositories MUST be standard Dart classes. Do NOT pollute Domain Entities with database annotations.
* **Dependency Injection Placement**: Place all `@riverpod` injection providers (including your base storage initialization like `@Riverpod(keepAlive: true) SharedPreferences sharedPreferences`) inside the `presentation/providers/dependency_injection.dart` file for the feature to maintain an easily readable execution flow mapping.
## 4. AI AGENT DIRECTIVES
1. Do NOT generate monolithic code. Separate features into Entity, UseCase, Repository, DataSource, State, Notifier, and UI.
2. **STRICT RIVERPOD RULE**: Absolutely no legacy Riverpod. You must use `@riverpod`, `AsyncValue.guard()`, and `state.requireValue`. Do not invent old state management patterns.
3. Always implement the 4-step Error Propagation Pipeline using `switch` statements and `sealed` classes. Never let the UI parse raw JSON errors.
4. Always remember the Unified User Model: Do not create separate authentication paths for customers and technicians.
5. Provide all `@riverpod` dependency injection wiring within the feature's `presentation/providers/` directory to adhere to the project's specific mapping standard.
6. Never write code immediately. First, output a step-by-step Execution Plan. Wait for my approval before modifying any files, Show me your <scratchpad> execution plan before modifying any file.

## 5. SECURITY & VULNERABILITY PREVENTION (SENIOR ENGINEER MINDSET)
Before generating any code, you MUST evaluate it for OWASP Top 10 vulnerabilities and business-logic flaws. Write code assuming the client is actively trying to exploit the system.

### A. Backend Security (Django/DRF)
* **Prevent IDOR (Insecure Direct Object Reference)**: Never assume `user_id` or `profile_id` passed in a JSON payload or URL is authorized. ALWAYS verify that the object being accessed/modified belongs to `request.user` (e.g., `TechnicianProfile.objects.get(id=pk, user=request.user)`).
* **Concurrency & Race Conditions (CRITICAL)**: Any operation involving the Technician's Virtual Wallet or Job Status changes MUST be wrapped in `transaction.atomic()` and use `select_for_update()` to lock the row. Prevent double-spending or parallel status manipulation.
* **Mass Assignment Prevention**: NEVER use `fields = '__all__'` in a ModelSerializer that handles `POST`, `PUT`, or `PATCH` requests. Explicitly define allowed fields to prevent users from maliciously updating their `wallet_balance` or `is_active` status.
* **Secret Management**: Never hardcode API keys, JazzCash credentials, or secret keys in the code. Always assume they will be loaded via environment variables (`django-environ`).
* **Strict Validation**: All incoming data MUST be sanitized and validated at the Serializer level. Never trust data coming from the Flutter app.

### B. Frontend Security (Flutter)
* **Secret Exclusion**: Never hardcode API URLs, environment types, or keys in Dart code. Use `--dart-define` or an `.env` package.
* **State Tampering**: Assume the local SQLite/Isar cache can be manipulated by a rooted device. Local storage is strictly for UX/caching, never for the "Source of Truth" regarding wallet balances or payment statuses.
* **Secure Storage**: (Re-iterating) JWT tokens and sensitive session IDs MUST remain inside `flutter_secure_storage`.

### C. The "Security Pause" Directive
* Before finalizing a Django View or Service, you must mentally pause and output a 1-sentence comment explaining how this specific code prevents unauthorized access. (e.g., `# SECURITY: Enforcing object-level permission via request.user`).


## 6. BACKEND TESTING ARCHITECTURE (SQA / PRINCIPAL MINDSET)
When asked to write tests, you MUST act as a Senior SQA Engineer. We do NOT use Django's default `TestCase` or JSON fixtures. 

### A. The Tooling Stack
* **Framework:** Use `pytest` and `pytest-django` exclusively.
* **Data Generation:** Use `factory_boy` (`factory.django.DjangoModelFactory`). NEVER use `Model.objects.create()` or hardcoded dictionaries for test data setup.
* **Structure:** Tests must be split by architectural layer: `test_api.py`, `test_services.py`, and `test_selectors.py`.

### B. Layer-Specific Testing Rules
1. **Testing Selectors (Data Layer):** * **Mandatory Rule:** You MUST use `django_assert_num_queries` for every selector test that fetches nested data. This guarantees that `select_related` and `prefetch_related` are working and prevents N+1 performance regressions.
2. **Testing Services (Business Logic Layer):**
   * Focus purely on state changes and side effects. 
   * **Mandatory Rule:** Always use `@patch` or `mocker` to mock external API calls (e.g., JazzCash, SMS gateways, S3 uploads). Do not let tests make real network requests.
3. **Testing API Views (Integration Layer):**
   * Use `APIClient`. 
   * Focus strictly on the "Contract": Test HTTP status codes, verify the JSON response payload matches the UI requirements, and explicitly test permissions (e.g., ensuring an unauthenticated user gets a 401).

### C. The SQA Philosophy (Beyond the Happy Path)
* **Test Every Edge Case**: Like a Principal SQA Engineer, you MUST test boundary conditions and failure states. Do NOT just test the "happy path" where data is perfect. 
* **Failure Assertions**: You must explicitly write tests for what happens when:
  * A user passes invalid data formats (e.g., wrong CNIC format, expired UUID).
  * A technician tries to accept a job but has an insufficient wallet balance.
  * Race conditions occur (testing the `transaction.atomic` locks).
  * A requested resource does not exist (asserting a clean 404 response).
* **The Error Envelope**: For every failure test, assert that the API returns the exact standardized JSON exception envelope defined in Section 2B.

### D. The Test Generation Directive
When generating tests, always generate the corresponding `factories.py` file first. Then, write the test suite ensuring robust coverage of BOTH success (happy path) and all possible failure scenarios for the specific View, Service, or Selector requested.

### E. Test Directory Structure (Monorepo Isolation)
* **The Backend Root:** The root directory for all Django code is `backend/`. All backend paths must be calculated relative to this folder.
* **Mandatory Pathing:** ALL backend tests must be placed in a top-level tests directory *inside the backend folder*: `backend/tests/`. NEVER put test files or `tests/` folders inside the individual `backend/apps/` directories.
* **Structure Mirroring:** The `backend/tests/` folder must perfectly mirror the `backend/apps/` directory structure.
  * *Code:* `backend/apps/catalog/selectors/search_selectors.py`
  * *Test:* `backend/tests/catalog/selectors/test_search_selectors.py`
* **Factories:** All `factory_boy` factories must live in `backend/tests/factories/` so they can be shared across all Django apps.


## 7. DOCUMENTATION & API CONTRACT STANDARDS
We maintain "Living Documentation" to ensure frontend/backend synchronization and architectural clarity.

### A. The API Contract (api.md)
* **Location Rule:** Every feature-specific API contract must live within its feature's API directory (e.g., `apps/customers/api/DISCOVERY_API.md`). Do NOT save these in the root directory.
* **Schema Enforcement:** Every endpoint entry must include the URL, Method, Query Parameters, and a Sample JSON Response.The `API.md` file is the **Source of Truth** for the Flutter frontend. Every endpoint must be documented there before or during implementation.
* **Schema Enforcement**: Every endpoint entry must include the URL, Method, Query Parameters, and a Sample JSON Response.
* **UI-Driven Fields**: Documentation must explicitly highlight "Dumb UI" fields (e.g., `ui_pricing_tag`) and explain the backend logic used to generate them.
* **Error Envelopes**: Document the specific error codes and messages returned in the standardized JSON Exception Envelope for that endpoint.

### B. Inline Code Documentation (The "Why" Rule)
* **Docstrings**: Every Service and Selector must have a Python docstring.
* **Logic Explanation**: Do not document what the code *is* (e.g., "saves user"). Document *why* it exists (e.g., "Using Bayesian score to prioritize technicians with high volume over lucky beginners").
* **Complex Math**: Any non-trivial logic (Haversine distance, Bounding Boxes, Bayesian averages) must include a comment explaining the variables and constants used (e.g., the Trust Constant `m=10`).

### C. Post-Implementation Sync
After generating or refactoring code, the final step of any task is to:
1. Verify the code matches the `API.md` contract.
2. Update `API.md` if any implementation details changed (e.g., a field was renamed for clarity).

## 8. FRONTEND TESTING ARCHITECTURE (SQA / PRINCIPAL MINDSET)

The Mirror Principle (Directory Structure): The `frontend/test/` directory MUST be an exact 1:1 structural mirror of the `frontend/lib/` directory. (e.g., `lib/features/auth/domain/` maps exactly to `test/features/auth/domain/`).

Tooling: Use `flutter_test` and `mocktail` exclusively. Do not use legacy `mockito`.

Data Layer: Mock external boundaries (`Dio`, `FlutterSecureStorage`, `http`). You MUST test the 'Error Propagation Pipeline' by simulating network failures (e.g., 500 status) and asserting the Repository correctly translates them into Domain sealed class exceptions.

State Layer (Riverpod v3): NEVER test Notifiers by mounting widgets. You MUST use Riverpod's `ProviderContainer`. Mock the Repository, trigger the Notifier method, and assert the exact state transitions (e.g., `AsyncLoading` -> `AsyncData` or `AsyncError`).

Presentation Layer (Widget Tests): Leverage the 'Dumb UI' principle. Inject hardcoded Freezed models into `StatelessWidget`s using `testWidgets`. Assert that specific text formats render correctly. NEVER mock network calls in widget tests.


Testing should be done like a true sqa engineer should do, with every edge case in mind.
and when ever a feature is complete complete tests for it should be suggested to me for approval.


## 9. FRONTEND DOCUMENTATION STANDARDS (CONTRACTS)

No Useless Comments: Focus on the 'Why' and the 'Contract'.

Domain Contracts: Every Freezed model MUST document exactly which backend API endpoint feeds it.

Error Contracts: Every Repository method MUST explicitly document which sealed class exceptions it throws (e.g., `/// Throws [MyFailure] if...`).

Visual Contracts: Reusable widgets MUST document their visual permutations.

Intent Contracts: Riverpod Notifiers MUST document why specific state mutations occur (e.g., using `AsyncValue.guard`).


General Gudline: When i am wrong, then explictly tell me that i am wrong, without hallucinating.
