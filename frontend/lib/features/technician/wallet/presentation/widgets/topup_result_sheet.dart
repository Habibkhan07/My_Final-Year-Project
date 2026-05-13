import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../domain/failures/topup_failure.dart';
import '../notifiers/topup_notifier.dart';
import '../notifiers/topup_state.dart';
import 'topup_amount_sheet.dart';

/// Shown after the top-up flow reaches a terminal state.
///
/// Two visual variants based on [TopupState.flow]:
///   * `success` — green check icon, "Wallet topped up successfully",
///                 Done button.
///   * `failed`  — red icon, plain-language failure copy derived
///                 from the sealed [TopupFailure] subclass, Try again
///                 + Close buttons.
///
/// Dismissing the sheet resets the notifier to ``idle`` so the next
/// top-up tap starts fresh.
class TopupResultSheet extends ConsumerWidget {
  const TopupResultSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topupProvider);
    final isSuccess = state.flow == TopupFlow.success;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  size: 40,
                  color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? 'Wallet topped up' : 'Top-up did not complete',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _bodyCopy(state),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (isSuccess)
              _PrimaryButton(
                label: 'Done',
                onPressed: () {
                  ref.read(topupProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(topupProvider.notifier).reset();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppShapes.radiusXL),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: 'Try again',
                      onPressed: () {
                        ref.read(topupProvider.notifier).reset();
                        Navigator.of(context).pop();
                        // Re-open the amount sheet on next frame.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: AppColors.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => const TopupAmountSheet(),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _bodyCopy(TopupState state) {
    if (state.flow == TopupFlow.success) {
      final amount = state.terminalStatus?.amount;
      return amount != null
          ? 'Rs. ${amount.toStringAsFixed(0)} has been added to your wallet.'
          : 'Your top-up is complete and the balance has been updated.';
    }
    // Failure path — sealed switch on the captured failure.
    return switch (state.failure) {
      TopupInvalidAmount(:final minimum, :final maximum) =>
        'Enter an amount between Rs.$minimum and Rs.$maximum and try again.',
      TopupGatewayUnavailable() =>
        'Top-up is temporarily unavailable. Please try again in a few minutes.',
      TopupNetworkFailure() =>
        'You appear to be offline. Reconnect and try again.',
      TopupPermissionFailure() =>
        'Your session has expired. Please sign in again.',
      TopupUserAborted() => 'You cancelled the top-up.',
      TopupPollTimeout() =>
        "We couldn't confirm the result in time. Pull down on the wallet to refresh in a few seconds.",
      TopupServerFailure(:final message) => message,
      null => 'Please try again.',
    };
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusXL),
        ),
      ),
      child: Text(label),
    );
  }
}
