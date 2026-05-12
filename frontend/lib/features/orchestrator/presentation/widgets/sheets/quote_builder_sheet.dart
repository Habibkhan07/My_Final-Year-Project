import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../stub_bodies/all_status_stubs.dart' show formatRupees;

/// Bottom sheet for the tech-side "Submit Quote" action.
///
/// Replaces the `pendingSheetQuote` explainer with a real builder.
/// Pre-fills a single line item from `booking.subService` (the service
/// the customer originally booked). Tech can edit the price + quantity
/// and (optionally) add more line items — each additional line reuses
/// the same `sub_service_id` because the backend requires a valid id
/// per line and the v1 catalog picker is deferred. The display name is
/// editable per line so the customer sees what each charge is for.
///
/// On submit, posts `{line_items: [...], is_upsell: false}` via the
/// provided [onConfirm] callback (which the caller wires up to the
/// `BookingActionExecutor`).
class QuoteBuilderSheet extends StatefulWidget {
  const QuoteBuilderSheet({
    super.key,
    required this.booking,
    required this.action,
    required this.onConfirm,
  });

  final BookingDetail booking;
  final BookingUiAction action;
  final Future<void> Function(Map<String, dynamic> body) onConfirm;

  /// Convenience opener. Returns `true` when the submit ran successfully,
  /// `false` on user-dismiss, `null` if the modal was dismissed by
  /// tap-outside / system back.
  static Future<bool?> show(
    BuildContext context, {
    required BookingDetail booking,
    required BookingUiAction action,
    required Future<void> Function(Map<String, dynamic> body) onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => QuoteBuilderSheet(
        booking: booking,
        action: action,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<QuoteBuilderSheet> createState() => _QuoteBuilderSheetState();
}

class _QuoteBuilderSheetState extends State<QuoteBuilderSheet> {
  late final List<_LineDraft> _lines;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Seed with one editable line from the booking's sub-service. If the
    // booking has no sub-service (shouldn't happen for non-terminal
    // bookings but the contract allows null), start with a blank row at
    // 0 — the tech will need to enter a price before submit is enabled.
    final sub = widget.booking.subService;
    _lines = [
      _LineDraft(
        nameController: TextEditingController(text: sub?.name ?? 'Repair'),
        priceController: TextEditingController(
          text: sub == null ? '' : sub.basePrice.toString(),
        ),
        qty: 1,
      ),
    ];
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.nameController.dispose();
      line.priceController.dispose();
    }
    super.dispose();
  }

  int get _total {
    var sum = 0;
    for (final line in _lines) {
      final price = int.tryParse(line.priceController.text.trim()) ?? 0;
      sum += price * line.qty;
    }
    return sum;
  }

  bool get _canSubmit {
    if (_busy) return false;
    if (_lines.isEmpty) return false;
    for (final line in _lines) {
      final price = int.tryParse(line.priceController.text.trim()) ?? 0;
      if (price <= 0) return false;
      if (line.nameController.text.trim().isEmpty) return false;
      if (line.qty < 1) return false;
    }
    return true;
  }

  void _addLine() {
    // Each additional line reuses the booking's sub-service id (the
    // backend requires a valid id; the v1 catalog picker is deferred).
    // The label is editable so the customer sees what each charge is.
    setState(() {
      _lines.add(
        _LineDraft(
          nameController: TextEditingController(),
          priceController: TextEditingController(),
          qty: 1,
        ),
      );
    });
  }

  void _removeLine(int index) {
    setState(() {
      final removed = _lines.removeAt(index);
      removed.nameController.dispose();
      removed.priceController.dispose();
    });
  }

  Future<void> _submit() async {
    final subServiceId = widget.booking.subService?.id;
    if (subServiceId == null) {
      setState(() => _error = 'This booking has no sub-service.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'line_items': [
        for (final line in _lines)
          {
            'sub_service_id': subServiceId,
            'priced_at': int.parse(line.priceController.text.trim()),
            'quantity': line.qty,
          },
      ],
      'is_upsell': false,
    };
    try {
      await widget.onConfirm(body);
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
        _error = 'Could not submit the quote.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
                  Icon(Icons.receipt_long_rounded, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Build quote',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customer reviews and approves before any repair work begins.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _lines.length; i++) ...[
                _LineEditor(
                  draft: _lines[i],
                  canRemove: _lines.length > 1,
                  onRemove: () => _removeLine(i),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _addLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add another item'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rs. ${formatRupees(_total)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0051AE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF0051AE).withValues(alpha: 0.4),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Send quote · Rs. ${formatRupees(_total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0051AE),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineDraft {
  _LineDraft({
    required this.nameController,
    required this.priceController,
    required this.qty,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  int qty;
}

class _LineEditor extends StatelessWidget {
  const _LineEditor({
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _LineDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.nameController,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'What is it?',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: 'Remove line',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: draft.priceController,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs.)',
                    isDense: true,
                    prefixText: 'Rs. ',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _QtyStepper(
                value: draft.qty,
                onChanged: (v) {
                  draft.qty = v;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Qty',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 22),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 22),
        ),
      ],
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
          Icon(
            Icons.error_outline,
            size: 18,
            color: colors.onErrorContainer,
          ),
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
