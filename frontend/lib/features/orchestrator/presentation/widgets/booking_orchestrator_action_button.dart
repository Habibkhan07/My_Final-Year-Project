import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/errors/http_failure.dart';
import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_ui_block.dart';
import '../providers/booking_action_executor.dart';
import '../providers/booking_detail_provider.dart';
import '_palette/orchestrator_palette.dart';
import 'feedback/orchestrator_snack.dart';
import 'sheets/booking_action_pending_sheet.dart';
import 'sheets/quote_builder_sheet.dart';

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
///     submit-quote, dispute-open: open the shared pending sheet.
///     Cancel + tech-cancel still POST a default reason so the demo
///     walks; the others show a "ships in session 5/6" explainer.
///
/// Sessions 5/6 will replace the pending-sheet branch with rich flows
/// (rich cancel form, reschedule date picker, quote builder, etc.).
///
/// **`/request-revision/` is intentionally a direct POST.** In this
/// market customer + tech are face-to-face on QUOTED — the customer
/// taps "Negotiate price" as a signal to the tech standing right
/// there, who then rebuilds the quote on their own device. There is no
/// remote ticket reviewer to read a "reason" string, so we don't
/// collect one. Backend's serializer accepts `reason` optional / blank
/// and the service stores empty string on `quote.decision_reason`.
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

    // Brand-blue language. Pressed state darkens via a Material state
    // resolver so users get visual feedback in addition to the ripple.
    final bgColor = isDestructive
        ? theme.colorScheme.error
        : OrchestratorPalette.brandPrimary;
    final fgColor = isDestructive ? theme.colorScheme.onError : Colors.white;

    if (widget.isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return isDestructive
                    ? theme.colorScheme.error.withValues(alpha: 0.86)
                    : OrchestratorPalette.brandPrimaryDeep;
              }
              if (states.contains(WidgetState.disabled)) {
                return bgColor.withValues(alpha: 0.55);
              }
              return bgColor;
            }),
            foregroundColor: WidgetStateProperty.all(fgColor),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 16),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 2;
              return 8;
            }),
            shadowColor: WidgetStateProperty.all(
              bgColor.withValues(alpha: 0.42),
            ),
            overlayColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.10),
            ),
          ),
          onPressed: _busy ? null : () => _onTap(classification),
          child: _busy
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                )
              : Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      );
    }

    return TextButton(
      onPressed: _busy ? null : () => _onTap(classification),
      style: TextButton.styleFrom(
        foregroundColor: isDestructive
            ? theme.colorScheme.error
            : OrchestratorPalette.brandPrimary,
      ),
      child: _busy
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : Text(
              action.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _onTap(_ActionClassification classification) async {
    // Light haptic on every primary/secondary action tap — confirms the
    // touch hit without the cheap-feel of `mediumImpact`. No-op under
    // flutter_test and on web platforms where the channel isn't wired,
    // so safe to call unconditionally.
    if (widget.isPrimary) {
      unawaited(HapticFeedback.lightImpact());
    }
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
        await _runQuoteBuilder();
      case _ActionClassification.pendingSheetDispute:
        await _runPendingSheetExplainer(
          title: 'Dispute form coming soon',
          body:
              'The full dispute form (intake reason + optional photo upload) ships in session 6.',
        );
      case _ActionClassification.pendingSheetCash:
        await _runPendingSheetCash();
      case _ActionClassification.pendingSheetDecline:
        await _runPendingSheetDecline();
    }
  }

  /// Cash-collection confirm sheet. The tech taps "Cash collected: Rs. X",
  /// the sheet renders "Confirm you received Rs. X from <customer>",
  /// and only on confirm does the actual POST fire. Before this sheet
  /// existed the cash button was a one-tap terminal POST — a mis-tap
  /// closed the booking and stamped a cash row.
  Future<void> _runPendingSheetCash() async {
    if (!mounted) return;
    final amount = widget.booking.pricing.finalCashToCollect;
    if (amount == null) return;
    final customerName = widget.booking.customer.fullName;
    final result = await BookingActionPendingSheet.show(
      context,
      title: 'Confirm cash received?',
      body:
          'You should have received Rs. $amount in cash from $customerName. '
          'Confirming closes the booking.', // ignore: html_in_doc_comment
      confirmLabel: 'Yes, received Rs. $amount',
      confirmIsDestructive: false,
      onConfirm: () => ref
          .read(bookingActionExecutorProvider)
          .execute(
            widget.action,
            body: {'amount': amount, 'method': 'cash'},
          ),
    );
    if (result == true && mounted) {
      ref.invalidate(bookingDetailProvider(widget.booking.id));
    }
  }

  /// Decline-quote confirm sheet. For the initial quote this is a
  /// terminal action (booking moves to COMPLETED_INSPECTION_ONLY +
  /// Rs.500 inspection fee owed in cash). For an upsell it's
  /// non-terminal (booking stays IN_PROGRESS, just refuses the
  /// additional work). Both require explicit confirmation.
  Future<void> _runPendingSheetDecline() async {
    if (!mounted) return;
    final isInProgress =
        widget.booking.status == BookingStatus.inProgress;
    final body = isInProgress
        ? 'The technician will continue the work they already started, '
            'but the extra work they proposed will not be added to the bill.'
        : 'You will still owe Rs. 500 inspection fee in cash. '
            'The technician will leave and the booking will be closed.';
    final result = await BookingActionPendingSheet.show(
      context,
      title: isInProgress ? 'Decline this extra work?' : 'Decline this quote?',
      body: body,
      confirmLabel: isInProgress ? 'Decline upsell' : 'Yes, decline',
      confirmIsDestructive: true,
      onConfirm: () => ref
          .read(bookingActionExecutorProvider)
          .execute(
            widget.action,
            body: {'decision_reason': 'customer_declined'},
          ),
    );
    if (result == true && mounted) {
      ref.invalidate(bookingDetailProvider(widget.booking.id));
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
      // Quote-superseded recovery (audit #15). The customer tapped
      // Approve / Decline / Request-Revision on a quote_id that the
      // tech meanwhile superseded. Don't surface the raw "invalid
      // transition" snack — invalidate the detail (the next render
      // shows the new active quote with fresh action ids) and tell
      // the user softly what happened.
      if (e.code == 'quote_superseded') {
        ref.invalidate(bookingDetailProvider(widget.booking.id));
        _showSnack('The quote was updated — showing the new one.');
      } else {
        _showSnack(e.message);
      }
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
    } catch (e, stack) {
      // Anything else (FormatException, unexpected runtime errors, ...).
      // Show the user a generic snack but log the stackTrace at SEVERE
      // so QA + on-device debugging can find the root cause instead of
      // it disappearing into the opaque snack.
      developer.log(
        'BookingActionExecutor unexpected error on '
        '${widget.action.endpoint}',
        name: 'orchestrator.action',
        level: 1000,
        error: e,
        stackTrace: stack,
      );
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

  /// Real quote builder — session 5 deliverable. Opens
  /// [QuoteBuilderSheet] with the booking's sub-service pre-filled, then
  /// POSTs the line-item body through the existing executor.
  Future<void> _runQuoteBuilder() async {
    if (!mounted) return;
    final result = await QuoteBuilderSheet.show(
      context,
      booking: widget.booking,
      action: widget.action,
      onConfirm: (body) => ref
          .read(bookingActionExecutorProvider)
          .execute(widget.action, body: body),
    );
    if (result == true && mounted) {
      ref.invalidate(bookingDetailProvider(widget.booking.id));
    }
  }

  Map<String, dynamic>? _autoBody() {
    // Currently only confirm-cash-received needs an auto body.
    //
    // Wire-contract: ``backend/bookings/api/completion/serializers.py``
    // declares `amount: DecimalField` + `method: ChoiceField(['cash'])`.
    // Earlier this file sent `cash_amount` which DRF rejected with
    // `validation_error` — fixed to the canonical field names.
    if (widget.action.endpoint.endsWith('/confirm-cash-received/')) {
      final amount = widget.booking.pricing.finalCashToCollect;
      if (amount == null) return null;
      return {'amount': amount, 'method': 'cash'};
    }
    return null;
  }

  void _showSnack(String text) {
    if (!mounted) return;
    OrchestratorSnack.error(context, text);
  }

  /// Classify by endpoint suffix. Wire spec from
  /// `backend/bookings/selectors/orchestrator_ui.py` is stable; if
  /// backend adds a new action, this falls through to direct-post
  /// (the safe default for bodyless ops).
  _ActionClassification _classify(String endpoint) {
    if (endpoint.endsWith('/confirm-cash-received/')) {
      // Terminal money-mutating action — must be behind a confirm sheet.
      return _ActionClassification.pendingSheetCash;
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
    if (endpoint.endsWith('/quotes/')) {
      // submit_quote root POST — the quote BUILDER lives in session 5.
      return _ActionClassification.pendingSheetQuote;
    }
    if (endpoint.endsWith('/decline/')) {
      // Customer decline of initial quote = terminal (Rs.500 inspection
      // fee charged); decline of an upsell = non-terminal but still a
      // material decision. Both require explicit confirmation.
      return _ActionClassification.pendingSheetDecline;
    }
    // Everything else is a bodyless POST: en-route, arrived,
    // start-inspection, /quotes/<id>/approve/, /quotes/<id>/request-revision/.
    // Approve + revision are recoverable / non-destructive — direct POST
    // is fine. (Revision flips a SUBMITTED quote back to SUPERSEDED so
    // the tech can rebuild it; the customer can ask again.)
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
  pendingSheetDispute,
  pendingSheetCash,
  pendingSheetDecline,
}
