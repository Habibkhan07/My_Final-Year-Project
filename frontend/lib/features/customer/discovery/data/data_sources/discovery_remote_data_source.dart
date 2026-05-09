import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/discovery_models.dart';

abstract class IDiscoveryRemoteDataSource {
  Future<DiscoveryResultModel> getNearbyTechnicians({
    double? lat,
    double? lng,
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    int page = 1,
  });
}

class DiscoveryRemoteDataSource implements IDiscoveryRemoteDataSource {
  final http.Client client;
  final String baseUrl =
      "${AppConstants.baseUrl}/customers/nearby-technicians/";

  DiscoveryRemoteDataSource({required this.client});

  @override
  Future<DiscoveryResultModel> getNearbyTechnicians({
    double? lat,
    double? lng,
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    int page = 1,
  }) async {
    final queryParams = {
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (query != null && query.isNotEmpty) 'q': query,
      if (serviceId != null) 'service_id': serviceId.toString(),
      if (subServiceId != null) 'sub_service_id': subServiceId.toString(),
      if (promotionId != null) 'promotion_id': promotionId.toString(),
      'page': page.toString(),
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    final response = await client.get(uri);

    _handleResponse(response);

    final data = jsonDecode(response.body);
    return DiscoveryResultModel.fromJson(data);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

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
