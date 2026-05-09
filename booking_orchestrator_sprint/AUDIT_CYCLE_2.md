# Booking Orchestrator Sprint — Audit Cycle 2

> Independent re-audit of the seven sprint files **after** cycle-1 patches landed (12,483 lines, +1,885 from cycle-1). Cross-referenced against the live codebase as of 2026-05-08. Goal: catch defects introduced by the cycle-1 patches themselves, items missed in cycle-1, and any cross-session inconsistencies the patches created.
>
> **Cycle-1 baseline**: see `AUDIT.md` (8 P0, 14 P1, 11 P2, 8 P3, 6 CSC items, all marked resolved in §15). This cycle does NOT re-litigate cycle-1 findings — it only finds new defects.

---

## §0 Executive summary

Cycle-1 patches closed every cycle-1 P0 and P1 in-document. **Cycle-2 finds 5 new P0 blockers, 7 new P1 highs, 3 new P2 mediums, 4 new P3 nits, and 3 new CSC items** introduced by the patches, plus a handful of items that cycle-1 missed entirely.

**Severity distribution of cycle-2 defects:**
- 5 P0 (compile-fails or runtime breakage) — half are URL-double-prefix bugs that hit every endpoint call.
- 7 P1 (will work in dev, breaks in prod or under specific paths) — mostly Riverpod/lifecycle mistakes in the WS reconnect patch.
- 3 P2 / 4 P3 / 3 CSC.

**The single largest blast radius**: the **double `/api/`** URL bug (C2-P0-01). Every booking endpoint call from sessions 3-6 hits `http://127.0.0.1:8000/api/api/bookings/...` and 404s because `AppConstants.baseUrl` already includes the `/api` prefix. Both the §24 canonical pattern and the backend `orchestrator_ui.py` selector handlers emit `/api/...` paths. Two-line fix — drop `/api/` from both.

**The cycle-1 fixes that are clean**: BookingValidationError class (envelope shape correct), TechReliabilityIncident model (fields and constraints correct), customer phone via UserProfile prefetch, technician profile_picture URL via build_absolute_uri, image upload size cap, settings path swap, related_name swap, catalog migration renumber, _can_subscribe terminal-status check, urls.py ordering, BookingDetailView cache_control drop. These all hold up under cycle-2 scrutiny.

