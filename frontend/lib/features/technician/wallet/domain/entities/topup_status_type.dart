/// Lifecycle states for a JazzCash Hosted Checkout top-up attempt.
///
/// Mirrors the backend's ``wallet.models.TopupStatus`` enum exactly —
/// values come over the wire as raw strings so the data mapper does a
/// string→enum lookup. Adding a new variant requires a coordinated
/// backend migration + frontend mapper update (failing closed in the
/// mapper if an unknown value arrives — see [TopupStatusTypeX.parse]).
///
/// Three of these are terminal — once the topup reaches [completed],
/// [failed], [expired], or [abandoned], no further state changes are
/// possible. The notifier short-circuits its poll loop on these.
enum TopupStatusType {
  /// Row exists; gateway not yet called. Mostly an in-memory state
  /// before [redirected]; rare to observe over the wire.
  pending,

  /// Gateway returned a session id + redirect URL; webview is in the
  /// tech's hands. The non-terminal state the FE polls against.
  redirected,

  /// Gateway callback verified success; ledger row written; balance
  /// already patched via realtime.
  completed,

  /// Gateway callback verified failure (e.g. wrong MPIN, insufficient
  /// JazzCash balance, customer cancelled on the JazzCash page).
  failed,

  /// Tech never returned from the gateway within the TTL window (15min
  /// default). Future janitor cron promotes stale [redirected] rows to
  /// this state; the FE treats it as a non-recoverable failure.
  expired,

  /// Tech explicitly cancelled (closed the webview, tapped Decline on
  /// the mock bridge, etc.). Distinct from [failed] so analytics can
  /// separate user-intent abandonment from gateway-side rejection.
  abandoned,
}

extension TopupStatusTypeX on TopupStatusType {
  /// True when the status is settled — further polling is pointless.
  bool get isTerminal => switch (this) {
        TopupStatusType.completed ||
        TopupStatusType.failed ||
        TopupStatusType.expired ||
        TopupStatusType.abandoned =>
          true,
        TopupStatusType.pending || TopupStatusType.redirected => false,
      };

  /// True only on [completed] — the only state that actually moved
  /// money into the wallet.
  bool get isSuccess => this == TopupStatusType.completed;

  /// Wire-format → enum. Unknown values map to [failed] so the FE
  /// fails closed (caller sees a generic failure) rather than crashing
  /// when the backend ships a new status variant ahead of the FE.
  static TopupStatusType parse(String raw) => switch (raw) {
        'PENDING' => TopupStatusType.pending,
        'REDIRECTED' => TopupStatusType.redirected,
        'COMPLETED' => TopupStatusType.completed,
        'FAILED' => TopupStatusType.failed,
        'EXPIRED' => TopupStatusType.expired,
        'ABANDONED' => TopupStatusType.abandoned,
        _ => TopupStatusType.failed,
      };
}
