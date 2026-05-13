/// Handle for an in-flight top-up attempt.
///
/// Returned by ``POST /api/technicians/wallet/topups/``. The
/// [redirectUrl] points at OUR bridge endpoint (signed-token gated,
/// 5-minute TTL); the Flutter app pushes it into a webview which then
/// auto-submits the gateway's form server-side. The webview never
/// loads JazzCash directly — credentials and the SecureHash stay on
/// our server.
class TopupSession {
  final int topupId;
  final String redirectUrl;

  const TopupSession({required this.topupId, required this.redirectUrl});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopupSession &&
          topupId == other.topupId &&
          redirectUrl == other.redirectUrl;

  @override
  int get hashCode => Object.hash(topupId, redirectUrl);
}
