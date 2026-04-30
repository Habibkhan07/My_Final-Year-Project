# Realtime Streams — Backend Patch Summary & Frontend Sync Brief

> **Purpose.** This file is a handoff document. It captures the backend
> changes shipped in the streams-introduction patch (2026-04-27) and
> brief the next session on the frontend work needed to sync. Read this
> before touching `frontend/lib/core/realtime/`.
>
> **Companion docs:**
> - `REALTIME_EVENTS_AUDIT_CONTEXT.md` — the original audit + architectural framing.
> - `backend/realtime/api/EVENT_DISPATCH_API.md` — event contract (now with `kind`).
> - `backend/realtime/api/STREAM_DISPATCH_API.md` — stream contract (new).

---

## 1. The mental model (load-bearing — internalize before reading code)

The frontend confusion that started this work — *"is wallet balance an
event?"* — has no answer per topic. It has one answer **per frame**.
The same topic can produce both kinds of traffic.

| | Event | Stream |
|---|---|---|
| **Is** | A *fact* about something that happened. | A *value* of current state. |
| **Examples** | `jobDispatched`, `paymentReceived`, `walletCredited`, `walletLowBalance`, chat *message* | live GPS, live wallet *balance display*, AI chatbot *tokens*, chat *typing indicator* |
| **Persistence** | `EventLog` row, indexed for sync replay | None — transient |
| **Offline** | FCM fallback via Celery | Drop the frame |
| **ACK** | Critical events require client ACK | None |
| **Frequency** | Discrete, business-paced | Continuous, can be sub-second |

**Wallet, for example, generates both:**
- `walletCredited` / `walletLowBalance` → **events** (durable, FCM fallback).
- `walletBalanceCurrent` (the live number on the dashboard) → **stream**
  (just paints state, no offline meaning).

**Chat, for example, generates both:**
- The chat *message itself* → event (durable, syncs on reconnect, can
  arrive via FCM when app is closed).
- The *typing indicator* / read receipts → streams.

The same socket carries both. The frontend dispatcher uses the wire-
level `kind` field to route.

---

## 2. What landed on the backend

### 2.1 The wire envelope now carries `kind`

**Event frame (existing shape, with new `kind` field):**

```json
{
  "kind": "event",
  "id": "uuid-v4",
  "rawType": "job_accepted",
  "targetRole": "customer",
  "timestamp": "2026-04-27T07:12:33.102000Z",
  "payload": { "job_id": "abc-123", ... }
}
```

**Stream frame (new):**

```json
{
  "kind": "stream",
  "streamType": "wallet_balance",
  "timestamp": "2026-04-27T07:12:33.102000Z",
  "payload": { "balance": 4237 }
}
```

Streams have **no** `id`, `targetRole`, or `is_critical`. They are
anonymous frames that paint state — nothing to correlate, route by
role, or elevate to FCM.

`kind` is **required** on every frame going forward. Frontend should
hard-cut: switch on `kind`, fail loudly if absent.

### 2.2 Same socket, same group, same consumer

The streams patch deliberately avoided introducing:
- A second WebSocket URL (`ws/streams/`).
- A second per-user channel-layer group.
- A second consumer class.
- A `StreamType` enum.
- A REST ingress endpoint.

Streams flow through:
- **URL:** `ws/events/` (kept; rename deferred to a future deliberate refactor — see naming caveat in `backend/realtime/events/consumers.py` module docstring).
- **Group:** `user_<id>_events` (same template, defined once in `backend/realtime/constants/groups.py`).
- **Consumer:** `SystemEventConsumer` (new `system_stream` handler added alongside existing `system_event`).
- **Channel-layer message types:** `system.event` (events) vs `system.stream` (streams) — the *backend-side* discriminator at the channel layer.

The consumer is envelope-agnostic. Both handlers do the same thing:
extract `event["message"]` and forward as JSON. The frontend is what
routes.

### 2.3 Two publishers, narrowly scoped

**Events:** `realtime.events.services.EventDispatchService.broadcast_event(...)` — unchanged in shape; envelope now includes `"kind": "event"`. Internals:
1. Persist `EventLog` row.
2. WS dispatch via `_push_to_channel_layer` (try/except narrowed — see 2.4).
3. FCM via Celery (still wrapped in barrel try/except).

**Streams:** `realtime.streams.publish_stream(*, user, stream_type, payload)` — new, ~30 lines:
1. Build envelope with `kind: "stream"`.
2. `group_send` with `system.stream` channel-layer type.
3. Narrow try/except around `group_send` only. No DB write. No FCM. Returns `None`.

