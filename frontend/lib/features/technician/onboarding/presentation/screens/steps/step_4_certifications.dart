// lib/features/technician/onboarding/presentation/steps/step_4_certifications.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/onboarding_notifier.dart';
import 'animated_upload_card.dart';

class Step4Certifications extends ConsumerWidget {
  const Step4Certifications({super.key});

  Future<void> _pickLicense(WidgetRef ref, int serviceId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      ref
          .read(onboardingProvider.notifier)
          .uploadDocument(picked, 'license', serviceId: serviceId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Changed from .value! to .requireValue
    final state = ref.watch(onboardingProvider).requireValue;

    // SMART LOGIC: Only find Parent Services where the user selected at least one sub-service
    final requiredServices = state.services.where((service) {
      return service.subServices.any(
        (sub) => state.selectedSkills.any((s) => s.subServiceId == sub.id),
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trade Certifications",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                requiredServices.isEmpty
                    ? "Please go back and select at least one service."
                    : "Upload general licenses for the trades you selected. (Optional but recommended)",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: requiredServices.length,
            itemBuilder: (context, index) {
              final service = requiredServices[index];
              final hasLicense = state.categoryLicenses.any(
                (l) => l.serviceId == service.id,
              );

              return AnimatedUploadCard(
                title: "${service.name} License",
                description:
                    "Upload your general certification for ${service.name}.",
                isUploaded: hasLicense,
                onTap: () => _pickLicense(ref, service.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
