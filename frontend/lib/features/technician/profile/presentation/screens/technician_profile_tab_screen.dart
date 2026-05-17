import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../customer/profile/domain/entities/customer_profile_entity.dart';
import '../../../../customer/profile/domain/failures/profile_failure.dart';
import '../../../../customer/profile/presentation/providers/profile_notifier.dart';
import '../../../dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import '../providers/skills_notifier.dart';

/// The technician profile tab — pushed when the bottom-nav Profile
/// tab is tapped from the technician dashboard.
///
/// Visual language intentionally mirrors `ProfileTabScreen` on the
/// customer side: same brand-blue (#0051AE) tile chrome, same header
/// card geometry, same section ordering. The chip text flips to
/// "TECHNICIAN" and the destination list is tech-specific (skills,
/// work location, wallet, customer-mode switch) — everything else
/// is visually identical so the two surfaces feel of-a-piece.
///
/// Identity (name/phone) is fed by the SAME `profileProvider` the
/// customer screen uses — `/api/accounts/me/` is role-agnostic. The
/// edit screen is also reused as-is (push to `/customer/profile/edit`).
class TechnicianProfileTabScreen extends ConsumerWidget {
  const TechnicianProfileTabScreen({super.key});

  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);
  static const Color _mutedText = Color(0xFF727785);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _titleText,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => _ProfileBody(profile: profile),
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _brandBlue)),
          error: (error, _) => _ErrorState(
            error: error,
            onRetry: () => ref.read(profileProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — header + ACCOUNT + ABOUT + sign-out + version footer
// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final CustomerProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Profile picture is owned by the technician dashboard payload — the
    // /me endpoint is role-agnostic and doesn't surface it. The dashboard
    // notifier is keepAlive + boot-warmed for techs, so reading it here is
    // a synchronous cache hit in practice. Null while the dashboard hasn't
    // resolved yet (or for techs with no uploaded picture) → fall back to
    // initials, matching the customer profile screen's default avatar.
    final profilePictureUrl = ref.watch(
      technicianDashboardProvider.select(
        (async) => async.value?.dashboard.profilePicture,
      ),
    );

    return RefreshIndicator(
      color: TechnicianProfileTabScreen._brandBlue,
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(profile: profile, profilePictureUrl: profilePictureUrl),
            const SizedBox(height: 28),
            const _SectionHeader('Account'),
            const SizedBox(height: 12),
            const _MySkillsTile(),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.place_outlined,
              label: 'Work Location',
              onTap: () => context.push('/technician/work-location'),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () => context.push('/technician/wallet'),
            ),
            const SizedBox(height: 10),
            // Customer Mode — mirrors the customer profile's
            // "Technician Mode" tile placement. The auth user is the
            // same person; this just routes them back to the customer
            // shell. is_technician stays true; the tile is always
            // available.
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: 'Customer Mode',
              onTap: () => context.go('/home'),
            ),
            const SizedBox(height: 28),
            const _SectionHeader('About'),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'About Karigar',
              // Reuses the customer-side static screen. The content
              // is brand-neutral; the route name is mis-scoped but
              // refactoring it is out of scope for this slice (see
              // flag.md proposal).
              onTap: () => context.push('/customer/about'),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.description_outlined,
              label: 'Terms & Privacy',
              onTap: () => context.push('/customer/legal'),
            ),
            const SizedBox(height: 32),
            const _SignOutButton(),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Karigar  ·  v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: TechnicianProfileTabScreen._mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header card — tap → edit screen (reuses customer EditProfileScreen)
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile, this.profilePictureUrl});

  final CustomerProfileEntity profile;
  final String? profilePictureUrl;

  String get _fullName {
    final first = profile.firstName?.trim() ?? '';
    final last = profile.lastName?.trim() ?? '';
    final joined = [first, last].where((s) => s.isNotEmpty).join(' ');
    return joined.isEmpty ? 'Add your name' : joined;
  }

  String get _initials {
    final first = profile.firstName;
    final last = profile.lastName;
    final fi = (first != null && first.isNotEmpty) ? first[0] : '';
    final li = (last != null && last.isNotEmpty) ? last[0] : '';
    final combined = '$fi$li'.toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }

  @override
  Widget build(BuildContext context) {
    final hasName = (profile.firstName?.isNotEmpty ?? false) ||
        (profile.lastName?.isNotEmpty ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/customer/profile/edit'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TechnicianProfileTabScreen._brandBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TechnicianProfileTabScreen._brandBlue
                  .withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(
                profilePictureUrl: profilePictureUrl,
                initials: _initials,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: hasName
                            ? TechnicianProfileTabScreen._titleText
                            : TechnicianProfileTabScreen._mutedText,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: TechnicianProfileTabScreen._bodyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TechnicianProfileTabScreen._brandBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TECHNICIAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TechnicianProfileTabScreen._mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular avatar used inside the profile header card. Prefers the
/// uploaded profile picture (sourced from the technician dashboard
/// payload — see `_ProfileBody.build`) and falls back to a brand-blue
/// initials circle when the URL is null / loads fail / dashboard
/// hasn't resolved yet. The two states share the same 56px geometry
/// so the header doesn't reflow during the network swap.
class _Avatar extends StatelessWidget {
  const _Avatar({this.profilePictureUrl, required this.initials});

  final String? profilePictureUrl;
  final String initials;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final url = profilePictureUrl;
    if (url == null || url.isEmpty) return _fallback();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _fallback(),
        errorWidget: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    width: _size,
    height: _size,
    decoration: const BoxDecoration(
      color: TechnicianProfileTabScreen._brandBlue,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Section header + standard menu tile — visual mirror of customer profile
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: TechnicianProfileTabScreen._bodyText,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Optional widget rendered before the trailing chevron — used by
  /// `_MySkillsTile` to show a skill-count badge. When null, the
  /// chevron stands alone (the default for all other tiles).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TechnicianProfileTabScreen._brandBlue.withValues(alpha: 0.04),
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
                child: Icon(
                  icon,
                  color: TechnicianProfileTabScreen._brandBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TechnicianProfileTabScreen._titleText,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: TechnicianProfileTabScreen._mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Skills tile — same chrome as _MenuTile but with a count badge
// ---------------------------------------------------------------------------

/// Renders the same visual chrome as `_MenuTile`, but with a small
/// "N" badge before the chevron showing the technician's skill count.
/// The badge reads from `skillsProvider` — which is `keepAlive: true`
/// — so it stays in lockstep with the My Skills screen without a
/// second round-trip.
///
/// The provider fires its `build()` lazily on first watch, so opening
/// the Profile tab triggers a `GET /me/skills/` in the background.
/// During the load window we render nothing in the trailing slot
/// (the chevron alone) — flashing a 0 → real-number transition
/// would feel buggy.
class _MySkillsTile extends ConsumerWidget {
  const _MySkillsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(skillsProvider).value?.length;

    return _MenuTile(
      icon: Icons.construction_outlined,
      label: 'My Skills',
      onTap: () => context.push('/technician/profile/skills'),
      trailing: count == null ? null : _CountBadge(count: count),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TechnicianProfileTabScreen._brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: TechnicianProfileTabScreen._brandBlue,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-out — same dialog + same auth notifier teardown as customer
// ---------------------------------------------------------------------------

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again with your phone number.',
          style: TextStyle(color: TechnicianProfileTabScreen._bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: TechnicianProfileTabScreen._bodyText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmAndSignOut(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.5),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state — Unauthorized forces sign-out (matches customer pattern)
// ---------------------------------------------------------------------------

class _ErrorState extends ConsumerStatefulWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  ConsumerState<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends ConsumerState<_ErrorState> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    if (error is ProfileUnauthorizedFailure) {
      if (!_loggingOut) {
        _loggingOut = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(authProvider.notifier).logout();
        });
      }
      return const Center(
        child: CircularProgressIndicator(
          color: TechnicianProfileTabScreen._brandBlue,
        ),
      );
    }

    String message = 'Could not load your profile.';
    if (error is ProfileFailure) message = error.message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: TechnicianProfileTabScreen._bodyText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TechnicianProfileTabScreen._brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
