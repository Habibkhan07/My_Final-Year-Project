import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/onboarding_notifier.dart';
import '../../utils/picker_source.dart';
import 'animated_upload_card.dart';

/// Step 0 — Basics + profile picture.
///
/// Collects first / last / city plus the customer-facing profile photo.
/// The picture is captured with the FRONT camera in release builds so it's
/// always a live selfie (the only thing we trust for the picture customers
/// see when booking). Debug builds fall back to gallery so emulators stay
/// usable.
class Step0BasicInfo extends ConsumerWidget {
  const Step0BasicInfo({super.key});

  Future<void> _pickProfile(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: pickerSource(ImageSource.camera),
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (picked != null) {
      // ignore: use_build_context_synchronously
      ref.read(onboardingProvider.notifier).uploadDocument(picked, 'profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider).requireValue;
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Let\'s start with the basics',
            subtitle: 'This is the name and face customers will see.',
          ),
          const SizedBox(height: 28),

          AnimatedUploadCard(
            title: 'Profile photo',
            description: 'Take a clear selfie in good light.',
            isUploaded: state.profilePictureUuid != null,
            localPreviewPath: state.profilePicturePath,
            glyph: Icons.person_outline,
            onTap: () => _pickProfile(ref),
          ),

          const SizedBox(height: 24),
          const _SectionLabel('Your name'),
          const SizedBox(height: 10),
          _OnboardingField(
            initialValue: state.firstName,
            label: 'First name',
            icon: Icons.person_outline,
            onChanged: (v) => notifier.updatePersonalInfo(firstName: v),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _OnboardingField(
            initialValue: state.lastName,
            label: 'Last name',
            icon: Icons.person_outline,
            onChanged: (v) => notifier.updatePersonalInfo(lastName: v),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 22),
          const _SectionLabel('Where do you work'),
          const SizedBox(height: 10),
          _CityPicker(
            value: state.city,
            onChanged: (v) => notifier.updatePersonalInfo(city: v),
          ),
        ],
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _OnboardingField extends StatelessWidget {
  final String initialValue;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextCapitalization textCapitalization;

  const _OnboardingField({
    required this.initialValue,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E6EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E6EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0051AE), width: 1.5),
        ),
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _CityPicker({required this.value, required this.onChanged});

  static const _options = [
    ('LHR', 'Lahore'),
    ('KHI', 'Karachi'),
    ('ISL', 'Islamabad'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((opt) {
        final selected = opt.$1 == value;
        return ChoiceChip(
          label: Text(opt.$2),
          selected: selected,
          onSelected: (_) => onChanged(opt.$1),
          showCheckmark: false,
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF151C24),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF0051AE),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF0051AE)
                  : const Color(0xFFE3E6EF),
            ),
          ),
        );
      }).toList(),
    );
  }
}
