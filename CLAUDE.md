# CLAUDE.md — Home Services Marketplace (Pakistan)
> Single monorepo: `frontend/` (Flutter) + `backend/` (Django REST Framework)

---

## PROJECT OVERVIEW
A hyper-local marketplace connecting customers with home service professionals (plumbers, electricians, etc.) — Pakistan market, similar to InDrive model.

**Critical Architecture Decisions (do not deviate):**
- Unified User model — NO separate Customer/Technician auth flows
- Every user registers as a standard User. Technicians apply via "Apply to be a Technician" flow → creates `TechnicianProfile` (OneToOne to User) with `status: PENDING` until Admin approves
- Payments: Customer ↔ Technician = **CASH ONLY** (no checkout screen). Technician ↔ Platform = **Virtual Wallet** (JazzCash top-up only)

---

## CATALOG IMAGE DESIGN (do not conflate these two fields)
Icons are **Flutter assets** (`frontend/assets/icons/*.svg`), NOT backend-served. Backend sends `icon_name` (a short key like `"ac_repair"`), Flutter maps it to a local SVG via `IconAssets.path()` in `lib/core/utils/icon_assets.dart`.

- `Service.icon_name` / `SubService.icon_name` — CharField key mapping to `assets/icons/{key}.svg`. Used for category chips, onboarding skill selection, search results.
- `SubService.card_image_url` — URLField, lifestyle photo (Unsplash/stock). Used only for the 110px hero image on Fixed Gig cards on the home screen. Set by admin in Django Admin.

**When adding a new service category:** add the SVG to `frontend/assets/icons/`, set `icon_name` in Django Admin to match the filename (without `.svg`).

---

## OTP IN DEVELOPMENT
`DEBUG=True` → OTP is never sent via Twilio. The code is **fixed to 123456** for test stability. It also prints to the Django terminal:
```
========================================
  [DEV OTP]  Phone : +923001234567
  [DEV OTP]  Code  : 123456
========================================
```
Pakistan blocks Twilio trial SMS verification. Keep `DEBUG=True` in `.env` during development.

---

## CORE BUSINESS RULES
- **Inspection Fee**: Rs. 500 base fee per visit
  - Quote ACCEPTED → Rs. 500 deducted from final bill
  - Quote DECLINED → Customer pays Rs. 500 cash for the visit
- **Wallet Lockout**: Technician blocked from accepting jobs if wallet balance < commission threshold, until JazzCash top-up

---

## MANDATORY WORKFLOW — READ BEFORE EVERY TASK
**NEVER write code immediately.**
1. Output a `<scratchpad>` execution plan first
2. Wait for explicit approval
3. Only then generate code

---

## BACKEND (Django REST Framework)
**Root**: `backend/`

### Architecture: Thin Views, Fat Services (4-Layer)
1. **`views.py`** — HTTP only: parse request, call serializer, delegate to service/selector, return response. No business logic. No DB queries.
2. **`services/`** — Business logic only. Use `transaction.atomic()`. Handle wallet deductions, model writes, UUID-to-File migrations. No `request` objects allowed here.
3. **`selectors/`** — All DB reads. Mandatory `select_related`/`prefetch_related` (no N+1 ever). Matchmaking: bounding-box filter → Haversine distance → Bayesian scoring (m=10 trust constant).
4. **`serializers.py`** — Strict data contracts. Transform ingress (UUIDs→files) and format egress for Flutter.

### Standard Error Envelope (ALL errors must use this)
```json
{
  "status": 400,
  "code": "validation_error",
  "message": "Human readable string for UI Toasts",
  "errors": {"field_name": ["Specific error"]}
}
```
Enforced via custom DRF exception handler in `exception.py`.

