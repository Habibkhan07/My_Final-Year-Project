# Home Services Marketplace — FYP

A hyper-local marketplace connecting customers with home service professionals (plumbers, electricians, AC technicians, etc.) in Pakistan. Modelled after the InDrive on-demand approach.

**Stack:** Flutter (frontend) + Django REST Framework (backend) + MySQL + Redis + Celery

> **New to the project?** Read this top-to-bottom and follow every step in order. The "Backend Setup" section requires three running processes (Django, Celery, Redis); skipping any of them breaks the booking flow. The "Troubleshooting" section at the bottom catches the most common gotchas.

---

## Repository Structure

```
my_fyp_project/
├── backend/                      # Django REST Framework API + Channels (WebSocket)
│   ├── accounts/                 # User auth (OTP-based, unified user model)
│   ├── bookings/                 # JobBooking model, instant-book service, SLA timer, API
│   ├── catalog/                  # Services, SubServices, search
│   ├── customers/                # Home feed, discovery, addresses, availability lookup
│   ├── marketing/                # Promotions / banners
│   ├── realtime/                 # WebSocket events + streams pipelines, FCM dispatch
│   │   ├── events/               # Durable events (EventLog, FCM fallback, ACK)
│   │   ├── streams/              # Transient state (live GPS, typing, no DB write)
│   │   ├── devices/              # FCM device registration + push delivery
│   │   └── api/                  # WS routing + EVENT_DISPATCH_API.md / STREAM_DISPATCH_API.md
│   ├── technicians/              # Onboarding, profile, reviews, schedule, matchmaking
│   ├── tests/                    # All pytest suites (mirrors app structure)
│   └── core/                     # Django settings, URLs, ASGI entry, Celery app, exception handler
├── frontend/                     # Flutter app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── realtime/         # Single WS connection + WsFrameDispatcher (event vs stream)
│   │   │   ├── routing/          # GoRouter wiring
│   │   │   └── utils/            # IconAssets, shared utilities
│   │   └── features/
│   │       ├── auth/             # OTP login, signup, JWT session
│   │       ├── booking/          # Technician profile, availability, instant booking
│   │       ├── customer/         # Home feed, discovery results, addresses
│   │       └── technician/       # Onboarding, dashboard, incoming-job request
│   ├── assets/icons/             # SVG icons (mapped by icon_name from backend)
│   └── test/                     # Widget, notifier, repository tests
├── CLAUDE.md                     # Architecture rules + workflow (read before non-trivial work)
├── flag.md                       # Tech-debt log — accepted shortcuts and how to migrate
├── REALTIME_EVENTS_PATCH_SUMMARY.md   # Handoff brief: job_new_request dispatch
└── REALTIME_STREAMS_PATCH_SUMMARY.md  # Handoff brief: streams pipeline
```

---

## Prerequisites

| Tool | Version | Required for |
|------|---------|--------------|
| Python | 3.12+ | Backend |
| Flutter | 3.27+ (Dart `^3.10.7`) | Frontend (`flutter doctor` must pass) |
| MySQL | 8.0+ | App database |
| Redis | 6.0+ | Channels (WebSocket layer) **and** Celery (async tasks) |
| Git | Any | — |

### Installing Redis

| OS | Command |
|----|---------|
| Linux (Debian/Ubuntu) | `sudo apt install redis-server && sudo systemctl enable --now redis` |
| macOS (Homebrew) | `brew install redis && brew services start redis` |
| Windows | Use **WSL2** (recommended) or **Memurai**. Native Windows `redis-server.exe` is unmaintained. |

**Verify Redis is running** (do this before any backend work):
```bash
redis-cli ping
# → PONG
```

---

## Backend Setup

You will end up running **three things in parallel** during development:
1. **Django** (HTTP + WebSocket via ASGI) — terminal 1
2. **Celery worker** (booking SLA timeouts, async dispatch) — terminal 2
3. **Redis** (background service started once via `systemctl` / `brew services`)

