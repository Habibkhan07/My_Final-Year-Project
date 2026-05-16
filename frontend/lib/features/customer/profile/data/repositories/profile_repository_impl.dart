import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/customer_profile_entity.dart';
import '../../domain/failures/profile_failure.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../data_sources/profile_local_data_source.dart';
import '../data_sources/profile_remote_data_source.dart';

/// Single arbitration point between remote, local cache, and secure storage
/// (token). Implements the offline-first contract for `getMe()` and the
/// strict error-pipeline mapping for `updateMe()`.
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource remote;
  final ProfileLocalDataSource local;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';

  ProfileRepositoryImpl({
    required this.remote,
    required this.local,
    required this.secureStorage,
  });

  Future<String> _requireToken() async {
    final token = await secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      throw const ProfileUnauthorizedFailure(
        'You are not signed in. Please sign in again.',
      );
    }
    return token;
  }

  @override
  Future<CustomerProfileEntity> getMe() async {
    try {
      final token = await _requireToken();
      final model = await remote.getMe(token);
      // Cache-on-success per the offline-first rule (CLAUDE.md).
      await local.cacheProfile(model);
      return model.toEntity();
    } on SocketException {
      // Offline: fall back to cache. Miss → propagate as Network failure
      // so the UI can show the offline state cleanly.
      final cached = local.getCachedProfile();
      if (cached != null) return cached.toEntity();
      throw const ProfileNetworkFailure();
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const ProfileParsingFailure();
    } on ProfileFailure {
      rethrow;
    } catch (e) {
      throw ProfileServerFailure(e.toString());
    }
  }

  @override
  Future<CustomerProfileEntity> updateMe({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final token = await _requireToken();
      final model = await remote.updateMe(
        token: token,
        firstName: firstName,
        lastName: lastName,
      );
      // Mutations refresh the cache so a subsequent cold-start GET that
      // fails offline still returns the post-edit state, not the pre.
      await local.cacheProfile(model);
      return model.toEntity();
    } on SocketException {
      // Mutations are NOT offline-tolerant — there is no write-through
      // cache. Surface a network failure so the user retries.
      throw const ProfileNetworkFailure(
        'Cannot save changes while offline. Try again when connected.',
      );
    } on HttpFailure catch (e) {
      throw _mapHttp(e);
    } on FormatException {
      throw const ProfileParsingFailure();
    } on ProfileFailure {
      rethrow;
    } catch (e) {
      throw ProfileServerFailure(e.toString());
    }
  }

  /// Maps the standard error envelope's `code` field onto the sealed
  /// domain failure hierarchy. Stays in lockstep with the codes the
  /// backend custom exception handler emits.
  ProfileFailure _mapHttp(HttpFailure e) {
    switch (e.code) {
      case 'unauthorized':
        return ProfileUnauthorizedFailure(e.message);
      case 'validation_error':
        return ProfileServerFailure(e.message, e.errors);
      default:
        return ProfileServerFailure(e.message, e.errors);
    }
  }
}
