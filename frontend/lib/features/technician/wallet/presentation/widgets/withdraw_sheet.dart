import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/entities/payout_account.dart';
import '../../domain/entities/payout_accounts.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../../domain/failures/withdrawal_failure.dart';
import '../notifiers/wallet_notifier.dart';
import '../notifiers/withdraw_notifier.dart';
import '../notifiers/withdraw_state.dart';

/// Modal bottom-sheet for submitting a withdrawal request.
///
/// Flow inside the sheet:
///   1. **Loading**  — fetching payout accounts (skeleton row).
///   2. **Editing**  — amount input + payout picker + submit button.
///   3. **Submitting** — submit button shows a spinner; inputs disabled.
///   4. **Success** — sheet body swaps to the "Request submitted" panel.
///   5. **Failed**  — inline banner under the form; tech can edit + retry.
///
/// The sheet does NOT pop itself on success — the success body shows
/// inline so the tech can see what happened and dismiss when ready.
/// This matches the existing booking-flow pattern (see customer cash
/// collection screen).
class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final _controller = TextEditingController();
  bool _bootstrapped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sync the text field with the notifier's amount input on first
  /// build (e.g. if the notifier was hydrated from a prior session).
  /// After that, the field is the source of truth for the input —
  /// every keystroke calls [WithdrawNotifier.setAmount].
  void _bootstrap(String fromState) {
    if (_bootstrapped) return;
    _bootstrapped = true;
    if (fromState.isNotEmpty && _controller.text != fromState) {
      _controller.text = fromState;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(withdrawProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              const SizedBox(height: 12),
              _Header(),
              const SizedBox(height: 16),
              asyncState.when(
                loading: () => const _LoadingBody(),
                error: (err, _) => _ErrorBody(
                  failure: err is WithdrawalFailure
                      ? err
                      : const WithdrawalServerFailure(),
                ),
                data: (state) {
                  _bootstrap(state.amountInput);
                  return _buildBody(context, state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WithdrawState state) {
    // Terminal success — swap to the success panel.
    if (state.flow == WithdrawFlow.success && state.submitted != null) {
      return _SuccessBody(
        request: state.submitted!,
        onDone: () => Navigator.of(context).pop(),
      );
    }

    // The picker empty state pre-empts the form. Submit must be
    // disabled because there's no target to submit against.
    if (state.accounts != null && state.accounts!.isEmpty) {
      return const _EmptyAccountsBody();
    }

    return _FormBody(
      state: state,
      controller: _controller,
      onAmountChanged: (value) =>
          ref.read(withdrawProvider.notifier).setAmount(value),
      onTargetSelected: (target) =>
          ref.read(withdrawProvider.notifier).selectTarget(target),
      onSubmit: () =>
          ref.read(withdrawProvider.notifier).submit(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Decomposed body widgets
// ──────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Withdraw funds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Admin will process your request within 24 hours.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppShapes.radiusMD),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppShapes.radiusMD),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ErrorBody extends ConsumerWidget {
  const _ErrorBody({required this.failure});
  final WithdrawalFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _failureCopy(failure);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            copy,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.invalidate(withdrawProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccountsBody extends StatelessWidget {
  const _EmptyAccountsBody();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.account_balance_outlined,
                size: 40, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'No payout account on file',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a bank account or top up via JazzCash to enable withdrawals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.request, required this.onDone});
  final WithdrawalRequest request;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle, size: 56, color: AppColors.secondary),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Request submitted',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Rs. ${request.amount.toStringAsFixed(0)} → ${request.payout.label}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Admin will process within 24 hours. You can track its status in withdrawal history.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShapes.radiusXL),
                ),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
}

class _FormBody extends ConsumerWidget {
  const _FormBody({
    required this.state,
    required this.controller,
    required this.onAmountChanged,
    required this.onTargetSelected,
    required this.onSubmit,
  });

  final WithdrawState state;
  final TextEditingController controller;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<PayoutAccount> onTargetSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final balance = walletAsync.value?.balance;
    final isLockedOut = walletAsync.value?.isLockedOut ?? false;
    final busy = state.flow == WithdrawFlow.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: !busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Allow digits + up to two decimal places. Server bounds
            // Rs. 1 – 5000 with 2dp precision.
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,2}')),
          ],
          autofocus: true,
          onChanged: onAmountChanged,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: 'Rs. ',
            helperText: balance != null
                ? 'Available: Rs. ${balance.toStringAsFixed(0)}'
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppShapes.radiusMD),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Payout to',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        if (state.accounts != null) _PayoutPicker(
          accounts: state.accounts!,
          selected: state.selectedTarget,
          onSelect: busy ? null : onTargetSelected,
        ),
        if (state.failure != null) ...[
          const SizedBox(height: 12),
          _InlineErrorBanner(failure: state.failure!),
        ],
        if (isLockedOut) ...[
          const SizedBox(height: 12),
          _InlineErrorBanner(
            failure: const WalletLockoutForWithdrawalFailure(
              balancePkr: 0,
              owedPkr: 0,
            ),
            overrideMessage:
                'Your wallet is locked. Top up to clear lockout before withdrawing.',
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              (busy || isLockedOut || !state.canSubmit) ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.outline.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.radiusXL),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Request withdrawal'),
        ),
      ],
    );
  }
}

