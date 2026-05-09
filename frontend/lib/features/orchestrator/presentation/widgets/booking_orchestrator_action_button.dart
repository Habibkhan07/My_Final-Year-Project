import 'dart:developer' as developer;
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_ui_block.dart';
import '../providers/booking_action_executor.dart';
import '../providers/booking_detail_provider.dart';
import 'sheets/booking_action_pending_sheet.dart';

/// The button widget that renders a single [BookingUiAction] from the
/// server's `ui` block.
///
/// **Action classification.** Each backend endpoint suffix falls into
/// one of three buckets:
///
///   * **Direct POST (no body)** — en-route, arrived, start-inspection,
///     approve-quote, decline-quote: tap → POST → invalidate detail.
///   * **Direct POST (auto body)** — confirm-cash-received: tap →
///     POST `{cash_amount: booking.pricing.finalCashToCollect}`.
///   * **Pending sheet** — cancel, tech-cancel, reschedule, no-show,
///     submit-quote, request-revision, dispute-open: open the shared
///     pending sheet. Cancel + tech-cancel still POST a default reason
///     so the demo walks; the others show a "ships in session 5/6"
///     explainer.
///
/// Sessions 5/6 will replace the pending-sheet branch with rich flows
/// (rich cancel form, reschedule date picker, quote builder, etc.).
class BookingOrchestratorActionButton extends ConsumerStatefulWidget {
  const BookingOrchestratorActionButton({
    super.key,
    required this.action,
    required this.booking,
    required this.isPrimary,
  });

  final BookingUiAction action;
  final BookingDetail booking;
  final bool isPrimary;

  @override
  ConsumerState<BookingOrchestratorActionButton> createState() =>
      _BookingOrchestratorActionButtonState();
}

