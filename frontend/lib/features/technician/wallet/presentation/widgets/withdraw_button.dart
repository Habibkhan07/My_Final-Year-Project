import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';

/// Withdraw CTA. Tonight: snackbar "Available Thursday".
/// Thursday: opens the withdraw form (bank or JazzCash payout account
/// picker → POST /api/wallet/withdrawals/). Admin processes manually.
class WithdrawButton extends StatelessWidget {
  const WithdrawButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Withdrawal requests open Thursday.'),
              ),
            );
        },
        icon: const Icon(Icons.account_balance_outlined),
        label: const Text('Withdraw'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusXL),
          ),
        ),
      ),
    );
  }
}
