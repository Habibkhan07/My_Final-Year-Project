import 'package:flutter/material.dart';

import '../utils/chatbot_palette.dart';

/// Show the daily-quota modal. Surface for [LlmQuotaExceededFailure].
///
/// **Copy** is the soft phrasing the user signed off on — not a
/// scolding "rate limited" tone:
///   * Title: "Daily limit reached"
///   * Body : "You've reached today's AI assistant limit. Try again
///            tomorrow, or use Help to file directly."
///   * Primary CTA: "Use Help" — navigates to the customer help flow
///     (route stub for v1 — see open items in CHATBOT_FRONTEND_PLAN
///     §13; will land as a tech-debt flag at D3 wrap-up)
///   * Secondary CTA: "OK" — dismisses and keeps the screen mounted
///     so the quota can reset and the user can keep typing
///
/// The screen calls this from its `ref.listen` on the session
/// notifier; multiple consecutive errors should NOT stack modals —
/// the caller guards via a local `bool` flag.
Future<void> showQuotaExceededModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.access_time_rounded,
          size: 36,
          color: ChatbotPalette.brandPrimary,
        ),
        title: const Text(
          'Daily limit reached',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "You've reached today's AI assistant limit. "
          'Try again tomorrow, or use Help to file directly.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              // TODO(D3b/help-flow): navigate to /customer/help once
              // that route lands. Closing the modal is the safe v1
              // behavior — the user is left on the chat with their
              // transcript intact and the screen still mounted.
              Navigator.of(context).pop();
            },
            child: Text(
              'Use Help',
              style: TextStyle(color: ChatbotPalette.brandPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: ChatbotPalette.brandPrimary),
            ),
          ),
        ],
      );
    },
  );
}
