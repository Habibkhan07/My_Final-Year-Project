// Per-status body widgets. Each is intentionally minimal — sessions
// 4–6 replace the specialized parts (live map, quote builder, cash
// collection sheet, cancel/reschedule modals) but keep the surrounding
// chrome these stubs establish. Every stub reads its prose from
// `booking.ui.bodyText` (dumb-UI principle); none branches on status
// for copy or computes its own.
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_quote.dart';

class AwaitingBodyStub extends StatelessWidget {
  const AwaitingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.schedule, booking: booking);
}

class ConfirmedBodyStub extends StatelessWidget {
  const ConfirmedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.check_circle_outline, booking: booking);
}

class EnRouteBodyStub extends StatelessWidget {
  const EnRouteBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _MapPlaceholder(),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ArrivedBodyStub extends StatelessWidget {
  const ArrivedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _MapPlaceholder(label: 'Tech is at the door'),
          const SizedBox(height: 16),
          Text(booking.ui.bodyText, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class InspectingBodyStub extends StatelessWidget {
  const InspectingBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.search, booking: booking);
}

class QuotedBodyStub extends StatelessWidget {
  const QuotedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final quote = booking.activeQuote;
    if (quote == null) {
      return _IconWithBody(icon: Icons.receipt_long_outlined, booking: booking);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuoteCard(quote: quote),
          const SizedBox(height: 12),
          Text(booking.ui.bodyText),
        ],
      ),
    );
  }
}

class InProgressBodyStub extends StatelessWidget {
  const InProgressBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.build_outlined, booking: booking);
}

class CompletedBodyStub extends StatelessWidget {
  const CompletedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.check_circle, booking: booking);
}

class CompletedInspectionOnlyBodyStub extends StatelessWidget {
  const CompletedInspectionOnlyBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) => _IconWithBody(
        icon: Icons.receipt_outlined,
        booking: booking,
      );
}

class CancelledBodyStub extends StatelessWidget {
  const CancelledBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.event_busy, booking: booking);
}

class RejectedBodyStub extends StatelessWidget {
  const RejectedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.do_not_disturb, booking: booking);
}

class NoShowBodyStub extends StatelessWidget {
  const NoShowBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.person_off_outlined, booking: booking);
}

class DisputedBodyStub extends StatelessWidget {
  const DisputedBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) =>
      _IconWithBody(icon: Icons.gavel_outlined, booking: booking);
}

/// Audit P1-11: log a warning when the legacy PENDING status surfaces
/// here (predates migration 0007; should not occur in v1). Helps spot
/// rollout-window regressions without surfacing a confusing UI.
class UnknownBodyStub extends StatelessWidget {
  const UnknownBodyStub({super.key, required this.booking});
  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.pending) {
      developer.log(
        'UnknownBodyStub rendering legacy PENDING booking ${booking.id}',
        name: 'orchestrator',
        level: 900,
      );
    }
    final text = booking.ui.bodyText.isEmpty
        ? 'Status not recognized.'
        : booking.ui.bodyText;
    return _IconWithBody(
      icon: Icons.help_outline,
      booking: booking,
      overrideText: text,
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────

class _IconWithBody extends StatelessWidget {
  const _IconWithBody({
    required this.icon,
    required this.booking,
    this.overrideText,
  });

  final IconData icon;
  final BookingDetail booking;
  final String? overrideText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            overrideText ?? booking.ui.bodyText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined,
              size: 32, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            label ?? 'Live tracking — coming in session 4',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final BookingQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Quote · revision ${quote.revisionNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in quote.lineItems) ...[
              _LineItemRow(
                name: item.subServiceName,
                qty: item.quantity,
                lineTotal: item.lineTotal,
              ),
              const SizedBox(height: 6),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleSmall),
                Text(
                  'Rs. ${_format(quote.totalAmount)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.name,
    required this.qty,
    required this.lineTotal,
  });

  final String name;
  final int qty;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            qty == 1 ? name : '$name · ×$qty',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          'Rs. ${_format(lineTotal)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Locale-naive comma grouping for rupees. Pakistan uses the en-PK
/// numbering system (lakhs/crores) but the entire app currently formats
/// with Western thousands separators — keeping consistent here.
String _format(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
