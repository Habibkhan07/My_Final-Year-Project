import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/onboarding_notifier.dart';
import '../../utils/picker_source.dart';
import 'animated_upload_card.dart';

/// Step 1 — Identity verification.
///
/// CNIC number + a photo of the CNIC's front side. The CNIC text field
/// auto-inserts the two hyphens of the ``00000-0000000-0`` format so the
/// tech only types the 13 digits — manual dashes were the #1 source of
/// "invalid format" errors in production. The image is captured with the
/// BACK camera in release builds (no selfie of an ID); debug builds fall
/// back to gallery for emulator-friendly testing.
class Step1Verification extends ConsumerWidget {
  const Step1Verification({super.key});

  Future<void> _pickCnic(WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: pickerSource(ImageSource.camera),
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 80,
    );
    if (picked != null) {
      ref.read(onboardingProvider.notifier).uploadDocument(picked, 'cnic');
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
            title: 'Verify your identity',
            subtitle:
                'We need your CNIC to confirm who you are. This stays private.',
          ),
          const SizedBox(height: 28),

          _SectionLabel('CNIC number'),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: state.cnicNumber,
            keyboardType: TextInputType.number,
            inputFormatters: [_CnicFormatter()],
            onChanged: (val) => notifier.updatePersonalInfo(cnic: val),
            decoration: InputDecoration(
              hintText: '00000-0000000-0',
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF6B7280),
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF0051AE),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel('CNIC photo (front side)'),
          const SizedBox(height: 10),
          AnimatedUploadCard(
            title: 'CNIC front',
            description: 'Hold steady, fit the card fully in the frame.',
            glyph: Icons.credit_card_outlined,
            isUploaded: state.cnicPictureUuid != null,
            localPreviewPath: state.cnicPicturePath,
            onTap: () => _pickCnic(ref),
          ),
        ],
      ),
    );
  }
}

/// Auto-inserts the two hyphens of the Pakistani CNIC format
/// (``XXXXX-XXXXXXX-X``) as the user types digits. Accepts a pasted
/// already-dashed string by stripping non-digits first.
///
/// Cursor handling: rather than tracking column-by-column edits we
/// rebuild the formatted string each time and place the cursor at the
/// end of the input. CNIC entry is a small, append-only flow — the
/// simpler invariant is more reliable than precise cursor preservation.
class _CnicFormatter extends TextInputFormatter {
  static const _maxDigits = 13;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;

    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 5 || i == 12) buf.write('-');
      buf.write(trimmed[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
