import 'dart:io' show SocketException;

import 'package:flutter/material.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../_palette/orchestrator_palette.dart';
import '../orchestrator_primary_button.dart';

/// Cancel-reason picker.
///
/// Replaces the older "Cancel with default reason" pending-sheet
/// confirmation. UX rationale: forcing the user to surface *why* they
/// are cancelling (1) gives them a moment to reconsider, (2) makes the
/// "Technician didn't arrive on time" path a *reason* (not a separate
/// peer button — see `feedback_cancel_vs_no_show` memory), and (3)
/// builds the surface for richer downstream behaviour (per-reason
/// finance treatment, reliability incidents, etc.).
///
/// Wire contract today: this sheet submits **no body** to the backend
/// cancel endpoints. The backend computes `cancel_reason` from the
/// booking phase (`customer_cancelled_pre_accept` / `pre_arrival` /
/// `post_arrival`). The user-selected reason is collected for UX
/// clarity; a future migration will add an optional `customer_reason`
/// CharField alongside `cancel_reason` so the picker's value is
/// persisted for analytics.
class CancelReasonSheet extends StatefulWidget {
  const CancelReasonSheet({
    super.key,
    required this.booking,
    required this.action,
    required this.onConfirm,
  });

  final BookingDetail booking;
  final BookingUiAction action;
  final Future<void> Function(Map<String, dynamic>? body) onConfirm;

  /// Convenience opener. Returns `true` on success, `false` on
  /// user-dismiss, `null` on tap-outside / back.
  static Future<bool?> show(
    BuildContext context, {
    required BookingDetail booking,
    required BookingUiAction action,
    required Future<void> Function(Map<String, dynamic>? body) onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => CancelReasonSheet(
        booking: booking,
        action: action,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CancelReasonSheet> createState() => _CancelReasonSheetState();
}

/// One row in the reason picker. The `code` is what we'd send to the
/// backend if/when the cancel endpoints grow a `customer_reason` field.
class _ReasonOption {
  const _ReasonOption({required this.code, required this.label});
  final String code;
  final String label;
}

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  /// Customer-side reason list. "Tech didn't arrive on time" is the
  /// load-bearing one — it's the entry that absorbs what used to be a
  /// standalone "Tech didn't show" button.
  static const _customerReasons = <_ReasonOption>[
    _ReasonOption(
      code: 'tech_did_not_arrive_in_time',
      label: "Technician didn't arrive in time",
    ),
    _ReasonOption(
      code: 'no_longer_needed',
      label: 'I no longer need this service',
    ),
    _ReasonOption(
      code: 'want_to_reschedule',
      label: 'I want to reschedule',
    ),
    _ReasonOption(code: 'other', label: 'Something else'),
  ];

  /// Tech-side reason list.
  static const _techReasons = <_ReasonOption>[
    _ReasonOption(
      code: 'customer_did_not_arrive',
      label: "Customer didn't come out to meet me",
    ),
    _ReasonOption(
      code: 'cannot_perform_job',
      label: "I can't perform this job",
    ),
    _ReasonOption(
      code: 'wrong_address',
      label: 'Address is wrong or unreachable',
    ),
    _ReasonOption(code: 'other', label: 'Something else'),
  ];

  _ReasonOption? _selected;
  bool _busy = false;
  String? _error;

  bool get _isTechFlow =>
      widget.action.endpoint.endsWith('/tech-cancel/');

  List<_ReasonOption> get _reasons =>
      _isTechFlow ? _techReasons : _customerReasons;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Submit with no body — see class doc. The selected reason is
      // recorded in the UI but the backend stamps its own phase-mapped
      // cancel_reason. A future migration will add `customer_reason`
      // to the request envelope.
      await widget.onConfirm(null);
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
        _error = 'Could not cancel the booking.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _isTechFlow
                    ? 'Why are you cancelling this job?'
                    : 'Why are you cancelling?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final reason in _reasons)
              RadioListTile<_ReasonOption>(
                value: reason,
                // ignore: deprecated_member_use — Flutter 3.32 introduced
                // RadioGroup. Migration sweep lands in the Saturday
                // design-system pass; mixing patterns mid-feature would
                // be incoherent.
                groupValue: _selected,
                onChanged: _busy ? null : (v) => setState(() => _selected = v),
                title: Text(reason.label),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeColor: OrchestratorPalette.brandPrimary,
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 12),
            // Destructive primary — backed by `OrchestratorPalette.dangerBase`
            // (cool burgundy) via the shared OrchestratorPrimaryButton recipe.
            // Was previously `colors.error` which derives a pink-coral red
            // from the brand-blue M3 seed; the palette docstring warns
            // against that derivation explicitly.
            OrchestratorPrimaryButton(
              label: widget.action.label,
              onPressed: _selected == null ? null : _submit,
              busy: _busy,
              isDestructive: true,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: OrchestratorPalette.brandPrimary,
              ),
              child: const Text(
                'Keep booking',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
