import 'package:flutter/material.dart';

/// Shown when a valid API response returns an empty list of results.
class DiscoveryEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const DiscoveryEmptyState({
    super.key,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16.0),
            Text(
              'No technicians found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              "We couldn't find anyone matching your current filters in this area.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 24.0),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
