// lib/features/technician/onboarding/presentation/steps/step_2_professional_id.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/onboarding_notifier.dart';
import 'animated_upload_card.dart';

class Step2ProfessionalId extends ConsumerWidget {
  const Step2ProfessionalId({super.key});

  Future<void> _pickImage(WidgetRef ref, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).uploadDocument(picked, type);
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
            "Professional Identity",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "This is what customers will see when they book you.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),

          AnimatedUploadCard(
            title: "Profile Picture",
            description: "A clear, professional face photo.",
            isUploaded: state.profilePictureUuid != null,
            onTap: () => _pickImage(ref, 'profile'),
          ),
          const SizedBox(height: 24),

          TextFormField(
            initialValue: state.experienceYears > 0
                ? state.experienceYears.toString()
                : '',
            decoration: InputDecoration(
              labelText: "Overall Experience (Years)",
              hintText: "e.g., 5",
              prefixIcon: const Icon(Icons.work_history_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => notifier.updatePersonalInfo(
              experienceYears: int.tryParse(val) ?? 0,
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            initialValue: state.bio,
            decoration: InputDecoration(
              labelText: "Professional Bio",
              hintText:
                  "I specialize in residential plumbing and have worked on...",
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 4,
            onChanged: (val) => notifier.updatePersonalInfo(bio: val),
          ),
        ],
      ),
    );
  }
}
