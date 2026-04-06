import 'package:flutter/material.dart';

/// A reusable banner to display the "Dumb UI" promo string provided by the backend.
class DiscoveryPromoBanner extends StatelessWidget {
  final String promoText;

  const DiscoveryPromoBanner({
    super.key,
    required this.promoText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            Icons.local_offer,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              promoText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
