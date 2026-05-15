import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/technician_entity.dart';
import '../providers/technician_status_provider.dart';

/// Final screen of the onboarding wizard. Shown once after a successful
/// `finalize_registration` call.
///
/// On "Continue" we **invalidate the technician status provider** before
/// navigating so the router's redirect picks up the freshly-created
/// `TechnicianStatusPending` instead of the stale `NoProfile` cached
/// before finalize. Without this invalidate the user would land on the
/// customer home for one frame, then flick over to /technician/pending
/// once the next read of the provider re-fetches.
class RegistrationSuccessScreen extends ConsumerWidget {
  final TechnicianEntity technician;

  const RegistrationSuccessScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. SUCCESS ANIMATION / ICON
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // 2. HEADLINE
              Text(
                "Application Received!",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Thanks, ${technician.fullName}. Your profile is now under review.",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // 3. RECEIPT CARD (Shows real data from backend)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildRow("Application ID", "#${technician.profileId}"),
                    const Divider(height: 24),
                    _buildRow(
                      "Current Status",
                      technician.status.toUpperCase(),
                      isStatus: true,
                    ),
                    const Divider(height: 24),
                    _buildRow(
                      "Date Submitted",
                      _formatDate(technician.joinedDate),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. CONTINUE BUTTON — drops the stale "NoProfile" status
              // cached before finalize so the router redirect picks up
              // `Pending` on the next read. We send the user directly to
              // /technician/pending instead of /home to avoid a one-frame
              // flicker through the customer surface.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.invalidate(technicianStatusProvider);
                    context.go('/technician/pending');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        isStatus
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return isoString;
    }
  }
}
