import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../../core/constants.dart';
import '../../../../../core/common/errors/http_failure.dart'; // Import Data Exception
import '../models/service_model.dart';
import '../models/technician_registration_model.dart';

class TechnicianOnboardingRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/technicians";

  // --- 1. METADATA: GET SERVICES ---
  Future<List<ServiceModel>> getOnboardingMetadata() async {
    final response = await http.get(Uri.parse('$baseUrl/onboarding/metadata/'));

    _handleResponse(response); // Standard Check

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  // --- 2. PHASE 1: UPLOAD MEDIA (Multipart) ---
  Future<String> uploadTemporaryMedia(File file, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/onboarding/upload-media/'),
    );

    request.headers.addAll({'Authorization': 'Token $token'});
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _handleResponse(response); // Standard Check

    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['uuid'];
  }

  // --- 3. PHASE 2: FINALIZE REGISTRATION (JSON) ---
  Future<Map<String, dynamic>> finalizeRegistration(
    TechnicianRegistrationModel registrationData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/finalize/'),
      // Note: Your Django View is 'RegisterTechnicianView', ensure URL matches urls.py
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(registrationData.toJson()),
    );

    _handleResponse(response); // Standard Check

    return jsonDecode(response.body);
  }

  // --- THE PARSER LOGIC (Matches Auth Feature) ---
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body);

      // 1. Check for Standard Envelope
      if (body is Map<String, dynamic> && body.containsKey('code')) {
        throw HttpFailure(
          statusCode: response.statusCode,
          code: body['code'], // e.g., "validation_error", "not_found"
          message: body['message'] ?? 'An error occurred',
          errors: body['errors'] ?? {},
        );
      }

      // 2. Fallback
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
