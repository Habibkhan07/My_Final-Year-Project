import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/brand_chip.dart';
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
      // White surface matches the Profile-tab and customer-addresses
      // screens; the prior pale-blue (#F7F9FF) didn't share with
      // anything else in the app and created a faint colour boundary
      // against the bottom sheets that open from this screen.
      backgroundColor: Colors.white,
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

/// Stateful so the service-picker chip row at the bottom of the body can
/// drive the bottom-bar CTA without prop-drilling. The customer can arrive
/// here two ways:
///
///   * Service-first (Home → Category → Results → tap tech) — constructor
///     receives a non-null [serviceId] / [subServiceId]; the picker is
///     pre-selected to match but the customer can still switch if the
///     technician offers multiple skills.
///   * Tech-first ("Top Rated Near You" carousel on home) — constructor
///     params are null; the picker must be tapped before the Select Time
///     CTA enables, OR auto-picks the only chip if the tech has exactly
///     one skill (zero-friction when there's no choice to make).
///
/// Either way, `_selectedServiceId` is the source of truth from this point
/// onwards — the route params just seed it.
class _ProfileContent extends StatefulWidget {
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

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  int? _selectedServiceId;
  int? _selectedSubServiceId;

  @override
  void initState() {
    super.initState();
    // Seed order matters:
    //   1. Route-provided serviceId wins (customer browsed a category).
    //   2. Otherwise, if the tech has exactly one skill, auto-pick it
    //      so the customer never sees a "pick a service" prompt for a
    //      degenerate one-option picker.
    //   3. Otherwise leave null and let the chip row do its job.
    if (widget.serviceId != null) {
      _selectedServiceId = widget.serviceId;
      _selectedSubServiceId = widget.subServiceId;
    } else if (widget.profile.skills.length == 1) {
      final only = widget.profile.skills.first;
      _selectedServiceId = only.serviceId;
      _selectedSubServiceId = only.subServiceId;
    }
  }

  void _onSkillPicked(TechnicianSkillEntity skill) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedServiceId = skill.serviceId;
      _selectedSubServiceId = skill.subServiceId;
    });
  }

  void _showSelectTimeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectTimeSheet(
        technician: widget.profile,
        serviceId: _selectedServiceId,
        subServiceId: _selectedSubServiceId,
        promotionId: widget.promotionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final canBook = _selectedServiceId != null;

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

                      // Hero — avatar, name, rating pill. Geometry matches
                      // the Profile-tab header card (96dp avatar, 24px
                      // name, brand-blue accents) for visual continuity
                      // across customer-facing surfaces.
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0051AE)
                                      .withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profile.profilePicture != null
                                  ? Image.network(
                                      profile.profilePicture!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFFE1E9F3),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Color(0xFF0051AE),
                                      ),
                                    ),
                            ),
                          ),
                          if (profile.isActive)
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Color(0xFF151C24),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.city,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF727785),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rating + distance combined in a single pill,
                      // matching the Profile-tab badge geometry.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0051AE)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB400),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              // Stripped of the leading emoji — the icon
                              // above carries the same meaning, cleaner.
                              profile.uiRatingText.replaceAll('⭐ ', ''),
                              style: const TextStyle(
                                color: Color(0xFF0051AE),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Price card — compact horizontal layout. The
                      // 48px display price was disproportionate; 28px
                      // keeps the price prominent without dominating
                      // the rest of the profile.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0051AE)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF0051AE)
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Color(0xFF0051AE),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.primaryPrice,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF0051AE),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          profile.priceContext,
                                          style: const TextStyle(
                                            color: Color(0xFF727785),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (profile.promoTag != null)
                              Positioned(
                                top: -10,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0051AE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.promoTag!.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Service picker — replaces the bio block dropped in
                      // the 2026-05-17 onboarding refactor. Doubles as the
                      // input that drives the Select Time CTA below: until
                      // a chip is selected, the bottom bar refuses to open
                      // the time sheet. Auto-selects when the tech has
                      // exactly one skill (see _ProfileContentState.initState).
                      if (profile.skills.isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              // Section header doubles as the prompt when
                              // no service is picked yet. Typography matches
                              // the Profile-tab section labels.
                              canBook ? 'SERVICE' : 'PICK A SERVICE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Color(0xFF424753),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.skills
                                .map(
                                  (s) => BrandChip(
                                    label: s.name,
                                    icon: Icons.handyman_outlined,
                                    isSelected:
                                        s.serviceId == _selectedServiceId &&
                                            s.subServiceId ==
                                                _selectedSubServiceId,
                                    onTap: () => _onSkillPicked(s),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Info section — review count + skills-licenses
                      // placeholder. Chrome matches the Profile-tab
                      // _MenuTile so the surface reads as part of the
                      // same app. Non-functional today (no onTap); when
                      // a Reviews screen ships, just point onTap here.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  'ABOUT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Color(0xFF424753),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoListTile(
                              icon: Icons.star_border_rounded,
                              label: 'Read ${profile.reviewCount} reviews',
                            ),
                            const SizedBox(height: 10),
                            _InfoListTile(
                              icon: Icons.verified_outlined,
                              label: 'Skills & licenses',
                            ),
                          ],
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

        // Sticky bottom bar — flat white with a hairline top border.
        // The previous 40px-radius rounded top + 28px-radius button
        // didn't share geometry with anything else in the app; the
        // tighter 16px button radius matches the bottom-sheet CTAs
        // and Profile-tab sign-out button.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEF1F6), width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                // Disabled until a service is picked — the chip row above
                // is the remediation surface. Label flips to make the
                // missing requirement explicit rather than leaving the
                // customer staring at a gray button with no hint.
                onPressed:
                    canBook ? () => _showSelectTimeSheet(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0051AE),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE1E9F3),
                  disabledForegroundColor: const Color(0xFF727785),
                  elevation: canBook ? 4 : 0,
                  shadowColor:
                      const Color(0xFF0051AE).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canBook
                          ? Icons.calendar_today_rounded
                          : Icons.touch_app_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canBook ? 'Select Time' : 'Pick a service first',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top-bar icon button (back / share). The previous implementation
/// rendered `white-alpha-0.2` on a white page — invisible. New chrome
/// matches the Profile-tab brand language: pale brand wash background,
/// brand-blue border, brand-blue icon. 40dp tap target with ripple.
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0051AE).withValues(alpha: 0.06),
      shape: CircleBorder(
        side: BorderSide(
          color: const Color(0xFF0051AE).withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: const Color(0xFF0051AE), size: 18),
        ),
      ),
    );
  }
}

/// Info tile — visually identical to Profile-tab `_MenuTile`. Brand
/// wash background, inset white icon container with subtle shadow,
/// chevron trailing. Currently non-functional (no onTap wiring) —
/// kept as informational rows until the Reviews / Licenses screens
/// ship.
class _InfoListTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoListTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0051AE).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0051AE), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF151C24),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF727785),
            size: 22,
          ),
        ],
      ),
    );
  }
}
