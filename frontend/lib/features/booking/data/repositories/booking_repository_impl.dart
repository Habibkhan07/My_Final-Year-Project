import 'dart:io';
import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/failures/booking_failure.dart';
import '../../domain/repositories/i_booking_repository.dart';
import '../data_sources/booking_remote_data_source.dart';
import '../models/booking_models.dart';

class BookingRepositoryImpl implements IBookingRepository {
  final IBookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TechnicianProfileEntity> getTechnicianProfile({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) async {
    try {
      final model = await remoteDataSource.getTechnicianProfile(
        id: id,
        lat: lat,
        lng: lng,
        serviceId: serviceId,
        subServiceId: subServiceId,
        promotionId: promotionId,
      );
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const BookingNetworkFailure();
    } on FormatException {
      throw const BookingUnexpectedFailure(
        'Parsing error: Invalid JSON format.',
      );
    } catch (e) {
      throw BookingUnexpectedFailure(e.toString());
    }
  }

  @override
  Future<List<AvailabilitySlotEntity>> getAvailability({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) async {
    try {
      final models = await remoteDataSource.getAvailability(
        technicianId: technicianId,
        date: date,
        serviceId: serviceId,
        subServiceId: subServiceId,
      );
      return models.map((m) => m.toEntity()).toList();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const BookingNetworkFailure();
    } on FormatException {
      throw const BookingUnexpectedFailure(
        'Parsing error: Invalid JSON format.',
      );
    } catch (e) {
      throw BookingUnexpectedFailure(e.toString());
    }
  }

  @override
  Future<CreatedBookingEntity> createInstantBooking({
    required int technicianId,
    required int addressId,
    required int serviceId,
    int? subServiceId,
    int? promotionId,
    required String scheduledStart,
    required String scheduledEnd,
  }) async {
    try {
      final request = InstantBookingRequestModel(
        technicianId: technicianId,
        addressId: addressId,
        serviceId: serviceId,
        subServiceId: subServiceId,
        promotionId: promotionId,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
      );
      final response = await remoteDataSource.createInstantBooking(request);
      return response.toEntity();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const BookingNetworkFailure();
    } on FormatException {
      throw const BookingUnexpectedFailure(
        'Parsing error: Invalid JSON format.',
      );
    } catch (e) {
      throw BookingUnexpectedFailure(e.toString());
    }
  }

  /// Maps an [HttpFailure] code from the standard error envelope to the
  /// appropriate typed [BookingFailure].
  ///
  /// 'out_of_service_area' passes the backend message directly — it is already
  /// human-readable (e.g. "Your address is 14.2 km away (limit: 10 km)").
  BookingFailure _mapFailure(HttpFailure failure) {
    switch (failure.code) {
      case 'not_found':
        return const BookingTechnicianNotFoundFailure();
      case 'out_of_service_area':
        return BookingOutOfServiceAreaFailure(failure.message);
      case 'slot_unavailable':
        return const BookingSlotUnavailableFailure();
      case 'validation_error':
        // IDOR-safe: address_id check returns validation_error, same as any
        // other 400, but the errors map will have 'address_id' as the key.
        final errors = failure.errors;
        if (errors.containsKey('address_id')) {
          return const BookingInvalidAddressFailure();
        }
        return BookingValidationFailure(
          message: failure.message,
          errors: errors.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      case 'server_error':
        return const BookingServerFailure();
      default:
        return BookingUnexpectedFailure(failure.message);
    }
  }
}
