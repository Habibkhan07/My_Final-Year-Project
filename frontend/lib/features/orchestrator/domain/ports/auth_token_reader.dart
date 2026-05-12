/// Thin port around "give me the auth token to send on this POST."
///
/// The orchestrator's `BookingActionExecutor` (and any future view that
/// needs an auth header) depends on this interface, not on the
/// `flutter_secure_storage` package directly. CLAUDE.md storage rule:
///
///   "All storage behind a LocalDataSource interface. Repository
///    arbitrates."
///
/// The executor isn't a repository, but the principle applies: storage
/// package types must not leak past the data layer. Today the only
/// implementation is `SecureStorageAuthTokenReader` (reads
/// `'auth_token'` from `FlutterSecureStorage`), but the seam lets us
/// swap the backend (e.g. hardware-backed keystore on Android) without
/// touching the executor.
abstract class IAuthTokenReader {
  /// Returns the bearer token to put after `'Token '` in the
  /// Authorization header, or `null` when no user is currently
  /// authenticated. Concrete implementations must NOT throw — the
  /// executor relies on null to mean "no auth header on this request"
  /// rather than "abort the request."
  Future<String?> read();
}