### 1. Create and activate the virtual environment

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

This installs Django, DRF, MySQL client, Channels, Celery, Redis client, Firebase Admin SDK, Twilio, and the test stack (`pytest`, `factory-boy`, `pytest-mock`).

### 3. Create the `.env` file

Create `backend/.env` with **every** key below. Ask a team member for real values.

```env
# --- Django core ---
SECRET_KEY=your-django-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# --- MySQL ---
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_HOST=127.0.0.1
DB_PORT=3306

# --- Twilio (SMS / OTP) ---
# Production credentials — only used when DEBUG=False.
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1xxxxxxxxxx

# Test credentials — for the (unused) Twilio test endpoint.
TWILIO_TEST_ACCOUNT_SID=your_twilio_test_account_sid
TWILIO_TEST_AUTH_TOKEN=your_twilio_test_auth_token
TWILIO_TEST_FROM_NUMBER=+15005550006

# --- Redis (Channels + Celery) ---
# Defaults shown — override only if Redis runs elsewhere.
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

# --- Celery ---
# Defaults derive from REDIS_HOST/PORT and use Redis DB 1 (Channels uses DB 0).
# Override only if you have a separate broker.
CELERY_BROKER_URL=redis://127.0.0.1:6379/1
CELERY_RESULT_BACKEND=redis://127.0.0.1:6379/1

# --- Firebase Admin (FCM push) ---
# Path to the service-account JSON. Default points at backend/firebase_credintials.json.
# (The filename typo is intentional — historical, do not rename without coordinating.)
FIREBASE_CREDENTIALS_PATH=firebase_credintials.json
```

> **OTP in development:** With `DEBUG=True`, OTP is **never** sent via Twilio. The code is fixed to `123456` and prints to the Django terminal:
> ```
> ========================================
>   [DEV OTP]  Phone : +923001234567
>   [DEV OTP]  Code  : 123456
> ========================================
> ```
> Pakistan blocks Twilio trial SMS verification — keep `DEBUG=True` during development.

### 4. Get the Firebase credentials JSON

The backend uses Firebase Admin SDK to deliver FCM pushes when a technician's WebSocket is offline.

- Ask a team member for `firebase_credintials.json` (note the spelling — historical typo, settings.py expects exactly this filename).
- Place it at `backend/firebase_credintials.json`.
- **Never commit this file** — it contains a service-account private key.
- If you skip this step, the backend will start, but FCM pushes will fail at runtime. WebSocket events still work (technicians who are online receive job dispatches).

### 5. Create the MySQL database

```sql
CREATE DATABASE your_db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 6. Run migrations

```bash
python manage.py migrate
```

### 7. Seed test data

```bash
python manage.py seed_test_data
```

This populates:
- Services (AC Repair, Plumbing) and sub-services with pricing + lifestyle photos
- Test technicians with skills, schedules, reviews
- A test customer with saved addresses
- Sample promotions

**Login:** there are no pre-seeded test phones — sign up fresh via the app using any Pakistani number (`+92...`) and the `123456` OTP.

### 8. Start Django (terminal 1)

```bash
python manage.py runserver 0.0.0.0:8000
```

This serves both HTTP and WebSocket. `'daphne'` is registered as the first entry in `INSTALLED_APPS` (`core/settings.py`), which is what causes `runserver` to be replaced with the Daphne ASGI runserver — Channels 4.x dropped its own runserver patch, so Daphne is the only thing that gets `runserver` to speak WebSocket. If you ever see `GET /ws/events/... HTTP/1.1 404` in the runserver logs (instead of `WSCONNECTING /ws/events/`), it means `'daphne'` got dropped from INSTALLED_APPS and `runserver` fell back to plain WSGI. Production typically runs Daphne directly via `daphne core.asgi:application` — that path bypasses `runserver` entirely and works regardless of INSTALLED_APPS ordering.

### 9. Start the Celery worker (terminal 2)

```bash
# from backend/ with venv activated
celery -A core worker -l info
```

**This worker is required for the booking flow.** When a customer instant-books a job, the backend arms an SLA timeout via Celery (`bookings.tasks.expire_pending_job_booking`). Without the worker:
- Bookings still get created and dispatched.
- But they sit in `AWAITING` forever — the SLA timer never fires, and the technician's accept-or-expire countdown is never enforced server-side.

You'll know it's working when the worker logs show:
```
[tasks]
  . bookings.tasks.expire_pending_job_booking
