// lib/features/technician/onboarding/presentation/steps/step_1_verification.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/onboarding_notifier.dart';
import 'animated_upload_card.dart';

class Step1Verification extends ConsumerWidget {
  const Step1Verification({super.key});

  Future<void> _pickImage(WidgetRef ref, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      ref
          .read(onboardingProvider.notifier)
          .uploadDocument(picked, type);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Changed from .value! to .requireValue
    final state = ref.watch(onboardingProvider).requireValue;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Identity Verification",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "For platform security, please verify your identity.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),

          TextFormField(
            initialValue: state.cnicNumber,
            decoration: InputDecoration(
              labelText: "CNIC Number",
              hintText: "00000-0000000-0",
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 15, // Enforces the format strictness
            onChanged: (val) => notifier.updatePersonalInfo(cnic: val),
          ),
          const SizedBox(height: 8),

          AnimatedUploadCard(
            title: "CNIC (Front Side)",
            description: "Upload a clear picture of your ID.",
            isUploaded: state.cnicPictureUuid != null,
            onTap: () => _pickImage(ref, 'cnic'),
          ),
        ],
      ),
    );
  }
}
