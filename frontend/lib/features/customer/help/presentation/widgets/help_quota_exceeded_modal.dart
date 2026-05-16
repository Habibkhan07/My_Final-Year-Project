// Daily-quota modal for the Help tab.
//
// The dispute side has its own `showQuotaExceededModal` whose copy
// points the user at Help as an alternative ("Try again tomorrow, or
// use Help to file directly"). That copy doesn't fit here — the user
// IS in Help. So this modal exists separately with help-appropriate
// phrasing.
//
// Triggered by the screen's `ref.listen` on the help-chat notifier
// when the wire error is `HttpFailure(code: 'llm_quota_exceeded')`
// (HTTP 429 from the backend). The screen guards against stacking
// duplicate modals via a local `bool _modalLock`.
import 'package:flutter/material.dart';

/// Show the help-tab daily-quota modal.
///
/// Copy is intentionally soft, not punitive — the limit is a per-user
/// daily budget shared across all chatbot personas (dispute + help),
/// and a user can plausibly hit it through legitimate use combined
/// with an open dispute. Reassures rather than scolds.
Future<void> showHelpQuotaExceededModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.access_time_rounded,
          size: 36,
          color: Color(0xFF0051AE),
        ),
        title: const Text(
          'Daily limit reached',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "You've reached today's AI assistant limit. Please try again "
          'tomorrow. Your past questions are still in this chat.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF0051AE)),
            ),
          ),
        ],
      );
    },
  );
}