### Security Rules (evaluate before every view/service)
- **IDOR Prevention**: Always scope queries to `request.user` — e.g., `TechnicianProfile.objects.get(id=pk, user=request.user)`
- **Race Conditions (CRITICAL)**: Wallet operations and job status changes MUST use `transaction.atomic()` + `select_for_update()`
- **Mass Assignment**: NEVER `fields = '__all__'` on write serializers. Explicitly whitelist fields.
- **Secrets**: All credentials via environment variables (`django-environ`). Never hardcode.
- **Validation**: All incoming data sanitized at Serializer level. Never trust Flutter app input.
- **Security Pause**: Before finalizing any View or Service, output a 1-sentence comment: `# SECURITY: <how this prevents unauthorized access>`

### Backend Testing Rules
- Framework: `pytest` + `pytest-django` only. No Django `TestCase`, no JSON fixtures.
- Data: `factory_boy` (`DjangoModelFactory`) only. Never `Model.objects.create()` or hardcoded dicts.
- Test files: `backend/tests/` (mirrors `backend/apps/` exactly). NEVER put tests inside `backend/apps/`.
  - Code: `backend/apps/catalog/selectors/search_selectors.py`
  - Test: `backend/tests/catalog/selectors/test_search_selectors.py`
- Factories: All in `backend/tests/factories/` (shared across all apps)
- Test split: `test_api.py`, `test_services.py`, `test_selectors.py`
- **Selectors**: Mandatory `django_assert_num_queries` on every test fetching nested data
- **Services**: Mock all external APIs (`@patch`/`mocker`) — JazzCash, SMS, S3. No real network calls.
- **API Views**: Use `APIClient`. Test HTTP status codes, JSON payload contract, and permissions (unauthenticated → 401).
- **Edge cases required**: Invalid data formats, insufficient wallet balance, race conditions, 404s, the full error envelope for every failure test.
- When a feature is complete, suggest the full test suite for approval before writing it.

### Documentation Rules
- API contracts live at `apps/<feature>/api/<FEATURE>_API.md` (never in root)
- Every endpoint: URL, Method, Query Params, Sample JSON response, error envelopes, "Dumb UI" fields explained
- Docstrings on every Service and Selector — document the *why*, not the *what*
- Complex math (Haversine, Bounding Box, Bayesian avg) must have variable/constant comments
- After every implementation: verify against `API.md`, update if anything changed

---

## FRONTEND (Flutter)
**Root**: `frontend/`

### Architecture: Clean Architecture + Modern Riverpod v2/v3 (Generator syntax)

#### Dumb UI Principle
- Widgets are purely presentational — no logic, no price formatting, no button state decisions
- Backend serializer drives UI via `ui_pricing_tag` and `ui_button_text` fields
- One `ResultsScreen` + one `TechnicianCard` for discovery (handles Query, Category, Promo, Fixed-Price Gig)

#### Error Propagation Pipeline (4 steps — never skip layers)
1. **Data Source**: Non-200 → throws `HttpFailure(code, message, errors)`
2. **Repository** (`_mapFailures` helper): `switch` on `HttpFailure.code` → throws specific Domain sealed class (e.g., `InvalidOnboardingInput`, `OnboardingNetworkFailure`)
3. **Domain**: Errors as `sealed class Failure` (e.g., `sealed class TechnicianFailure implements Exception`)
4. **UI (Presentation)**: `switch` expression (pattern matching) on sealed class → user-friendly Snackbar

#### Riverpod Rules (STRICT)
- **Code generation is mandatory**: ALWAYS use `@riverpod` annotation + `_$MyNotifier` pattern
- NEVER use legacy `StateNotifierProvider` or manual `NotifierProvider`
- State classes: `@freezed` immutable Freezed classes
- Form submissions: `@Default(AsyncValue.data(null))` — do not overwrite form data on load
- Async mutations: ALWAYS `state = await AsyncValue.guard(() async { ... })` — never manual `try/catch` with `AsyncLoading()`/`AsyncError()`
- Safe data access: ALWAYS `state.requireValue`, NEVER `state.value!`
- **Testing Warm-up**: In tests, always `await container.read(myProvider.future)` before mutations to ensure `build()` is complete.

