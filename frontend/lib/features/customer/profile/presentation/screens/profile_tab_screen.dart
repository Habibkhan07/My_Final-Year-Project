import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../technician/onboarding/domain/entities/technician_status.dart';
import '../../../../technician/onboarding/presentation/providers/technician_status_provider.dart';
import '../../domain/entities/customer_profile_entity.dart';
import '../../domain/failures/profile_failure.dart';
import '../providers/profile_notifier.dart';

/// The Profile tab embedded in `HomeScreen`'s IndexedStack at index 3.
///
/// Visual language is intentionally aligned with `AddressSelectorSheet`
/// (brand-blue tinted tiles, white icon-squares, 10sp uppercase section
/// headers) so the customer-side identity surfaces feel of-a-piece.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  // Tokens duplicated from `AddressSelectorSheet` for visual continuity.
  // When the design-system pass lands ([[project_ui_cleanup_planned]])
  // these collapse into a single token set; until then both surfaces
  // pin to the same literal hex so they stay in lockstep.
  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);
  static const Color _mutedText = Color(0xFF727785);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return SafeArea(
      child: profileAsync.when(
        data: (profile) => _ProfileBody(profile: profile),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _brandBlue)),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.read(profileProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — header card + sections + sign-out + version
// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final CustomerProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: ProfileTabScreen._brandBlue,
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(profile: profile),
            const SizedBox(height: 28),
            const _SectionHeader('Account'),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.location_on_outlined,
              label: 'My addresses',
              onTap: () => context.push('/customer/addresses'),
            ),
            const SizedBox(height: 10),
            const _TechnicianModeTile(),
            const SizedBox(height: 28),
            const _SectionHeader('About'),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'About Karigar',
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
                  color: ProfileTabScreen._mutedText,
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
// Header card — tap target for the edit screen
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final CustomerProfileEntity profile;

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
            color: ProfileTabScreen._brandBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ProfileTabScreen._brandBlue.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar circle with initials.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ProfileTabScreen._brandBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
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
                            ? ProfileTabScreen._titleText
                            : ProfileTabScreen._mutedText,
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
                        color: ProfileTabScreen._bodyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Role chip — read-only marker. Today this is always
                    // "Customer" on the profile tab since the tab itself
                    // lives inside the customer shell; `is_technician`
                    // determines whether the Technician Mode tile routes
                    // to onboarding or the dashboard.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ProfileTabScreen._brandBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CUSTOMER',
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
                color: ProfileTabScreen._mutedText,
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
// Section header — small uppercase label
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
          color: ProfileTabScreen._bodyText,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Standard menu tile — used for everything except Technician Mode
// ---------------------------------------------------------------------------

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
            color: ProfileTabScreen._brandBlue.withValues(alpha: 0.04),
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
                child: Icon(icon, color: ProfileTabScreen._brandBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ProfileTabScreen._titleText,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ProfileTabScreen._mutedText,
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
// Technician Mode — single smart-routing tile
// ---------------------------------------------------------------------------

class _TechnicianModeTile extends ConsumerWidget {
  const _TechnicianModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(technicianStatusProvider);
    final user = ref.watch(authProvider.select((s) => s.value?.user));

    final isLoading = statusAsync.isLoading && !statusAsync.hasValue;

    return _MenuTile(
      icon: Icons.handyman_outlined,
      label: 'Technician Mode',
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ProfileTabScreen._brandBlue,
              ),
            )
          : null,
      onTap: () {
        if (isLoading) return;
        // Smart routing — single button, four destinations.
        // The order of checks matters: a user that has never applied
        // (`!isTechnician`) is sent to onboarding regardless of any
        // stale status fetch; an applied user routes by their status.
        final isTechnician = user?.isTechnician ?? false;
        if (!isTechnician) {
          context.push('/technician/onboarding');
          return;
        }
        final status = statusAsync.value;
        switch (status) {
          case TechnicianStatusApproved():
            context.push('/technician/dashboard');
          case TechnicianStatusPending():
          case TechnicianStatusRejected():
            context.push('/technician/pending');
          case TechnicianStatusNoProfile():
          case null:
            // is_technician=true but no profile (data inconsistency) —
            // treat as a fresh applicant and route to onboarding. The
            // backend will reject duplicate-pending if there is actually
            // an active row; this is the same recovery the auth router
            // does on a status-cache miss.
            context.push('/technician/onboarding');
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-out — outlined red, full-width
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
          style: TextStyle(color: ProfileTabScreen._bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ProfileTabScreen._bodyText),
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
    // The auth notifier handles teardown order: FCM dereg, then
    // POST /logout/, then local clear, then state = AsyncData(empty).
    // go_router's redirect bounces to /login when user becomes null.
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
// Error state — auth failure forces sign-out, anything else retries
// ---------------------------------------------------------------------------

class _ErrorState extends ConsumerStatefulWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  ConsumerState<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends ConsumerState<_ErrorState> {
  // Guard against the rebuild loop: when this widget responds to a
  // `ProfileUnauthorizedFailure` it fires `authProvider.notifier.logout()`,
  // which can take multiple frames to settle. During those frames a
  // re-render is possible (IndexedStack rebuilds tabs eagerly once
  // visited), and without this flag the widget would queue a second
  // logout. The auth notifier itself short-circuits a re-entrant
  // logout when `state.isLoading`, but we shouldn't rely on that —
  // a future change to the auth notifier's guard could regress this
  // into an infinite loop.
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    if (error is ProfileUnauthorizedFailure) {
      // Session is dead. Sign out cleanly so the router moves the
      // user to /login. Fire-and-forget; the redirect happens once
      // the auth state goes to AsyncData(empty).
      if (!_loggingOut) {
        _loggingOut = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(authProvider.notifier).logout();
        });
      }
      return const Center(
        child: CircularProgressIndicator(color: ProfileTabScreen._brandBlue),
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
                color: ProfileTabScreen._bodyText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileTabScreen._brandBlue,
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
