import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/service_entity.dart';
import '../../providers/onboarding_notifier.dart';

/// Step 2 of the post-2026-05-17 onboarding wizard — trade selection.
///
/// (File still named ``step_3_primary_trade.dart`` so the diff stays
/// narrow; the position in the main screen's PageView is what matters.)
///
/// Bridge row is pure membership after the refactor — no per-skill
/// labor rate or experience years to collect. The picker is purely
/// "what tasks can you do?".
class Step3PrimaryTrade extends ConsumerWidget {
  const Step3PrimaryTrade({super.key});

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider).requireValue;
    final notifier = ref.read(onboardingProvider.notifier);
    final selectedIds = state.selectedSkills.map((s) => s.subServiceId).toSet();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: _StepHeader(
            title: 'What services do you offer?',
            subtitle:
                'Pick every task you can take on. You can add more later from your profile.',
          ),
        ),
        if (selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _brand, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${selectedIds.length} selected',
                    style: const TextStyle(
                      color: _brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: state.services.length,
            itemBuilder: (context, idx) {
              final service = state.services[idx];
              final hasSelection = service.subServices.any(
                (sub) => selectedIds.contains(sub.id),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasSelection ? _brand : const Color(0xFFE3E6EF),
                    width: hasSelection ? 1.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ExpansionTile(
                    initiallyExpanded: hasSelection,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF151C24),
                      ),
                    ),
                    subtitle: Text(
                      _selectedSummary(service, selectedIds),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasSelection
                            ? _brand
                            : const Color(0xFF6B7280),
                        fontWeight: hasSelection
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    children: service.subServices.map((sub) {
                      final isSelected = selectedIds.contains(sub.id);
                      return InkWell(
                        onTap: () => notifier.toggleSkill(sub.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              _Checkbox(value: isSelected),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  sub.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF151C24),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _selectedSummary(ServiceEntity service, Set<int> selectedIds) {
    final total = service.subServices.length;
    final count = service.subServices
        .where((sub) => selectedIds.contains(sub.id))
        .length;
    if (count == 0) {
      // ``subServices`` is a list of tasks under the parent service —
      // "services" in this copy would be confusing.
      return total == 1 ? '1 task available' : '$total tasks available';
    }
    return count == 1 ? '1 selected' : '$count selected';
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;
  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? const Color(0xFF0051AE) : Colors.white,
        border: Border.all(
          color: value ? const Color(0xFF0051AE) : const Color(0xFFC2C6D6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: value
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
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