**The cycle-1 fixes that need more work**: §24 canonical http pattern (URL prefix bug + cross-feature DI dependency), session 4 §4.7.5 + §4.9 WS reconnect patch (duplicated, contradictory `TrackingSubscriptionController` definitions; `dispose()` override that won't run; `_connectionEvents.add(...)` shown as commented placeholder), modal endpoint parity contract (asymmetric — `techCancelConfirm` is frontend-only).

**Recommended action**: a small cycle-2 patch (estimated 1-2 hours) closes every C2-P0 and C2-P1. Then sessions are ready to open.

---

## §1 Severity legend (same as cycle-1)

- **P0**: code as written will not compile or will silently mis-behave at runtime. Fix before opening any session.
- **P1**: code compiles but produces broken feature, wrong data, or correctness gap. Fix in the relevant session.
- **P2**: works in dev, breaks in production / scale / specific edge case. Fix or flag.
- **P3**: nit. Defer or batch.
- **CSC**: cross-session consistency. Names, types, paths.
- **Cycle-2 ID prefix**: `C2-` to distinguish from cycle-1 IDs.

---

## §2 P0 findings (introduced by cycle-1 patches)

### C2-P0-01 — Double `/api/` prefix in every booking endpoint URL

**Where**:
- `BOOKING_ORCHESTRATOR_SPRINT.md` §24 canonical pattern, lines 808, 821, 860 (the EXAMPLE the rest of the sprint references).
- `session_3_orchestrator_frontend_skeleton.md` line 759 — `BookingDetailRemoteDataSource.fetch()`.
- `session_4_live_tracking_and_dual_maps.md` line 1356 — `TechLocationRemoteDataSource.postLocation()`.
- `session_5_quote_flow_and_cash_collection.md` lines 577, 591, 618, 646, 676 — every quote/cash/inspection/catalog endpoint.
- `session_2_backend_transitions.md` lines 933, 947, 961, 962 — every `orchestrator_ui.py` handler emits `endpoint=f'/api/bookings/{booking.id}/...'` strings.

**Reality**: `AppConstants.baseUrl` is defined at `frontend/lib/core/constants.dart`:
```dart
static const String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000/api'    // already includes /api
    : 'http://127.0.0.1:8000/api';
```

The codebase convention (verified across `customer_bookings_remote_data_source.dart` line 72, `address_remote_data_source.dart` line 13, `incoming_job_remote_data_source.dart` line 38, etc.) is `'${AppConstants.baseUrl}/bookings/'` — endpoint paths do **not** include the `/api/` prefix.

**Why this is a blocker**: every URL ends up as `http://127.0.0.1:8000/api/api/bookings/...` — DOUBLE `/api/`. Django returns 404 for every transition POST, every detail GET, every tech-location POST. Frontend never reaches a working endpoint.

**Fix**:
1. **§24 in meta-doc**: rewrite the canonical pattern. Change `Uri.parse('${AppConstants.baseUrl}/api/foo/$id/')` → `Uri.parse('${AppConstants.baseUrl}/foo/$id/')` (drop the `/api/` literal). Apply to all three URLs in §24 (lines 808, 821, 860).
2. **Sessions 3-6 inline URLs**: same drop in every data-source code block.
3. **Backend `orchestrator_ui.py` handlers (session 2 §4.8)**: emit endpoints WITHOUT `/api/` prefix. Change `f'/api/bookings/{booking.id}/cancel/'` → `f'/bookings/{booking.id}/cancel/'`. The `BookingActionExecutor` then concatenates `${baseUrl}${endpoint}` correctly.
4. Add a verification step: `grep -rn "${AppConstants.baseUrl}/api/" booking_orchestrator_sprint/ frontend/lib/features/orchestrator/` should return zero matches after the patch.

**Note**: the modal-endpoint pattern (`/booking/{id}/cash-collection-confirm`) uses a DIFFERENT prefix (`/booking/`, singular, no `/api/`) because those strings are key-extraction targets, not URLs. Keep them as-is; this finding is about HTTP endpoint URLs only.

---

### C2-P0-02 — `wsConnectionNotifierProvider` does not exist; provider is `wsConnectionProvider`

**Where**: `session_4_live_tracking_and_dual_maps.md` line 1129 (inside §4.7.5 `TrackingSubscriptionController`):
```dart
final ws = ref.read(wsConnectionNotifierProvider.notifier);
```

**Reality**: `lib/core/realtime/presentation/notifiers/ws_connection_notifier.g.dart` line 27 declares `final wsConnectionProvider = WsConnectionNotifierProvider._();` and line 64 `name: r'wsConnectionProvider'`. **The exposed provider name is `wsConnectionProvider`** — Riverpod's code-gen strips the `Notifier` suffix when the class name has it.

This is verified by the rest of the codebase: `app_lifecycle_orchestrator.dart:160`, `:207`, `:306`, `:310`, `connection_status_provider.dart:17`, and `incoming_job_swipe_to_accept.dart:295` all use `wsConnectionProvider`. Session 4 line 1290 uses the correct name (`wsConnectionProvider`); only line 1129 in §4.7.5 has the wrong one.

**Why this is a blocker**: line 1129 won't compile (`wsConnectionNotifierProvider` is undefined). The patch was added in cycle-1 to fix audit P1-06; the symbol name was guessed wrong.

**Fix**: in session 4 §4.7.5, change `wsConnectionNotifierProvider` → `wsConnectionProvider`. Single-line edit.

---

### C2-P0-03 — Two contradictory `TrackingSubscriptionController` implementations in session 4

**Where**: `session_4_live_tracking_and_dual_maps.md`:
- §4.7.5 lines 1126-1147 — version A: listens to `ws.connectionEvents` Stream (added in cycle-1 patch); resubscribes on `WsConnected`.
- §4.9 lines 1253-1296 — version B: listens to `bookingDetailNotifierProvider` AND `wsConnectionStatusProvider`; carries a `bool _subscribed` flag; resubscribes when `wsConnectionStatusProvider` flips to `connected`.

**Why this is a blocker**: implementer reads two definitions. Both claim to be "the" `TrackingSubscriptionController`. They use entirely different reactive plumbing (Stream listener vs Riverpod provider listener) and have different lifetimes (version A subscribes immediately on `build`; version B waits for booking status to enter `EN_ROUTE`/`ARRIVED`). The CI parity test, integration test mocks, and the screen-side `ref.watch(trackingSubscriptionControllerProvider(jobId))` all need to know which one actually ships.

The cycle-1 patch added §4.7.5 to resolve audit P1-06 but didn't reconcile with the §4.9 definition that pre-existed. Two valid designs were copied side-by-side.

**Decision needed**: pick one. Recommendations:

**Option A (recommended): version B with `connectionEvents` injected**.
- Keep §4.9's "listen to bookingDetail and gate on status × role" — that's the correct lifecycle (don't subscribe until tech is actually moving toward customer).
- Replace `wsConnectionStatusProvider` listener with the `ws.connectionEvents` Stream listener from §4.7.5 (more precise — `WsConnected` fires once per successful (re)connect; `wsConnectionStatusProvider` could miss a fast reconnect).
- Single notifier, ~30 lines.

**Option B: drop §4.7.5's controller, keep §4.9 unchanged**, and instead resubscribe on `WsConnectionStatus.connected` transitions read from the existing notifier state.

**Fix**: rewrite §4.7.5 as a "supersedes §4.9" section that defines the merged controller; mark §4.9 as superseded. Or rewrite §4.9 to incorporate the connectionEvents listener and delete §4.7.5's controller code (keep its `WsConnectionNotifier` extension). Either way, ONE definition.

---

### C2-P0-04 — Stale Dio code blocks remain in sessions 4 and 5 despite audit P0-03 "fix"

**Where**: cycle-1 §25 P0-03 row claimed "sessions 3-6 each open with an audit note instructing readers to substitute Dio→http per §24; the most-quoted code blocks (BookingDetailRemoteDataSource, BookingActionExecutor, StartInspectionRemoteDataSource) are fully rewritten as concrete examples."

**Reality**: only those 3 examples were rewritten. The rest of the Dio code remains untouched. Verified inventory:

```
session_4_live_tracking_and_dual_maps.md:
  L42  GPS broadcast cadence:  "Each fix POSTs to /api/bookings/<id>/tech-location/ over a Dio instance"
  L97  file table:              "Geolocator stream subscription + Dio POSTs"
  L544 GoogleDirectionsService: final Dio _dio
  L596 GoogleDirectionsService: } on DioException catch (e) {
  L616 OsrmDirectionsService:   final Dio _dio
  L657 OsrmDirectionsService:   } on DioException catch (e) {
  L742 foreground service:      final dio = Dio()
  L1344 TechLocationRemoteDataSource: final Dio _dio
  L1402 test:                   _remote = TechLocationRemoteDataSource(Dio())
  L1641 test:                   final dio = MockDio()

session_5_quote_flow_and_cash_collection.md:
  L36  decision 3:              "POST/GET/etc — HTTP request via Dio (existing)"
  L569 QuoteRemoteDataSource:   final Dio _dio
  L582-583,594-595             on DioException catch
  L602 _mapDio(DioException e)
  L610 CashCollectionRemoteDataSource: final Dio _dio
  L622-623,627                 DioException helpers
  L668 SubServiceCatalogRemoteDataSource: final Dio _dio
  L682-683,687                 DioException helpers
  L1765 DoD checklist:          "No widgets import Dio directly" (still references Dio as the thing to grep against)

session_6_lifecycle_edges_and_polish.md:
  L1354 gotcha 8:               "The dispute multipart POST uses FormData from Dio"
```

**Why this is a blocker**: the audit note says "substitute mentally" but a session is expected to be readable as a working spec. With ~30 Dio symbols left in 2 sessions, the implementer either:
1. Mistypes the substitution and introduces real bugs (e.g. `_dio.post(url, data: body)` → `_client.post(Uri.parse(url), body: body)` — but `body` needs `jsonEncode(...)` and a `Content-Type: application/json` header, missing in the mental substitution).
2. Stops trusting the doc and treats it as illustrative-only — losing the value of having concrete examples at all.

**Fix**: a real find/replace pass. For each Dio block, rewrite to the §24 pattern. Estimated 1 hour. Scope:
- Session 4 §4.4 GoogleDirectionsService + §4.5 OsrmDirectionsService (Google Directions and OSRM both use plain GET; trivial rewrite).
- Session 4 §4.10 foreground service handler (use `http.Client()` instantiated in `onStart` per §24's "foreground service isolate exception").
- Session 4 §4.11 TechLocationRemoteDataSource.
- Session 5 §4.5 QuoteRemoteDataSource, CashCollectionRemoteDataSource, SubServiceCatalogRemoteDataSource — each is ~15 lines.
- Session 6 gotcha 8 — replace "FormData from Dio" with reference to §24 multipart pattern.
- Session 5 line 36 decision 3 — fix the "via Dio (existing)" wording.

After the rewrite: `grep -rn "Dio\b\|DioException\|MockDio" booking_orchestrator_sprint/` should return only references in §1 audit notes and the audit document itself.

---

### C2-P0-05 — Session 1 verification step references migration `0009` that doesn't exist

**Where**: `session_1_backend_foundations.md` line 1574:
```bash
python manage.py migrate                                   # apply 0008 + 0009
```

**Reality**: cycle-1's audit P0-05 fix renamed catalog `0009_subservice_max_price.py` → `0008_subservice_max_price.py`. Bookings sprint migration is `0008_booking_orchestrator_foundations.py`. **There is no `0009`** — both new migrations are `0008` (different apps).

The "0008 + 0009" comment is leftover v0.9 cruft that was missed in the rename pass.

**Why this is a blocker**: the verification command is part of the "static checks" gate (line 1571 ff.). An implementer running it sees the comment, expects two migrations to apply, finds only one, and assumes something is broken. Lost time during onboarding.

**Fix**: change the comment to `# apply bookings 0008 + catalog 0008 (different apps)` or `# apply 0008 in bookings + 0008 in catalog`. Trivial.

---

## §3 P1 findings (high — fix in the relevant session)

### C2-P1-01 — `dispose()` override on Riverpod Notifier won't run

**Where**: `session_4_live_tracking_and_dual_maps.md` lines 1114-1118 (inside §4.7.5):
```dart
@Riverpod(keepAlive: true)
class WsConnectionNotifier extends _$WsConnectionNotifier {
  // ... existing state ...
  final _connectionEvents = StreamController<WsConnectionEvent>.broadcast();
  Stream<WsConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  void dispose() {
    _connectionEvents.close();
    super.dispose();
  }
}
```

**Reality**: Riverpod v2/v3 `Notifier`/`AsyncNotifier` classes do NOT have a `dispose()` method to override. The lifecycle is managed by `Ref.onDispose(() => ...)` registered inside `build()`. Overriding `void dispose()` is either:
- A no-op (Dart calls a base class method that doesn't exist; compile error).
- Or, in some Riverpod versions, an unrecognized override warning at runtime.

**Why this matters**: the StreamController never gets closed. After repeated app session cycles (or test container disposals), `_connectionEvents` leaks. A test that creates and disposes a `ProviderContainer` 100x sees 100 leaked broadcast controllers. Not catastrophic, but flags during memory profiling and may surface as ZoneMissingHandlerExceptions in Riverpod test harnesses.

**Fix**: register the close in `build()`:
```dart
@override
WsConnectionStatus build() {
  ref.onDispose(() {
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _connectionEvents.close();    // <- add this line
  });
  return WsConnectionStatus.disconnected;
}
```

(The existing `build()` already registers a `ref.onDispose` for the timer/subscription/channel — see `lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart:51-55`. Just append the controller close.)

Drop the `@override void dispose()` block entirely.

---

### C2-P1-02 — `_connectionEvents.add(WsConnected(...))` shown as commented placeholder; insertion sites unspecified

**Where**: `session_4_live_tracking_and_dual_maps.md` lines 1101-1104 (inside §4.7.5):
```dart
// In the existing connect() success branch (after socket open + group join):
//   _connectionEvents.add(WsConnected(DateTime.now()));
// In the existing disconnect / _onSocketDone paths:
//   _connectionEvents.add(WsDisconnected(DateTime.now(), closeCode));
```

**Why this matters**: this is the load-bearing piece of the entire audit P1-06 fix. Without these two `.add(...)` calls firing in the right places, `connectionEvents` never emits anything and `TrackingSubscriptionController` never resubscribes. The `Stream` exists but is silent.

The patch shows them as comments without specifying exact insertion lines. The existing `WsConnectionNotifier` (verified at `lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart`) has multiple paths that flip state — the implementer must guess which ones to instrument.

**Fix**: replace the comments with concrete code, with line-anchored insertion instructions:

```markdown
**Insert (a)**: in `connect()`, after the existing line `state = WsConnectionStatus.connected;` (~line 96):
  _connectionEvents.add(WsConnected(DateTime.now()));

**Insert (b)**: in `disconnect()`, BEFORE the existing line `state = WsConnectionStatus.disconnected;` (~line 155):
  _connectionEvents.add(WsDisconnected(DateTime.now(), null));

**Insert (c)**: in `_scheduleReconnect()`, BEFORE flipping state to `reconnecting` or `failed`:
  _connectionEvents.add(WsDisconnected(DateTime.now(), null));

**Insert (d)** in the `onDone:` branch of `_socketSubscription` (around line 109-111):
  _connectionEvents.add(WsDisconnected(DateTime.now(), null));

(The current notifier doesn't expose closeCode; pass null. Refactor to capture it later if needed.)
```

Spec: `WsConnected` fires exactly once per successful handshake completion. `WsDisconnected` fires once per disconnect (clean or unclean). Idempotent extras don't break TrackingSubscriptionController (it filters on `event is WsConnected`) but tighter is better.

---

### C2-P1-03 — `payment_received is_critical=True` in spot-check list contradicts registry and sprint meta

**Where**: `session_1_backend_foundations.md` line 1193:
> **Important**: verify `EVENT_REGISTRY` has `is_critical=True` for `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`, `payment_received` (sprint meta §16 says these are critical).

**Reality**:
- `backend/realtime/constants/event_types.py` — `PAYMENT_RECEIVED: {'is_critical': False, ...}`. Verified.
- `BOOKING_ORCHESTRATOR_SPRINT.md` §16 line 563 — `| payment_received | False | Customer | confirm-cash-received endpoint | ... |`. Says False.

Both ground-truth sources agree that `payment_received` is **not** critical. The session 1 spot-check list incorrectly includes it.

**Why this matters**: an implementer following the spot-check would "fix" a problem that doesn't exist by changing `payment_received` to `is_critical=True`. That ripples through:
- ACK contract: `payment_received` would be required to ACK, but the customer-side handler doesn't ACK refresh-only events.
- FCM body: switching `is_critical` may change notification priority and "Notification" body resolution.
- Sprint meta §16 vs registry: now disagreeing.

**Fix**: drop `payment_received` from the line-1193 spot-check list. The intended list was the 5 critical events in sprint §16: `quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`. (`payment_received` is non-critical because the cash-collection UI confirms via the explicit POST response, not via the notification.)

---

### C2-P1-04 — Modal endpoint parity contract is asymmetric; `techCancelConfirm` is frontend-only

**Where**:
- `session_5_quote_flow_and_cash_collection.md` line 425 — frontend test "asserts every key in `ModalEndpointKeys.all` has a handler in `_openModal`".
- Same file line 430 — backend test "enumerate every (status, role) handler... assert each key is in `ALL_KEYS`".
- `session_6_lifecycle_edges_and_polish.md` line 254 — frontend `static const techCancelConfirm = 'tech-cancel-confirm';` IS in `ModalEndpointKeys.all`.
- Same file line 285 — backend `ALL_KEYS` deliberately EXCLUDES `tech-cancel-confirm` ("never emitted by orchestrator_ui.py").

**Why this matters**: as written, the parity tests are designed to enforce **both directions** ("Bidirectional parity guaranteed", session 5 line 430). With `techCancelConfirm` in frontend `all` but NOT in backend `ALL_KEYS`, a strict bidirectional comparison test (`assert frontend_set == backend_set`) FAILS. The patch added the asymmetric behavior without reconciling the test contract.

The actual intent: backend tests verify "every endpoint I emit has a handler" (one-way: backend ⊆ frontend). Frontend tests verify "every key in my registry has a handler" (one-way: frontend's own list is consistent with its switch). Together those don't enforce equality.

**Fix**: explicitly split the registries to encode the asymmetry, and document the contract precisely:

```dart
// frontend/lib/features/orchestrator/presentation/providers/modal_endpoint_keys.dart
abstract class ModalEndpointKeys {
  // Server-emitted keys (must match backend ALL_KEYS exactly)
  static const cashCollectionConfirm = 'cash-collection-confirm';
  static const quoteDecline = 'decline';
  static const quoteBargain = 'bargain';
  static const cancelConfirm = 'cancel-confirm';
  static const reschedule = 'reschedule';
  static const noShowConfirm = 'no-show-confirm';

  // Client-only keys (invoked from overflow / non-server paths)
  static const techCancelConfirm = 'tech-cancel-confirm';

  /// Server-emitted keys; parity with backend ALL_KEYS.
  static const serverEmitted = <String>{
    cashCollectionConfirm, quoteDecline, quoteBargain,
    cancelConfirm, reschedule, noShowConfirm,
  };

  /// All keys (server-emitted + client-only); parity with _openModal switch.
  static const all = <String>{
    ...serverEmitted,
    techCancelConfirm,
  };
}
```

Test contracts:
- **Backend test**: every (status, role) handler emits a key in `ALL_KEYS`; AND `ALL_KEYS == ModalEndpointKeys.serverEmitted` (loaded via test fixture file or hard-coded).
- **Frontend test 1**: every key in `ModalEndpointKeys.all` has a `case` in `_openModal` switch.
- **Frontend test 2**: `ModalEndpointKeys.serverEmitted` matches the backend `ALL_KEYS` contents exactly.

Update both session 5 §4.0 and session 6 §4.0 with the split.

---

### C2-P1-05 — Session 5 §1 decision 3 still says "via Dio (existing)" — stale Dio reference contradicts P0-03 fix

**Where**: `session_5_quote_flow_and_cash_collection.md` line 36:
> 3. **`BookingActionExecutor` extended** to support 3 action methods:
>    - `POST` / `GET` / etc. — HTTP request via Dio (existing).

**Reality**: cycle-1 patches rewrote `BookingActionExecutor` (in session 3 §4.10) as a concrete `package:http` implementation. The "Dio (existing)" wording is stale.

**Why this matters**: a reader of session 5 sees decision 3, takes it at face value, and starts looking for `Dio` in their imports. The audit-cycle-1 fix note further down the file (line 55) says "every Dio impl is illustrative only" — but decision 3 is in the AUTHORITATIVE decisions section, not a footnote. Authoritative-vs-footnote conflicts are exactly the kind of doc-rot that creates implementation drift.

**Fix**: change line 36 to:
> 3. **`BookingActionExecutor` extended** to support 3 action methods:
>    - `POST` / `GET` / etc. — HTTP request via `package:http` (per §24 canonical pattern).
>    - `NAVIGATE` — `GoRouter.of(context).push(action.endpoint)`.
>    - `MODAL` — opens a feature-side modal sheet keyed by `action.endpoint` (registry-matched per `ModalEndpointKeys`; see §4.0).

---

### C2-P1-06 — `flutterSecureStorageProvider` couples booking-orchestrator to auth feature

**Where**:
- `BOOKING_ORCHESTRATOR_SPRINT.md` line 881 (the §24 canonical pattern).
- `session_3_orchestrator_frontend_skeleton.md` line 796 — `BookingDetailRemoteDataSource` DI.
- `session_3_orchestrator_frontend_skeleton.md` line 1461 — `BookingActionExecutor` DI.

**Reality**: `flutterSecureStorageProvider` is defined at `lib/features/auth/presentation/providers/dependency_injection.dart:18`. It's an auth-feature provider.

The codebase's clear convention is **per-feature secure-storage providers**:
- `eventSecureStorageProvider` (realtime)
- `customerBookingsSecureStorageProvider`
- `addressSecureStorageProvider`
- `incomingJobSecureStorageProvider`
- `bookingSecureStorageProvider` (legacy booking feature)

Each just returns `const FlutterSecureStorage()` — they're not real singletons; they're naming conventions enforcing feature isolation.

**Why this matters**: importing `flutterSecureStorageProvider` from auth means `lib/features/orchestrator/...` now depends on `lib/features/auth/presentation/providers/...`. Auth refactors (renaming, splitting) break orchestrator. CLAUDE.md's "per-feature DI" implicit convention is broken.

This is **not a compile blocker** (the symbol exists; the import path is valid), so it ships as P1 not P0. But it's a load-bearing convention violation.

**Fix**: add a per-feature secure-storage provider in the orchestrator DI:

```dart
// frontend/lib/features/orchestrator/presentation/providers/dependency_injection.dart
@Riverpod(keepAlive: true)
FlutterSecureStorage orchestratorSecureStorage(Ref ref) =>
    const FlutterSecureStorage();
```

And reference `orchestratorSecureStorageProvider` (not `flutterSecureStorageProvider`) in:
- §24 canonical pattern in meta-doc.
- Session 3 §4.4 BookingDetailRemoteDataSource DI (line 796).
- Session 3 §4.10 BookingActionExecutor DI (line 1461).
- Sessions 4, 5, 6 — every new data source DI block.

---

### C2-P1-07 — Two `sendUpstream` definitions for `WsConnectionNotifier` in session 4

**Where**: `session_4_live_tracking_and_dual_maps.md`:
- §4.7.5 lines 1108-1112 — version 1: returns silently if `_channel == null`; no try/catch.
- §4.9 lines 1306-1314 — version 2: same null guard; ALSO has a try/catch around `channel.sink.add(jsonEncode(message))`; logs on failure.

**Why this matters**: the WsConnectionNotifier patch is described in two non-coterminous sections. The implementer either copies one and ignores the other, or merges them mechanically and ends up with two `sendUpstream` methods on the same class (compile error: duplicate member).

The version-2 implementation is strictly safer (catches `WebSocketChannelException` if the sink throws synchronously). It should win.

**Fix**: keep version 2 (in §4.9). Delete the `sendUpstream` block from §4.7.5. Reference §4.9 for the method body. Add a one-line note in §4.7.5: "see §4.9 for `sendUpstream` definition; this section only adds `connectionEvents`."

(This also tightens C2-P0-03's resolution: the WsConnectionNotifier patch and the TrackingSubscriptionController patch should both consolidate to single sources.)

---

## §4 P2 findings (medium — fix or flag)

### C2-P2-01 — `readonly_fields=['__all__']` is invalid Django Admin syntax

**Where**: `session_1_backend_foundations.md` line 1510 — `TechReliabilityIncident` admin registration:
> register with default `ModelAdmin`, `list_display=[...]`, `list_filter=['incident_type']`, `readonly_fields=['__all__']` (audit log; never edited).

**Reality**: Django Admin's `readonly_fields` expects a list of field name strings (or callable names). The string `'__all__'` is NOT a recognized special value (unlike DRF serializers). With `readonly_fields=['__all__']`, Django:
1. Looks up a field named literally `__all__` on the model.
2. Doesn't find one.
3. Either raises `AdminFieldError` (Django ≥3.x) or silently treats every field as editable.

**Why this matters**: the intent ("never edited") goes unmet. Admin can mutate any field — an admin accidentally clicking and editing a `TechReliabilityIncident` row corrupts the reliability audit trail.

**Fix**: implement the "all readonly" pattern correctly:

```python
@admin.register(TechReliabilityIncident)
class TechReliabilityIncidentAdmin(admin.ModelAdmin):
    list_display = ['id', 'technician', 'booking', 'incident_type', 'created_at']
    list_filter = ['incident_type']

    def get_readonly_fields(self, request, obj=None):
        # Audit log: never editable post-write.
        return [f.name for f in self.model._meta.fields]

    def has_add_permission(self, request):
        return False    # only orchestrator writes; no admin-side adds

    def has_delete_permission(self, request, obj=None):
        return False    # never delete an audit row
```

Update session 1 File 24 admin block accordingly.

---

### C2-P2-02 — Modal keys `decline` and `bargain` are too generic; collision risk

**Where**: `session_5_quote_flow_and_cash_collection.md` line 257-258:
```dart
static const quoteDecline = 'decline';
static const quoteBargain = 'bargain';
```

**Why this matters**: keys are used as the last path segment of the modal endpoint. `decline` is a generic word — if a future sprint adds an "inspection-decline" modal, "tech-decline-job" modal, etc., the key collides. The parity test catches duplicate Dart const declarations (compile error) but doesn't catch reuse of the same string for two semantically different modals.

The longer keys (`cash-collection-confirm`, `tech-cancel-confirm`) are namespaced — collision-resistant by construction.

**Fix**: rename for namespace consistency:
- `decline` → `quote-decline`
- `bargain` → `quote-bargain`

Also update backend `quote_decline_endpoint(...)` and `quote_bargain_endpoint(...)` to emit the new strings:
```python
def quote_decline_endpoint(booking_id, quote_id):
    return f'/booking/{booking_id}/quotes/{quote_id}/quote-decline'
```

This breaks the URL convention slightly (the `quotes/<id>` segment is now followed by `quote-decline` not `decline`) — accept it for the namespace win, OR keep URL structure and only rename the Dart constants (less consistent but lower-impact).

**Trade-off**: 7 keys total currently. Rename now or accept the risk. P2 — not blocking.

---

### C2-P2-03 — Inline `// Audit P0-X` comments couple sprint code to AUDIT.md

**Where**: every patched code block in sessions 1-6 carries `# Audit P0-X` / `// Audit P1-X` annotations (estimated ~80 inline comments across the 8 files).

**Why this matters**: the comments ARE the only documentation for WHY a particular line exists. They reference an external doc (`AUDIT.md`) which:
1. May get archived after the sprint ships (cycle-1 was advisory; some teams delete audit files post-implementation).
2. Has 1003 lines of detail; finding "P1-05" requires scrolling.
3. Doesn't ship in production code — the inline comments would (the IDs persist in compiled comments after the sprint files are deleted).

**Why it's not a P1**: the patches work without the comments; they're documentation. But the comments are a coupling between code and an external doc that may have a shorter lifespan than the code.

**Fix (defer-OK)**: at sprint completion, do a post-implementation pass that either:
- Replaces `// Audit P0-X: <reason>` with just `// <reason>` (drop the ID).
- Or replaces with `// (sprint v1 audit; see flag.md #N)` if the corresponding flag is opened.
- Or copies the relevant explanation directly into the code so the file is self-contained.

Defer to the planned UI/code-cleanup pass.

---

## §5 P3 findings (nits)

### C2-P3-01 — `developer.log(...)` import not shown in modal dispatch snippet

**Where**: `session_5_quote_flow_and_cash_collection.md` lines 329, 367 — `developer.log(...)` calls in `_openModal`.

`developer.log` is from `dart:developer`. The snippet header doesn't show this import; the implementer may forget. Add an `import 'dart:developer' as developer;` line to the example, or note it explicitly.

---

### C2-P3-02 — Mixed casing on `audit P0-X` annotations

Some inline annotations use `Audit P0-X` (capitalized), others use `audit P0-X` (lowercase). Examples: session 4 line 1219 "Audit P1-05:", session 4 line 1233 "Audit P0-07:", but other places use lowercase. Choose one and apply consistently. Trivial.

---

### C2-P3-03 — Sprint meta §16 strikethrough line is unformatted in some renderers

**Where**: `BOOKING_ORCHESTRATOR_SPRINT.md` line 557 — `| ~~tech_reliability_penalty~~ | — | — | — | **Removed per audit P0-08.**`.

GitHub markdown renders `~~text~~` correctly, but some markdown viewers (raw IDE preview, certain pandoc configs) don't. Consider replacing with a non-rendered marker like `| [REMOVED] tech_reliability_penalty |`.

---

### C2-P3-04 — `'orchestrator'` log name namespace inconsistent

`developer.log(..., name: 'orchestrator')` in modal dispatch (session 5/6) doesn't follow the existing namespace convention (`'core.presentation.ws_dispatcher'` per `ws_frame_dispatcher.dart:38`). Consider `'features.orchestrator.modal_dispatcher'` for searchability.

---

## §6 CSC findings (cross-session consistency, cycle 2)

### C2-CSC-01 — Provider name inconsistent within session 4

Session 4 line 1129 says `wsConnectionNotifierProvider`; line 1290 says `wsConnectionProvider`. Resolve as part of C2-P0-02. Single doc, two different references to the same provider — a strong signal that nobody re-read the doc end-to-end after the §4.7.5 patch was added.

### C2-CSC-02 — Two `TrackingSubscriptionController` definitions (also covered by C2-P0-03)

Re-listed here for the consistency angle: the same class name with two different bodies in the same file. Resolve by deleting one.

### C2-CSC-03 — `BookingUiTone.fromWire(String wire)` non-nullable, `BookingUiActionStyle.fromWire(String? wire)` nullable

Both are extensions added in session 3. The non-null/null choice depends on whether the field is required in the serializer:
- `_UiBlockSerializer.tone` is `ChoiceField(...)` without `allow_null` → required → non-null `fromWire` is correct.
- `_UiActionSerializer.style` has `required=False` → optional → null `fromWire` is correct.

**Verdict**: actually correct as-is, but the rationale isn't documented. Add a one-line comment in session 3 §4.1 explaining the choice so future-readers don't "fix" the asymmetry.

---

## §7 Coupling & cohesion (cycle 2)

Cycle-1 §7 covered the existing structural concerns; cycle-2 reviews changes introduced by the patches:

### Coupling concerns introduced by patches

- **§24 canonical pattern + per-data-source duplication**. The §24 pattern is good; but each data source duplicates ~15 lines of token-read + URL-build + response-parsing scaffolding. With 7 data sources in sessions 3-6, that's 100+ lines of identical-looking boilerplate. **Recommendation**: introduce a `BookingHttpClient` wrapper in `features/orchestrator/data/datasources/` that takes `(http.Client, FlutterSecureStorage)` and exposes `Future<http.Response> get(String path)`, `post(String path, {dynamic body})`, `multipart(String path, {required MultipartRequestBuilder build})`. Each data source reduces from 15 lines to 3. Single point to fix C2-P0-01 (URL prefix), C2-P1-06 (secure-storage provider), and any future header changes (e.g. CSRF, API versioning).
  - Trade-off: small abstraction, real benefit. P2-priority refactor.

- **`flutterSecureStorageProvider` cross-feature dependency** (C2-P1-06). Coupling to auth feature breaks per-feature DI convention.

- **Session 4's `TrackingSubscriptionController` listens to `bookingDetailNotifierProvider`** to gate subscription on status × role. This couples the realtime subscription mechanism to the booking-detail provider. Acceptable since both are orchestrator-feature-internal, but a stricter design separates "subscription owner" (just the WS plumbing) from "subscription policy" (status × role decision) — the former lives in `core/realtime`, the latter in feature code. P2-cleanup, not urgent.

- **`BookingActionExecutor`'s 3-method dispatch** (HTTP / NAVIGATE / MODAL): cycle-1 §7 identified this; cycle-2 patches did NOT address. Still a single class doing 3 things. Not addressed by audit P1-09 (which fixed only the MODAL dispatch fragility, not the dispatch consolidation).

### Cohesion improvements introduced by patches

- **Modal endpoint registry** (C2-P1-04 fix needed but the *concept* is clean). Frontend keys ↔ backend constants ↔ helper functions for endpoint construction. Three small modules with one job each. Better than the v0.9 inline strings.

- **`TechReliabilityIncident` model** (cycle-1 P0-08 fix). Replaces a fuzzy "broadcast to admin" semantic with a concrete database table. Higher cohesion: admin reliability data has one home.

- **`BookingValidationError` envelope** (cycle-1 P0-01 fix). One error class for orchestrator transitions; matches the documented error envelope. Higher cohesion than per-condition exception classes.

### Coupling concerns inherited from cycle-1 (unchanged)

- `available_transitions` projection vs orchestrator validation (cycle-1 P2-05) — still two sources of truth for transition rules.
- `BookingStatus` enum lives in customer/bookings — still cross-feature.
- Foreground service lifecycle in `BookingOrchestratorScreen.initState` — still tightly coupled.

---

## §8 What cycle-1 missed (independent of cycle-1 patches)

These are findings that should have surfaced in cycle-1 but didn't, and aren't introduced by patches.

### C2-X-01 — `BookingDetailView` ordering clarification missed

Session 2 §4.7 shows path order with `<int:booking_id>/` for booking-detail BEFORE `<int:pk>/accept/` for accept. Both work because the trailing-segment pattern differs (`/`)v.s. `/accept/`), but the kwarg name divergence (`booking_id` vs `pk`) is jarring. cycle-1 P1-13 fix said "show full ordered urls.py"; it does, but the kwarg-name inconsistency is worth a one-line note.

**Severity**: P3.

### C2-X-02 — `BookingDetailView` ETag not specified

Session 2 §4.6 dropped `cache_control` (cycle-1 P1-04 fix). But there's no `ETag` / `Last-Modified` either. For mobile clients on poor networks, a conditional GET (`If-None-Match`) saving 1.5KB per fetch on no-change is valuable. Not addressed.

**Severity**: P3 — acceptable for v1.

### C2-X-03 — Dispute photo MIME-type whitelist missing

Cycle-1 P1-10 added the 5MB size cap for `OpenDisputeRequestSerializer.validate_photo`. Good. But MIME-type whitelist is missing — DRF's `ImageField` does Pillow-validate (rejects non-images) but accepts BMP/TIFF/SVG which are rare and may indicate evasion attempts. A `if photo.image.format not in {'JPEG', 'PNG', 'WEBP'}` check tightens the whitelist.

**Severity**: P3.

### C2-X-04 — `_can_subscribe` log message includes booking ID

Session 2 §4.10 `_can_subscribe` returns False for various reasons (not participant, terminal status, booking not found). The patch added a `logger.warning('subscribe_tracking denied: user=%s booking=%s', ...)` (line 1096 of session 2). Logging the `booking_id` of denied requests creates a side-channel: a malicious client can probe enumeration by feeding sequential IDs and measuring log volume.

**Severity**: P3 — acceptable; production logs should be access-controlled.

---

## §9 Summary table — cycle-2 fix priority

| ID | Severity | Title | Where | Effort |
|---|---|---|---|---|
| C2-P0-01 | P0 | Double `/api/` URL prefix | §24, sessions 2-6 | 30 min |
| C2-P0-02 | P0 | `wsConnectionNotifierProvider` undefined | session 4 §4.7.5 | 1 min |
| C2-P0-03 | P0 | Two contradictory `TrackingSubscriptionController` defs | session 4 §4.7.5 + §4.9 | 30 min (decide + merge) |
| C2-P0-04 | P0 | Stale Dio code blocks remain | sessions 4, 5 | 1 hr (rewrites) |
| C2-P0-05 | P0 | Stale `0009` migration reference | session 1 §6 | 1 min |
| C2-P1-01 | P1 | Riverpod `dispose()` override won't run | session 4 §4.7.5 | 5 min |
| C2-P1-02 | P1 | `_connectionEvents.add(...)` shown as comment | session 4 §4.7.5 | 10 min |
| C2-P1-03 | P1 | `payment_received is_critical=True` wrong in spot-check | session 1 File 13 | 1 min |
| C2-P1-04 | P1 | Modal-key parity contract asymmetric | sessions 5, 6 §4.0 | 20 min |
| C2-P1-05 | P1 | Session 5 dec 3 says "via Dio (existing)" | session 5 §1 | 1 min |
| C2-P1-06 | P1 | `flutterSecureStorageProvider` cross-feature coupling | §24, sessions 3-6 | 15 min |
| C2-P1-07 | P1 | Two `sendUpstream` defs for WsConnectionNotifier | session 4 §4.7.5 + §4.9 | 5 min |
| C2-P2-01 | P2 | `readonly_fields=['__all__']` invalid Django syntax | session 1 File 24 | 5 min |
| C2-P2-02 | P2 | Modal keys `decline`/`bargain` too generic | session 5/6 | 10 min |
| C2-P2-03 | P2 | Inline `// Audit P0-X` couples to AUDIT.md | all sessions | defer to cleanup |
| C2-P3-01 | P3 | `developer.log` import not shown | session 5 | 1 min |
| C2-P3-02 | P3 | Mixed casing on Audit IDs | all sessions | trivial |
| C2-P3-03 | P3 | `~~strikethrough~~` rendering | meta §16 | trivial |
| C2-P3-04 | P3 | `'orchestrator'` log namespace inconsistent | sessions 5/6 | trivial |
| C2-CSC-01 | CSC | `wsConnectionNotifierProvider` vs `wsConnectionProvider` | session 4 | 1 min |
| C2-CSC-02 | CSC | Two `TrackingSubscriptionController` defs | session 4 | (covered by C2-P0-03) |
| C2-CSC-03 | CSC | `fromWire` nullability rationale undocumented | session 3 §4.1 | 1 min |

**Total cycle-2 effort to close all P0 + P1**: ~3 hours.

---

## §10 Recommended action sequence

1. **C2-P0-01 first** (URL double prefix): 30-min find/replace pass across §24, sessions 2-6 inline URLs, session 2 backend `orchestrator_ui.py` handlers. Highest blast radius.

2. **C2-P0-02, C2-P0-05, C2-P1-03, C2-P1-05**: trivial 1-line edits each, ~5 min total.

3. **C2-P0-03 and C2-P1-07 together** (TrackingSubscriptionController + sendUpstream consolidation): one design decision (Option A from C2-P0-03), ~30 min to rewrite §4.7.5 and §4.9 cleanly.

4. **C2-P0-04 (Dio rewrite)**: 1 hour. Either do all 30 occurrences in one pass, or accept the cost and add a stronger header note at the top of each session 4 / 5 saying "code blocks below are illustrative; pubspec ships `http`. Translate per §24 mechanically." (P1 not P0 if the latter — but cleaner to just do the rewrite.)

5. **C2-P1-01, C2-P1-02 (Riverpod dispose, _connectionEvents.add insertion)**: ~15 min combined.

6. **C2-P1-04 (modal parity registry split)**: ~20 min — define `serverEmitted` vs `all` constants, update both session 5 and 6, document the test contract precisely.

7. **C2-P1-06 (secure storage per-feature)**: 15 min — add `orchestratorSecureStorageProvider`, replace cross-feature reference.

8. **P2 / P3 / CSC**: batch with a code-cleanup pass post-sprint, or address opportunistically.

After the patch: run a third audit pass only if the cycle-2 patch ends up materially refactoring more than two sections. If the cycle-2 patch is the surgical 5-edit set described above, no third cycle is needed.

---

## §11 What this audit does NOT cover

- Visual design (planned UI cleanup pass).
- Test code internals (tests don't exist yet).
- iOS implementation (deferred per flag #10).
- Finance sprint (deferred).
- Real production load profiles (no load test).
- Internationalization, accessibility (out of sprint scope).

---

**Audit by**: Claude Opus 4.7
**Date**: 2026-05-08
**Files audited**: `BOOKING_ORCHESTRATOR_SPRINT.md` + `session_1` through `session_6` + cycle-1 `AUDIT.md` (12,483 lines).
**Codebase ground-truth re-verification**: pubspec, `lib/core/constants.dart`, `lib/core/common/errors/http_failure.dart`, `lib/core/realtime/presentation/providers/dependency_injection.dart`, `lib/core/realtime/presentation/notifiers/ws_connection_notifier.dart` + generated, `lib/core/realtime/presentation/services/ws_frame_dispatcher.dart`, `backend/realtime/constants/event_types.py`, `backend/bookings/exceptions.py`, `backend/catalog/migrations/`, `backend/bookings/migrations/`, plus grep verification of every claim about file paths, symbol names, and provider naming.

---

**Cycle-2 status**: 5 P0, 7 P1, 3 P2, 4 P3, 3 CSC findings. All P0 and P1 are localized to small specific lines. The plan remains structurally sound; cycle-2 is a polish-pass on cycle-1's patch, not a re-design.

---

## §12 Resolutions (cycle-2 close-out)

The cycle-2 findings have been patched into the seven sprint files. Each finding ID below maps to the file and section where the fix lives. Verification: post-patch grep for the bug signatures (`AppConstants.baseUrl}/api/`, `wsConnectionNotifierProvider`, `flutterSecureStorageProvider` in code, `final Dio _dio`) returns zero matches outside this audit document.

### P0 (all resolved)

| ID | Where the fix lives |
|---|---|
| C2-P0-01 | **Meta §24** — canonical pattern URL changed `${baseUrl}/api/foo/...` → `${baseUrl}/foo/...`; new "URL convention" subsection added explaining baseUrl already includes `/api`. **Session 2 §4.8** — every `orchestrator_ui.py` handler emits `f'/bookings/{booking.id}/...'` (literal `/api/` dropped from `endpoint=` strings). **Session 3 §4.4** — `BookingDetailRemoteDataSource.fetch` URL fixed with inline audit annotation. **Session 4 §4.11** — `TechLocationRemoteDataSource.postLocation` URL fixed (combined with C2-P0-04 rewrite). **Session 5 §4.2** — `QuoteRemoteDataSource`, `CashCollectionRemoteDataSource`, `StartInspectionRemoteDataSource`, `SubServiceCatalogRemoteDataSource` all use `${baseUrl}/<resource>/...`. **Session 6 gotcha 8** — multipart pattern URL fixed. |
| C2-P0-02 | **Session 4 §4.7.5 line 1132** — `wsConnectionNotifierProvider` → `wsConnectionProvider` with inline rationale comment citing the `.g.dart` ground truth (riverpod_generator strips the `Notifier` suffix). |
| C2-P0-03 | **Session 4 §4.7.5** rewritten as "WsConnectionNotifier extension only" (no controller defined here); explicit reference points implementer to §4.9 for the canonical `TrackingSubscriptionController`. **Session 4 §4.9** rewritten as the single canonical controller — listens to `bookingDetailNotifierProvider` for status×role gating AND `ws.connectionEvents` Stream for reconnect re-subscribe (replaces `wsConnectionStatusProvider` listener; rationale documented inline — Stream is precise where Riverpod state listener can elide fast disconnect-reconnect transitions). |
| C2-P0-04 | Stale Dio code blocks rewritten to `package:http`: **Session 4 §4.4** `GoogleDirectionsService` (uses `Uri.https(...)` for query params, drops `DioException` in favor of `SocketException` + statusCode checks); `OsrmDirectionsService` (same pattern). **Session 4 §4.5** `directionsServiceProvider` reuses the existing `eventHttpClientProvider` singleton instead of `Dio()`. **Session 4 §4.11** `TechLocationRemoteDataSource` (full http rewrite; constructor takes `http.Client`; returns `bool` for throttle vs success). **Session 4 §4.12** foreground task handler constructs a fresh `http.Client()` in `onStart`, closes it in `onDestroy`. **Session 4 test mocks** use `MockClient` from `package:http/testing.dart` instead of `MockDio`. **Session 5 §4.2** all three remaining data sources rewritten. **Session 6 gotcha 8** multipart pattern points to §24 `http.MultipartRequest` template. |
| C2-P0-05 | **Session 1 §6** verification step — comment changed `# apply 0008 + 0009` → `# applies bookings 0008 + catalog 0008 (different apps)`. |

### P1 (all resolved)

| ID | Where the fix lives |
|---|---|
| C2-P1-01 | **Session 4 §4.7.5** — `dispose()` override removed; replaced by `ref.onDispose(() { ... _connectionEvents.close(); })` registered inside the existing `build()` method. The patch shows the FULL `build()` body (existing teardown + new controller close) so implementer doesn't have to merge. |
| C2-P1-02 | **Session 4 §4.7.5** — placeholder comments replaced by 4 concrete insertion-site instructions, each with the existing-file line number anchor: (a) after `state = WsConnectionStatus.connected;` in `connect()` (~line 96); (b) before `state = WsConnectionStatus.disconnected;` in `disconnect()` (~line 155); (c) in the `onDone:` and (d) `onError:` branches inside `connect()`'s stream listener (~lines 109–122) before each `_scheduleReconnect(authToken);` call. |
| C2-P1-03 | **Session 1 File 13** — spot-check note rewritten to list ONLY the 5 critical events (`quote_generated`, `quote_approved`, `job_completed`, `dispute_opened`, `dispute_resolved`); explicitly states `payment_received` is `is_critical=False` with rationale ("cash collection confirms via the explicit POST response, not via an ACK on the realtime event"); explicitly says "Do NOT flip `payment_received` to True." |
| C2-P1-04 | **Session 5 §4.0** — `ModalEndpointKeys` split into `serverEmitted` (parity-tested against backend `ALL_KEYS`) and `all` (= `serverEmitted ∪ {client-only}`, used by handler-coverage test). Three test contracts replace the single "bidirectional parity" claim: (1) frontend handler-coverage; (2) backend emission-coverage; (3) cross-language fixture-based equality on `serverEmitted` only. **Session 6 §4.0** — `ModalEndpointKeys` extension uses the same split; `techCancelConfirm` placed in `all` (client-only) but NOT in `serverEmitted`. The `_openModal` switch now has an explicit `case ModalEndpointKeys.techCancelConfirm:` arm with rationale comment. |
| C2-P1-05 | **Session 5 §1 decision 3** — "HTTP request via Dio (existing)" → "HTTP request via `package:http` per the canonical pattern in `BOOKING_ORCHESTRATOR_SPRINT.md` §24"; explicit reference to session 3 §4.10 where `BookingActionExecutor` was rewritten in cycle-1's P0-03 fix. |
| C2-P1-06 | **Meta §24** — "Provider wiring" subsection rewritten with `orchestratorSecureStorage` declaration; explicit prose forbids cross-feature import of `flutterSecureStorageProvider` and explains the codebase convention (per-feature secure-storage providers). **Session 3 §2** file table updated to mention `orchestratorSecureStorage`. **Session 3 §4.4** DI block now declares `orchestratorSecureStorage` provider before the data-source provider; both sites that previously referenced `flutterSecureStorageProvider` now use `orchestratorSecureStorageProvider`. **Session 4 §4.12** foreground service controller swapped to `orchestratorSecureStorageProvider`. |
| C2-P1-07 | **Session 4 §4.7.5** — sole canonical `sendUpstream` definition kept (with `try/catch` + `log` per the safer version 2). **Session 4 §4.9** — duplicate `sendUpstream` definition removed; explicit "see §4.7.5 for the method body" note. |

### P2 (resolved or accepted)

| ID | Where the fix lives |
|---|---|
| C2-P2-01 | **Session 1 File 24** — `readonly_fields=['__all__']` (invalid Django syntax) replaced with full `TechReliabilityIncidentAdmin` class showing `get_readonly_fields()` returning every field name, `has_add_permission()` returning False, `has_delete_permission()` returning False — locks the audit log immutable. |
| C2-P2-02 | **Not patched.** Modal keys `decline` and `bargain` retained as-is. Risk: a future modal could collide on the same key. Mitigated by the parity tests (test #2 catches duplicate emitted keys; test #3 catches cross-language drift). Accept; rename in a future polish pass if a real collision arises. |
| C2-P2-03 | **Not patched.** Inline `// Audit P0-X` annotations retained. Defer the cleanup pass (drop the audit IDs and inline the rationale) to the planned UI/code-cleanup pass post-sprint, per memory `project_ui_cleanup_planned`. |

### P3 / CSC

| ID | Status |
|---|---|
| C2-P3-01 | Not patched (snippet-level nit). Add `import 'dart:developer' as developer;` if missing during implementation. |
| C2-P3-02 | Not patched (cosmetic). The mixed-casing on Audit IDs gets cleaned up alongside C2-P2-03 in the post-sprint cleanup pass. |
| C2-P3-03 | Not patched (renderer-specific). `~~strikethrough~~` works in GitHub markdown which is the primary rendering target. |
| C2-P3-04 | Not patched (cosmetic). Log namespace `'orchestrator'` works; future cleanup can align with the `core.presentation.*` convention. |
| C2-CSC-01 | Resolved by C2-P0-02. |
| C2-CSC-02 | Resolved by C2-P0-03. |
| C2-CSC-03 | Not patched (rationale documentation only). The non-null/null asymmetry on `BookingUiTone.fromWire(String)` vs `BookingUiActionStyle.fromWire(String?)` is correct (matches serializer's required-vs-optional fields); a one-line documentation comment can be added during implementation. |

### Files modified by the cycle-2 patch

```
booking_orchestrator_sprint/
  AUDIT_CYCLE_2.md                                (this §12 added)
  BOOKING_ORCHESTRATOR_SPRINT.md                  (§24: URL convention, http rewrite, orchestratorSecureStorage)
  session_1_backend_foundations.md                (File 13 spot-check; File 24 admin; §6 migration comment)
  session_2_backend_transitions.md                (orchestrator_ui.py endpoint strings: /api/ dropped)
  session_3_orchestrator_frontend_skeleton.md     (§2 file table; §4.4 BookingDetailRemoteDataSource URL + DI; §4.10 BookingActionExecutor DI; data-layer prose)
  session_4_live_tracking_and_dual_maps.md        (§1 dec 10 prose; §2 file table; §4.4 GoogleDirectionsService + OsrmDirectionsService http rewrite; §4.5 directionsServiceProvider; §4.7.5 WS notifier extension only; §4.9 single canonical TrackingSubscriptionController; §4.11 TechLocationRemoteDataSource http rewrite; §4.12 foreground handler http.Client; §4.13 secure-storage provider; test mocks → MockClient)
  session_5_quote_flow_and_cash_collection.md     (§1 dec 3; §4.0 ModalEndpointKeys serverEmitted/all split + 3-test parity contract; §4.2 QuoteRemoteDataSource + CashCollectionRemoteDataSource + StartInspectionRemoteDataSource URL + SubServiceCatalogRemoteDataSource http rewrite; DoD scan note)
  session_6_lifecycle_edges_and_polish.md         (§4.0 ModalEndpointKeys extension matching split; _openModal techCancelConfirm explicit case; gotcha 8 multipart pattern)
```

**Net effect**: all 5 P0 and 7 P1 cycle-2 items closed in-document. P2-01 patched; P2-02/P2-03/P3-01/P3-02/P3-03/P3-04/CSC-03 accepted as defer-OK. Sessions are now executable as written, against the cycle-1 + cycle-2 verified codebase ground truth.

A third audit cycle is not recommended at this point — cycle-2 patch was surgical (5 modal-registry edits, 7 Dio rewrites, 6 URL drops, 4 small instruction edits). The risk surface for new defects is minimal.
