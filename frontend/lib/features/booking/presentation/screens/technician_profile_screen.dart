import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking_entities.dart';
import '../providers/technician_profile_notifier.dart';
import '../widgets/select_time_sheet.dart';

/// Screen displaying the technician's profile detail.
///
/// Fully driven by [TechnicianProfileNotifier] to fetch Context-Aware
/// pricing and "Dumb UI" formatted strings from the backend.
class TechnicianProfileScreen extends ConsumerWidget {
  final int technicianId;
  final double? lat;
  final double? lng;
  final int? serviceId;
  final int? subServiceId;
  final int? promotionId;

  const TechnicianProfileScreen({
    super.key,
    required this.technicianId,
    this.lat,
    this.lng,
    this.serviceId,
    this.subServiceId,
    this.promotionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      technicianProfileProvider(
        id: technicianId,
        lat: lat,
        lng: lng,
        serviceId: serviceId,
        subServiceId: subServiceId,
        promotionId: promotionId,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: profileAsync.when(
        data: (profile) => _ProfileContent(
          profile: profile,
          serviceId: serviceId,
          subServiceId: subServiceId,
          promotionId: promotionId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load profile.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final TechnicianProfileEntity profile;
  final int? serviceId;
  final int? subServiceId;
  final int? promotionId;

  const _ProfileContent({
    required this.profile,
    this.serviceId,
    this.subServiceId,
    this.promotionId,
  });

  void _showSelectTimeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectTimeSheet(
        technician: profile,
        serviceId: serviceId,
        subServiceId: subServiceId,
        promotionId: promotionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                  child: Column(
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _HeaderButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context),
                            ),
                            _HeaderButton(icon: Icons.share, onTap: () {}),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Hero Section
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0051AE,
                                  ).withOpacity(0.1),
                                  blurRadius: 24,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profile.profilePicture != null
                                  ? Image.network(
                                      profile.profilePicture!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey.shade300),
                            ),
                          ),
                          if (profile.isActive)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Color(0xFF151C24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0051AE).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF0051AE).withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.uiRatingText.replaceAll(
                                '⭐ ',
                                '',
                              ), // Pre-formatted
                              style: const TextStyle(
                                color: Color(0xFF0051AE),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Price Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0051AE,
                                ).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    profile.primaryPrice,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      color: Color(0xFF0051AE),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.priceContext,
                                    style: const TextStyle(
                                      color: Color(0xFF424753),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (profile.promoTag != null)
                              Positioned(
                                top: -12,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0051AE),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      profile.promoTag!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Info List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _InfoListTile(
                              icon: Icons.star_border,
                              label: 'Read ${profile.reviewCount} Reviews',
                            ),
                            const SizedBox(height: 16),
                            _InfoListTile(
                              icon: Icons.verified_outlined,
                              label: 'Skills & Licenses',
                            ),
                            const SizedBox(height: 16),
                            _InfoListTile(
                              icon: Icons.person_outline,
                              label: 'About Me',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          profile.bio,
                          style: const TextStyle(
                            color: Color(0xFF424753),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),

                      // Padding for sticky bottom bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Sticky Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            child: ElevatedButton(
              onPressed: () => _showSelectTimeSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: const Color(0xFF0051AE).withOpacity(0.4),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Select Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF151C24)),
      ),
    );
  }
}

class _InfoListTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoListTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0051AE)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF151C24),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFC2C6D6)),
        ],
      ),
    );
  }
}