class _BookingOrchestratorActionButtonState
    extends ConsumerState<BookingOrchestratorActionButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = widget.action;
    final classification = _classify(action.endpoint);

    final isDestructive = action.style == BookingUiActionStyle.destructive;

    if (widget.isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          onPressed: _busy ? null : () => _onTap(classification),
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(action.label),
        ),
      );
    }

    return TextButton(
      onPressed: _busy ? null : () => _onTap(classification),
      style: isDestructive
          ? TextButton.styleFrom(foregroundColor: theme.colorScheme.error)
          : null,
      child: _busy
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : Text(action.label),
    );
  }

  Future<void> _onTap(_ActionClassification classification) async {
    switch (classification) {
      case _ActionClassification.directPostNoBody:
        await _runDirect(body: null);
      case _ActionClassification.directPostAutoBody:
        await _runDirect(body: _autoBody());
      case _ActionClassification.pendingSheetCancel:
        await _runPendingSheetCancel();
      case _ActionClassification.pendingSheetTechCancel:
        await _runPendingSheetTechCancel();
      case _ActionClassification.pendingSheetReschedule:
        await _runPendingSheetExplainer(
          title: 'Reschedule coming soon',
          body:
              'Reschedule with a date/time picker ships in session 6. For now you can ask the customer to cancel and rebook.',
        );
      case _ActionClassification.pendingSheetNoShow:
        await _runPendingSheetExplainer(
          title: 'Single-tap no-show coming soon',
          body:
              'A single-tap confirmation ships in session 6. For now please use the in-app dispute path if the counterparty did not show.',
        );
      case _ActionClassification.pendingSheetQuote:
        await _runPendingSheetExplainer(
          title: 'Quote builder coming soon',
          body:
              'The line-item quote builder ships in session 5. The button is shown so you can verify the surface; submission is disabled.',
        );
      case _ActionClassification.pendingSheetRevision:
        await _runPendingSheetExplainer(
          title: 'Bargain flow coming soon',
          body:
              'Asking for a revision opens a free-text reason field in session 5.',
        );
      case _ActionClassification.pendingSheetDispute:
        await _runPendingSheetExplainer(
          title: 'Dispute form coming soon',
          body:
              'The full dispute form (intake reason + optional photo upload) ships in session 6.',
        );
    }
  }

  Future<void> _runDirect({Map<String, dynamic>? body}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(bookingActionExecutorProvider)
          .execute(widget.action, body: body);
      ref.invalidate(bookingDetailProvider(widget.booking.id));
    } on SocketException {
      _showSnack('No connection. Try again when online.');
    } on HttpFailure catch (e) {
      _showSnack(e.message);
    } on StateError catch (e, stack) {
      // Unsupported HTTP method from the executor — server contract drift.
      // Surface the generic error to the user but log loudly so we notice
      // during QA / on-device debugging.
      developer.log(
        'BookingActionExecutor refused unsupported method',
        name: 'orchestrator.action',
        level: 1000, // SEVERE
        error: e,
        stackTrace: stack,
      );
      _showSnack('Could not complete action.');
    } catch (_) {
      _showSnack('Could not complete action.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runPendingSheetCancel() async {
    if (!mounted) return;
    final result = await BookingActionPendingSheet.show(
      context,
      title: 'Cancel booking?',
      body:
          'A richer cancel flow with timing-aware copy + reason picker ships in session 6. Tapping confirm will cancel with the default reason.',
      confirmLabel: 'Cancel booking',
      confirmIsDestructive: true,
      onConfirm: () => ref
          .read(bookingActionExecutorProvider)
          .execute(
            widget.action,
            body: const {'cancel_reason': 'customer_cancelled'},
          ),
    );
    // Only refresh when the action actually ran. Sheet dismissal (Keep
    // booking / tap-outside / system back) returns false/null and must
    // not trigger a network round-trip. The sheet itself surfaces any
    // confirm error inline and stays open; we never reach this line on
    // a failed POST.
    if (result == true && mounted) {
      ref.invalidate(bookingDetailProvider(widget.booking.id));
    }
  }

  Future<void> _runPendingSheetTechCancel() async {
    if (!mounted) return;
    final result = await BookingActionPendingSheet.show(
      context,
      title: 'Cancel this job?',
      body:
          'Cancelling counts against your reliability score. The full cancel form ships in session 6; tapping confirm cancels with the default reason.',
      confirmLabel: 'Cancel job',
      confirmIsDestructive: true,
      onConfirm: () => ref
          .read(bookingActionExecutorProvider)
          .execute(
            widget.action,
            body: const {'cancel_reason': 'technician_cancelled'},
          ),
    );
    if (result == true && mounted) {
      ref.invalidate(bookingDetailProvider(widget.booking.id));
    }
  }

  Future<void> _runPendingSheetExplainer({
    required String title,
    required String body,
  }) async {
    if (!mounted) return;
    await BookingActionPendingSheet.show(context, title: title, body: body);
  }

  Map<String, dynamic>? _autoBody() {
    // Currently only confirm-cash-received needs an auto body.
    if (widget.action.endpoint.endsWith('/confirm-cash-received/')) {
      final amount = widget.booking.pricing.finalCashToCollect;
      if (amount == null) return null;
      return {'cash_amount': amount};
    }
    return null;
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Classify by endpoint suffix. Wire spec from
  /// `backend/bookings/selectors/orchestrator_ui.py` is stable; if
  /// backend adds a new action, this falls through to direct-post
  /// (the safe default for bodyless ops).
  _ActionClassification _classify(String endpoint) {
    if (endpoint.endsWith('/confirm-cash-received/')) {
      return _ActionClassification.directPostAutoBody;
    }
    if (endpoint.endsWith('/cancel/')) {
      return _ActionClassification.pendingSheetCancel;
    }
    if (endpoint.endsWith('/tech-cancel/')) {
      return _ActionClassification.pendingSheetTechCancel;
    }
    if (endpoint.endsWith('/reschedule/')) {
      return _ActionClassification.pendingSheetReschedule;
    }
    if (endpoint.endsWith('/no-show/')) {
      return _ActionClassification.pendingSheetNoShow;
    }
    if (endpoint.endsWith('/disputes/')) {
      return _ActionClassification.pendingSheetDispute;
    }
    if (endpoint.endsWith('/request-revision/')) {
      return _ActionClassification.pendingSheetRevision;
    }
    if (endpoint.endsWith('/quotes/')) {
      // submit_quote root POST — the quote BUILDER lives in session 5.
      return _ActionClassification.pendingSheetQuote;
    }
    // Everything else is a bodyless POST: en-route, arrived,
    // start-inspection, /quotes/<id>/approve/, /quotes/<id>/decline/.
    return _ActionClassification.directPostNoBody;
  }
}

enum _ActionClassification {
  directPostNoBody,
  directPostAutoBody,
  pendingSheetCancel,
  pendingSheetTechCancel,
  pendingSheetReschedule,
  pendingSheetNoShow,
  pendingSheetQuote,
  pendingSheetRevision,
  pendingSheetDispute,
}
