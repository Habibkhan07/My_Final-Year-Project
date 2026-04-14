import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/booking_models.dart';

abstract class IBookingRemoteDataSource {
  /// GET /api/customers/technician-profile/{id}/
  Future<TechnicianProfileModel> getTechnicianProfile({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  });

  /// GET /api/customers/technicians/{id}/availability/
  Future<List<AvailabilitySlotModel>> getAvailability({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  });

  /// POST /api/bookings/instant-book/
  Future<InstantBookingResponseModel> createInstantBooking(
      InstantBookingRequestModel request);

  /// GET /api/customers/addresses/
  Future<List<SavedAddressModel>> getSavedAddresses();
}

class BookingRemoteDataSource implements IBookingRemoteDataSource {
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  // Matches the key written by AuthLocalDataSource
  static const String _tokenKey = 'auth_token';

  BookingRemoteDataSource({
    required this.client,
    required this.secureStorage,
  });

  @override
  Future<TechnicianProfileModel> getTechnicianProfile({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) async {
    final queryParams = <String, String>{
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (serviceId != null) 'service_id': serviceId.toString(),
      if (subServiceId != null) 'sub_service_id': subServiceId.toString(),
      if (promotionId != null) 'promotion_id': promotionId.toString(),
    };

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/customers/technician-profile/$id/',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await client.get(uri);
    _handleResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TechnicianProfileModel.fromJson(data);
  }

  @override
  Future<List<AvailabilitySlotModel>> getAvailability({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) async {
    final queryParams = <String, String>{
      'date': date,
      if (serviceId != null) 'service_id': serviceId.toString(),
      if (subServiceId != null) 'sub_service_id': subServiceId.toString(),
    };

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/customers/technicians/$technicianId/availability/',
    ).replace(queryParameters: queryParams);

    final response = await client.get(uri);
    _handleResponse(response);

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => AvailabilitySlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InstantBookingResponseModel> createInstantBooking(
      InstantBookingRequestModel request) async {
    final token = await secureStorage.read(key: _tokenKey);

    final uri = Uri.parse('${AppConstants.baseUrl}/bookings/instant-book/');

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(request.toJson()),
    );

    _handleResponse(response);

    return InstantBookingResponseModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<List<SavedAddressModel>> getSavedAddresses() async {
    final token = await secureStorage.read(key: _tokenKey);
    final uri = Uri.parse('${AppConstants.baseUrl}/customers/addresses/');

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SavedAddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'],
          message: body['message'] ?? 'An error occurred',
          errors: body['errors'] ?? {},
        );
      }
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'unknown',
        message: body['detail'] ?? body['error'] ?? 'Unknown error',
      );
    } catch (e) {
      if (e is HttpFailure) rethrow;
      throw HttpFailure(
        statusCode: response.statusCode,
        code: 'server_error',
        message: 'Server error: ${response.statusCode}',
      );
    }
  }
}
