import '../../domain/repositories/auth_repository.dart';
import '../../../../core/common/domain/entities/user_entity.dart';
import '../../domain/failures/auth_failure.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../data_sources/auth_local_data_source.dart';
import '../../../../core/common/errors/http_failure.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<String> requestOtp(String phone) async {
    return _guard(() => remoteDataSource.requestOtp(phone));
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    return _guard(() async {
      final model = await remoteDataSource.verifyOtp(phone, otp);
      final entity = model.toEntity();

      // Tier 1: Save Token
      if (entity.token != null) {
        await localDataSource.saveToken(entity.token!);
      }

      // Tier 2: Save Profile
      await localDataSource.saveUser(entity);

      return entity;
    });
  }

  @override
  Future<String> completeSignup(
    String firstName,
    String lastName,
    String token,
  ) async {
    return _guard(() async {
      return await remoteDataSource.completeSignup(firstName, lastName, token);
    });
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final user = await localDataSource.getUser();
    final token = await localDataSource.getToken();

    // Safety check: We only return the user if we also have their token
    if (user != null && token != null) {
      // Inject the latest token from secure storage into the entity
      return user.copyWith(token: token);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    // Server-side token invalidation FIRST, local clear regardless.
    //
    // Order: the POST must run while the token is still in storage so
    // its Authorization header authenticates. After this we always wipe
    // local state — an offline failure or 401 from a token already
    // revoked elsewhere must NOT trap the user in a logged-in shell.
    // The user always ends up at /login; the worst case on a network
    // failure is a dead Token row lingering server-side until a future
    // cleanup job (acceptable per the v1.1 deferral in AUTH_API.md).
    final token = await localDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await remoteDataSource.logout(token);
      } catch (_) {
        // Swallow — local clear below is the source of truth for
        // "is the user signed out on this device?". Server-side
        // reconciliation can happen later.
      }
    }
    await localDataSource.clearAll();
  }

  @override
  Future<void> persistUser(UserEntity user) async {
    await localDataSource.saveUser(user);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on HttpFailure catch (e) {
      switch (e.code) {
        case 'resource_conflict':
          throw UserAlreadyExists(e.message);
        case 'not_found':
          throw ResourcesExpired(e.message);
        case 'validation_error':
          throw InvalidInput(e.message, e.errors);
        case 'unauthorized':
          throw Unauthorized(e.message);
        default:
          throw ServerError(e.message);
      }
    } catch (e) {
      throw ServerError(e.toString());
    }
  }
}
