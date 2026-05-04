// Translates the wire model [CustomerBookingModel] into the typed
// domain entity [CustomerBooking]. This is the boundary where wire
// strings become typed values:
//
//   * status string ("CONFIRMED") → BookingStatus enum
//   * tone string ("positive") → BookingUiTone enum
//   * ISO-8601 string → DateTime
//
// The mapper is forgiving: unknown enum strings become the `unknown`
// member of each enum (forward-compat with future backend rollouts).
// Unparseable timestamps fall back to `DateTime.now().toUtc()` and log
// — better than throwing into the queue notifier, which would drop the
// entire page.
import 'dart:developer';

import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_ui_tone.dart';
import '../../domain/entities/customer_booking.dart';
import '../models/customer_booking_model.dart';
import '../models/bookings_list_response_model.dart';
import '../models/bookings_counts_model.dart';
import '../../domain/entities/bookings_page.dart';
import '../../domain/entities/bookings_counts.dart';

class CustomerBookingMapper {
  CustomerBookingMapper._();

  static const _logName =
      'features.customer.bookings.mapper';

  static CustomerBooking fromModel(CustomerBookingModel model) {
    return CustomerBooking(
      id: model.id,
      status: BookingStatus.fromWire(model.status),
      service: BookingService(
        name: model.service.name,
        iconName: model.service.iconName,
      ),
      technician: BookingTechnician(
        id: model.technician.id,
        displayName: model.technician.displayName,
        profilePictureUrl: model.technician.profilePictureUrl,
      ),
      addressLabel: model.addressLabel,
      scheduledStart: _parseIsoOrNow(model.scheduledStart, model.id, 'scheduled_start'),
      scheduledEnd: _parseIsoOrNow(model.scheduledEnd, model.id, 'scheduled_end'),
      createdAt: _parseIsoOrNow(model.createdAt, model.id, 'created_at'),
      price: BookingPrice(
        amount: model.price.amount,
        context: model.price.context,
        uiLabel: model.price.uiLabel,
      ),
      ui: BookingUi(
        badgeText: model.ui.badgeText,
        badgeTone: BookingUiTone.fromWire(model.ui.badgeTone),
        headline: model.ui.headline,
      ),
    );
  }

  /// Maps the full list response envelope. [isStaleCache] flag and
  /// [cachedAt] are passed in by the repository when the page came
  /// from the local cache after a SocketException; the network path
  /// passes false / null.
  static BookingsPage pageFromResponse(
    BookingsListResponseModel response, {
    bool isStaleCache = false,
    DateTime? cachedAt,
  }) {
    return BookingsPage(
      items: response.items.map(fromModel).toList(growable: false),
      nextCursor: response.nextCursor,
      hasMore: response.hasMore,
      serverTime: _parseIsoOrNow(
        response.serverTime,
        -1,
        'server_time',
      ),
      isStaleCache: isStaleCache,
      cachedAt: cachedAt,
    );
  }

  static BookingsCounts countsFromModel(BookingsCountsModel model) {
    return BookingsCounts(
      upcoming: model.upcoming,
      past: model.past,
      serverTime: _parseIsoOrNow(model.serverTime, -1, 'counts.server_time'),
    );
  }

  static DateTime _parseIsoOrNow(String iso, int bookingId, String field) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      log(
        'Unparseable $field "$iso" on booking $bookingId; falling back to now().',
        name: _logName,
      );
      return DateTime.now().toUtc();
    }
  }
}
