import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_detail_model.dart';

/// Crash-recovery cache for the orchestrator screen. Used as fallback
/// only when the remote fetch throws `SocketException` for the FIRST
/// hydration of a given jobId — subsequent fetches always go to network.
///
/// Key: `orchestrator_booking_detail_v1_<jobId>`. Bump the `_v1_` suffix
/// when the response shape changes to avoid stale-cache parsing crashes.
abstract interface class IBookingDetailLocalDataSource {
  Future<void> cache(int bookingId, BookingDetailModel model);
  Future<BookingDetailModel?> read(int bookingId);
  Future<void> clear(int bookingId);
}

class BookingDetailLocalDataSource implements IBookingDetailLocalDataSource {
  final SharedPreferences _prefs;
  static const _kKeyPrefix = 'orchestrator_booking_detail_v1_';

  BookingDetailLocalDataSource(this._prefs);

  @override
  Future<void> cache(int bookingId, BookingDetailModel model) async {
    await _prefs.setString(
      '$_kKeyPrefix$bookingId',
      jsonEncode(model.toJson()),
    );
  }

  @override
  Future<BookingDetailModel?> read(int bookingId) async {
    final raw = _prefs.getString('$_kKeyPrefix$bookingId');
    if (raw == null) return null;
    try {
      return BookingDetailModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Corrupted entry (schema bump, partial write). Treat as absent;
      // a fresh fetch will overwrite.
      return null;
    }
  }

  @override
  Future<void> clear(int bookingId) async {
    await _prefs.remove('$_kKeyPrefix$bookingId');
  }
}
