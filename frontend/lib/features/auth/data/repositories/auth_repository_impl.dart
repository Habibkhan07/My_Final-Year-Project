import '../../domain/repositories/auth_repository.dart';
import '../../../../core/common/domain/entities/user_entity.dart';
import '../../domain/failures/auth_failure.dart'; // Import Sealed Class
import '../data_sources/auth_remote_data_source.dart';
import '../../../../core/common/errors/http_failure.dart'; // Import Data Exception

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> requestOtp(String phone) async {
    return _guard(() => remoteDataSource.requestOtp(phone));
  }

  // OPTIMIZED (Catches mapping errors too)
  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    return _guard(() async {
      final model = await remoteDataSource.verifyOtp(phone, otp);
      return model.toEntity();
    });
  }

  @override
  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  ) async {
    return _guard(
      () => remoteDataSource.completeSignup(firstName, lastName, token),
    );
  }

  // --- THE MAPPING LOGIC ---
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on HttpFailure catch (e) {
      // Map Backend Codes -> Domain Failures
      switch (e.code) {
        case 'resource_conflict': // 409
          throw UserAlreadyExists(e.message);

        case 'not_found': // 404
          throw ResourcesExpired(e.message);

        case 'validation_error': // 400
          throw InvalidInput(e.errors);

        case 'unauthorized': // 401
          throw Unauthorized(e.message);

        default:
          throw ServerError(e.message);
      }
    } catch (e) {
      // Catch-all for other errors (SocketException, parsing, etc.)
      throw ServerError(e.toString());
    }
  }
}