#### Local Storage & Caching (Tiered)
- **Tier 1 (Secure)**: `flutter_secure_storage` — JWT tokens and sensitive session IDs ONLY
- **Tier 2 (Cache)**: `shared_preferences` — app settings, recent searches, mandatory offline cache of API responses
- **Tier 3 (Session Recovery)**: Cache `active_job_id` + `job_status` — crash recovery must reload user into Active Job Screen

**Offline-First Pattern (mandatory on every read operation):**
1. Fetch from `RemoteDataSource`
2. On success → immediately cache in `LocalDataSource`
3. On `SocketException` → retrieve from `LocalDataSource`
4. If cache empty → throw Domain `NetworkFailure`

**Abstraction rule**: UI and Notifiers MUST NEVER import storage packages directly. All storage behind a `LocalDataSource` interface. Repository arbitrates.

#### Dependency Injection
- All `@riverpod` providers (including base storage init like `SharedPreferences`) go in `presentation/providers/dependency_injection.dart` per feature

#### Class Definition Rules
- `@freezed`: ONLY for State classes and Data Models
- DataSources and Repositories: standard Dart classes (no Freezed)
- Domain Entities: no database annotations

#### Security Rules (Flutter)
- No hardcoded API URLs, env types, or keys — use `--dart-define` or `.env` package
- Local cache is UX only, never source of truth for wallet balances or payment status
- JWT tokens: `flutter_secure_storage` only

### Frontend Testing Rules
- Test directory mirrors `lib/` exactly (`test/features/auth/domain/` mirrors `lib/features/auth/domain/`)
- Framework: `flutter_test` + `mocktail` only (no legacy `mockito`)
- **Data Layer**: Mock `Dio`, `FlutterSecureStorage`, `http`. Test the full Error Propagation Pipeline by simulating network failures and asserting correct Domain sealed class exceptions.
- **State Layer**: NEVER mount widgets to test Notifiers. Use `ProviderContainer`. Mock Repository, trigger Notifier method, assert exact state transitions (`AsyncLoading` → `AsyncData` or `AsyncError`).
- **Widget Layer**: Inject hardcoded Freezed models into `StatelessWidget`s. Assert text renders correctly. NEVER mock network calls in widget tests.
- When a feature is complete, suggest full test suite for approval before writing.

### Cross-Boundary Integration Testing
- **Mandate**: Validate "The Bridge". Do not re-test business logic (leave that to unit tests).
- **Option A: Full-GUI E2E**: Flutter `integration_test` against a running local Django server (requires emulator/desktop).
- **Option B: Headless Notifier-Level (Recommended)**: Standard `flutter test` files in `test/integration/` hitting real Django API. Mocks limited to platform storage only.
- **Mandatory Warm-up**: `await container.read(myProvider.future)` before any action.
- **Fixed Dev OTP**: Use `123456` for all integration tests in `DEBUG=True`.

### Frontend Documentation Rules
- No useless comments — document the *why* and the *contract*
- **Domain contracts**: Every Freezed model must document which backend endpoint feeds it
- **Error contracts**: Every Repository method must document which sealed class exceptions it throws (`/// Throws [MyFailure] if...`)
- **Visual contracts**: Reusable widgets must document their visual permutations
- **Intent contracts**: Notifiers must document why specific state mutations occur

---

## AI AGENT DIRECTIVES (HIGHEST PRIORITY)
1. **Scratchpad first**: Never write code without a `<scratchpad>` execution plan + approval
2. **No monolithic code**: Separate into Entity, UseCase, Repository, DataSource, State, Notifier, UI
3. **No legacy Riverpod**: `@riverpod`, `AsyncValue.guard()`, `state.requireValue` — no exceptions
4. **4-step Error Pipeline**: Always. No shortcuts. No raw JSON in the UI.
5. **Unified User Model**: No separate auth paths for customers and technicians
6. **DI wiring**: All providers in `presentation/providers/` per feature
7. **Honesty**: If I am wrong about something, explicitly say so. Do not hallucinate or silently comply.
