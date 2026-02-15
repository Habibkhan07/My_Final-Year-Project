import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Required for MultipartFile
import '../../../../../core/constants.dart';
import '../models/service_model.dart';
import '../models/technician_registration_model.dart';

class TechnicianOnboardingRemoteDataSource {
  final String baseUrl = "${AppConstants.baseUrl}/technicians";

  // --- 1. METADATA: GET SERVICES ---
  Future<List<ServiceModel>> getOnboardingMetadata() async {
    final response = await http.get(
      Uri.parse('$baseUrl/onboarding/metadata/'), //
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body); //
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } else {
      throw "${response.statusCode}: Failed to load onboarding data";
    }
  }

  // --- 2. PHASE 1: UPLOAD MEDIA (Multipart) ---
  Future<String> uploadTemporaryMedia(File file, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/onboarding/upload-media/'), //
    );

    // Adding headers
    request.headers.addAll({'Authorization': 'Token $token'});

    // Adding the file stream to the request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Key expected by MediaUploadSerializer
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['uuid']; // Returning the UUID for Phase 2 storage
    } else {
      throw "${response.statusCode}: Media upload failed";
    }
  }

  // --- 3. PHASE 2: FINALIZE REGISTRATION (JSON) ---
  Future<Map<String, dynamic>> finalizeRegistration(
    TechnicianRegistrationModel registrationData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/finalize/'), //
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(registrationData.toJson()), // Uses your robust JSON keys
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body); // Returns profile_id, status, etc.
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      print("DEBUG BACKEND ERROR: $errorData");
      // Extracts the specific "uuid_error" or general error keys from backend
      final errorMessage =
          errorData['uuid_error'] ??
          errorData['error'] ??
          "Finalization failed";
      throw "${response.statusCode}: $errorMessage";
    }
  }
}
