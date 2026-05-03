import 'package:flutter/material.dart';

/// Placeholder for the customer-side booking detail screen.
///
/// Wired as the tap target for the `booking_rejected` MaterialBanner.
/// The route slot — `/customer/booking/:job_id` — and the
/// `EventUrgencyRouter` payload-key substitution that produces the
/// concrete path are both shipped; the rich detail UI (status timeline,
/// re-pick CTA, cancellation history) is the next sprint's work — see
/// flag #26 for the deferred `bookings` feature stack (domain entities,
/// repository, data source, notifier) that will replace this stub.
class CustomerBookingDetailScreen extends StatelessWidget {
  const CustomerBookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Booking #$bookingId',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Detail screen coming soon.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
