# Home Services Marketplace — FYP

A hyper-local marketplace connecting customers with home service professionals (plumbers, electricians, AC technicians, etc.) in Pakistan. Modelled after the InDrive on-demand approach.

**Stack:** Flutter (frontend) + Django REST Framework (backend) + MySQL

---

## Repository Structure

```
my_fyp_project/
├── backend/          # Django REST Framework API
│   ├── accounts/     # User auth (OTP-based, unified user model)
│   ├── catalog/      # Services, SubServices, search
│   ├── customers/    # Home feed, discovery, nearby technicians
│   ├── technicians/  # Onboarding, profile, matchmaking
│   ├── marketing/    # Promotions/banners
│   ├── tests/        # All pytest test suites (mirrors app structure)
│   └── core/         # Django settings, URLs, exception handler
└── frontend/         # Flutter app
    ├── lib/
    │   ├── core/     # Routing, constants, shared entities, utilities
    │   └── features/ # Feature-first: auth, customer, technician
    ├── assets/icons/ # SVG icons (mapped by icon_name from backend)
    └── test/         # Widget, notifier, and repository tests
```

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.12+ | Use system Python or pyenv |
| Flutter | 3.41+ | `flutter doctor` must pass |
| MySQL | 8.0+ | Running locally |
| Git | Any | — |

---

## Backend Setup

### 1. Create and activate virtual environment

```bash
cd backend
python3 -m venv venv
source venv/bin/activate       # Linux/macOS
# venv\Scripts\activate        # Windows
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Create the `.env` file

Create `backend/.env` with the following keys (ask a team member for real values):

```env
SECRET_KEY=your-django-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=127.0.0.1
DB_PORT=3306

TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1xxxxxxxxxx

TWILIO_TEST_ACCOUNT_SID=your_twilio_test_account_sid
TWILIO_TEST_AUTH_TOKEN=your_twilio_test_auth_token
TWILIO_TEST_FROM_NUMBER=+15005550006
```

> **OTP in development:** With `DEBUG=True`, OTPs are never sent via Twilio. They print directly to the Django terminal:
> ```
> ========================================
>   [DEV OTP]  Phone : +923001234567
>   [DEV OTP]  Code  : 123456
> ========================================
> ```
> Pakistan blocks Twilio trial SMS verification — keep `DEBUG=True` during development.

### 4. Create the MySQL database

```sql
CREATE DATABASE your_db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 5. Run migrations

```bash
python manage.py migrate
```

### 6. Seed test data

```bash
python manage.py seed_test_data
```

This populates services (AC Repair, Plumbing), sub-services with pricing and Unsplash lifestyle photos, a test technician account, and sample promotions.

### 7. Start the development server

```bash
python manage.py runserver 0.0.0.0:8000
```

---

## Backend Tests

```bash
# From backend/ with venv activated
pytest
```

Tests use `pytest-django` + `factory_boy`. They run against an in-memory SQLite DB (configured automatically in `pytest.ini`). No MySQL connection needed for tests.

---

## Frontend Setup

### 1. Install Flutter dependencies

```bash
cd frontend
flutter pub get
```

### 2. Set the backend IP address

Open `frontend/lib/core/constants.dart` and update the IP to your machine's local network IP (not `localhost` — the Android emulator/device cannot reach the host machine via `localhost`):

```dart
static const String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000/api'
    : 'http://192.168.X.X:8000/api';  // <-- your machine's IP
```

Find your IP with `ip addr` (Linux) or `ipconfig` (Windows).

### 3. Run the app

```bash
flutter run
```

### 4. Regenerate code (if needed)

If you modify any `@freezed` model or `@riverpod` notifier, regenerate the generated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Frontend Tests

```bash
cd frontend
flutter test
```

---

## Icons

Service category icons are bundled as Flutter SVG assets in `frontend/assets/icons/`. The backend sends an `icon_name` key (e.g., `"ac_repair"`), and the frontend maps it to a local asset via `lib/core/utils/icon_assets.dart`.

**To add a new service category:**
1. Add an SVG file to `frontend/assets/icons/<icon_name>.svg`
2. Set `icon_name` to match (without `.svg`) in Django Admin

Recommended icon set: [Phosphor Icons](https://phosphoricons.com) (MIT-licensed, rounded style).

---

## Key Architecture Decisions

- **Unified User model** — no separate Customer/Technician registration. All users register with phone + OTP. Technicians apply via an onboarding flow that creates a `TechnicianProfile` with `status: PENDING` until an admin approves.
- **Payments** — Customer ↔ Technician: cash only. Technician ↔ Platform: virtual wallet (JazzCash top-up only).
- **Inspection Fee** — Rs. 500 per visit. If the customer accepts the technician's quote, Rs. 500 is deducted from the final bill. If declined, the customer pays Rs. 500 for the visit.
- **Backend architecture** — Thin Views → Fat Services → Selectors → Serializers (4-layer, no N+1 queries).
- **Frontend architecture** — Clean Architecture + Riverpod v3 (generator syntax, `@riverpod` annotation). All state via `@freezed` immutable classes.
