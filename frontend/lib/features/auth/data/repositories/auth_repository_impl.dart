import '../../../../core/common/domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> requestOtp(String phone) async {
    try {
      // 1. Guard against obvious local errors before calling the API
      if (phone.length < 10) {
        throw 'The phone number is too short. Please check and try again.';
      }

      return await remoteDataSource.requestOtp(phone);
    } catch (e) {
      // 2. Map low-level exceptions to human-readable domain failures
      throw _handleError(e);
    }
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    try {
      final userModel = await remoteDataSource.verifyOtp(phone, otp);
      return userModel.toEntity();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Inside AuthRepositoryImpl class

  @override
  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  ) async {
    try {
      // 1. Client-Side Guard: Immediate feedback if names are empty
      if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
        throw 'First and last names are required.';
      }

      // 2. Call Data Source: Pass values to the remote API
      final result = await remoteDataSource.completeSignup(
        firstName,
        lastName,
        token,
      );

      return result; // Returns the success message (e.g., "Profile updated successfully.")
    } catch (e) {
      // 3. Professional Propagation: Maps backend 400/500 errors to human strings
      throw _handleError(e);
    }
  }

  /// Helper to convert technical errors into user-friendly messages
  // auth_repository_impl.dart

  String _handleError(dynamic e) {
    // If we threw a local string guard (like "Too short"), pass it through
    if (e is String) return e;

    final errorString = e.toString();

    // 1. Handle Network Connectivity
    if (errorString.contains('SocketException')) {
      return 'Check your internet connection.';
    }

    // 2. Handle Structured Server Errors
    // We look for the message we formatted in the Data Source: "CODE: MESSAGE"
    if (errorString.contains(':')) {
      final parts = errorString.split(':');
      final code = parts[0].trim();
      final message = parts[1].trim();

      if (code.contains('400') || code.contains('401')) {
        return message; // This will now return "Invalid OTP"
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
