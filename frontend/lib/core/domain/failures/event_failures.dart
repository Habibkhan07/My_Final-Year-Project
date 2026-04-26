// ─── Event Sync Failures ───────────────────────────────────────────────────

/// Base failure for the event sync repository methods.
sealed class EventSyncFailure implements Exception {
  const EventSyncFailure();
}

/// Thrown when the device has no network connectivity and no cached events
/// are available to return.
final class EventSyncNetworkFailure extends EventSyncFailure {
  const EventSyncNetworkFailure();
}

/// Thrown when the `/api/events/sync/` endpoint returns a non-2xx response.
final class EventSyncServerFailure extends EventSyncFailure {
  final String message;
  const EventSyncServerFailure(this.message);
}

/// Thrown when the auth token is expired or invalid.
/// The presentation layer must redirect the user to the login flow.
final class EventSyncUnauthorized extends EventSyncFailure {
  const EventSyncUnauthorized();
}

// ─── Device Registration Failures ─────────────────────────────────────────

/// Base failure for the FCM device registration repository methods.
sealed class DeviceRegistrationFailure implements Exception {
  const DeviceRegistrationFailure();
}

/// Thrown when the FCM token registration call cannot reach the backend
/// due to a network error.
final class DeviceRegistrationNetworkFailure extends DeviceRegistrationFailure {
  const DeviceRegistrationNetworkFailure();
}

/// Thrown when the device registration endpoint returns a non-2xx response.
final class DeviceRegistrationServerFailure extends DeviceRegistrationFailure {
  final String message;
  const DeviceRegistrationServerFailure(this.message);
}
