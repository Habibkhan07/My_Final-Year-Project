# Realtime Events Architecture Audit & Context

This document captures the context of the realtime event subsystem audit conducted on April 27, 2026. It outlines the current state of the architecture, the architectural question raised regarding separating "solo web socket data" from "system events", and the recommended solutions to maintain clean architecture.

---

## 1. The User's Architectural Clarification & Question

**The Core Distinction:**
The user has established a strict architectural boundary between two types of WebSocket traffic:

1. **Solo Web Socket Data (Not Events):** 
   - **Examples:** Live telemetry (GPS updates), Live continuous wallet balance streams.
   - **Characteristics:** High-frequency, transient data. They do not need Firebase fallbacks, they do not need to be cached offline, and they are strictly *not* considered "events". They should simply flow in over the socket and update Riverpod state directly.
2. **Notification Events:**
   - **Examples:** Wallet balance drops below a critical threshold (`walletLowBalance`), `jobDispatched`, `paymentReceived`.
   - **Characteristics:** Triggered by backend business logic. They require guaranteed delivery, offline caching, and routing (either high urgency full-screen pushes or low urgency banners).

**Question:** 
"How should I structure the switches to separate these 'solo web socket' data streams from the robust 'notification events' pipeline without tangling the clean architecture?"

---

## 2. Codebase Audit Findings

An audit of the frontend Flutter codebase revealed a highly mature, production-ready implementation of Clean Architecture and Riverpod state management.

### Strengths Identified:
*   **Feature-First Structure:** State is localized by feature (e.g., `features/technician/dashboard`, `features/auth`), preventing global state tangling.
*   **Clean Dependency Injection (DI):** `dependency_injection.dart` files cleanly separate instantiation from business logic, making repositories easily testable.
*   **Robust Notifier Patterns:** Features use `AsyncValue.guard()` and `.copyWith()` for elegant state transitions. Optimistic UI updates (e.g., `setOnline` in `TechnicianDashboardNotifier`) are implemented correctly with rollback mechanisms.
*   **Defensive Local Storage:** The Local Data Source layer (e.g., `EventLocalDataSource`) tiers security (SecureStorage for tokens vs. SharedPreferences for cache) and uses highly defensive JSON parsing that gracefully handles corrupt data without throwing fatal exceptions.
*   **Decoupled Navigation:** `EventUrgencyRouter` correctly lives outside the notifier tree and acts as a listener, driving UI navigation (push routes and banners) based on the current state.

### The Realtime Pipeline Today:
1. `WsConnectionNotifier` receives raw JSON frames.
2. It feeds them into `SystemEventNotifier.processEvent()`.
3. `SystemEventNotifier` deduplicates, caches to disk for offline support, and emits a `SystemEventState`.
4. `EventUrgencyRouter` listens to this state and triggers UI (Navigation/Banners).

---

## 3. Architectural Solution: The Network Edge Switch

Routing high-frequency "solo web socket" data (like live GPS or live wallet balance streams) through the robust event pipeline is an architectural trap. It would thrash `SharedPreferences` with constant disk writes, unnecessarily wake up background isolates, and waste network bandwidth with ACKs.

To enforce the user's clean separation, the routing "switch" must be placed at the very edge of the network layer, before any caching or routing logic occurs.

### The Gateway Switch in `WsConnectionNotifier`
Do **not** put the switch in the `EventUrgencyRouter` or `SystemEventNotifier`. 

The switch belongs inside `WsConnectionNotifier`, acting as a gateway traffic controller based on a top-level payload envelope (e.g., a `type` or `category` field that distinguishes a stream from an event).

```dart
// Inside WsConnectionNotifier
void _onWebSocketFrame(String rawJson) {
  final data = jsonDecode(rawJson);
  final messageType = data['type']; // e.g., 'event' vs 'telemetry' vs 'wallet_stream'
  
  if (messageType == 'event') {
    // ➔ NOTIFICATION EVENT: Route to the robust pipeline
    // This handles threshold drops (walletLowBalance), job dispatches, etc.
    // Handles Caching, FCM fallback, ACKs, and UI Routing.
    ref.read(systemEventProvider.notifier).processEvent(data['payload']);
  } 
  else if (messageType == 'telemetry') {
    // ➔ SOLO WEB SOCKET DATA: Live GPS
    // Bypass the heavy pipeline entirely. Update transient state directly.
    ref.read(liveTelemetryProvider.notifier).updateLocation(data['payload']);
  }
  else if (messageType == 'wallet_stream') {
    // ➔ SOLO WEB SOCKET DATA: Live Wallet Balance
    // Bypass the heavy pipeline entirely. Update the dashboard state directly.
    final newBalance = data['payload']['balance'] as double;
    ref.read(technicianDashboardProvider.notifier).onWalletBalanceEvent(newBalance);
  }
}
```

### Summary of the Separation
1.  **`WsConnectionNotifier`:** Becomes the traffic cop. It reads the raw JSON and decides if the payload is an `event` or a `solo_stream`.
2.  **`SystemEventNotifier` & `EventUrgencyRouter`:** Remain completely untouched. They continue to do exactly what they do best: manage durable, guaranteed-delivery business events.
3.  **Feature Notifiers (`TechnicianDashboardNotifier`, etc.):** Can expose simple, synchronous methods (like `onWalletBalanceEvent`) that the `WsConnectionNotifier` can call directly for transient data streams, avoiding full-screen loading flashes.
