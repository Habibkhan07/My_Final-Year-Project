import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../data/models/quotable_sub_service_model.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_ui_block.dart';
import '../../providers/quotable_sub_services_notifier.dart';
import '../stub_bodies/all_status_stubs.dart' show formatRupees;

/// Bottom sheet for the tech-side "Submit Quote" action.
///
/// Fetches the tech's qualified sub-services for this booking's parent
/// service via `quotableSubServicesProvider(serviceId)` — the
/// backend filters by `TechnicianSkill` so the dropdown only shows
/// items this tech is licensed to charge for.
///
/// **Per-line price rules:**
///   * `is_fixed_price=true` sub-service → price field is locked,
///     pre-filled with `base_price`. The line always submits exactly
///     that amount.
///   * variable sub-service → price field is editable, gated to
///     `[base_price, max_price]`. Out-of-band lines disable submit.
///
/// Each line POSTs its own chosen `sub_service_id` — multi-line quotes
/// are now real itemizations, not N copies of the same row (audit fix
/// for the v1 "all lines reuse booking.subService.id" shortcut).
class QuoteBuilderSheet extends ConsumerStatefulWidget {
  const QuoteBuilderSheet({
    super.key,
    required this.booking,
    required this.action,
    required this.onConfirm,
  });

  final BookingDetail booking;
  final BookingUiAction action;
  final Future<void> Function(Map<String, dynamic> body) onConfirm;

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
  ConsumerState<QuoteBuilderSheet> createState() => _QuoteBuilderSheetState();
}

class _QuoteBuilderSheetState extends ConsumerState<QuoteBuilderSheet> {
  final List<_LineDraft> _lines = [_LineDraft()];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final line in _lines) {
      line.priceController.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Catalog-aware seeding: when the dropdown data arrives, pre-fill the
  // first line with the booking's original sub-service (if it's in the
  // qualified list) so the tech doesn't have to pick the obvious thing.
  // ------------------------------------------------------------------

  bool _seeded = false;

  void _maybeSeedFirstLine(List<QuotableSubServiceModel> catalog) {
    if (_seeded || catalog.isEmpty) return;
    _seeded = true;
    final bookingSubId = widget.booking.subService?.id;
    QuotableSubServiceModel? match;
    for (final item in catalog) {
      if (item.id == bookingSubId) {
        match = item;
        break;
      }
    }
    match ??= catalog.first;
    _applyChoice(_lines.first, match);
  }

  void _applyChoice(_LineDraft line, QuotableSubServiceModel chosen) {
    line.chosen = chosen;
    if (chosen.isFixedPrice) {
      // Fixed-price: lock the price to base_price. The line always
      // submits exactly that figure; no editing.
      line.priceController.text = _decimalToWholeRupees(chosen.basePrice);
    } else {
      // Variable: pre-fill with base_price as the starting suggestion.
      // The tech can edit within [base_price, max_price].
      line.priceController.text = _decimalToWholeRupees(chosen.basePrice);
    }
  }

  // ------------------------------------------------------------------
  // Submit gating: every line must have a chosen sub-service AND a
  // price in band. Empty/zero/missing → disable.
  // ------------------------------------------------------------------

  int get _total {
    var sum = 0;
    for (final line in _lines) {
      final price = int.tryParse(line.priceController.text.trim()) ?? 0;
      sum += price * line.qty;
    }
    return sum;
  }

  bool _isLineValid(_LineDraft line) {
    final chosen = line.chosen;
    if (chosen == null) return false;
    if (line.qty < 1) return false;
    final price = int.tryParse(line.priceController.text.trim()) ?? 0;
    if (price <= 0) return false;
    final basePrice = int.parse(_decimalToWholeRupees(chosen.basePrice));
    if (chosen.isFixedPrice) {
      // Fixed: price must equal base_price exactly. The field is locked
      // so this should always hold, but we check defensively.
      return price == basePrice;
    }
    // Variable: price must be in [base, max]. If max is null on a
    // variable item (unusual but possible per the model), treat as no
    // upper cap.
    if (price < basePrice) return false;
    final maxPrice = chosen.maxPrice;
    if (maxPrice != null) {
      final maxRupees = int.parse(_decimalToWholeRupees(maxPrice));
      if (price > maxRupees) return false;
    }
    return true;
  }

  bool get _canSubmit {
    if (_busy) return false;
    if (_lines.isEmpty) return false;
    for (final line in _lines) {
      if (!_isLineValid(line)) return false;
    }
    return true;
  }

  void _addLine() {
    setState(() => _lines.add(_LineDraft()));
  }

  void _removeLine(int index) {
    setState(() {
      final removed = _lines.removeAt(index);
      removed.priceController.dispose();
    });
  }

  /// True when this sheet was opened from an IN_PROGRESS booking — i.e.
  /// the customer already approved the initial quote and the tech is
  /// adding extra line items mid-job. Backend keys off this flag to
  /// stamp the new Quote with `is_upsell=True` (which keeps the booking
  /// at IN_PROGRESS, appends line items, and broadcasts QUOTE_GENERATED
  /// so the customer can approve the delta).
  bool get _isUpsell =>
      widget.booking.status == BookingStatus.inProgress;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'line_items': [
        for (final line in _lines)
          {
            'sub_service_id': line.chosen!.id,
            'priced_at': int.parse(line.priceController.text.trim()),
            'quantity': line.qty,
          },
      ],
      'is_upsell': _isUpsell,
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

  // ------------------------------------------------------------------
  // build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final catalogAsync = ref.watch(
      quotableSubServicesProvider(widget.booking.service.id),
    );
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
                    _isUpsell ? 'Add upsell' : 'Build quote',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _isUpsell
                    ? 'Add new line items to the in-progress job. The customer '
                        'will be asked to approve the extras before they are charged.'
                    : 'Customer reviews and approves before any repair work begins.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              catalogAsync.when(
                loading: () => const _CatalogLoading(),
                error: (e, _) => _CatalogError(
                  message: e is HttpFailure ? e.message : 'Could not load catalog.',
                  onRetry: () => ref.invalidate(
                    quotableSubServicesProvider(
                      widget.booking.service.id,
                    ),
                  ),
                ),
                data: (catalog) {
                  if (catalog.isEmpty) {
                    return const _CatalogEmpty();
                  }
                  _maybeSeedFirstLine(catalog);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _lines.length; i++) ...[
                        _LineEditor(
                          draft: _lines[i],
                          catalog: catalog,
                          canRemove: _lines.length > 1,
                          onRemove: () => _removeLine(i),
                          onChoice: (chosen) {
                            setState(() => _applyChoice(_lines[i], chosen));
                          },
                          onPriceChanged: () => setState(() {}),
                          onQtyChanged: (v) {
                            setState(() => _lines[i].qty = v);
                          },
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
                    ],
                  );
                },
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
                        _isUpsell
                            ? 'Send upsell · Rs. ${formatRupees(_total)}'
                            : 'Send quote · Rs. ${formatRupees(_total)}',
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

