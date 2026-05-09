import 'package:flutter/material.dart';

/// Standard loading state for any map-based screen.
class AppMapSkeleton extends StatelessWidget {
  final double bottomCardHeight;

  const AppMapSkeleton({super.key, this.bottomCardHeight = 240});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map placeholder
        Container(color: const Color(0xFFE8EAF0)),

        // Bottom card skeleton
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: bottomCardHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE3EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 16,
                  width: 200,
                  color: const Color(0xFFF0F3F9),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: 140,
                  color: const Color(0xFFF0F3F9),
                ),
              ],
            ),
          ),
        ),

        // Back button placeholder
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard error state for any map-based screen.
class AppMapErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppMapErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
