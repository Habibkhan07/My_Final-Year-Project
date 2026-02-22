// lib/features/technician/onboarding/presentation/steps/step_5_skill_pricing.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_notifier.dart';

class Step5SkillPricing extends ConsumerWidget {
  const Step5SkillPricing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider).value!;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    // Get only the explicitly selected skills
    final selectedSkillsList = state.selectedSkills;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Skill Experience",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedSkillsList.isEmpty
                    ? "No services selected."
                    : "Set your years of experience for your specific services.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: selectedSkillsList.length,
            itemBuilder: (context, index) {
              final skill = selectedSkillsList[index];

              // Find the name of the sub-service from the metadata to display
              String subServiceName = "Unknown Service";
              for (var s in state.services) {
                for (var sub in s.subServices) {
                  if (sub.id == skill.subServiceId) subServiceName = sub.name;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subServiceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${skill.yearsOfExperience} Years",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).primaryColor,
                        thumbColor: Theme.of(context).primaryColor,
                        overlayColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        valueIndicatorColor: Theme.of(context).primaryColor,
                      ),
                      child: Slider(
                        value: skill.yearsOfExperience.toDouble(),
                        min: 0,
                        max: 20,
                        divisions: 20,
                        label: "${skill.yearsOfExperience} years",
                        onChanged: (val) => notifier.updateSkillExperience(
                          skill.subServiceId,
                          val.toInt(),
                        ),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Beginner",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          "Master (20+)",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
