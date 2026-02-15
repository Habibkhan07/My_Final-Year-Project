import 'dart:io';
import '../repositories/technician_onboarding_repository.dart';

class UploadMediaUseCase {
  final TechnicianRepository repository;

  UploadMediaUseCase(this.repository);

  Future<String> execute(File file, String token) {
    return repository.uploadMedia(file, token);
  }
}