Two distinct classes/modules. A service that imports `publish_stream` *cannot* accidentally write to `EventLog` (the model isn't imported). A service that imports `EventDispatchService` *cannot* accidentally publish a stream. The import graph enforces the boundary.

### 2.4 Try/except scoping — `kind` of bug-hiding fixed

**Old shape (event dispatch):** the entire `_push_to_channel_layer` helper was wrapped in `try/except Exception` from the caller — which swallowed *coding errors* (bad config, formatting bugs, KeyError on `user.id`) along with network errors.

**New shape (events + streams):** the try/except lives **inside** the helper, scoped to the network call only:

```python
try:
    async_to_sync(channel_layer.group_send)(group_name, message)
except Exception:
    logger.exception(...)  # or warning for streams
```

Bugs above the `group_send` line propagate so they surface in dev. Only
the actual network operation is best-effort.

### 2.5 Sync endpoint also returns `kind`

`backend/realtime/events/api/serializers.py:EventLogSerializer` gained a
`kind` `SerializerMethodField` returning the literal `"event"`. So
`GET /api/events/sync/` and `GET /api/events/unacknowledged/` return
envelopes that match the wire shape — the frontend dispatcher uses one
switch for live frames *and* replayed frames.

---

## 3. Files changed (backend)

| File | Change |
|---|---|
| `backend/realtime/constants/groups.py` | **New.** Single source of truth for `USER_GROUP_TEMPLATE`. |
| `backend/realtime/events/consumers.py` | Imports template from constants. New `system_stream` handler. Module docstring documents the historical-naming caveat. |
| `backend/realtime/events/services/event_dispatch_service.py` | Envelope gains `kind: "event"`. WS try/except narrowed to `group_send` only. Module docstring updated. |
| `backend/realtime/events/api/serializers.py` | `kind` `SerializerMethodField` so sync output matches wire shape. |
| `backend/realtime/streams/__init__.py` | **New.** Re-exports `publish_stream`. |
| `backend/realtime/streams/dispatch.py` | **New.** ~90 lines incl. docstring + security comment. |
| `backend/realtime/api/STREAM_DISPATCH_API.md` | **New.** Stream contract doc. |
| `backend/realtime/api/EVENT_DISPATCH_API.md` | `kind` documented. Pointer to streams sibling added. |
| `backend/tests/factories/core.py` | `EventLogFactory.payload` includes `kind` for shape parity. |
| `backend/tests/realtime/test_event_dispatch_service.py` | Channel-layer-failure test mocks at new narrow boundary (`group_send`). Positive `kind` assertions added. |
| `backend/tests/realtime/test_event_api.py` | `kind` assertions on sync + unacknowledged endpoints. |
| `backend/tests/realtime/test_consumers.py` | New forwarding tests for both `system_event` and `system_stream`. |
| `backend/tests/realtime/test_stream_dispatch.py` | **New.** 5 tests: envelope shape, no-EventLog, no-FCM, narrow-swallow + caplog, no-channel-layer fallback. |

**Test result:** 30/30 passing in `pytest backend/tests/realtime/` (was 23 before patch, +7 new).

---

## 4. Frontend sync work — what the next session needs to do

The frontend currently treats every WS frame as an event (per
`REALTIME_EVENTS_AUDIT_CONTEXT.md`):

```
WsConnectionNotifier → SystemEventNotifier.processEvent → EventLog cache → EventUrgencyRouter
```

This pipeline must **only** receive `kind: "event"` frames. Streams must
short-circuit before touching `SystemEventNotifier` (otherwise we'd
thrash `SharedPreferences` with telemetry frames, which is the exact
trap the audit document warned about).

### 4.1 Add a frame dispatcher at the network edge

Per the architectural decision in `REALTIME_EVENTS_AUDIT_CONTEXT.md`
section 3, the switch belongs in `WsConnectionNotifier`. But per the
*revised* design discussion in the streams patch, **don't** inline a
giant `if/else` chain in the notifier. Extract a `WsFrameDispatcher`
(plain Dart class, not a Riverpod notifier):

```dart
// Concept — adapt to actual conventions in lib/core/realtime/
class WsFrameDispatcher {
  WsFrameDispatcher(this._ref);
  final Ref _ref;

  void dispatch(Map<String, dynamic> frame) {
    final kind = frame['kind'] as String?;
    switch (kind) {
      case 'event':
        _ref.read(systemEventProvider.notifier).processEvent(frame);
        return;
      case 'stream':
        _routeStream(frame);
        return;
      default:
        // Hard fail in dev so missing 'kind' surfaces immediately.
        // In prod, log + drop.
        assert(false, 'WS frame missing or unknown kind: $kind');
        _logger.warning('Dropping WS frame with unknown kind: $kind');
    }
  }

  void _routeStream(Map<String, dynamic> frame) {
    final streamType = frame['streamType'] as String?;
    final payload = frame['payload'] as Map<String, dynamic>;
    // Registered handlers per streamType. For now, no streams ship —
    // log unknown ones and move on.
    final handler = _streamHandlers[streamType];
    if (handler == null) {
      _logger.fine('No handler for streamType=$streamType; dropping.');
      return;
    }
    handler(payload);
  }
}
```

`WsConnectionNotifier` calls `dispatcher.dispatch(decodedFrame)` instead
of touching `SystemEventNotifier` directly.

### 4.2 Update `SystemEventNotifier` to expect `kind: "event"`

Today `SystemEventNotifier.processEvent` receives the raw frame. Going
forward:
- The dispatcher only routes `kind == "event"` frames here, so you can
  trust `kind == "event"` is set.
- The Freezed model that represents the envelope should add a `kind`
  field (literal `"event"`) for shape parity.
- The sync-endpoint response (used on reconnect) now also includes
  `kind` — the same Freezed model can deserialize both.

**Heads up on the sync-endpoint shape:** the existing serializer has a
pre-existing oddity where `EventLog.payload` (the JSON column) stores
the *full* envelope, so the serialized output has a doubly-nested
`payload` (top-level fields rebuilt from columns + `payload` field that
is the whole envelope again). This was **not** fixed in the streams
patch — it's pre-existing and out of scope. If the existing frontend
already handles this, no change needed. If it doesn't and you discover
breakage, the fix is on the backend serializer (not the frontend
parser) — flag it back and address separately.

### 4.3 Stream handler registration (when concrete stream types arrive)

This patch ships **zero** concrete stream types. The dispatcher should
have an empty handler registry that's easy to populate later. When a
stream type does ship (e.g. `wallet_balance`), the corresponding feature
notifier registers a handler from its DI file:

```dart
// In features/technician/dashboard/presentation/providers/dependency_injection.dart
@Riverpod(keepAlive: true)
void registerDashboardStreamHandlers(RegisterDashboardStreamHandlersRef ref) {
  final dispatcher = ref.read(wsFrameDispatcherProvider);
  dispatcher.register('wallet_balance', (payload) {
    final balance = (payload['balance'] as num).toDouble();
    ref.read(technicianDashboardProvider.notifier)
       .onWalletBalanceStream(balance);
  });
}
```

This keeps the dispatcher feature-agnostic — it doesn't import any
feature provider directly.

### 4.4 Tests to add on the frontend

- **Dispatcher tests:** unit-test that `kind == "event"` routes to the
  event notifier and `kind == "stream"` routes to the registered
  stream handler. Test unknown `kind` is dropped + logged. Test missing
  `kind` is dropped + logged.
- **Update existing `SystemEventNotifier` tests:** input frames now
  include `kind: "event"`. Assert nothing else regressed.
- **Sync-endpoint deserialization tests:** ensure the new `kind` field
  parses without breaking the existing model.

### 4.5 What the frontend should *not* do in this sync patch

- Don't add stream handlers for types we don't have yet (no
  `wallet_balance`, no `telemetry` handlers — wait until those streams
  ship from a real backend caller).
- Don't add a second WS connection.
- Don't rename `SystemEventNotifier` → `RealtimeFrameNotifier` or
  similar. The class's role narrows (it now only handles events, not
  all frames), but the rename costs touching the existing 117-test
  invariants for no behavioral benefit. Defer.
