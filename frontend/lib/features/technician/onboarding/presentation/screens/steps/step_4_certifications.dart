import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/onboarding_notifier.dart';
import '../../utils/picker_source.dart';
import 'animated_upload_card.dart';

/// Step 3 of the post-2026-05-17 onboarding wizard — trade certifications.
///
/// (File still named ``step_4_certifications.dart`` so the diff stays
/// narrow; only its position in the PageView matters.)
///
/// One upload slot per parent service the tech picked a skill under.
/// Licenses are OPTIONAL — the category-gate uses license-row existence,
/// not license-picture presence — so the picker is purely a
/// "send your proofs if you have them" affordance. Captured with the
/// BACK camera in release builds.
class Step4Certifications extends ConsumerWidget {
  const Step4Certifications({super.key});

  Future<void> _pickLicense(WidgetRef ref, int serviceId) async {
    final picked = await ImagePicker().pickImage(
      source: pickerSource(ImageSource.camera),
      preferredCameraDevice: CameraDevice.rear,
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
    final state = ref.watch(onboardingProvider).requireValue;
    final selectedIds = state.selectedSkills.map((s) => s.subServiceId).toSet();

    final requiredServices = state.services.where((service) {
      return service.subServices.any((sub) => selectedIds.contains(sub.id));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepHeader(
                title: 'Show your credentials',
                subtitle:
                    'Photos of your licenses help customers trust you. Optional, but recommended.',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFB45309),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Skip any you don\'t have right now — you can upload them later from your profile.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8A5D00),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: requiredServices.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: requiredServices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final service = requiredServices[idx];
                    final hasLicense = state.categoryLicenses.any(
                      (l) => l.serviceId == service.id,
                    );
                    final localPath = state.categoryLicensePaths[service.id];

                    return AnimatedUploadCard(
                      title: '${service.name} license',
                      description: 'Tap to upload a photo of your license.',
                      glyph: Icons.workspace_premium_outlined,
                      isUploaded: hasLicense,
                      localPreviewPath: localPath,
                      onTap: () => _pickLicense(ref, service.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 32, color: Color(0xFF9AA3B2)),
            SizedBox(height: 12),
            Text(
              'Pick at least one service in the previous step to see your license slots here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF151C24),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
