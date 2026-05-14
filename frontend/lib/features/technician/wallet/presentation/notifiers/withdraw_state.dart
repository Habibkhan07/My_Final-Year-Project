import '../../domain/entities/payout_account.dart';
import '../../domain/entities/payout_accounts.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/failures/withdrawal_failure.dart';

/// State-machine phases the withdrawal sheet walks through.
///
///   loadingAccounts  — GET /payout-accounts/ in flight (sheet shows skeleton).
///   editing          — user is filling the form (amount + payout target).
///   submitting       — POST /withdrawals/ in flight.
///   success          — terminal: the freshly-created request lives in
///                      [submitted]; sheet swaps to its "Request
///                      submitted" success body.
///   failed           — terminal: [failure] is populated with a sealed
///                      [WithdrawalFailure]. Sheet remains on the form
///                      so the tech can correct + retry. ``editing``
///                      methods (setAmount / selectTarget) implicitly
///                      clear the failure to keep the flow recoverable.
enum WithdrawFlow {
  loadingAccounts,
  editing,
  submitting,
  success,
  failed,
}

/// Immutable state for [WithdrawNotifier].
///
/// Tracks four things at once: the fetched picker data, the form
/// inputs, the in-flight submission, and any sealed failure. One
/// state object keeps the sheet's reactive ``ref.watch`` minimal —
/// every widget reads its slice and the notifier mutates as a whole.
class WithdrawState {
  final WithdrawFlow flow;

  /// Result of ``listPayoutAccounts()``. Null while loading; populated
  /// the moment the build completes.
  final PayoutAccounts? accounts;

  /// User-typed amount. Kept as a string (not a parsed double) so the
  /// field can render mid-edit values ("100.") and so leading zeros
  /// don't get normalised away under the user's cursor.
  final String amountInput;

  /// Currently-selected radio in the payout picker.
  final PayoutAccount? selectedTarget;

  /// On terminal-success, the freshly-created request — used by the
  /// success body to render "Submitted: Rs. X to `<payout>`".
  final WithdrawalRequest? submitted;

  /// On terminal-failure (or fetch failure), the sealed failure the
  /// sheet pattern-matches against.
  final WithdrawalFailure? failure;

  const WithdrawState({
    this.flow = WithdrawFlow.loadingAccounts,
    this.accounts,
    this.amountInput = '',
    this.selectedTarget,
    this.submitted,
    this.failure,
  });

  /// True when the submit button should be enabled. All four
  /// conditions must hold:
  ///   * we're in the ``editing`` phase (not loading / mid-submit / terminal),
  ///   * the amount parses to a positive double,
  ///   * a payout target is selected,
  ///   * the picker has at least one account to choose from.
  bool get canSubmit {
    if (flow != WithdrawFlow.editing && flow != WithdrawFlow.failed) {
      return false;
    }
    if (accounts == null || accounts!.isEmpty) return false;
    if (selectedTarget == null) return false;
    final parsed = double.tryParse(amountInput);
    if (parsed == null || parsed <= 0) return false;
    return true;
  }

  bool get isBusy =>
      flow == WithdrawFlow.loadingAccounts ||
      flow == WithdrawFlow.submitting;

  WithdrawState copyWith({
    WithdrawFlow? flow,
    PayoutAccounts? accounts,
    String? amountInput,
    PayoutAccount? selectedTarget,
    WithdrawalRequest? submitted,
    WithdrawalFailure? failure,
    bool clearSelectedTarget = false,
    bool clearFailure = false,
    bool clearSubmitted = false,
  }) {
    return WithdrawState(
      flow: flow ?? this.flow,
      accounts: accounts ?? this.accounts,
      amountInput: amountInput ?? this.amountInput,
      selectedTarget: clearSelectedTarget
          ? null
          : (selectedTarget ?? this.selectedTarget),
      submitted: clearSubmitted ? null : (submitted ?? this.submitted),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithdrawState &&
          flow == other.flow &&
          accounts == other.accounts &&
          amountInput == other.amountInput &&
          selectedTarget == other.selectedTarget &&
          submitted == other.submitted &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(
        flow,
        accounts,
        amountInput,
        selectedTarget,
        submitted,
        failure,
      );
}
