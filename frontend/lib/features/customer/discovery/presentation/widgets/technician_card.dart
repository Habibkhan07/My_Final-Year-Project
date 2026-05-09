import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/discovery_entities.dart';

/// A "Dumb UI" widget representing a single technician in the discovery list.
/// Restored to the original layout structure with refined production styling.
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture with status ring
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F9),
                        shape: BoxShape.circle,
                        image: technician.profilePicture != null
                            ? DecorationImage(
                                image: NetworkImage(technician.profilePicture!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: technician.profilePicture == null
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFFC2C6D6),
                              size: 30,
                            )
                          : null,
                    ),
                    if (technician.isActive)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16.0),

                // Technician Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Row
                      Text(
                        technician.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF151C24),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),

                      // Subtitle (Promo or Category) - Dumb UI
                      Text(
                        technician.uiSubtitleText ?? technician.primaryCategory,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: technician.uiSubtitleText != null
                              ? const Color(0xFF0051AE)
                              : const Color(0xFF424753),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6.0),

                      // Rating & Distance Row
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFB400),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            technician.uiRatingText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF151C24),
                            ),
                          ),
                          if (technician.distanceKm != null) ...[
                            const SizedBox(width: 8.0),
                            Text(
                              '•',
                              style: TextStyle(
                                color: const Color(0xFFC2C6D6).withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF424753),
                            ),
                            const SizedBox(width: 2.0),
                            Text(
                              '${technician.distanceKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF424753),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Bottom Row: Category Label & Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left: Promo Tag or Category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (technician.promoTag != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0051AE,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      technician.promoTag!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0051AE),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  technician.primaryCategory.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: const Color(
                                      0xFF424753,
                                    ).withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Right: Price Corner
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                technician.primaryPrice,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0051AE),
                                ),
                              ),
                              Text(
                                technician.priceContext.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: const Color(
                                    0xFF424753,
                                  ).withOpacity(0.6),
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
      ),
    );
  }
}
