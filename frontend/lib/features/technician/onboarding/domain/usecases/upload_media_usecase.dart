import '../repositories/technician_onboarding_repository.dart';
import 'package:image_picker/image_picker.dart'; // ADD THIS IMPORT

class UploadMediaUseCase {
  final TechnicianRepository repository;

  UploadMediaUseCase(this.repository);

  Future<String> execute(XFile file, String token) {
    return repository.uploadMedia(file, token);
  }
}
