import 'package:flutter/material.dart';
import '../../domain/entities/discovery_entities.dart';

/// A "Dumb UI" widget representing a single technician in the discovery list.
/// All strings and formatting are dictated by the backend.
class TechnicianCard extends StatelessWidget {
  final DiscoveryTechnicianEntity technician;
  final VoidCallback onTap;

  const TechnicianCard({
    super.key,
    required this.technician,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: technician.profilePicture != null 
                    ? NetworkImage(technician.profilePicture!) 
                    : null,
                child: technician.profilePicture == null 
                    ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
              const SizedBox(width: 16.0),
              
              // Technician Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Active Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            technician.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (technician.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    
                    // Dumb UI: Subtitle (Promo or Parent Category)
                    if (technician.uiSubtitleText != null) ...[
                      Text(
                        technician.uiSubtitleText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                    ] else ...[
                      Text(
                        technician.primaryCategory,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                    ],

                    // Dumb UI: Rating & Distance
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                        const SizedBox(width: 4.0),
                        Text(
                          technician.uiRatingText,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (technician.distanceKm != null) ...[
                          const SizedBox(width: 8.0),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8.0),
                          Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2.0),
                          Text(
                            '${technician.distanceKm!.toStringAsFixed(1)} km',
                            style: theme.textTheme.bodySmall,
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Unified Money Corner: Pricing & Promos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Category or Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (technician.promoTag != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    technician.promoTag!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                              ],
                              Text(
                                technician.uiSubtitleText ?? technician.primaryCategory,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Right: The "Money Corner"
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              technician.primaryPrice,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              technician.priceContext,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
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
