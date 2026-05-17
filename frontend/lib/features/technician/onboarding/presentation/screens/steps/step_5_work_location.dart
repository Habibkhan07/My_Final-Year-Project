import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding_notifier.dart';
import '../onboarding_work_location_picker_screen.dart';

/// Step 4 of the post-2026-05-17 onboarding wizard — work location.
///
/// (File still named ``step_5_work_location.dart`` so the diff to the
/// old skill-pricing position stays narrow; only its position in the
/// PageView matters.)
///
/// This step DOES NOT embed the map directly — the wizard's PageView
/// has a fixed slot height and the picker's bottom card would collide
/// with the wizard nav bar. Instead, the step is a slim summary card
/// that opens a fullscreen picker on tap, and shows the picked
/// address + radius when returning.
class Step5WorkLocation extends ConsumerWidget {
  const Step5WorkLocation({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final s = ref.read(onboardingProvider).requireValue;
    final result = await Navigator.of(context).push<OnboardingWorkLocationResult>(
      MaterialPageRoute(
        builder: (_) => OnboardingWorkLocationPickerScreen(
          initialLatitude: s.baseLatitude,
          initialLongitude: s.baseLongitude,
          initialAddressLabel:
              s.workAddressLabel.isEmpty ? null : s.workAddressLabel,
          initialRadiusKm: s.maxTravelRadiusKm,
        ),
      ),
    );
    if (result != null) {
      ref.read(onboardingProvider.notifier).updateWorkLocation(
            latitude: result.latitude,
            longitude: result.longitude,
            addressLabel: result.addressLabel,
            radiusKm: result.radiusKm,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider).requireValue;
    final hasLocation =
        state.baseLatitude != null && state.baseLongitude != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Where do you work from?',
            subtitle:
                'We use this to match you with customers nearby. Pin it on the map.',
          ),
          const SizedBox(height: 28),
          if (hasLocation)
            _SummaryCard(
              label: state.workAddressLabel.isNotEmpty
                  ? state.workAddressLabel
                  : '${state.baseLatitude!.toStringAsFixed(5)}, ${state.baseLongitude!.toStringAsFixed(5)}',
              radiusKm: state.maxTravelRadiusKm,
              onChange: () => _openPicker(context, ref),
            )
          else
            _PickCta(onTap: () => _openPicker(context, ref)),
        ],
      ),
    );
  }
}

class _PickCta extends StatelessWidget {
  final VoidCallback onTap;
  const _PickCta({required this.onTap});

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: _brand,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x660051AE),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick your work area',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search by name or drop a pin on the map.',
                    style: TextStyle(
                      color: Color(0xFFE6EEFB),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int radiusKm;
  final VoidCallback onChange;

  const _SummaryCard({
    required this.label,
    required this.radiusKm,
    required this.onChange,
  });

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brand, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline,
                  color: _brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR WORK AREA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF424753),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF151C24),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFD7DEEC), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Travel radius',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '$radiusKm km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Change location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brand,
                side: const BorderSide(color: _brand, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