- Don't add WebSocket ingress for client-originated streams. When the
  first such stream needs to flow client → server (e.g. typing
  indicator), use a thin REST endpoint that internally calls
  `publish_stream` on the backend — see `STREAM_DISPATCH_API.md`
  ingress section.

---

## 5. Decision log — what we considered and rejected

So the next session doesn't re-litigate these:

1. **Two WS connections (events + streams) → rejected.** One socket is enough; the channel-layer message type already discriminates on the backend, and `kind` discriminates on the wire. Two connections = more reconnect logic, more auth surface, no scaling benefit at our size.
2. **Two channel-layer groups per user → rejected.** Same reasoning. Add only when a real flooding problem appears.
3. **A parallel `realtime/streams/` sub-module mirroring `realtime/events/` (with `services/`, `constants/`, `api/` subfolders) → rejected.** Cargo-cult symmetry. The stream publisher is one function; one file (`realtime/streams/dispatch.py`) is right.
4. **A `StreamType` enum upfront → rejected.** Streams have no registry-worthy metadata. Strings work until one needs metadata.
5. **One pipeline with an `is_transient` flag in the event registry → rejected.** Would pollute the read-side (sync, unacknowledged) with `if not is_transient` filters. Conflates orthogonal offline policies (FCM vs. drop). Two publishers is cleaner code despite the small "duplication."
6. **Renaming `ws/events/` → `ws/realtime/`, `SystemEventConsumer` → `UserChannelConsumer`, `user_<id>_events` → `user_<id>_channel` → deferred.** Cosmetic rename costs coordinated frontend churn (touches `SystemEventNotifier`, `EventUrgencyRouter`, providers, feature doc, and the Flutter-side 117-test invariants). The naming is now slightly off (these names predate streams), but the rename earns its keep only if the misnomer proves confusing in real use. Leave a comment, defer the rename.
7. **WebSocket ingress for client-originated streams → deferred.** Use REST → `publish_stream` for now. Realistic typing-indicator frequency is 1–3 Hz; HTTP per frame is fine. Reconsider only when a stream type genuinely needs sub-100ms client→server latency (canvas drawing, audio levels).
8. **Backfilling `EventLog.payload` to add `kind` to historical rows → not needed.** Zero production data.

