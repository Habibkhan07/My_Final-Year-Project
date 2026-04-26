import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/technician_dashboard_model.dart';

abstract class ITechnicianDashboardRemoteDataSource {
  Future<TechnicianDashboardModel> getDashboard();
}

class TechnicianDashboardRemoteDataSource implements ITechnicianDashboardRemoteDataSource {
  final http.Client client;
  final String baseUrl = "${AppConstants.baseUrl}/technicians";

  TechnicianDashboardRemoteDataSource({required this.client});

  @override
  Future<TechnicianDashboardModel> getDashboard() async {
    final uri = Uri.parse('$baseUrl/dashboard/');
    
    final response = await client.get(uri);

    _handleResponse(response);

    final data = jsonDecode(response.body);
    return TechnicianDashboardModel.fromJson(data);
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
