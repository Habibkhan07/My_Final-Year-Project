import 'dart:io' show SocketException;

import 'package:flutter/material.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../_palette/orchestrator_palette.dart';

/// Single shared bottom sheet for actions that need a richer flow than
/// session 3 ships. The action button widget opens this with a label
/// + body explaining what's coming and what (if anything) the user can
/// do today. Configurable confirm action so the cancel-with-default-
/// reason path can still complete the booking lifecycle for the demo.
///
/// **Error handling.** When [onConfirm] throws, the sheet renders an
/// inline error message and stays open so the user can retry — it does
/// NOT pop. On success the sheet pops with `true`. On user-dismiss it
/// pops with `false` (or `null`). Callers MUST gate post-confirm work
/// (e.g. invalidating the detail provider) on `result == true` so a
/// dismissed sheet doesn't trigger spurious refetches.
class BookingActionPendingSheet extends StatefulWidget {
  const BookingActionPendingSheet({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel,
    this.onConfirm,
    this.confirmIsDestructive = false,
  });

  final String title;
  final String body;

  /// When set, the sheet renders a confirm button that calls [onConfirm]
  /// and pops with `true` on success. When null, the sheet only offers a
  /// "Got it" dismiss button — used for actions whose flow is genuinely
  /// deferred to sessions 5/6.
  final String? confirmLabel;
  final Future<void> Function()? onConfirm;
  final bool confirmIsDestructive;

  /// Convenience: open the sheet from a BuildContext. Returns `true`
  /// when the confirm action ran successfully, `false` on user-dismiss,
  /// `null` if the modal was dismissed by tap-outside / system back.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    String? confirmLabel,
    Future<void> Function()? onConfirm,
    bool confirmIsDestructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => BookingActionPendingSheet(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        confirmIsDestructive: confirmIsDestructive,
      ),
    );
  }

  @override
  State<BookingActionPendingSheet> createState() =>
      _BookingActionPendingSheetState();
}

class _BookingActionPendingSheetState extends State<BookingActionPendingSheet> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        // `isScrollControlled: true` removes Material's default 9/16
        // height cap, so a long [body] (typical of session-5/6 explainer
        // sheets) would overflow the screen without scrolling. Wrapping
        // here, not at the modal boundary, keeps the confirm/dismiss
        // buttons fixed at the bottom while only the prose scrolls.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                widget.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (widget.confirmLabel != null && widget.onConfirm != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.confirmIsDestructive
                        ? colors.error
                        : OrchestratorPalette.brandPrimary,
                    foregroundColor: widget.confirmIsDestructive
                        ? colors.onError
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: (widget.confirmIsDestructive
                            ? colors.error
                            : OrchestratorPalette.brandPrimary)
                        .withValues(alpha: 0.4),
                  ),
                  onPressed: _busy ? null : _runConfirm,
                  child: _busy
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.confirmIsDestructive
                                ? colors.onError
                                : Colors.white,
                          ),
                        )
                      : Text(
                          widget.confirmLabel!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: OrchestratorPalette.brandPrimary,
                ),
                child: Text(
                  _dismissLabel(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick the dismiss-button copy. When the sheet is purely informational
  /// (no confirm action), "Got it" is the natural acknowledgement. When
  /// the sheet asks for confirmation of a destructive action, "Keep
  /// booking" / "Keep job" reads as the "no, never mind" answer to the
  /// title's question rather than colliding with "Cancel booking" — which
  /// would be ambiguous: tapping a button labeled "Cancel" right next to
  /// "Cancel booking" looks like the same thing.
  String _dismissLabel() {
    if (widget.confirmLabel == null) return 'Got it';
    if (widget.confirmIsDestructive) return 'Keep it';
    return 'Cancel';
  }

  Future<void> _runConfirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm!.call();
      if (mounted) Navigator.of(context).pop(true);
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No connection. Try again when online.';
      });
    } on HttpFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not complete action.';
      });
    }
  }
}
