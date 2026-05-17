import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Prompts the technician to set their work area when [hasWorkLocation] is
/// false. While unset, the matchmaker's bounding-box filter silently excludes
/// this technician from every customer search — the banner is the only path
/// that surfaces that fact.
///
/// Once the work area is set, the banner renders nothing — editing happens
/// from Profile → Work Location, which keeps the dashboard focused on jobs +
/// status and avoids surfacing the same affordance twice.
///
/// Visual language: blue "primary action" card that matches the customer
/// addresses picker confirm button (#0051AE), per
/// [[feedback_ui_target_foodpanda]]'s direction to mirror the booking flow's
/// existing ElevatedButton brand blue.
class WorkLocationBanner extends StatelessWidget {
  final bool hasWorkLocation;

  const WorkLocationBanner({super.key, required this.hasWorkLocation});

  @override
  Widget build(BuildContext context) {
    if (hasWorkLocation) return const SizedBox.shrink();
    return _UnsetLocationCallToAction(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/technician/work-location');
      },
    );
  }
}

class _UnsetLocationCallToAction extends StatelessWidget {
  final VoidCallback onTap;
  const _UnsetLocationCallToAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0051AE), Color(0xFF0046AC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0051AE).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_searching,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set your work area',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Customers can\'t find you until you pick a location.',
                        style: TextStyle(
                          color: Color(0xFFE6EEFB),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