---

## 6. Open follow-ups (not in this patch)

Track these on the backend; they're not blockers for the frontend sync but they *will* matter eventually:

- **The doubly-nested `payload` in sync-endpoint output.** Pre-existing oddity (`EventLog.payload` JSON column stores the full envelope, and the serializer also outputs `payload` from that column verbatim — so the consumer sees a nested envelope inside the field). Not load-bearing on the frontend if the existing parser already handles it. If it bites, fix on the backend serializer side, not by reshaping in the frontend.
- **First concrete stream type.** Likely candidates in roadmap order: live wallet balance (server-push, just needs a publisher caller in the wallet recompute path), then chat typing indicator (client-originated, needs the REST ingress endpoint).
- **The naming refactor.** Bundle with another coordinated frontend-touching change — don't do it for its own sake.

---

## 7. How to start the next session

Open Claude in this repo and paste:

> Read `REALTIME_STREAMS_PATCH_SUMMARY.md` and the linked docs. The
> backend streams patch landed and is green (30/30 tests). Plan the
> frontend sync per Section 4 of the summary — start with the
> `WsFrameDispatcher` and the `SystemEventNotifier` `kind` update.
> Scratchpad first, then await approval.

The summary has enough context that the next session does not need to
re-audit the codebase. It does need to read the actual frontend
realtime files (`frontend/lib/core/realtime/`) to ground the plan in
current conventions — don't let it skip that step.

---

## 8. Frontend sync — landed (2026-04-28)

Section 4 work landed in this session. State after:

- ✅ **§4.1 — `WsFrameDispatcher`** at
  `frontend/lib/core/realtime/presentation/services/ws_frame_dispatcher.dart`.
  Plain Dart class (not a notifier). Registry-based handler lookup.
  Provider in `presentation/providers/dependency_injection.dart`,
  `keepAlive: true`. Logging policy:
    - Missing `kind` → severe + `assert(false)` (contract violation).
    - Unknown `kind` value → warning + drop (version skew).
    - Unknown `streamType` with no registered handler → warning + drop.
- ✅ **§4.2 — `SystemEventModel.kind`** added as a required field.
  Required (not nullable) was deliberate — pre-`kind` cached events in
  `event_sync_cached_events` deserialize to `null` via
  `EventLocalDataSource.getCachedEventList`'s catch-all, which the
  repository correctly treats as cache miss. No softening needed.
  `WsConnectionNotifier._onMessage` is now transport-only (decode +
  forward to dispatcher); imports of mapper/model/notifier moved into
  the dispatcher.
- ✅ **§4.4 — Dispatcher tests** added at
  `frontend/test/core/realtime/presentation/services/ws_frame_dispatcher_test.dart`
  (D1–D7: event routing, stream routing, unknown streamType, malformed
  event payload returns null, missing `kind` asserts, unknown `kind`,
  register/unregister round-trip). Existing fixtures in mapper /
  repository / local-DS / FCM-handler / WS-connection tests updated to
  include `kind: "event"`. Full frontend suite green (446 tests).
- ⏳ **§4.3 — Stream handler registration** intentionally not
  exercised. No concrete `streamType` ships with this patch; the
  registry is in place for the first real caller (likely
  `wallet_balance` per §6 of the original summary).

**Out-of-scope items (§4.5) honored** — no rename of
`SystemEventNotifier`, no second WS connection, no REST ingress for
client-originated streams.

**Open follow-ups from §6 unchanged** — the doubly-nested `payload`
oddity in the sync endpoint did not bite during this work and remains a
backend-side cleanup item. The naming refactor stays deferred.