class _PayoutPicker extends StatelessWidget {
  const _PayoutPicker({
    required this.accounts,
    required this.selected,
    required this.onSelect,
  });

  final PayoutAccounts accounts;
  final PayoutAccount? selected;
  final ValueChanged<PayoutAccount>? onSelect;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final bank in accounts.bankAccounts) {
      rows.add(_PayoutRow(
        target: bank,
        selected: selected is BankPayoutAccount &&
            (selected as BankPayoutAccount).id == bank.id,
        onTap: onSelect == null ? null : () => onSelect!(bank),
      ));
    }
    for (final jazz in accounts.jazzcashAccounts) {
      rows.add(_PayoutRow(
        target: jazz,
        selected: selected is JazzCashPayoutAccount &&
            (selected as JazzCashPayoutAccount).id == jazz.id,
        onTap: onSelect == null ? null : () => onSelect!(jazz),
      ));
    }
    return Column(children: rows);
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final PayoutAccount target;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (target) {
      BankPayoutAccount() => Icons.account_balance,
      JazzCashPayoutAccount() => Icons.phone_iphone,
    };
    final title = switch (target) {
      BankPayoutAccount(:final bankName, :final accountTitle) =>
        '$bankName — $accountTitle',
      JazzCashPayoutAccount(:final accountTitle) =>
        'JazzCash — $accountTitle',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppShapes.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(iconData,
                    color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        target.masked,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.failure,
    this.overrideMessage,
  });
  final WithdrawalFailure failure;
  final String? overrideMessage;

  @override
  Widget build(BuildContext context) {
    final message = overrideMessage ?? _failureCopy(failure);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppShapes.radiusMD),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dumb-UI sealed pattern-match → friendly user-facing string.
///
/// Centralised so the same copy is used by both the inline form
/// banner and the top-level error body. Adding a new sealed case is
/// a compile-time error on this switch — exactly the bulletproofing
/// we want for financial-flow surfaces.
String _failureCopy(WithdrawalFailure failure) => switch (failure) {
      InsufficientFundsFailure(
        :final requestedPkr,
        :final availablePkr,
      ) =>
        'You tried to withdraw Rs. $requestedPkr but only Rs. $availablePkr is available.',
      WalletLockoutForWithdrawalFailure(:final owedPkr) =>
        owedPkr > 0
            ? 'Wallet is locked (Rs. $owedPkr owed). Top up to continue.'
            : 'Wallet is locked. Top up to continue.',
      DuplicatePendingWithdrawalFailure() =>
        'A previous withdrawal is still under review. Wait for it to be processed.',
      InactiveTechnicianForWithdrawalFailure(:final status) =>
        status == 'DEACTIVATED'
            ? 'Your account has been deactivated. Contact support.'
            : 'Your account is not approved for withdrawals yet.',
      InvalidPayoutAccountFailure() =>
        'Selected payout account is no longer available. Please pick another.',
      WithdrawalAmountOutOfRangeFailure(:final message) => message,
      WithdrawalValidationFailure(:final message) => message,
      WithdrawalNetworkFailure(:final message) => message,
      WithdrawalServerFailure(:final message) => message,
      WithdrawalPermissionFailure(:final message) => message,
    };
