import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/payout_account.dart';
import '../../domain/failures/withdrawal_failure.dart';
import '../providers/dependency_injection.dart';
import 'pending_withdrawal_notifier.dart';
import 'withdrawal_history_notifier.dart';
import 'withdraw_state.dart';

part 'withdraw_notifier.g.dart';

/// Drives the withdrawal-sheet state machine.
///
/// Lifecycle:
///   1. [build]            fetches payout accounts; transitions to
///                          ``editing`` (or ``failed`` on fetch error).
///   2. [setAmount] /
///      [selectTarget]    mutate the form. They implicitly clear any
///                          prior failure so the sheet's "fix and
///                          retry" loop works without a separate
///                          method call.
///   3. [submit]           POSTs the request; transitions to
///                          ``submitting`` then terminal ``success``
///                          or ``failed``.
///   4. [reset]            wipe terminal state so the next "Withdraw"
///                          tap shows the form fresh — used by the
///                          sheet's Done button.
///
/// Sync ``Notifier`` (not ``AsyncNotifier``) for the same reason as
/// [TopupNotifier]: more states than just loading/data/error. Errors
/// live in [WithdrawState.failure].
///
/// ``keepAlive: false`` — the sheet is modal; when it dismisses, the
/// notifier disposes and the next tap re-fetches. Stale accounts on
/// re-entry would be a usability bug (tech added a bank account
/// elsewhere and we'd miss it).
@riverpod
class WithdrawNotifier extends _$WithdrawNotifier {
  @override
  Future<WithdrawState> build() async {
    final repo = ref.read(withdrawalRepositoryProvider);
    try {
      final accounts = await repo.listPayoutAccounts();
      return WithdrawState(
        flow: WithdrawFlow.editing,
        accounts: accounts,
      );
    } on WithdrawalFailure catch (failure) {
      return WithdrawState(
        flow: WithdrawFlow.failed,
        failure: failure,
      );
    } catch (e) {
      // Belt-and-braces: anything that slipped past the repo mapper
      // becomes a generic server failure so the sheet still renders
      // a sealed-class case.
      return WithdrawState(
        flow: WithdrawFlow.failed,
        failure: WithdrawalServerFailure('Unexpected error: $e'),
      );
    }
  }

  /// Update the amount input. Clears any prior submission failure so
  /// the tech can correct and retry without a second tap. No
  /// validation here — the submit gate does that.
  void setAmount(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        amountInput: value,
        flow: current.flow == WithdrawFlow.failed
            ? WithdrawFlow.editing
            : current.flow,
        clearFailure: true,
      ),
    );
  }

  /// Select a payout target from the picker. Mirror semantics of
  /// [setAmount] re: failure clearing.
  void selectTarget(PayoutAccount target) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedTarget: target,
        flow: current.flow == WithdrawFlow.failed
            ? WithdrawFlow.editing
            : current.flow,
        clearFailure: true,
      ),
    );
  }

  /// Submit the request. Caller-side preconditions:
  ///   * amount parses to a positive double,
  ///   * a payout target is selected.
  /// The sheet uses [WithdrawState.canSubmit] to disable the button
  /// until both hold; this method re-asserts as defense in depth.
  Future<void> submit() async {
    final current = state.value;
    if (current == null) return;
    if (!current.canSubmit) return;

    final amount = double.tryParse(current.amountInput);
    if (amount == null || amount <= 0) {
      state = AsyncData(
        current.copyWith(
          flow: WithdrawFlow.failed,
          failure: const WithdrawalAmountOutOfRangeFailure(
            'Enter a valid amount.',
          ),
        ),
      );
      return;
    }

    final target = current.selectedTarget!;

    // Transition to ``submitting`` so the sheet renders a loading
    // spinner and disables further input. Done as a copyWith so the
    // accounts list + amount + target remain visible during the call.
    state = AsyncData(
      current.copyWith(
        flow: WithdrawFlow.submitting,
        clearFailure: true,
        clearSubmitted: true,
      ),
    );

    try {
      final repo = ref.read(withdrawalRepositoryProvider);
      final created = await repo.createRequest(
        amount: amount,
        bankAccountId:
            target is BankPayoutAccount ? target.id : null,
        jazzcashAccountId:
            target is JazzCashPayoutAccount ? target.id : null,
      );
      state = AsyncData(
        current.copyWith(
          flow: WithdrawFlow.success,
          submitted: created,
          clearFailure: true,
        ),
      );
      // Patch the wallet screen's pending pill + history list so the
      // tech sees their just-submitted row without waiting for a
      // pull-to-refresh. ``ref.invalidate`` is a no-op when the
      // provider hasn't been read yet (e.g. wallet screen unmounted),
      // so this is safe even when the sheet is opened from a deep
      // link without the wallet screen on the stack.
      ref.invalidate(pendingWithdrawalProvider);
      ref.invalidate(withdrawalHistoryProvider);
    } on WithdrawalFailure catch (failure) {
      state = AsyncData(
        current.copyWith(
          flow: WithdrawFlow.failed,
          failure: failure,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          flow: WithdrawFlow.failed,
          failure: WithdrawalServerFailure('Unexpected error: $e'),
        ),
      );
    }
  }

  /// Reset to a fresh editing state, preserving the fetched accounts
  /// list. Called by the sheet's Done button after a success — the
  /// next tap of Withdraw shows the form blank.
  void reset() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      WithdrawState(
        flow: WithdrawFlow.editing,
        accounts: current.accounts,
      ),
    );
  }
}
