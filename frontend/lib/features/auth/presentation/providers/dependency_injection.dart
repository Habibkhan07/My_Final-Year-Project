import 'package:flutter_riverpod/flutter_riverpod.dart';

// ../ moves up to 'presentation'
// ../../ moves up to 'auth'
// ../../../ moves up to 'features' (if needed)

import '../../data/data_sources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/use_cases/request_otp_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';
// --- DATA LAYER PROVIDERS ---

// 1. Provide the Raw Data Source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

// 2. Provide the Repository Implementation
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// --- DOMAIN LAYER PROVIDERS (Use Cases) ---

// 3. Provide the Request OTP Use Case
final requestOtpUseCaseProvider = Provider<RequestOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RequestOtpUseCase(repository);
});

// 4. Provide the Verify OTP Use Case
final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyOtpUseCase(repository);
});

// dependency_injection.dart

// 5. Provide the Complete Signup Use Case
final completeSignupUseCaseProvider = Provider<CompleteSignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CompleteSignupUseCase(repository);
});
