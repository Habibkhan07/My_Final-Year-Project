import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/constants.dart';
import '../../../../auth/data/data_sources/auth_local_data_source.dart';
import '../models/technician_metrics_model.dart';

abstract interface class IMetricsRemoteDataSource {
  Future<TechnicianMetricsModel> getMetrics();
}

class MetricsRemoteDataSource implements IMetricsRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource authLocalDataSource;
  final String _baseUrl = '${AppConstants.baseUrl}/technicians';

  MetricsRemoteDataSource({
    required this.client,
    required this.authLocalDataSource,
  });

  @override
  Future<TechnicianMetricsModel> getMetrics() async {
    final token = await authLocalDataSource.getToken();
    final uri = Uri.parse('$_baseUrl/metrics/');

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
    );

    _handleResponse(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return TechnicianMetricsModel.fromJson(data);
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
