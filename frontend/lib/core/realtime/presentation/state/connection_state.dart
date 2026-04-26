/// High-level lifecycle of the realtime WebSocket connection.
///
/// Intentionally UI-friendly — the app's "connection lost" banner maps
/// directly from this enum without needing any further derivation.
enum WsConnectionStatus {
  /// Initial state before `connect()` has been called.
  disconnected,

  /// TCP handshake + auth in progress.
  connecting,

  /// Socket open, auth succeeded, missed-event sync kicked off.
  connected,

  /// Socket dropped, backoff timer running.
  reconnecting,

  /// 10+ consecutive reconnect failures. UI shows a persistent indicator
  /// but the notifier continues to retry — REST sync still works and the
  /// socket may recover if the server comes back up.
  failed,
}