celery@<host> ready.
```

### 10. Verify the stack

```bash
redis-cli ping                        # → PONG
curl http://127.0.0.1:8000/admin/     # → 302 redirect to login
celery -A core inspect active         # → shows the worker is registered
```

---

## Backend Tests

```bash
# from backend/ with venv activated
pytest
```

Tests use `pytest-django` + `factory_boy` against an in-memory SQLite DB (configured in `pytest.ini`). **All external services are mocked** — Twilio, the Channels group_send, Celery `apply_async`, and Firebase Admin. You do **not** need MySQL, Redis, or the Celery worker running to execute the test suite.

---

## Frontend Setup

### 1. Install Flutter dependencies

```bash
cd frontend
flutter pub get
```

### 2. Set the backend IP address

Open `frontend/lib/core/constants.dart` and update the IP to your machine's local network IP (not `localhost` — Android emulators and physical devices cannot reach the host via `localhost`):

```dart
static const String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000/api'
    : 'http://192.168.X.X:8000/api';  // <-- your machine's IP
```

Find your IP with `ip addr` (Linux) or `ipconfig` (Windows) or `ipconfig getifaddr en0` (macOS).

### 3. Run the app

```bash
flutter run
```

### 4. Regenerate code (when you modify a `@freezed` model or `@riverpod` notifier)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Frontend Tests

```bash
cd frontend
flutter test
```

Tests use `flutter_test` + `mocktail`. No real network calls — `Dio` and `FlutterSecureStorage` are mocked at the data-source boundary.

---

## Realtime Pipeline (read before touching `lib/core/realtime/` or `backend/realtime/`)

The project has **two distinct kinds of WebSocket traffic** that share one socket but have separate publishers, persistence, and contracts:

| | **Events** | **Streams** |
|---|---|---|
| Examples | `job_new_request`, `payment_received`, `wallet_low_balance`, chat *message* | live GPS, live wallet *balance*, AI chatbot *tokens*, chat *typing indicator* |
| Persistence | Written to `EventLog` | None |
| Offline fallback | FCM push | Drop on disconnect |
| ACK contract | Yes (for critical types) | No |
| Backend publisher | `EventDispatchService.broadcast_event(...)` | `realtime.streams.publish_stream(...)` |
| Wire envelope `kind` | `"event"` | `"stream"` |

The frontend `WsFrameDispatcher` routes on the top-level `kind` field. **Streams must never touch `EventLog`; events must never bypass it.** The two backend publishers are intentionally separate modules — the import graph enforces the boundary.

**Authoritative docs:**
- `backend/realtime/api/EVENT_DISPATCH_API.md` — event envelope + dispatcher contract
- `backend/realtime/api/STREAM_DISPATCH_API.md` — stream envelope + topic patterns
- `REALTIME_EVENTS_PATCH_SUMMARY.md` and `REALTIME_STREAMS_PATCH_SUMMARY.md` — handoff briefs (snapshots, may have stale references — see header in each)

---

## Booking Lifecycle

A `JobBooking` moves through these states:

```
PENDING → AWAITING (tech accept) → CONFIRMED → COMPLETED
                  ↘ REJECTED (SLA timeout fires while still AWAITING)
                  ↘ CANCELLED (customer)