// Wire prices are Decimal strings ("2500.00"); the rest of the sheet
// works in integer rupees. Drop the fractional part — Pakistan retail
// pricing doesn't use sub-rupee precision for service jobs.
String _decimalToWholeRupees(String wireDecimal) {
  final dot = wireDecimal.indexOf('.');
  return dot < 0 ? wireDecimal : wireDecimal.substring(0, dot);
}

class _LineDraft {
  _LineDraft();

  /// `null` until the tech picks a sub-service from the dropdown.
  QuotableSubServiceModel? chosen;
  final TextEditingController priceController = TextEditingController();
  int qty = 1;
}

class _LineEditor extends StatelessWidget {
  const _LineEditor({
    required this.draft,
    required this.catalog,
    required this.canRemove,
    required this.onRemove,
    required this.onChoice,
    required this.onPriceChanged,
    required this.onQtyChanged,
  });

  final _LineDraft draft;
  final List<QuotableSubServiceModel> catalog;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<QuotableSubServiceModel> onChoice;
  final VoidCallback onPriceChanged;
  final ValueChanged<int> onQtyChanged;

  String _bandHint(QuotableSubServiceModel sub) {
    final base = _decimalToWholeRupees(sub.basePrice);
    if (sub.isFixedPrice) return 'Fixed price · Rs. $base';
    final maxP = sub.maxPrice;
    if (maxP == null) return 'Min Rs. $base';
    return 'Rs. $base – Rs. ${_decimalToWholeRupees(maxP)}';
  }

  /// Returns an error string when the typed price is parseable but out
  /// of the sub-service's band; null otherwise (empty field, no chosen
  /// sub-service, fixed-price locked field, or in-band price). Drives
  /// the [TextField]'s `errorText` so the tech knows why Submit greys
  /// instead of silently disabling it.
  String? _priceError(QuotableSubServiceModel sub, String raw) {
    if (sub.isFixedPrice) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final price = int.tryParse(trimmed);
    if (price == null) return null;
    final basePrice = int.parse(_decimalToWholeRupees(sub.basePrice));
    final maxP = sub.maxPrice;
    final maxPrice = maxP == null
        ? null
        : int.parse(_decimalToWholeRupees(maxP));
    if (price < basePrice) {
      return maxPrice == null
          ? 'Must be at least Rs. $basePrice'
          : 'Must be Rs. $basePrice – Rs. $maxPrice';
    }
    if (maxPrice != null && price > maxPrice) {
      return 'Must be Rs. $basePrice – Rs. $maxPrice';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chosen = draft.chosen;
    final isFixed = chosen?.isFixedPrice ?? false;
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
          // Row 1: sub-service dropdown + remove
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<QuotableSubServiceModel>(
                  initialValue: chosen,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'What is it?',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  items: [
                    for (final item in catalog)
                      DropdownMenuItem(
                        value: item,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) onChoice(value);
                  },
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
          if (chosen != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 2),
              child: Text(
                _bandHint(chosen),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          // Row 2: price + qty
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: draft.priceController,
                  onChanged: (_) => onPriceChanged(),
                  // Locked on fixed-price: read-only via `enabled: false`.
                  // Field still shows the value (driven by the controller)
                  // but tap doesn't surface the keyboard.
                  enabled: !isFixed,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isFixed ? 'Price (locked)' : 'Price (Rs.)',
                    isDense: true,
                    prefixText: 'Rs. ',
                    suffixIcon: isFixed
                        ? const Icon(Icons.lock_outline, size: 16)
                        : null,
                    errorText: chosen == null
                        ? null
                        : _priceError(chosen, draft.priceController.text),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _QtyStepper(value: draft.qty, onChanged: onQtyChanged),
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

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You don't have any skills enabled for this service category. "
              'Contact admin to add the items you can charge for.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
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
