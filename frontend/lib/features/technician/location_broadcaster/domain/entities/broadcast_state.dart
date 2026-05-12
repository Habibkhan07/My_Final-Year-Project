// Lifecycle state surfaced by `ForegroundLocationServiceController`.
// The orchestrator screen (tech-side) reads this to render a "Sharing
// your location" indicator and to know whether to nudge the user with
// the permission-explainer dialog.
enum BroadcastState {
  /// No active booking in the EN_ROUTE/ARRIVED window for this tech.
  idle,

  /// Foreground service running and posting GPS frames every ~5s.
  running,

  /// Location permission denied (foreground or background). Service
  /// cannot start until the user grants permission via the
  /// permission-explainer dialog or the OS settings page.
  permissionDenied,

  /// Notification permission denied on Android 13+. The OS will not
  /// surface the persistent foreground-service notification, which
  /// means the system can kill the service. Surface a banner asking
  /// the user to grant.
  notificationPermissionDenied,

  /// Generic failure (init failed, startService returned a failure
  /// result, etc.). Logged for ops; surfaced as "Tracking unavailable"
  /// in the UI.
  error,

  /// Running on a platform where the native foreground service is not
  /// available (web, desktop). The controller will not attempt to start
  /// the service; the banner surfaces a "GPS broadcasting requires the
  /// Android app — use dev_panel [4] in development" hint so the dev
  /// user knows to fan in frames via the simulator instead of
  /// expecting in-browser GPS.
  unsupportedPlatform,
}
