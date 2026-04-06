import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart';
import '../models/search_result_model.dart';

class SearchRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/catalog/search";

  Future<List<SearchResultModel>> getSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/?q=$query'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((json) => SearchResultModel.fromJson(json)).toList();
    }

    // Standard Error Handling
    try {
      final body = jsonDecode(response.body);
      throw HttpFailure(
        statusCode: response.statusCode,
        code: body['code'] ?? 'server_error',
        message: body['message'] ?? 'An error occurred during search',
        errors: body['errors'] ?? {},
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
