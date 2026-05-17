import 'package:flutter/material.dart';

import '../../../domain/entities/booking_quote.dart';
import '../_palette/orchestrator_palette.dart';
import '../stub_bodies/all_status_stubs.dart' show QuoteSummaryCard;

/// Focused bottom sheet that surfaces a single [BookingQuote] as the
/// customer's (or technician's) receipt of record.
///
/// **Why this exists.** Post-completion the inline [QuoteSummaryCard]
/// is rendered below the celebratory hero in [CompletedBodyStub] — so
/// the receipt is technically visible, but only after the user scrolls
/// past the green-check celebration + the "finished the job" message.
/// On smaller phones the receipt sits below the fold and the customer
/// has to discover it by scrolling.
///
/// This sheet gives the receipt a one-tap, focused entry point. It
/// also explicitly hints at the WhatsApp-screenshot workflow that
/// dominates how cash-paying customers share their receipts in the
/// Pakistan market — the previous inline view was too crowded for a
/// clean screenshot.
///
/// **Surface.** Standard Material bottom sheet — drag handle, scrollable
/// content, safe-area-aware bottom padding. Reuses the same
/// QuoteSummaryCard the rest of the orchestrator displays so the
/// receipt the user sees here matches the one inline.
class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet({super.key, required this.quote});

  final BookingQuote quote;

  static Future<void> show(BuildContext context, BookingQuote quote) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ReceiptSheet(quote: quote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: OrchestratorPalette.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Receipt',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: OrchestratorPalette.inkPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap and hold to save a screenshot.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: OrchestratorPalette.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              QuoteSummaryCard(quote: quote),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OrchestratorPalette.brandPrimary,
                  side: const BorderSide(
                    color: OrchestratorPalette.brandPrimary,
                    width: 1.4,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
