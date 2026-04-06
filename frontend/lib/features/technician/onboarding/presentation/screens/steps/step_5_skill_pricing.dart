// lib/features/technician/onboarding/presentation/steps/step_5_skill_pricing.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_notifier.dart';
import '../../../domain/entities/service_entity.dart';

class Step5SkillPricing extends ConsumerWidget {
  const Step5SkillPricing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Changed from onboardingNotifierProvider to onboardingProvider to match generated code
    final state = ref.watch(onboardingProvider).requireValue;
    final notifier = ref.read(onboardingProvider.notifier);

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
                "Experience & Pricing",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedSkillsList.isEmpty
                    ? "No services selected."
                    : "Set your experience and labor rates for your specific services.",
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

              // Find the sub-service metadata.
              // Uses a separate mutable `found` variable so that the final
              // `metadata` binding is definitively non-nullable — Dart's flow
              // analysis can struggle to narrow a mutable loop-assigned variable
              // even after a null-check return.
              SubServiceEntity? found;
              outer:
              for (final s in state.services) {
                for (final sub in s.subServices) {
                  if (sub.id == skill.subServiceId) {
                    found = sub;
                    break outer;
                  }
                }
              }

              if (found == null) return const SizedBox.shrink();
              final metadata = found;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                            metadata.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                    const Text(
                      "Years of Experience",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Slider(
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
                    const Divider(height: 32),
                    const Text(
                      "Your Labor Rates (PKR)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata.maxPrice != null
                          ? "Platform Range: Rs. ${metadata.basePrice} - Rs. ${metadata.maxPrice}"
                          : "Fixed Rate: Rs. ${metadata.basePrice}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _RateInput(
                            label: "Base Rate",
                            initialValue: skill.baseRate ?? metadata.basePrice,
                            hint: metadata.basePrice,
                            onChanged: (val) => notifier.updateSkillRates(
                              skill.subServiceId,
                              baseRate: val,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RateInput(
                            label: "Max Rate",
                            // When maxPrice is null the sub-service is fixed-rate; default the max to basePrice
                            initialValue: skill.maxRate ?? metadata.maxPrice ?? metadata.basePrice,
                            hint: metadata.maxPrice ?? metadata.basePrice,
                            onChanged: (val) => notifier.updateSkillRates(
                              skill.subServiceId,
                              maxRate: val,
                            ),
                          ),
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

class _RateInput extends StatelessWidget {
  final String label;
  final String initialValue;
  final String hint;
  final Function(String) onChanged;

  const _RateInput({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue == hint ? null : initialValue,
          decoration: InputDecoration(
            hintText: "Rs. $hint",
            prefixText: "Rs. ",
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
