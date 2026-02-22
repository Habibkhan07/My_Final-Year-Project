// lib/features/technician/onboarding/presentation/steps/step_0_basic_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_notifier.dart';

class Step0BasicInfo extends ConsumerWidget {
  const Step0BasicInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider).value!;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Basic Information",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's start with your core details.",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),

          TextFormField(
            initialValue: state.firstName,
            decoration: InputDecoration(
              labelText: "First Name",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => notifier.updatePersonalInfo(firstName: val),
          ),
          const SizedBox(height: 20),

          TextFormField(
            initialValue: state.lastName,
            decoration: InputDecoration(
              labelText: "Last Name",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => notifier.updatePersonalInfo(lastName: val),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: state.city.isEmpty ? null : state.city,
            decoration: InputDecoration(
              labelText: "City of Operation",
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'LHR', child: Text('Lahore')),
              DropdownMenuItem(value: 'KHI', child: Text('Karachi')),
              DropdownMenuItem(value: 'ISL', child: Text('Islamabad')),
            ],
            onChanged: (val) => notifier.updatePersonalInfo(city: val),
          ),
        ],
      ),
    );
  }
}
