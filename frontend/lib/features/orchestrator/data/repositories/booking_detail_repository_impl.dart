import 'dart:io' show SocketException;

import '../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/failures/booking_detail_failure.dart';
import '../../domain/repositories/booking_detail_repository.dart';
import '../datasources/booking_detail_local_data_source.dart';
import '../datasources/booking_detail_remote_data_source.dart';
import '../mappers/booking_detail_mapper.dart';

/// Offline-first orchestrator repository.
///
/// Network is the source of truth. We try remote first; on success the
/// model is cached for crash-recovery. On `SocketException` we fall back
/// to the cache; if the cache is empty, we throw
/// [BookingDetailOfflineNoCache] so the screen renders the offline state.
///
/// All other HTTP failures map to typed sealed-class failures so the
/// presentation layer pattern-matches without raw string codes.
class BookingDetailRepositoryImpl implements IBookingDetailRepository {
  final IBookingDetailRemoteDataSource _remote;
  final IBookingDetailLocalDataSource _local;
  final int _currentUserId;

  BookingDetailRepositoryImpl({
    required IBookingDetailRemoteDataSource remote,
    required IBookingDetailLocalDataSource local,
    required int currentUserId,
  }) : _remote = remote,
       _local = local,
       _currentUserId = currentUserId;

  @override
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    try {
      final model = await _remote.fetch(bookingId);
      // Best-effort cache write; never fails the request. We cache the
      // wire model BEFORE attempting the domain map so that even partial
      // schema drift (e.g., a new status enum we don't recognize yet)
      // doesn't lose the latest known wire snapshot. The map step then
      // double-checks: if it throws, we evict the cache row to avoid
      // serving a model we know we can't translate. Next online fetch
      // overwrites — no permanent corruption.
      _local.cache(bookingId, model).ignore();
      try {
        return BookingDetailMapper.toDomain(
          model,
          currentUserId: _currentUserId,
        );
      } catch (_) {
        _local.clear(bookingId).ignore();
        rethrow;
      }
    } on SocketException {
      final cached = await _local.read(bookingId);
      if (cached == null) throw const BookingDetailOfflineNoCache();
      try {
        return BookingDetailMapper.toDomain(
          cached,
          currentUserId: _currentUserId,
        );
      } catch (_) {
        // Cached row is now untranslatable — evict so next fetch starts
        // fresh and the user doesn't get an "Error" loop on every offline
        // re-mount.
        _local.clear(bookingId).ignore();
        throw const BookingDetailOfflineNoCache();
      }
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e, bookingId);
    } on BookingDetailFailure {
      rethrow; // already typed; pass through.
    } catch (e) {
      throw UnknownBookingDetailFailure(e.toString());
    }
  }

  BookingDetailFailure _mapHttpFailure(HttpFailure e, int bookingId) {
    if (e.statusCode == 404) {
      return BookingDetailNotFound(bookingId);
    }
    if (e.statusCode == 403 && e.code == 'not_a_participant') {
      return const BookingDetailNotParticipant();
    }
    if (e.statusCode >= 500) {
      return const BookingDetailServerFailure();
    }
    return UnknownBookingDetailFailure(e.message);
  }
}
