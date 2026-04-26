# Session 1/4: Domain Layer — Karigar Real-Time Events

## Context

We are building the **Real-Time Event Routing, Recovery, and Idempotency Layer** for the Karigar Flutter app. This is a **4-session feature** — this is session 1. You will build only the Domain layer in this session. Data and Presentation layers come in sessions 2 and 3.

The Django backend is already operational. It emits events through WebSocket + FCM with this exact JSON contract:

```json
{
  "id": "uuid4-string",
  "rawType": "job_dispatched",
  "targetRole": "technician",
  "timestamp": "2025-01-15T14:30:00.000000Z",
  "payload": { ... }
}
```

## Constraints

Read `CLAUDE.md` in the repo root first — all architectural constraints apply. Key reminders for this session:
- Domain Entities have **no** serialization annotations, **no** `fromJson`, **no** Freezed.
- Use plain Dart classes with `final` fields and `const` constructors.
- Sealed failure classes use `sealed class` + `final class` pattern.
- No `print()` — use `dart:developer log()`.
- All enum mappings must fall back gracefully to a safe default — **never throw** on unknown input.

## Workflow

Follow the `CLAUDE.md` workflow: output a `<scratchpad>` plan listing every file you will create with its purpose. Wait for approval before writing code.

---

## Files to Create

### 1. `lib/core/domain/entities/system_event_type.dart`

```dart
enum SystemEventType {
  jobDispatched,
  jobAccepted,
  quoteGenerated,
  quoteApproved,
  techEnRoute,
  techArrived,
  jobCompleted,
  paymentReceived,
  chatMessage,
  disputeOpened,
  disputeResolved,
  walletLowBalance,
  unknown;

  static SystemEventType fromRawType(String raw) { ... }
}
```

- Use a **static const `Map<String, SystemEventType>`** for O(1) lookup. Do NOT use if/else chains.
- Map backend strings like `"job_dispatched"` → `SystemEventType.jobDispatched`.
- **CRITICAL:** Unrecognized `rawType` → return `SystemEventType.unknown`. NEVER throw.

### 2. `lib/core/domain/entities/event_urgency.dart`

```dart
enum EventUrgency { highUrgency, lowUrgency, silent }
```

Include a **static const `Map<SystemEventType, EventUrgency>`** classifying every type:

| High Urgency (Full-Screen)              | Low Urgency (Banner)           | Silent         |
|-----------------------------------------|--------------------------------|----------------|
| `jobDispatched`                         | `techEnRoute`                  | `unknown`      |
| `jobAccepted`                           | `techArrived`                  |                |
| `quoteGenerated`                        | `chatMessage`                  |                |
| `quoteApproved`                         | `paymentReceived`              |                |
| `jobCompleted`                          | `walletLowBalance`             |                |
| `disputeOpened`                         |                                |                |
| `disputeResolved`                       |                                |                |

Provide a static method `EventUrgency.of(SystemEventType type)` that looks up the map. Default to `silent` for unmapped types.

### 3. `lib/core/domain/entities/target_role.dart`

```dart
enum TargetRole {
  customer,
  technician;

  static TargetRole fromString(String raw) { ... }
}
```

- `'customer'` → `customer`, `'technician'` → `technician`.
- Fallback: `customer` (defensive — unknown role should not crash).

### 4. `lib/core/domain/entities/event_criticality.dart`

A **static const `Set<SystemEventType>`** of critical event types:

```dart
abstract class EventCriticality {
  static const criticalTypes = <SystemEventType>{
    SystemEventType.jobDispatched,
    SystemEventType.jobAccepted,
    SystemEventType.quoteGenerated,
    SystemEventType.quoteApproved,
    SystemEventType.jobCompleted,
    SystemEventType.disputeOpened,
    SystemEventType.disputeResolved,
  };

  static bool isCritical(SystemEventType type) => criticalTypes.contains(type);
}
```

**CRITICAL:** This set must exactly match the Django backend's Event Type Registry. If they drift, critical events will either never be ACK'd or non-critical events will trigger unnecessary ACK calls.

### 5. `lib/core/domain/entities/system_event_entity.dart`

A **plain Dart class** — no Freezed, no serialization.

**Fields (all `final`):**
- `id` — `String`. The UUID from the backend.
- `rawType` — `String`. The raw event type string as sent by the backend.
- `eventType` — `SystemEventType`. Derived from `rawType`.
- `targetRole` — `TargetRole`.
- `timestamp` — `DateTime`. Parsed from ISO-8601 string.
- `payload` — `Map<String, dynamic>`. Opaque — core never reads inside this.
- `urgency` — `EventUrgency`. Derived from `eventType` via `EventUrgency.of()`.
- `isCritical` — `bool`. Derived via `EventCriticality.isCritical(eventType)`.

**Constructor:**
- Use a `const` constructor that takes all fields.
- Also provide a named constructor `SystemEventEntity.fromComponents(...)` that takes only `id`, `rawType`, `targetRole`, `timestamp`, `payload` and derives `eventType`, `urgency`, `isCritical` internally. The Data layer mapper in session 2 will use this.

**Equality:**
- Override `==` and `hashCode` using **`id` only**. Two events with the same UUID are the same event regardless of other fields — this is essential for the dedup logic in session 3.

**Dartdoc:**
- Document the contract: which Django endpoint feeds this entity (the WebSocket stream and `/api/events/sync/`).
- Note that `payload` is opaque to the core layer.

### 6. `lib/core/domain/failures/event_failures.dart`

Two parallel sealed hierarchies:

```dart
sealed class EventSyncFailure implements Exception {
  const EventSyncFailure();
}

/// Network unreachable and no cached data available.
final class EventSyncNetworkFailure extends EventSyncFailure {
  const EventSyncNetworkFailure();
}

/// Backend returned a non-2xx response.
final class EventSyncServerFailure extends EventSyncFailure {
  final String message;
  const EventSyncServerFailure(this.message);
}

/// Auth token expired or invalid. Triggers re-login flow.
final class EventSyncUnauthorized extends EventSyncFailure {
  const EventSyncUnauthorized();
}
```

And a parallel hierarchy for device registration:

```dart
sealed class DeviceRegistrationFailure implements Exception {
  const DeviceRegistrationFailure();
}

final class DeviceRegistrationNetworkFailure extends DeviceRegistrationFailure {
  const DeviceRegistrationNetworkFailure();
}

final class DeviceRegistrationServerFailure extends DeviceRegistrationFailure {
  final String message;
  const DeviceRegistrationServerFailure(this.message);
}
```

**Dartdoc each class** with when it is thrown (the Repository methods in session 2 will throw these).

---

## Deliverable

Six Dart files in `lib/core/domain/`. No tests yet — session 4 covers the test suite suggestion. No `build_runner` needed for this session (no Freezed, no Riverpod).

Run `dart analyze` at the end to verify zero errors/warnings.

Output the `<scratchpad>` execution plan and wait for my approval before writing any code.
