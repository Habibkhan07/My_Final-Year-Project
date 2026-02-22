// lib/features/technician/onboarding/presentation/steps/animated_upload_card.dart
import 'package:flutter/material.dart';

class AnimatedUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isUploaded;
  final VoidCallback onTap;

  const AnimatedUploadCard({
    super.key,
    required this.title,
    required this.description,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? Colors.green.shade300 : Colors.grey.shade300,
          width: isUploaded ? 1.5 : 1.0,
        ),
        boxShadow: isUploaded
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Animated Icon Background
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.shade100 : Colors.white,
                  shape: BoxShape.circle,
                ),
                // AnimatedSwitcher handles the fade-in/out of the icons
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isUploaded ? Icons.check_circle : Icons.cloud_upload,
                    key: ValueKey<bool>(isUploaded), // Triggers the animation
                    color: isUploaded
                        ? Colors.green.shade700
                        : Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // CrossFade smoothly switches between the description and the success text
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: isUploaded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      secondChild: Text(
                        "Upload Complete\n(Tap to change)",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
