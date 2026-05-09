// lib/features/customer/home/data/data_sources/home_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/home_feed_model.dart';

class HomeRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/customers";

  Future<HomeFeedModel> getHomeFeed({double? lat, double? lng}) async {
    // Construct Query Params
    final Map<String, String> queryParams = {};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
    }

    // Build URL safely with query params
    final uri = Uri.parse(
      '$baseUrl/home/',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri);

    _handleResponse(response);

    final data = jsonDecode(response.body);
    return HomeFeedModel.fromJson(data);
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
