// lib/features/technician/onboarding/presentation/steps/step_3_primary_trade.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_notifier.dart';

class Step3PrimaryTrade extends ConsumerWidget {
  const Step3PrimaryTrade({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider).value!;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Your Services",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose the specific tasks you are qualified to perform.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.services.length,
            itemBuilder: (context, index) {
              final service = state.services[index];

              // Only expand if they have something selected in this category
              final hasSelection = service.subServices.any(
                (sub) =>
                    state.selectedSkills.any((s) => s.subServiceId == sub.id),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: hasSelection
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: hasSelection,
                  shape:
                      const Border(), // Removes the default borders on expansion
                  title: Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  children: service.subServices.map((sub) {
                    final isSelected = state.selectedSkills.any(
                      (s) => s.subServiceId == sub.id,
                    );

                    return CheckboxListTile(
                      title: Text(
                        sub.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        "Base Price: \$${sub.basePrice}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                      activeColor: Theme.of(context).primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isSelected,
                      onChanged: (_) => notifier.toggleSkill(sub.id),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
