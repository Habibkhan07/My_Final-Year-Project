import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/data_sources/auth_remote_data_source.dart';
import '../../../../core/data/local_sources/auth_local_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/request_otp_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';
import '../../../../features/technician/onboarding/presentation/providers/dependency_injection.dart'; // Source of sharedPreferencesProvider

part 'dependency_injection.g.dart';

// --- DATA LAYER PROVIDERS ---

@Riverpod(keepAlive: true)
FlutterSecureStorage flutterSecureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@Riverpod(keepAlive: true)
AuthLocalDataSource authLocalDataSource(Ref ref) {
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSource(secureStorage, prefs);
}

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRemoteDataSource(localDataSource);
}

@riverpod
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource, localDataSource);
}

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

@riverpod
RequestOtpUseCase requestOtpUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RequestOtpUseCase(repository);
}

@riverpod
VerifyOtpUseCase verifyOtpUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyOtpUseCase(repository);
}

@riverpod
CompleteSignupUseCase completeSignupUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CompleteSignupUseCase(repository);
}