```

- **`AWAITING`** and **`CONFIRMED`** both block the technician's slot in availability lookups (so an unaccepted booking still reserves its window).
- The **`AWAITING → REJECTED`** transition is driven by the Celery task `bookings.tasks.expire_pending_job_booking` — fired with a 60s countdown for ASAP jobs (`scheduled_start − now ≤ 2h`) or 900s otherwise.
- The **`AWAITING → CONFIRMED`** transition (technician accepts the job) is **not yet implemented** — see `flag.md`. For local end-to-end testing, simulate acceptance via Django Admin or shell by flipping `JobBooking.status` from `AWAITING` to `CONFIRMED`.

Full contract: `backend/bookings/api/BOOKINGS_API.md`.

---

## Per-feature documentation

Every feature owns its own contract docs. Read these before changing the feature:

- **Backend APIs**: `backend/<app>/api/<APP>_API.md` (e.g. `backend/bookings/api/BOOKINGS_API.md`, `backend/realtime/api/EVENT_DISPATCH_API.md`)
- **Frontend features**: `frontend/lib/features/<feature>/<FEATURE>_FEATURE.md` (e.g. `lib/features/booking/BOOKING_FEATURE.md`)

---

## Tech-Debt Log — `flag.md`

`flag.md` (repo root) is the authoritative log of accepted shortcuts and partial implementations. **Read it before changing anything that might intersect a flagged area** — it tells you what's deferred, why, and how to migrate when you pick the work back up. The full workflow (when to log a flag, schema, resolution format) is in `CLAUDE.md`.

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
- **Backend architecture** — Thin Views → Fat Services → Selectors → Serializers (4-layer, no N+1 queries). Strict error envelope across all endpoints.
- **Async tasks (Celery)** — Port-and-Adapter pattern. Service layer depends on a `typing.Protocol`; the only file that imports the Celery task is the adapter. Side-effects scheduled via `transaction.on_commit(...)` so a rolled-back transaction never queues phantom work. Full contract in `CLAUDE.md`.
- **Realtime** — Events vs streams (see above). One shared socket, two publishers, one frontend dispatcher.
- **Booking pricing** — Bookings carry FKs to `Service` / `SubService` / `Promotion` (the catalog references the customer chose). The server resolves a `booking_type` (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`) and stamps `price_amount` server-side — clients never send a price on the wire.
- **Frontend architecture** — Clean Architecture + Riverpod v3 (generator syntax, `@riverpod` annotation only). All state via `@freezed` immutable classes. Errors flow through the 4-step pipeline (DataSource → Repository → Domain sealed class → UI snackbar).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `redis.exceptions.ConnectionError` on Django startup | Redis isn't running. `redis-cli ping` should print `PONG`. Start it via `systemctl` / `brew services`. |
| WebSocket frames never arrive on Flutter | Redis not running, or `ALLOWED_HOSTS` doesn't include your dev host. Channels uses Redis as the channel layer. |
| Booking sits in `AWAITING` forever after dispatch | Celery worker isn't running. Start it: `celery -A core worker -l info`. |
| `FileNotFoundError: firebase_credintials.json` | Get the file from a team member; place at `backend/firebase_credintials.json` (note the spelling). |
| Flutter on Android can't reach backend | Replace `127.0.0.1` in `lib/core/constants.dart` with your machine's LAN IP, and make sure `ALLOWED_HOSTS` in `.env` allows it. |
| OTP isn't arriving on phone | Expected — `DEBUG=True` skips Twilio. Code is `123456` and prints to the Django terminal. |
| `pytest` fails with a Redis or Celery connection error | A test forgot to mock the channel layer or `apply_async`. Check `tests/realtime/` and `tests/bookings/services/` for the mock patterns used elsewhere. |
| `ModuleNotFoundError` after pulling new code | Re-run `pip install -r requirements.txt` (backend) or `flutter pub get` (frontend). |
| Frontend build fails with `*.freezed.dart not found` | Run `dart run build_runner build --delete-conflicting-outputs` from `frontend/`. |
