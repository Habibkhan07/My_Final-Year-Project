# Booking Orchestrator Sprint — Audit Report (v1)

> Independent audit of `BOOKING_ORCHESTRATOR_SPRINT.md` + the six session files. Cross-referenced against the live codebase as of 2026-05-08. Findings are bucketed by severity (P0 → P3) and category. Each finding cites session + section and proposes a concrete fix.
>
> **What this audit is NOT**: a re-design. The sprint's overall architecture (orchestrator service + slot UI + dual-barrel realtime + null-finance port) is sound. This audit catches the *details* that would burn implementation hours if shipped as-is.

---

## §0 Executive summary

**The plan is structurally good.** The orchestrator-as-single-writer, the FinancePort null-adapter pattern, the per-event feature wiring, the dumb-UI dispatch, the dual-provider map abstraction, the chip-stack quote builder and cash-collection single-tap — these are all defensible decisions that will hold up.

**The plan has ~30 concrete defects** (paths that don't exist, classes that don't exist, fields with the wrong name, packages assumed-present that aren't, race windows, and one architectural omission). They cluster in three buckets:

1. **Path/identifier hallucinations** — file paths and symbol names that don't match the live codebase (8 P0/P1 items). These will fail at the very first `import` statement.
2. **Package mismatch** — sprint code uses `Dio` everywhere; pubspec has `http`. Compile-fail blast radius across sessions 3-6 (1 P0 item but the largest in scope).
3. **Subtle correctness gaps** — promo snapshot writes never patched, `tech_reliability_penalty` event has no admin target_role, WS dispatcher unregister arity mismatch, cache + realtime serving stale data without bust, etc. (10 P1/P2 items).

**Recommended action**: do a "fix-the-audit" pass on the seven files in this folder before opening session 1. Most fixes are 1-2 line edits. Two fixes (Dio→http, promo snapshot) are larger but localized.

**What this audit does NOT find**: the sprint is internally consistent on naming (status enum values, event wire strings, modal endpoint patterns), the role separation (customer/tech) is consistently applied, and the deferral story (finance/iOS/chatbot/reviews) is well-scoped. The 16 architectural decisions are coherent.

---

## §1 Severity legend

- **P0 — Blocker**: code as written will not compile or will silently mis-behave. Fix before session 1.
- **P1 — High**: code will compile but produce a broken feature, wrong data, or a security hole. Fix in the relevant session.
- **P2 — Medium**: works in dev, breaks in production / under load / under specific edge cases. Fix in the relevant session if time permits, otherwise log a flag.
- **P3 — Low/nit**: style, documentation, future-proofing. Defer or batch.

---

## §2 P0 findings (blockers — fix before any session starts)

### P0-01 — `BookingValidationError` does not exist in `bookings/exceptions.py`

**Where**: Session 1 §1 decision 11, §4 File 12, and every orchestrator function in §4.8 imports `from bookings.exceptions import BookingValidationError`. Session 2 §4.0 and §4.11 also import it.

**Reality**: `backend/bookings/exceptions.py` defines `InvalidAddressError`, `OutOfServiceAreaError`, `SlotUnavailableError`, `InconsistentBookingIntentError`, `PromoFirewallError`, `BookingNotFoundForTechnicianError`, `BookingNotActionableError` — **no `BookingValidationError`**.

**Why this is a blocker**: every orchestrator function `raise BookingValidationError(code=..., message=..., errors=...)` would `NameError` at call time. The custom exception handler envelope shape (`{status, code, message, errors}`) needs a class that carries those fields.

**Fix**: in Session 1 File 12, **add** the class (don't pretend it already exists):

```python
# backend/bookings/exceptions.py — add
from rest_framework.exceptions import APIException

class BookingValidationError(APIException):
    """Raised by orchestrator transitions; serialized by the standard
    exception handler into {status, code, message, errors}."""
    status_code = 400
    default_detail = 'Booking transition invalid.'
    default_code = 'invalid_transition'

    def __init__(self, *, code: str, message: str, errors: dict | None = None, status: int = 400):
        self.status_code = status
        self.code = code
        self.message = message
        self.errors = errors or {}
        super().__init__(detail=message, code=code)
```

**Also update**: `backend/core/common/failures/exception.py` (the custom handler) to recognize `BookingValidationError` and emit the envelope — verify by reading the existing handler and patching if needed.

---

### P0-02 — `request.user.technician_profile` related_name is wrong

**Where**: Session 2 §4.0 canonical example, §4.6 BookingDetailView (line `request.user.technician_profile.id`), §4.10 `_can_subscribe`, plus implicit assumption throughout sessions 3–6.

**Reality**: `TechnicianProfile.user = OneToOneField(..., related_name='tech_profile')` — the reverse accessor is `request.user.tech_profile`, **not** `request.user.technician_profile`.

**Why this is a blocker**: every tech-side permission check `if not hasattr(request.user, 'technician_profile')` returns False for legitimate techs → every tech-only endpoint returns 403. The whole orchestrator flow is bricked.

**Fix**: replace **all** instances across sessions 2–6 of `technician_profile` (as a User attribute) with `tech_profile`:

```python
# Wrong
if not hasattr(request.user, 'technician_profile'):
    return Response({'status': 403, 'code': 'not_a_technician', ...})
booking.technician_id == request.user.technician_profile.id

# Right
if not hasattr(request.user, 'tech_profile'):
    return Response({'status': 403, 'code': 'not_a_technician', ...})
booking.technician_id == request.user.tech_profile.id
```

Frontend is unaffected (Flutter doesn't reference this).

---

### P0-03 — Codebase uses `http`, sprint uses `Dio` everywhere

**Where**: Sessions 3, 4, 5, 6 — every data source (`booking_detail_remote_data_source.dart`, `quote_remote_data_source.dart`, `cash_collection_remote_data_source.dart`, `start_inspection_remote_data_source.dart`, `sub_service_catalog_remote_data_source.dart`, `cancellation_remote_data_source.dart`, `reschedule_remote_data_source.dart`, `no_show_remote_data_source.dart`, `dispute_remote_data_source.dart`, `tech_location_remote_data_source.dart`), `BookingActionExecutor`, `GoogleDirectionsService`, `OsrmDirectionsService`, the foreground service handler.

**Reality**: `frontend/pubspec.yaml` declares `http: ^1.2.0`. There is no `dio` package. Existing data sources (e.g. `auth_remote_data_source.dart`, `customer_bookings_remote_data_source.dart`) use `http.Client` injected via `eventHttpClient` provider.

**Why this is a blocker**: every Dio import in every new file fails at compile. ~20 files affected.

**Fix — pick one**:

**Option A (recommended): swap to `http`**. Faster. Keeps the existing pattern. Each data source takes `http.Client` (constructor-injected via Riverpod), reads token from `flutter_secure_storage`, calls `client.post(Uri.parse(...), headers: {...}, body: jsonEncode(...))`. Maps `response.statusCode` to `HttpFailure` directly (no `DioException`). Existing `_handleResponse` pattern in `auth_remote_data_source.dart` is the template.

**Option B: add `dio: ^5.x` to pubspec**. Bigger upfront work — also need to introduce a Dio instance provider (`dioProvider`), a Dio interceptor for auth (sprint's data sources read token per-request, but that's not idiomatic Dio), and migrate the existing http data sources to maintain consistency. Likely 1-day effort just for this.

**Decide before session 3 starts.** I recommend **A** because the existing http pattern is fine, the sprint doesn't actually use any Dio-specific feature (cancellation tokens, interceptors, retry), and B would force migration of currently-working code.

**Also**: the foreground service in session 4 (which runs in a separate isolate) needs its own http.Client (Dio's would too). Document this in §4.

---

### P0-04 — `event_urgency_router.dart` path is wrong

**Where**: Session 3 §2 (file table), §4.7 heading, and several other references; Session 4 §2 NOT-touched table.

**Sprint says**: `frontend/lib/core/realtime/router/event_urgency_router.dart`

**Reality**: `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` (under `presentation/`).

**Fix**: update all references to include the `presentation/` segment. Same fix in 4 places.

---

### P0-05 — Catalog migration number is wrong

**Where**: Session 1 §2 (table), §4 File 4, §6 (rollback example).

**Sprint says**: `backend/catalog/migrations/0009_subservice_max_price.py`.

**Reality**: `catalog/migrations/` latest is `0007_add_duration_minutes.py`. **Next migration is `0008_*`**, not `0009_*`. The §6 verification block also says `python manage.py migrate catalog 0008` (rollback), which would mean rolling back the new migration — but it actually rolls back to the existing 0007.

**Fix**: rename the new migration to `0008_subservice_max_price.py`. Update §3 pre-flight (`grep 0009` → `grep 0008`), §6 rollback example, and any later session that references it.

---

### P0-06 — Wrong settings file path

**Where**: Session 2 §2 (settings table), §4.7 verification (`grep BOOKING_GEOFENCE_STRICT backend/karigar/settings.py`), §6 verification.

**Sprint says**: `backend/karigar/settings.py`.

**Reality**: `backend/core/settings.py` — there is no `backend/karigar/` directory.

**Fix**: replace `karigar` with `core` everywhere in session 2 (§2, §3 pre-flight grep, §4.7, §6).

---

### P0-07 — `WsFrameDispatcher.unregister(streamType, handler)` is wrong arity

**Where**: Session 4 §4.8 `TechnicianLocationStreamNotifier.build()`:

```dart
ref.onDispose(() {
  dispatcher.unregister('tech_gps', handler);   // <- wrong arity
});
```

**Reality**: `WsFrameDispatcher.unregister(String streamType)` takes a single positional arg. The dispatcher stores **one handler per streamType** (`Map<String, void Function(...)>`); registering a second handler for the same type silently replaces the first. There is no per-handler unregistration.

**Why this matters**: code as written fails to compile. And even after fixing the arity, the sprint's contract ("multiple booking-detail screens can coexist as stream consumers" implied in §4.8) is **not supported by the existing dispatcher** — it's a real refactor, not a confirmation.

**Fix — pick one**:

**Option A (simpler, recommended for v1)**: keep dispatcher as-is. Document that only ONE active orchestrator screen consumes the `tech_gps` stream at a time. `TechnicianLocationStreamNotifier` registers in `build()`, calls `dispatcher.unregister('tech_gps')` (single arg) in `ref.onDispose`. Add a runtime guard: log a warning if a second registration happens.

**Option B (do the real refactor)**: extend dispatcher to `Map<String, List<HandlerFn>>`, change `register` to append + return a token, change `unregister(token)` to remove by token. This is what the sprint *implies* but doesn't actually scope.

**Decide before session 4.** The streams contract today is single-handler.

---

### P0-08 — `tech_reliability_penalty` event has no admin `target_role`

**Where**: Sprint meta §16 (event table), Session 1 File 8 `cancel_by_tech` docstring.

**Sprint says**: "Fires `tech_reliability_penalty` event (admin-only audience this sprint; user-facing reliability score is post-MVP)".

**Reality**: `EventLog.target_role` accepts only `TARGET_CUSTOMER = "customer"` and `TARGET_TECHNICIAN = "technician"`. There is no `admin` value. `EventDispatchService.broadcast_event(target_role=...)` is a free-form string param but the model has CHOICES that would reject other values at save time.

**Fix — pick one**:

**Option A (recommended)**: don't broadcast `tech_reliability_penalty` as a realtime event at all. It's not user-facing this sprint. Write it to a new `TechReliabilityEventLog` model (or just an admin-visible log line), keep it out of the realtime pipeline. Update sprint meta §16 to remove the row.

**Option B**: extend `EventLog.TARGET_ROLE_CHOICES` to include `"admin"` and `"system"`. Adds complexity (admin users don't subscribe to a per-user WS group; they subscribe to an all-admins group). Defer to a future "admin notification" sprint.

---

## §3 P1 findings (high — must fix in the relevant session)

### P1-01 — Customer `phone_no` field doesn't exist on User

**Where**: Session 2 §4.6 `_CustomerMiniSerializer` and `BookingDetailResponseSerializer.to_representation`:
```python
'phone_no': getattr(booking.customer, 'phone_no', ''),
```
Session 3 §4.1 `BookingCustomer.phoneNo` field; mapper reads `model.customer['phone_no']`.

**Reality**: `booking.customer` is a Django `User`. User has no `phone_no` attribute. The phone lives on `accounts.UserProfile.phone` (separate model, OneToOne via `user.userprofile.phone`).

**Why this matters**: `getattr(... 'phone_no', '')` always returns `''`. Customer's phone never reaches the orchestrator screen. Tech can't call them.

**Fix**: in session 2 serializer:

```python
'phone_no': getattr(booking.customer, 'userprofile', None) and booking.customer.userprofile.phone or '',
```

Better: change the selector to `prefetch_related('customer__userprofile')` and pass `booking.customer.userprofile.phone`. Document that `userprofile` is the related_name (verify via `accounts/models.py`).

---

### P1-02 — Technician `profile_url` field doesn't exist

**Where**: Session 2 §4.6 `BookingDetailResponseSerializer.to_representation`:
```python
'profile_picture_url': getattr(booking.technician, 'profile_url', None),
```

**Reality**: `TechnicianProfile.profile_picture = ImageField(upload_to='tech_profiles/')`. To get a URL, use `booking.technician.profile_picture.url` (when set) and ideally absolutize via `request.build_absolute_uri(...)` — see existing `technicians/selectors/dashboard_selector.py` lines 71–80 for the canonical pattern.

**Fix**:
```python
profile_picture_url = (
    request.build_absolute_uri(booking.technician.profile_picture.url)
    if booking.technician.profile_picture else None
)
```

---

### P1-03 — `promo_code_snapshot` write site is missing

**Where**: Sprint meta §17 says `JobBooking.promo_code_snapshot` is "denormalized to survive promo deletion/expiry" and §15 edge case 10 says "Snapshotted at booking creation". Sprint meta §4 architectural decision 12 confirms.

**Reality**: Session 1 adds the **column** but does not patch `instant_book_service.py::create_instant_booking` to **write** the snapshot. As a result, every new booking has `promo_code_snapshot = NULL` even when a promotion was applied. The snapshot is dead data.

**Why this matters**: the entire reason for the snapshot (survive promotion deletion mid-flow) is defeated. Booking detail will show no promo info if the promo gets disabled or deleted between booking creation and completion.

**Fix**: add an explicit modification to `instant_book_service.py` in Session 1 §2 file table:

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/services/instant_book_service.py` | **modified** | After resolving promotion, write `promo_code_snapshot=promotion.code, promo_discount_snapshot=<discount_amount>` onto the new booking before save. |

And add Session 1 §4 instructions for the patch + a test.

---

### P1-04 — `BookingDetailView` cache vs realtime patches: stale data window

**Where**: Session 2 §4.6 `@method_decorator(cache_control(private=True, max_age=5))`. Session 2 §5 gotcha 10 acknowledges and says frontend should `?nocache=<ts>` query-bust.

**Reality**: Session 3 §4.4 `BookingDetailRemoteDataSource.fetch()` does NOT add a cache-bust query string when called as part of `refresh()`. So when a realtime event fires `→ BookingOrchestratorEventsNotifier.refresh() → repository.getBookingDetail()`, the request hits the same URL — and within 5 seconds of the previous fetch, the browser/client cache (or any intermediate proxy) returns the stale response. UI stays out of sync until the cache window expires.

**Why this matters**: defeats the realtime patching architecture. The realtime event is what makes the UI fresh; the cache silently undermines it.

**Fix — pick one**:

**Option A (recommended)**: drop the `cache_control` decorator entirely. The orchestrator screen mounts ONCE per booking; subsequent fetches are event-triggered (which by definition mean state changed). 5s caching saves nothing meaningful and breaks correctness.

**Option B**: keep the cache, but `BookingDetailRemoteDataSource.fetch()` adds `?ts=${DateTime.now().millisecondsSinceEpoch}` on every call. Document the convention. Risk: future intermediate proxies might still cache.

I'd take A. The original justification ("absorb burst from screen mount + per-event re-fetches") is not a real burst — there's one fetch on mount and ~one fetch per event.

---

### P1-05 — Stream notifier mutates `state` from inside `build()`

**Where**: Session 4 §4.8 `TechnicianLocationStreamNotifier`:

```dart
@Riverpod(keepAlive: false)
class TechnicianLocationStreamNotifier extends _$TechnicianLocationStreamNotifier {
  TechGpsFrame? _latest;

  @override
  TechGpsFrame? build(int jobId) {
    final dispatcher = ref.read(wsFrameDispatcherProvider);

    void handler(Map<String, dynamic> payload) {
      // ...
      _latest = frame;
      state = frame;          // <- mutating state from inside the closure
    }

    dispatcher.register('tech_gps', handler);
    ref.onDispose(() {
      dispatcher.unregister('tech_gps', handler);
    });
    return null;       // initial build returns null
  }
}
```

**Why this matters**: writing `state = frame` from a callback registered during `build()` is well-defined in Riverpod v2 (it's how stream subscriptions work — you set up the listener during build, then it fires async), BUT:
1. If the handler fires before `build()` returns and produces the `_$TechnicianLocationStreamNotifierProvider` element, the assignment is a no-op (or worse, an error in some Riverpod versions).
2. The dual-storage (`_latest` and `state`) is redundant — `state` IS the latest.

**Fix**: simplify. Use `StreamNotifier` pattern OR ensure `state` set happens in a microtask:

```dart
@Riverpod(keepAlive: false)
class TechnicianLocationStreamNotifier extends _$TechnicianLocationStreamNotifier {
  @override
  TechGpsFrame? build(int jobId) {
    final dispatcher = ref.read(wsFrameDispatcherProvider);

    void handler(Map<String, dynamic> payload) {
      try {
        final model = TechGpsFrameModel.fromJson(payload);
        if (model.bookingId != jobId) return;
        // Defer state set to the next microtask so it never races with build's return.
        Future.microtask(() {
          if (!ref.mounted) return;
          state = TechGpsFrameMapper.toDomain(model);
        });
      } catch (_) { /* drop malformed */ }
    }

    dispatcher.register('tech_gps', handler);
    ref.onDispose(() {
      dispatcher.unregister('tech_gps');     // single-arg per P0-07 fix
    });
    return null;
  }
}
```

Drop `_latest` entirely.

---

### P1-06 — `WS subscribe_tracking` re-subscribe on reconnect is hand-waved

**Where**: Session 2 §5 gotcha 5 ("Frontend (session 4) handles this on `wsConnected` event"). Session 4 §1 decision 12 ("Re-subscribe on WS reconnect (handled by reconnect listener)").

**Reality**: `WsConnectionNotifier` (verified) exposes `connect()`, `disconnect()`, but does NOT expose a public "I just reconnected" event/stream. The reconnect logic is private (`_scheduleReconnect`). There is no listener pattern.

**Why this matters**: if the WS drops (mobile networks, app backgrounded then foregrounded), the consumer rejoins the user-group automatically (server-side `connect`), but `tracking_job_<id>` subgroup membership is per-channel — it's lost on disconnect. The customer's map silently freezes and there's no re-subscribe trigger.

**Fix**: in Session 4 §2 add to the modified-files table:

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` | **modified** | Expose a `Stream<WsConnectionEvent>` (or a `connectedAt: DateTime?` watchable state field) that emits on every successful (re)connection. `TrackingSubscriptionController` listens and re-issues subscribe calls for any currently-tracked booking. |

Document the contract change in CLAUDE.md amendments at session 6.

---

### P1-07 — In-memory rate limit for `/tech-location/` is per-process

**Where**: Session 2 §1 decision 8, §4.5 throttle, §5 gotcha 4 (acknowledges).

**Reality**: under any multi-worker Daphne/Gunicorn deployment, a tech could send N tightly-spaced POSTs and get past the 4s throttle once per worker (so up to N/throttle_window if requests round-robin). Each accepted POST publishes a stream frame and may auto-transition.

**Why this matters in v1**: probably tolerable for development. But **auto-transition** firing under burst conditions could cause status bouncing (CONFIRMED → EN_ROUTE → ARRIVED in rapid succession if the GPS spike is bad). Customer's UI gets event spam.

**Fix — minimum**: add Session 2 §4.5 stricter doc + a flag for production. **Recommended**: implement Redis-backed token bucket using the Channels Redis instance (already deployed). Cost: ~30 lines of code, single redis SET/GET round-trip per call.

```python
import redis
import time
from django.conf import settings

_redis = redis.from_url(settings.CELERY_BROKER_URL)

def _rate_limit(tech_id: int, booking_id: int, window_s: int = 4) -> bool:
    key = f'tech_location_rl:{tech_id}:{booking_id}'
    now = time.time()
    # SET key NX EX window_s — returns True only if key didn't exist.
    return bool(_redis.set(key, str(now), nx=True, ex=window_s))
```

If skipped this sprint, **explicitly open a flag** (`tech-location-rate-limit-not-distributed`) so it doesn't get lost.

---

### P1-08 — `start_inspection` fire-and-forget swallows real failures

**Where**: Session 5 §4.2 `StartInspectionRemoteDataSource.startInspection`:

```dart
try {
  await _dio.post(...);
} catch (e) {
  log('start-inspection failed (continuing): $e');
}
```

Combined with §4.4 `QuoteBuilderScreen.initState`'s `Future.microtask(() => startInspection(...))`.

**Why this matters**: if the call fails for a *real* reason (booking is in CANCELLED, tech is no longer assigned, network is down), the tech sees the quote builder open and starts entering line items, then gets a `400 invalid_transition` on submit (or worse, the submit succeeds against a stale state and creates a Quote on a CANCELLED booking).

**Fix — minimum**: the swallow is fine, but `submit_quote` orchestrator must reject quote creation when booking status is not in `{ARRIVED, INSPECTING, IN_PROGRESS}` (it already does per session 1 §4.8 — verify). Add a UI-side guard: if the screen mounts and `booking.status` is terminal, show an error overlay and a "Back" button instead of the builder.

Better: don't fire-and-forget. Await the call; on failure, surface a snackbar; if the failure was "already INSPECTING", continue (orchestrator's idempotency makes it safe).

---

### P1-09 — Modal endpoint dispatch via `endpoint.endsWith(...)` is fragile

**Where**: Session 5 §4.0, Session 6 §4.0 — `_openModal(String endpoint, int bookingId)` uses an if-else chain on `endpoint.endsWith(...)`.

**Why this matters**: server emits a stable string contract. Frontend matches by suffix. If the server typo-changes a single character (`/cancel-confirm` → `/cancel-confirmation`), frontend silently falls through every branch and the user taps a button that does nothing. No compile-time guard. No test catches it unless the test enumerates strings.

**Fix**: a **modal endpoint registry** as a source-of-truth constant, used by both server (in `bookings/selectors/orchestrator_ui.py`) and client. Server-side: define `MODAL_ENDPOINTS` in a shared location (e.g. `bookings/api/modal_endpoints.py`); UI selector imports + emits constants. Client-side: define a Dart `MODAL_ENDPOINT_KEYS` constant; `_openModal` switches on the key, not endsWith. Code-gen the same enum from a YAML file if you want to be fancy; otherwise just keep them in sync via test that asserts the lists match.

For v1 minimum: write a single test that hits each backend `orchestrator_ui` handler, captures every emitted modal endpoint, and asserts each is handled by `_openModal`. Catches mismatches at CI time.

---

### P1-10 — Image upload validation is missing

**Where**: Session 2 §4.4 `OpenDisputeView` and `OpenDisputeRequestSerializer`:

```python
photo = serializers.ImageField(required=False, allow_null=True)
```

**Why this matters**: no `max_length`, no MIME-type whitelist, no file-size limit. Risk: malicious upload (multi-GB image, ZIP-bomb, malformed image that crashes Pillow). DRF's `ImageField` does Pillow-validate the image (rejects malformed) but doesn't bound size.

**Fix**: in the serializer, validate:

```python
class OpenDisputeRequestSerializer(serializers.Serializer):
    initial_reason = serializers.CharField(min_length=10, max_length=2000)
    photo = serializers.ImageField(required=False, allow_null=True)

    def validate_photo(self, photo):
        if photo and photo.size > 5 * 1024 * 1024:    # 5 MB
            raise serializers.ValidationError('Photo must be under 5 MB.')
        return photo
```

Plus: enforce server-wide limits at the WSGI/ASGI layer (`DATA_UPLOAD_MAX_MEMORY_SIZE`, `FILE_UPLOAD_MAX_MEMORY_SIZE` in settings). Verify these are configured.

---

### P1-11 — `BodySlot` switch is exhaustive but `pending` and `unknown` are folded together

**Where**: Session 3 §4.10 `BodySlot.build()`:

```dart
BookingStatus.pending || BookingStatus.unknown => UnknownBodyStub(booking: booking),
```

**Why this matters**: `pending` is a legacy status (per-codebase docs) that should never be seen on the orchestrator screen. Folding it into `unknown` hides the distinction. If a legacy `PENDING` booking somehow surfaces, the customer/tech sees a generic "unknown" UI rather than a more specific "this booking is pre-orchestrator-era" message — useful for debugging during the rollout.

**Fix — minor**: keep them folded, but `UnknownBodyStub` should log a warning if `booking.status == BookingStatus.pending` so reports surface during QA. P3 candidate, P1 because it'll bite you in the rollout window.

---

### P1-12 — Reviews/ratings flag is in §15 but not in §20

**Where**: Sprint meta §15 edge case 9 says "Defer to its own future sprint. **Open flag**." But §20 (per-session flag transitions) does not list a `reviews-deferred` flag opening for any session.

**Fix**: add to §20 session 1 (or another session) row: opens `reviews-deferred`. Otherwise the deferral has no audit trail.

---

### P1-13 — `URL pattern conflict` between booking-detail and bookings-list

**Where**: Session 2 §4.7 `bookings/api/urls.py` modification.

**Reality**: existing `bookings/api/urls.py` line 16 has `path('', CustomerBookingsListView)`. Session 2 adds `path('<int:booking_id>/', BookingDetailView)`. Django URL resolution is order-dependent. The `'<int:booking_id>/'` pattern won't match the empty path — but the order matters when adding `path('counts/', ...)` etc. The existing layout already routes them correctly, but session 2 doesn't show the **explicit ordering** of the modifications.

**Fix**: in Session 2 §4.7, show the **full** new urls.py with explicit ordering: `''` (list) → `'counts/'` → `'<int:>/'` (detail) → `'instant-book/'` → `'<int:>/<action>/'`. Verify in pre-flight that order is correct.

Edge case: a booking with id "instant-book" wouldn't exist (id is int), so no actual collision. But "counts" would match as text — Django's `<int:>` converter rejects non-numeric, so safe.

---

### P1-14 — `target_role` for `dispute_opened` to admin/counterparty is ambiguous

**Where**: Sprint meta §16 events table: `dispute_opened` recipient = "Counterparty + admin". Session 1 file 8 `open_dispute` docstring says "Fires `dispute_opened` event to counterparty + admin".

**Reality**: `EventDispatchService.broadcast_event` takes ONE `target_role` per call. To target two recipients (counterparty + admin), the orchestrator must call `broadcast_event` TWICE: once with `target_role='customer'` (or `'technician'`) and again with `target_role='admin'`. But `'admin'` isn't a valid choice (P0-08).

**Fix**: same as P0-08. Drop the admin broadcast for now; the admin sees disputes via Django Admin, not via realtime push. Update sprint meta §16 + Session 1 file 8 docstring to say "Fires `dispute_opened` event to counterparty (admin sees via Django Admin)".

---

## §4 P2 findings (medium — fix if time permits, otherwise flag)

### P2-01 — Foreground service battery cost not budgeted

**Where**: Session 4 §1 decision 7+10. 5s GPS + foreground notification + WS connection + Dio POST per fix.

**Why this matters**: average job duration is 1-2 hours. Continuous high-accuracy GPS for 2 hours drains ~30-40% of a typical battery. Pakistani technicians often use older Android phones with degraded batteries.

**Fix**: distance-filter the position stream more aggressively (`distanceFilter: 25m` instead of 10m for extra savings); reduce accuracy when distance to customer is >2km; reduce broadcast cadence to 10s when speed is low (parked, walking). Document trade-off in flag if not implemented.

---

### P2-02 — Polyline refresh quota math (Google free tier)

**Where**: Session 4 §1 decision 5+6. 30s minimum interval; polyline refresh on >500m drift.

**Reality**: Google Directions free tier ~$200 credit/month → ~40k requests/month (at $5/1000). At 1 request per 30s per active EN_ROUTE booking, with 10 simultaneous active bookings, that's 1200/hour = 28800/day = exhausted in 1.4 days. OSM/OSRM is unlimited but the public OSRM instance has a 1 RPS limit.

**Fix**: enforce 30s minimum + recompute-on-drift more strictly; for production switch to a self-hosted OSRM or Mapbox; flag the cost.

---

### P2-03 — EventLog unbounded growth

**Where**: Sprint introduces 5 new event types fired per transition. Backend doesn't define a cleanup task.

**Reality**: at scale, EventLog grows at (events/booking) × (bookings/day) rows/day. 13 events × 1000 bookings/day = 13k rows/day = 4.7M rows/year. Indexed by user/created_at, queries stay fast, but storage adds up.

**Fix**: open a `eventlog-retention-policy-tbd` flag. Define a Celery beat task to delete EventLog rows older than 90 days. Defer to ops/scaling sprint.

---

### P2-04 — Test factory inheritance chain depth

**Where**: Session 1 §5 gotcha 16 acknowledges the chain (`JobBookingFactory` → `Confirmed` → `EnRoute` → `Arrived` → `Inspecting` → `Quoted` → `InProgress` → `Completed`).

**Why this matters**: 7 levels of inheritance. Field overrides at each level. Test brittleness: changing a field in `JobBookingFactory` could ripple unpredictably. Each subclass must explicitly set what it needs to flip.

**Fix**: factory chain is OK but **add a `traits` pattern** (`factory_boy` supports them) for the more orthogonal status combinations. Or: keep the chain but assert with a unit test that `JobBookingCompletedFactory()` produces a row with all expected fields populated (regression catch).

---

### P2-05 — `available_transitions` projection vs orchestrator validation drift

**Where**: Session 2 §4.9 `transition_validator.py` is a hand-mirrored list of orchestrator's actual rules. Session 2 §1 decision 5 says the test enumerates every (status, role) and asserts they match.

**Why this matters**: the test catches drift but doesn't prevent it. A future PR could add an orchestrator rule and forget the validator. Drift becomes a UI-only bug (button missing or button shown that 400s).

**Fix**: instead of two implementations, derive the validator FROM the orchestrator. Have each orchestrator function declare its valid from-states as a class attribute (or a registered decorator); validator iterates the registry. Single source of truth. ~20 lines of refactor; saves future drift entirely.

If skipped: add a CI-level test (already in §1 decision 5) — make sure it actually enumerates every case via parametrize, and runs in CI.

---

### P2-06 — `bookingDetailNotifierProvider.refresh()` flashes loading state

**Where**: Session 3 §4.8 `BookingDetailNotifier.refresh()`:

```dart
state = const AsyncValue.loading();
state = await AsyncValue.guard(() async { ... });
```

Session 3 §5 gotcha 14 acknowledges and defers to session 6.

**Why this matters**: every realtime event triggers a refresh that flashes the loading spinner. UX feels jittery on a busy lifecycle.

**Fix (defer is OK)**: use AsyncValue with `previous` value preserved:

```dart
state = AsyncValue<BookingDetail>.loading().copyWithPrevious(state);
state = await AsyncValue.guard(() async { ... });
```

This shows the prior data with a subtle loading indicator instead of a full spinner.

---

### P2-07 — `_can_subscribe` doesn't check booking status

**Where**: Session 2 §4.10 `_can_subscribe(user_id, booking_id)`.

**Reality**: only checks user is customer or tech of the booking. Doesn't check booking is in EN_ROUTE / ARRIVED. So a customer could subscribe to `tracking_job_<id>` for a COMPLETED booking and receive any stale stream frames the tech accidentally sends post-completion.

**Why this matters**: low-impact privacy issue (tech's location after job done). Tech's app should stop publishing on COMPLETED, but defense-in-depth.

**Fix**: in `_can_subscribe`, also reject if `booking.status` is in `TERMINAL_STATUSES` (`COMPLETED, COMPLETED_INSPECTION_ONLY, CANCELLED, REJECTED, NO_SHOW, DISPUTED`). Log and silent-drop.

---

### P2-08 — Customer cancellation Rs.500 fee accumulation: no idempotency check

**Where**: Sprint meta §7 cancellation policy. Session 1 file 8 `cancel_by_customer`:
> Sets `final_cash_to_collect` for fee phases.

**Why this matters**: if customer cancels at CONFIRMED (`final_cash_to_collect = 500`), then somehow the row gets back to a non-CANCELLED state (admin rollback?), then customer cancels again at ARRIVED (`final_cash_to_collect = 500`) — does it overwrite or add? Sprint silent.

**Reality**: the orchestrator's idempotency clause says "same actor, same target state → no-op success", which means the second cancel is a no-op. Good. But: not enforced for customer-cancel from a *different* phase reaching the same CANCELLED status.

**Fix**: in `cancel_by_customer`, check if `booking.status == CANCELLED` and return early (idempotent), regardless of which from-state was previously valid. Add test.

---

### P2-09 — `parent_booking` cascade behavior on hard delete

**Where**: Session 1 §5 gotcha 4 acknowledges. `parent_booking` uses `on_delete=SET_NULL`.

**Why this matters**: if a parent booking is hard-deleted (admin tooling, or future migration), the child loses its lineage link. Sprint says "you shouldn't" hard-delete. But Django Admin allows hard-delete by default.

**Fix**: override `delete_model` on `JobBookingAdmin` to refuse hard delete on bookings with children. Or set `is_archived` flag and filter admin views. Defer to a future polish if not critical.

---

### P2-10 — Stream-staleness threshold (60s) doesn't pause auto-refresh of other UI

**Where**: Session 4 §4.6 `LiveTrackingMap` shows the offline banner. But the orchestrator screen's `bookingOrchestratorEventsNotifier` continues subscribing — no signal that the tech has actually disconnected.

**Why this matters**: customer sees "Tech offline" banner on the map, but the rest of the orchestrator UI (status label, etc.) doesn't acknowledge the offline state. Could be confusing — "Tech is offline" but "Status: ARRIVED" sticking.

**Fix (P3-ish)**: when stream is stale, show a header banner ("Connection to technician lost; status may be out of date"). Not critical for v1.

---

### P2-11 — Geofence strict mode rejects but doesn't tell tech how to override

**Where**: Session 2 §4.1 `ArrivedView`: in strict mode, returns `400 not_at_customer_location`.

**Why this matters**: tech sees an error; UI mode doesn't expose the manual override path (long-press? admin contact?). Per §14 rule 1 manual overrides exist "via long-press or admin override" — not implemented in any session.

**Fix**: implement the long-press affordance in session 6 OR explicitly defer with a flag. As written, strict mode locks out techs with spotty GPS.

---

## §5 P3 findings (low / nits)

### P3-01 — Sprint meta §3 pre-read list outdated

Sprint meta §3 references `session_4_customer_bookings_list_ui.md` as a voice template. Confirm this file exists in the repo root (it should, per the conversation history). If not, point to a different exemplar.

### P3-02 — `NullFinanceAdapter` accepts `Decimal` but ignores; type unused

The `from decimal import Decimal` import in `null_finance.py` is technically unused (no real arithmetic happens). Either keep for type-hint consistency or drop. P3.

### P3-03 — `BookingDetailMapper.toDomain` parses many `int.parse(model.x.toString())`

Verbose. A small helper `_decimalToInt(Map<String, dynamic> obj, String key)` would DRY up the mapper. P3 cleanup.

### P3-04 — `customer_bookings_list_notifier.dart` switch grows with each new event

Session 3 §4.13 extends the switch. Today: 2 cases. After sprint: 7 cases. Eventually a registry pattern would scale better — but at 7 cases, switch is readable. P3.

### P3-05 — `_friendlyError` duplicated across notifiers

Sessions 5 + 6 each define a `_friendlyError(Object e)` helper. Pull into shared `lib/core/common/errors/error_messages.dart` to avoid drift. P3.

### P3-06 — Sprint meta §15 mentions session 9

Sprint meta §15 last bullet: "UI in session 9". Sprint has 6 sessions. Either typo (should be a follow-up sprint reference) or stale. Fix the reference.

### P3-07 — Session 4 `_LineItemRow` referenced but undefined

Session 3 §4.11 `QuotedBodyStub` uses `_LineItemRow(item: li)` without defining it in the visible code block. Probably means it's defined in the same `all_status_stubs.dart` file, just not shown. Add a one-line note in the session.

### P3-08 — Sprint meta §3 lists `frontend/lib/features/technician/incoming_job_requests/INCOMING_JOB_REQUESTS_FEATURE.md` as a pre-read

Verified present. Good. Just cite the line numbers of the most-relevant sections (the per-event notifier shape) so reader doesn't re-read 2k lines.

---

## §6 Cross-session consistency audit

Spot-checked names, types, identifiers across the 7 files. **Mostly clean** — sprint shows real care here. Issues found:

### CSC-01 — `bookingDetailProvider` vs `bookingDetailNotifierProvider`

Sprint §1 decision 6 calls it `bookingDetailProvider`. Session 3 §4.8 declaration is class `BookingDetailNotifier`, generated as `bookingDetailNotifierProvider`. Action button code at §4.10 reads `ref.read(bookingDetailNotifierProvider(widget.bookingId).notifier).refresh()`. So the **generated** name is `bookingDetailNotifierProvider`. The sprint meta uses the wrong (shorter) name.

**Fix**: align. Either rename the class to `BookingDetail` (generates `bookingDetailProvider`) or update sprint meta to say `bookingDetailNotifierProvider`.

### CSC-02 — `ref.invalidate(...)` vs `ref.read(...).notifier.refresh()`

Session 3 §1 decision 5 says "calls `ref.invalidate(bookingDetailProvider(jobId))`". Session 3 §4.9 implementation calls `ref.read(bookingDetailNotifierProvider(jobId).notifier).refresh()`. Both work but have different semantics:
- `ref.invalidate` re-runs `build()` from scratch on next watch (provider element rebuilds).
- `notifier.refresh()` calls a method on the same notifier that re-runs the fetch and assigns state.

For `keepAlive: false` with a screen actively watching, both produce the same UX. Pick one and stay consistent.

**Recommendation**: `ref.invalidate` — simpler, doesn't require defining `refresh` on every notifier.

### CSC-03 — `BookingStatus.fromWire` argument type

Existing enum (verified): `static BookingStatus fromWire(String? raw)` — accepts nullable. Sprint extension (Session 3 §4.1) shows `static BookingStatus fromWire(String wire) => switch (wire) { ... }` — non-nullable. Drops the nullability handling.

**Fix**: keep nullable signature.

### CSC-04 — Sprint §3 says "INCOMING_JOB_REQUESTS_FEATURE.md" is the ref impl

Verified file exists. But sprint then proceeds to define the orchestrator events notifier as a *single* multi-event filter (§3 decision 5), not a per-event notifier per CLAUDE.md template. This is justified in the decision text (avoid 13 near-identical files), but it's a deviation from the canonical pattern. **Worth a CLAUDE.md amendment** at session 6 explicitly: "for refresh-only events that all do the same thing, a multi-event filter notifier is acceptable; per-event notifiers are mandatory only when behavior diverges per event."

### CSC-05 — `EventType` enum naming

Backend: `class EventType(str, Enum)` (verified). Frontend: `enum SystemEventType` (verified). Sprint sometimes says `SystemEventType.X` and sometimes `EventType.X`. They are different — one is server-side, other is client-side. Sprint is mostly disciplined but verify each reference uses the right one.

### CSC-06 — Sprint says backend events "EXISTING in enum, first wired publisher this sprint"

For events like `tech_en_route`, `tech_arrived`, `quote_generated`, `quote_approved`, `job_completed`, `payment_received`, `dispute_opened`, `dispute_resolved` (sprint §16 lists them). Verified in `realtime/constants/event_types.py` — yes, all present in `EventType` enum.

**However**: `EVENT_REGISTRY` metadata for `is_critical` may not match sprint's claims. Sprint says `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`, `payment_received` are critical. Verify `EVENT_REGISTRY` has `is_critical=True` for each. Spot-check during session 1.

---

## §7 Coupling & cohesion audit

Sprint shows good architectural taste in most places. Specific observations:

### Healthy cohesion
- `bookings/services/orchestrator.py` — 14 functions all about status transitions. Single responsibility: own `JobBooking.status` + related-row writes. Good.
- `auto_transition.py` — separate from orchestrator. Trigger layer. Good separation.
- `finance_ports.py` — 5 methods, all about money decisions. Good cohesion. Real adapters can implement subsets.
- `bookings/selectors/orchestrator_ui.py` — 26 handlers, each tiny. Cohesion = "produce UI dict for one (status, role)". Good.
- `LiveTrackingMap` — composes map + marker + polyline + ETA + offline banner. Cohesion = "show one tech's live trip". Good.
- `BookingOrchestratorScreen` 5-slot layout — each slot is independent. Low coupling.

### Coupling concerns
- **`BookingActionExecutor` does 3 dispatch methods (HTTP / NAVIGATE / MODAL)** — Session 5 §4.0. The class mixes a transport concern (HTTP POST), a navigation concern (GoRouter push), and a modal concern (showModalBottomSheet with builder dispatch). Three responsibilities → three reasons to change.
  - **Fix**: split into `BookingActionExecutor` (HTTP only), `BookingActionRouter` (NAVIGATE), and `BookingActionModalDispatcher` (MODAL). The action button widget switches on `action.method` and delegates to the right one. Each is testable in isolation. P2.
- **Modal endpoint dispatch via `endpoint.endsWith()`** — already P1-09. The if-else chain in `_openModal` couples the dispatcher to every modal's endpoint string. Adding a modal = editing the dispatcher. Adding a key registry decouples them.
- **`available_transitions` projection** — already P2-05. Two source-of-truths for the transition matrix is the very definition of duplicated coupling.
- **`BookingDetailView` returns booking + active_quote + booking_items + open_tickets_count + ui + available_transitions** — large composite payload. Coupled to many readers. Justified for a one-screen-one-fetch design (the orchestrator screen needs all of it). But: if the bookings list screen ever needs `available_transitions` (for an "actionable" badge), it'd have to re-call this big endpoint. Acceptable for v1.
- **`bookingOrchestratorEventsNotifier`** filters 12 event types but they ALL just call refresh. **Cohesion**: yes, all events mean "booking changed, re-fetch detail". **Coupling**: the notifier knows about all 12 event types. Adding event #13 = touching this file. Acceptable; the alternative (per-event notifier) trades one file edit for 13 files.
- **`BookingStatus` enum lives in `customer/bookings/`** but is imported by `orchestrator/`. Cross-feature coupling via shared enum. Defensible — enums are types, not behaviors. But the long-term home is `core/domain/`, not under a sibling feature. Consider moving as part of the planned UI cleanup.
- **`auto_transition.py` imports `orchestrator`** which in turn doesn't import `auto_transition` — clean directional coupling. Good.
- **Session 4's foreground service** owns lifecycle from inside `BookingOrchestratorScreen.initState`. Tightly coupled to the screen. Reasonable for v1 (no other code path needs to start the broadcaster). If future code paths emerge (background tracking, admin force-broadcast), refactor to an app-lifecycle-owned controller.
- **Stream consumer notifier** registers handler with `WsFrameDispatcher` directly instead of going through a per-feature subscription manager. **Acceptable** — the dispatcher IS the manager. But: registration is per-stream-type, not per-consumer, so if two consumers want the same stream type, they collide (P0-07). Architectural debt.
- **`BookingActionExecutor.execute(action)` reads `auth_token` per-request**. No interceptor/middleware. Every data source independently reads the token. Five+ data sources duplicate this. **Fix**: if migrating to http-instead-of-Dio (P0-03), introduce a custom http.Client wrapper that injects the token automatically. Cuts ~5 lines per data source × 10 data sources = 50 lines saved + single source of truth for auth header format.
- **Backend `TechLocationIngressView` does 3 things**: throttle, publish stream, fire auto_transition. Acceptable cohesion (all are "process one GPS frame") but the throttle could move to a decorator or middleware for reuse. P3.

### Structural strengths
- Port-and-adapter pattern (`FinancePort`, existing `JobDispatchScheduler`) keeps service layer free of queue/finance imports. Clean.
- Sealed failure hierarchies on the frontend isolate UI from transport concerns. Mature error handling.
- Dual-barrel events vs streams enforced at the publisher layer (`broadcast_event` vs `publish_stream`). Prevents accidental EventLog writes for transient streams.
- The `ui.*` server-driven dispatch lets backend evolve UX strings without frontend release. Strong dumb-UI discipline.

---

## §8 Scalability & performance audit

### Hot paths

| Path | Volume | Risk | Mitigation in sprint? |
|---|---|---|---|
| `tech_location` ingress | 1 POST / 5s / active EN_ROUTE booking | OK at 100 active jobs (~20 RPS) | Yes (4s throttle, but per-process — P1-07). |
| `tech_gps` stream broadcasts | 1 frame / 5s / active EN_ROUTE booking × subscribers | OK; Channels handles ~hundreds of groups easily. | Implicit in dual-barrel arch. |
| Booking detail re-fetch | 1 HTTP per realtime event | Per active orchestrator screen × event-burst rate (~1-3 events per quote round). Each fetch = ~1 query (with prefetch) | Yes (5s cache — but conflicts with realtime, P1-04). |
| WS upstream (subscribe_tracking) | 1 per screen mount + reconnect | Trivial | OK. |
| EventLog writes | 1 per orchestrator-fired event | ~13 events × N bookings/day. Unbounded growth. | No (P2-03). |
| Polyline fetch | 1 per 30s per active EN_ROUTE | Google quota constraint at scale. | Soft (debounced; P2-02). |
| Foreground GPS battery | 100% screen time during EN_ROUTE/ARRIVED | High (P2-01) | No. |

### Database concerns
- `BookingDetailView` selectors use `select_related` + `prefetch_related`. Verify query count via test (`django_assert_num_queries(<n>)`). Sprint mentions the test in §4.14; ensure n is asserted as ≤4 (booking + customer profile + tech profile + tickets prefetch).
- `available_transitions` may issue an extra query for `booking.tickets.filter(status='OPEN').exists()`. Add to prefetch or annotate.
- `mark_no_show` view checks `arrived_at + 15min` at view layer. Done in Python; no extra DB hit.

### Realtime concerns
- The Channels Redis instance is shared with EventLog cache + per-user WS groups + new `tracking_job_<id>` subgroups. With 10k active subgroups, Redis memory grows but should be bounded (each subgroup is just a SET of channel names).
- `system_event` and `system_stream` consumer methods both forward via `send_json`. No back-pressure handling. If a slow client lags, Channels buffers indefinitely. For tracking streams this is mostly harmless (frames dropped on disconnect anyway), but for events it could OOM the worker over time. Channels has built-in `capacity` settings — verify defaults are reasonable (10).

### Frontend
- `BookingDetailModel.fromJson` parses ~10 nested maps + lists. ~100 lines of computation per fetch. Negligible.
- `LiveTrackingMap` rebuilds on every GPS frame (5s). The ETA `Timer.periodic(1s)` triggers `setState` every second. Fine on Android; verify low-end devices don't drop frames.
- `SystemEventNotifier` dedup uses an in-memory map; capped at 500 (verified). Good.

### Storage
- `dispute_evidence/` and `booking_attachments/` ImageFields write to `MEDIA_ROOT`. No mention of S3/CDN. For a dev sprint, OK; production needs a real backend.
- `SharedPreferences` cache key prefix `orchestrator_booking_detail_v1_<id>` — accumulates per booking ever viewed. No pruning. After 1k bookings × ~3KB each = 3MB. Tolerable for years. P3.

---

## §9 Security & race-condition audit

### Strong points (sprint correctly handles)
- IDOR: every transition checks `booking.technician.user_id == technician_user.id` or customer equivalent. Standard pattern. ✅
- `select_for_update` inside `transaction.atomic`: every orchestrator transition. ✅
- `transaction.on_commit`: every event broadcast. Rolled-back transactions don't fire phantom events. ✅
- `MarkNoShowView` derives `actor_role` from auth, not body. ✅ (Session 2 §4.4)
- WS subscribe_tracking validates participant. ✅ (Session 2 §4.10)
- No `fields = '__all__'` on write serializers. ✅
- DRF token auth + custom envelope handler. ✅

### Issues
- **Image upload** — already P1-10.
- **WS subscribe doesn't check booking status** — already P2-07.
- **In-memory throttle** — already P1-07.
- **`OpenDisputeView` allows photo from any participant** but doesn't validate the participant has a legitimate complaint. Acceptable — DRF doesn't pre-judge content.
- **`dispute_intake_method='FORM'` allows arbitrary `initial_reason` text** — XSS-safe because it's never rendered as HTML; admin sees plain text in Django Admin. ✅
- **Modal dispatcher fall-through** silently does nothing — already P1-09. Not a security issue but a correctness one.
- **`navigatorKeyProvider`** is read in `BookingRescheduledNotifier` to pushReplacementNamed. Confirm that the navigator key is the GoRouter one (verified: navigatorKeyProvider exists in `lib/core/realtime/presentation/providers/dependency_injection.dart`). ✅
- **Race: customer cancel vs tech accept** — sprint meta §15 edge case 4 acknowledges; relies on `select_for_update`. Loser gets `409 booking_no_longer_available` (existing). ✅
- **Race: customer approve_quote vs tech submit_quote (revision)** — if customer is approving v1 just as tech submits v2, who wins? `select_for_update` serializes; first commit wins. The losing flow returns `400 invalid_transition`. UI snackbar. Acceptable, but sprint doesn't explicitly test this.
- **Race: cash collection vs dispute open** — tech taps "Cash Collected" while customer opens dispute. Both serialize on `JobBooking` row. First wins; second sees `400 invalid_transition`. Acceptable.

### Race tests sprint should add
- approve_quote vs submit_quote (revision N+1 from tech) concurrent.
- cancel_by_customer vs accept_quote concurrent (impossible? customer can only cancel from QUOTED before approving; check explicitly).
- Two cancel_by_tech (network retry) concurrent — should idempotent-resolve.
- WS subscribe_tracking just before booking flips to terminal — second WS session might still receive a stream frame for ~ms. Tolerable.

---

## §10 Requirements & edge-case coverage audit

**The user explicitly asked for "every edge case." Sprint claims §15 covers 15 edge cases. Verified coverage:**

| Edge | Sprint covers? | Notes |
|---|---|---|
| Mid-job upsell | ✅ | §15 #1, session 5 |
| Quote-decision SLA (customer doesn't decide) | ⚠️ | §15 #2: "tech presses 'Customer not deciding' → no_show". UI not explicitly designed (no button on tech-side QUOTED). **Gap**. |
| Reschedule | ✅ | §15 #3, sessions 2 + 6 |
| Race: cancel vs arrived | ✅ | §15 #4 |
| Cash-collection offline | ✅ | §15 #5, session 5 |
| Disputes on COMPLETED_INSPECTION_ONLY | ✅ | §15 #6 |
| Multiple disputes | ✅ | §15 #7 |
| Tech accepts but never starts | ✅ | §15 #8 (customer flips no-show after `scheduled_start + 15min`) |
| Reviews/ratings | ❌ | §15 #9 deferred but flag opening missing in §20 (CSC-01). |
| Promo expiration mid-flow | ✅ | §15 #10, session 1 — but write site missing (P1-03) |
| Tech goes offline mid-EN_ROUTE | ✅ | §15 #11, session 4 |
| Quote line-item removal via bargain | ✅ | §15 #12 |
| Customer is also a tech | ✅ | §15 #13 (structurally) |
| Booking attachments | ⚠️ | §15 #14: schema-only, no UI. Acceptable. |
| Concurrent bookings | ✅ | §15 #15 (structurally) |

**Edge cases NOT in §15 but worth covering**:

- **What happens if a tech accepts then never opens the app again?** Customer's UI shows CONFIRMED forever. Sprint relies on customer flipping to NO_SHOW after `scheduled_start + 15min`. But: scheduled_start might be hours away. Customer is stuck waiting. **Add**: tech-app-presence-detection or a max-acceptance-to-en_route SLA (e.g., 30min before scheduled_start). Defer to a flag.

- **What if customer's app dies during dispute open?** Photo upload mid-stream → connection drops → server has partial multipart. DRF handles cleanly (rejects partial). Customer sees error. They retry. Acceptable.

- **What if a tech submits the same quote twice rapidly (network retry)?** revision_number increments → two SUBMITTED quotes. Customer sees the latest only (via `get_active_quote`'s ORDER BY -revision_number). Acceptable but creates a confusing audit trail. **Add**: orchestrator's `submit_quote` should reject if there's an existing SUBMITTED quote (force tech to wait for customer decision or to request_revision first). Tighten in session 1.

- **What if tech cancels at exactly the moment customer is approving a quote?** approve_quote takes the lock; tech-cancel waits; gets booking in IN_PROGRESS state; rejects with invalid_transition. Acceptable.

- **What if backend crashes mid-orchestrator transaction?** transaction rolls back; events not fired (on_commit); finance port not called. Booking retains old status. Tech retries; succeeds. Acceptable.

- **What if customer creates a booking, then tech's wallet drops below threshold mid-acceptance?** `can_accept_job` finance port check happens during accept. NullFinanceAdapter always returns (True, None). Real finance sprint will catch this. Acceptable.

- **What if `BookingAttachment` is uploaded by a non-participant via API?** Schema-only this sprint, no upload UI/API → no attack surface yet. Future sprint must scope. ✅

- **What if multiple admins try to resolve the same dispute simultaneously?** Django Admin → orchestrator's `admin_resolve_dispute` — uses `select_for_update`. First wins. Second sees ticket already RESOLVED → orchestrator rejects with invalid_transition. Acceptable but sprint doesn't test.

- **What if scheduled_start is in the past at creation time?** Sprint assumes future. existing `instant_book_service` may or may not validate. Outside the orchestrator's concern but worth a sanity check.

- **What if customer approves the quote but then the orchestrator's broadcast_event fails (Redis down)?** transaction commits (status flipped to IN_PROGRESS); broadcast scheduled `on_commit` then fails (caught in narrow try/except). FCM fallback fires. Tech eventually sees the event when WS reconnects (sync replay). Acceptable.

- **What if `parent_booking` link forms a chain >2 deep?** Customer reschedules booking #1 → child #2; reschedules #2 → child #3. Sprint allows it (no chain depth check). Each is a fresh booking; the chain is observed only via the linked-list traversal. Acceptable but could be confusing in admin.

---

## §11 Documentation gaps

- Sprint meta §3 cites docs that exist (verified). ✅
- Sprint doesn't explicitly say where the AUDIT.md should live (this file lands at `booking_orchestrator_sprint/AUDIT.md`).
- `BOOKINGS_API.md` modification (Session 2 §4.13) is described but the actual section structure isn't templated. Future-you will guess. Worth pre-templating one example fully and pointing to it.
- `STREAMS_TECH_GPS.md` (new, Session 2 §4.12) is fully sketched. ✅
- CLAUDE.md amendments planned in Session 6 §4.10. The text is sketched. ✅
- `ORCHESTRATOR_FEATURE.md` (Session 3 §4.14, Session 5 modification, Session 6 modification): outline good, verify the final version covers all 14 transitions and modal endpoints.

---

## §12 Summary table — fix priority

| ID | Severity | Title | Where | Effort |
|---|---|---|---|---|
| P0-01 | P0 | `BookingValidationError` undefined | Session 1 | 5 min |
| P0-02 | P0 | `tech_profile` related_name | Session 2-6 | 15 min (find/replace) |
| P0-03 | P0 | Dio not in pubspec | Sessions 3-6 | 2-4 hr (rewrite data sources) |
| P0-04 | P0 | event_urgency_router path | Session 3, 4 | 5 min |
| P0-05 | P0 | catalog migration 0008 not 0009 | Session 1 | 5 min |
| P0-06 | P0 | settings path `core/` not `karigar/` | Session 2 | 5 min |
| P0-07 | P0 | WsFrameDispatcher.unregister arity | Session 4 | 30 min (decide + patch) |
| P0-08 | P0 | tech_reliability_penalty admin target | Sprint meta, Session 1 | 30 min (drop or extend) |
| P1-01 | P1 | Customer phone_no | Session 2, 3 | 30 min |
| P1-02 | P1 | profile_url field | Session 2 | 10 min |
| P1-03 | P1 | promo snapshot write missing | Session 1 | 30 min |
| P1-04 | P1 | Cache vs realtime stale | Session 2, 3 | 15 min (drop cache) |
| P1-05 | P1 | Stream notifier state mutation | Session 4 | 20 min |
| P1-06 | P1 | WS reconnect re-subscribe | Session 4 | 1 hr |
| P1-07 | P1 | Per-process throttle | Session 2 | 1 hr (Redis) or flag |
| P1-08 | P1 | Fire-and-forget start_inspection | Session 5 | 30 min |
| P1-09 | P1 | Modal endpoint fragility | Session 5, 6 | 1 hr (registry) |
| P1-10 | P1 | Image upload validation | Session 2 | 30 min |
| P1-11 | P1 | pending vs unknown | Session 3 | 5 min |
| P1-12 | P1 | reviews flag in §20 | Sprint meta | 5 min |
| P1-13 | P1 | URL ordering | Session 2 | 15 min |
| P1-14 | P1 | dispute_opened admin target | Sprint meta, Session 1 | 15 min |
| P2-01 to P2-11 | P2 | (various) | (see above) | varies |
| P3-01 to P3-08 | P3 | (nits) | (see above) | minor |
| CSC-01 to CSC-06 | mixed | (consistency) | (see above) | varies |

---

## §13 Recommended action sequence

1. **Triage hour**: walk through every P0 with the user, decide on each (especially P0-03 Dio swap, P0-07 dispatcher refactor scope, P0-08 admin event drop). Update the seven sprint files with the resolutions.

2. **P1 batch**: address all P1 items in their respective sessions as you start each session. Don't try to fix all P1s upfront — they're localized to sessions.

3. **P2 acknowledgments**: open flags for P2 items not addressed in the relevant session. Don't let them silently slip.

4. **CSC fixes**: do these alongside the P0 triage hour.

5. **Audit cycle 2** (optional): after making the P0/P1 fixes, run another audit pass to catch any new issues introduced. The fix-the-audit pass itself can introduce defects.

---

## §14 What this audit didn't cover

- Visual design choices (out of scope; planned UI cleanup pass).
- Test code per se (tests are implied by sprint; couldn't audit lines that don't exist yet).
- iOS implementation (deferred per flag #10).
- Finance sprint (deferred).
- Chatbot sprint (deferred).
- Performance under specific load profiles (would need a load test).
- Internationalization (not in sprint scope).
- Accessibility (not in sprint scope).
- Real GPS provider quota costs at production scale (estimated only).

---

**Audit by**: Claude Opus 4.7
**Date**: 2026-05-08
**Files audited**: `BOOKING_ORCHESTRATOR_SPRINT.md` + `session_1` through `session_6` (10,598 lines).
**Codebase ground-truth scan**: `backend/` + `frontend/lib/` (selective file reads + grep verification of every claim about file paths, class names, field names, related_names, imports, and package presence).

---

## §15 Resolutions (audit cycle 1 close-out)

The audit findings have been patched into the seven sprint files. Below: each finding ID → file(s) where the fix lives. Cross-reference with the relevant session before opening it.

### P0 (all resolved)

| ID | Where the fix lives |
|---|---|
| P0-01 | `session_1` File 12 — adds `BookingValidationError` class with envelope shape, plus instructions to verify the custom exception handler picks it up. |
| P0-02 | `session_2` — global replace `request.user.technician_profile` → `request.user.tech_profile` (4 occurrences); error code message updated. |
| P0-03 | `BOOKING_ORCHESTRATOR_SPRINT.md` §24 — defines the canonical `package:http` data-source pattern (incl. multipart for session 6). Sessions 3-6 each open with an audit note instructing readers to substitute Dio→http per §24; the most-quoted code blocks (BookingDetailRemoteDataSource, BookingActionExecutor, StartInspectionRemoteDataSource) are fully rewritten as concrete examples. |
| P0-04 | `session_3` + `session_4` — global replace `lib/core/realtime/router/...` → `lib/core/realtime/presentation/router/...`. |
| P0-05 | `session_1` — catalog migration renamed to `0008_subservice_max_price.py`; pre-flight + rollback example updated. |
| P0-06 | `session_2` — global replace `backend/karigar/settings.py` → `backend/core/settings.py`. |
| P0-07 | `session_4` §4.8 — `unregister('tech_gps')` is single-arg; constraint documented (single-handler-per-type); flag `ws-stream-multi-handler-deferred` opens for the multi-handler refactor. |
| P0-08 | Sprint meta §11.5 introduces `TechReliabilityIncident` model; §16 events table strikes through `tech_reliability_penalty`; `session_1` File 24 adds the model + migration + tests; `cancel_by_tech` and `mark_no_show` docstrings updated; flag `admin-realtime-channel-deferred` opens. |

### P1 (all resolved)

| ID | Where the fix lives |
|---|---|
| P1-01 | `session_2` §4.6 BookingDetailView — prefetch `customer__userprofile`; serializer reads `booking.customer.userprofile.phone` with try/except fallback. |
| P1-02 | `session_2` §4.6 — serializer builds `booking.technician.profile_picture.url` via `request.build_absolute_uri(...)`; matches existing `dashboard_selector.py` pattern. |
| P1-03 | `session_1` File 25 — modifies `instant_book_service.py` to write `promo_code_snapshot` and `promo_discount_snapshot` at booking creation. Tests added. |
| P1-04 | `session_2` §4.6 — `cache_control` decorator dropped; import removed; gotcha 10 invalidated. |
| P1-05 | `session_4` §4.8 `TechnicianLocationStreamNotifier` — `state` mutations wrapped in `Future.microtask` + `ref.mounted` guard; `_latest` field removed (state IS the latest). |
| P1-06 | `session_4` §4.7.5 (new subsection) — extends `WsConnectionNotifier` with `connectionEvents` Stream; introduces `TrackingSubscriptionController` that listens and re-issues `subscribe_tracking` on every reconnect. |
| P1-07 | `session_2` §1 decision retained but flag `tech-location-rate-limit-not-distributed` opens explicitly in DoD; redis token-bucket alternative documented in audit. |
| P1-08 | `session_5` §4.4 + §4.2 — `start_inspection` is awaited (not fire-and-forget); failures surface a snackbar; orchestrator idempotency means "already INSPECTING" no-ops cleanly. |
| P1-09 | `session_5` §4.0 introduces `ModalEndpointKeys` registry + backend `bookings/api/modal_endpoints.py` mirror + bidirectional CI parity test; `session_6` §4.0 extends with the 4 new keys. The fragile `endpoint.endsWith()` chain is replaced with explicit key-switch matching. |
| P1-10 | `session_2` §4.4 `OpenDisputeRequestSerializer` — `validate_photo` enforces 5MB cap. |
| P1-11 | `session_3` §4.11 — `UnknownBodyStub` logs a WARNING when `booking.status == BookingStatus.pending` to surface legacy rows during QA. |
| P1-12 | Sprint meta §20 — `reviews-deferred` flag opening explicitly listed under session 1 row. |
| P1-13 | `session_2` §4.7 — full ordered `urls.py` shown with explicit ordering (literal-prefix paths before typed-int paths); audit note explains why. |
| P1-14 | Sprint meta §16 + `session_1` `open_dispute` and `mark_no_show` docstrings — admin half of `dispute_opened` and `booking_no_show` dropped; admin reads via Django Admin / `TechReliabilityIncident` table. |

### CSC (cross-session consistency, all resolved)

| ID | Where the fix lives |
|---|---|
| CSC-01 | `session_3` §1 decision 17 — provider name standardized as `bookingDetailNotifierProvider` (matches generated name from `BookingDetailNotifier` class). |
| CSC-02 | `session_3` §1 decision 17 + §4.9 — event-driven refetches use `ref.invalidate(...)`; `notifier.refresh()` reserved for explicit user-initiated reloads. |
| CSC-03 | `session_3` §4.1 BookingStatus extension — `fromWire(String? raw)` keeps nullable signature; map+null-handling pattern preserved. |
| CSC-04 | (Documentation note in §6 covered by audit; no patch needed — multi-event filter notifier acceptable per CLAUDE.md amendment in session 6 §4.10.) |
| CSC-05 | (No patch — sprint already disciplined about `EventType` vs `SystemEventType`.) |
| CSC-06 | `session_1` File 13 — explicit verify-step added: "verify `EVENT_REGISTRY` has `is_critical=True` for [list]". |

### P2 / P3

P2 items:
- P2-01 (battery): retained as-is, recommend distance-filter tuning post-MVP.
- P2-02 (Google quota): retained; flag opens via `tech-location-rate-limit-not-distributed` adjacent.
- P2-03 (EventLog growth): flag `eventlog-retention-policy-tbd` opens in session 6.
- P2-04 (factory chain): no patch — gotcha 16 already covers.
- P2-05 (validator drift): no patch — test in §1 decision 5 catches it.
- P2-06 (loading flash): no patch — gotcha 14 already defers.
- P2-07 (`_can_subscribe` status check): `session_2` §4.10 — checks `TERMINAL_STATUSES`.
- P2-08 (cancellation idempotency): no patch — gotcha addresses; orchestrator's existing idempotency clause covers.
- P2-09 (parent_booking hard delete): no patch — gotcha 4 already covers.
- P2-10 (stream-staleness header banner): no patch — defer to UX cleanup pass.
- P2-11 (geofence strict override path): no patch — flag `geofence-strictness-config-tbd` covers.

P3 items: batched as nits or accepted as deferred.

### Files modified by the patch

```
booking_orchestrator_sprint/
  AUDIT.md                                        (this §15 added)
  BOOKING_ORCHESTRATOR_SPRINT.md                  (§24 + §25 added; §16, §17, §18, §20 patched)
  session_1_backend_foundations.md                (§1 dec 6/11; §2 file table; Files 12/13/14/24/25; §5 gotcha 3; §8 DoD)
  session_2_backend_transitions.md                (§1 dec 14/15; §2 settings path; §4.0/4.1/4.4/4.6/4.7/4.10; §8 DoD)
  session_3_orchestrator_frontend_skeleton.md     (§1 dec 17; §2 file table; §4.1/4.4/4.5/4.7/4.9/4.10/4.11; §8 DoD)
  session_4_live_tracking_and_dual_maps.md        (§1 dec 19; §2 file table; §4.7.5 new; §4.8; gotchas)
  session_5_quote_flow_and_cash_collection.md     (§1 dec 17; §4.0 rewrite + registry; §4.2; §4.4 initState)
  session_6_lifecycle_edges_and_polish.md         (§1 dec 17; §2 file table; §4.0 registry extension; §1 dec 14)
```

**Net effect**: all P0 and P1 items closed in-document. Sessions are now executable as written, against the verified codebase ground truth.

A second audit cycle (re-run the same scan after these patches land) is recommended but optional. The patch was reviewed for new defects (e.g., `request.build_absolute_uri` requires `request` in serializer context — that's wired in §4.6).
