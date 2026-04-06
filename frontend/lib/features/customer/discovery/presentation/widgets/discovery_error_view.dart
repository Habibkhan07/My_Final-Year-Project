import 'package:flutter/material.dart';
import '../../domain/failures/discovery_failure.dart';

/// A reusable error view that maps specific [DiscoveryFailure] sealed classes
/// to user-friendly UI messages and provides a retry mechanism.
class DiscoveryErrorView extends StatelessWidget {
  final DiscoveryFailure failure;
  final VoidCallback onRetry;

  const DiscoveryErrorView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Pattern match the sealed class to get specific UI representations
    final (icon, title, message) = switch (failure) {
      DiscoveryNetworkFailure() => (
          Icons.wifi_off_rounded,
          'No Internet Connection',
          failure.message,
        ),
      DiscoveryServerFailure() => (
          Icons.dns_rounded,
          'Server Error',
          failure.message,
        ),
      DiscoveryValidationFailure() => (
          Icons.error_outline_rounded,
          'Validation Error',
          failure.message,
        ),
      DiscoveryUnauthorizedFailure() => (
          Icons.lock_outline_rounded,
          'Unauthorized',
          failure.message,
        ),
      DiscoveryNotFoundFailure() => (
          Icons.search_off_rounded,
          'Not Found',
          failure.message,
        ),
      DiscoveryUnexpectedFailure() => (
          Icons.warning_amber_rounded,
          'Something went wrong',
          failure.message,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
