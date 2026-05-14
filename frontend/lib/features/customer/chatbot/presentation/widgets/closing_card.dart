import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/output_refs.dart';
import '../utils/chatbot_palette.dart';

/// Terminal-state UI for the chatbot. Mounted by [InputRenderer] when
/// the directive is `TerminalDirective`. The SLA disclosure
/// ("We'll review within 3 working days.") is **not** shown here —
/// it's already the last SYSTEM message in the transcript, templated
/// by the backend's `closing_template`.
///
/// Tapping "Back to booking" pops the chatbot route. The booking
/// detail screen behind it will pick up the `DISPUTED` status flip
/// via its own realtime listener (the chatbot itself doesn't
/// broadcast — see plan §2 claim 3).
class ClosingCard extends StatelessWidget {
  final OutputRefs refs;

  const ClosingCard({super.key, required this.refs});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ChatbotPalette.composerSurface,
          boxShadow: ChatbotPalette.composerSoftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: ChatbotPalette.successAccent,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'Dispute filed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A2540),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ticket #${refs.ticketId}',
              style: TextStyle(
                fontSize: 14,
                color: ChatbotPalette.systemInk,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatbotPalette.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Back to booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
