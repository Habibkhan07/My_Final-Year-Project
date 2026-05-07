import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/failures/booking_failure.dart';
import '../providers/booking_notifier.dart';
import '../../../customer/addresses/presentation/providers/dependency_injection.dart';
import '../../../customer/addresses/presentation/widgets/address_selector_sheet.dart';
import 'modal_bottom_sheet_layout.dart';

class ReviewBookingSheet extends ConsumerWidget {
  final TechnicianProfileEntity technician;
  final DateTime selectedDate;
  final AvailabilitySlotEntity selectedSlot;
  final int? serviceId;
  final int? subServiceId;
  final int? promotionId;

  const ReviewBookingSheet({
    super.key,
    required this.technician,
    required this.selectedDate,
    required this.selectedSlot,
    this.serviceId,
    this.subServiceId,
    this.promotionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to state changes for navigation & error handling
    ref.listen<AsyncValue<CreatedBookingEntity?>>(
      instantBookingProvider,
      (previous, next) {
        next.whenOrNull(
          data: (entity) {
            if (entity != null) {
              // TODO: Cache booking ID to Tier 3 (SharedPreferences)
              Navigator.pop(context); // Close Review sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking Confirmed!')),
              );
            }
          },
          error: (error, stack) {
            if (error is BookingFailure) {
              final (message, popOnShow) = _resolveErrorPresentation(error);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
              if (popOnShow) {
                // Pop the review sheet so the customer can refresh discovery
                // (slot taken, stale catalog, stale promo, stale price).
                Navigator.pop(context);
              }
            }
          },
        );
      },
    );

    final bookingState = ref.watch(instantBookingProvider);
    final isSubmitting = bookingState.isLoading;

    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final defaultAddress = defaultAddressAsync.value;

    final formattedDate = DateFormat('EEE d').format(selectedDate);
    final daySuffix = _getDaySuffix(selectedDate.day);
    final displayDate = '$formattedDate$daySuffix';

    return ModalBottomSheetLayout(
      title: 'Review Booking',
      footer: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSubmitting || defaultAddress == null || serviceId == null
              ? null
              : () {
                  ref.read(instantBookingProvider.notifier).book(
                        technicianId: technician.id,
                        addressId: defaultAddress.id,
                        serviceId: serviceId!,
                        subServiceId: subServiceId,
                        promotionId: promotionId,
                        scheduledStart: selectedSlot.isoStart,
                        scheduledEnd: selectedSlot.isoEnd,
                      );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0051AE),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF0051AE).withOpacity(0.4),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Book',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      child: Column(
        children: [
          // Summary List
          _SummaryTile(
            icon: Icons.schedule,
            label: 'Date & Time',
            value: '$displayDate, ${selectedSlot.timeString}',
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total (${technician.priceContext})',
            value: technician.primaryPrice,
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            icon: Icons.location_on_outlined,
            label: 'Service Address',
            value: defaultAddress != null 
                ? '${defaultAddress.label} - ${defaultAddress.streetAddress}'
                : 'Select an address',
            trailing: TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddressSelectorSheet(),
                );
              },
              child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),

          // Legal Note
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF424753),
                height: 1.6,
              ),
              children: [
                TextSpan(text: 'By tapping the button below, you agree to our '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF0051AE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' and authorize the hold for this transaction on your selected card.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Resolves a [BookingFailure] into a user-friendly toast string and
  /// whether the review sheet should pop afterwards.
  ///
  /// The two field-keyed validation errors are translated via the dictionary
  /// in BOOKINGS_API.md §2.2 — the server returns diagnostic-friendly text,
  /// not user-friendly text, so we map locally rather than render `error.message`.
  /// Both pop the sheet so the customer is sent back to discovery to refresh.
  (String message, bool popSheet) _resolveErrorPresentation(BookingFailure error) {
    if (error is BookingValidationFailure) {
      final keys = error.errors?.keys.toSet() ?? const <String>{};
      if (keys.contains('sub_service_id')) {
        return ('This gig is no longer available. Refresh and try again.', true);
      }
      if (keys.contains('promotion_id')) {
        return ("This gig already has a fixed price — promotions don't apply.", true);
      }
    }
    if (error is BookingSlotUnavailableFailure) {
      return (error.message, true);
    }
    return (error.message, false);
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0051AE).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0051AE), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Color(0xFF424753),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151C24),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}