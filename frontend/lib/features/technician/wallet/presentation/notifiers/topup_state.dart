import '../../domain/entities/topup_session.dart';
import '../../domain/entities/topup_status.dart';
import '../../domain/failures/topup_failure.dart';

/// State-machine phases the top-up flow walks through.
///
///   idle             — initial, ready to take amount input
///   starting         — POST /topups/ in flight
///   awaitingGateway  — session minted; the FE has pushed the webview
///                      and is waiting for the JazzCash result.
///   verifying        — webview returned; polling `/topups/<id>/` until
///                      `gateway_status` becomes terminal.
///   success          — terminal: ledger row written; balance card
///                      will patch via realtime any moment.
///   failed           — terminal: [failure] is populated with a sealed
///                      [TopupFailure].
enum TopupFlow {
  idle,
  starting,
  awaitingGateway,
  verifying,
  success,
  failed,
}

/// Immutable state for [TopupNotifier].
///
/// Models the multi-screen top-up flow as a single value the wallet
/// screen reads with ``ref.watch``. Cross-screen coordination (modal
/// sheet → webview screen → result sheet) all flow through this
/// single source of truth; each widget reacts to its slice of the
/// state and calls the notifier to transition.
class TopupState {
  final TopupFlow flow;
  final TopupSession? session;
  final TopupStatus? terminalStatus;
  final TopupFailure? failure;

  const TopupState({
    this.flow = TopupFlow.idle,
    this.session,
    this.terminalStatus,
    this.failure,
  });

  /// True when [flow] is in a terminal state ([success] or [failed]).
  bool get isTerminal =>
      flow == TopupFlow.success || flow == TopupFlow.failed;

  /// Convenience for widgets that want to surface a busy spinner —
  /// either we're talking to the backend or we're holding the user
  /// in a sub-screen waiting for a callback.
  bool get isBusy =>
      flow == TopupFlow.starting ||
      flow == TopupFlow.awaitingGateway ||
      flow == TopupFlow.verifying;

  TopupState copyWith({
    TopupFlow? flow,
    TopupSession? session,
    TopupStatus? terminalStatus,
    TopupFailure? failure,
    bool clearSession = false,
    bool clearTerminalStatus = false,
    bool clearFailure = false,
  }) {
    return TopupState(
      flow: flow ?? this.flow,
      session: clearSession ? null : (session ?? this.session),
      terminalStatus: clearTerminalStatus
          ? null
          : (terminalStatus ?? this.terminalStatus),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopupState &&
          flow == other.flow &&
          session == other.session &&
          terminalStatus == other.terminalStatus &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(flow, session, terminalStatus, failure);
}
