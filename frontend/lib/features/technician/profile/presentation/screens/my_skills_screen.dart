import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/icon_assets.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/technician_skill_entity.dart';
import '../../domain/failures/skills_failure.dart';
import '../providers/skills_notifier.dart';

/// The technician's "My Skills" surface — listed, service-grouped,
/// and editable.
///
/// Visual chrome mirrors the customer profile feature (brand-blue
/// `#0051AE`, `AddressSelectorSheet`-style tile borders, 10sp
/// uppercase section headers) so the two surfaces feel of-a-piece.
/// When the design-system pass lands ([[project_ui_cleanup_planned]])
/// these tokens collapse into a shared set; until then both surfaces
/// pin to the same literal hex.
class MySkillsScreen extends ConsumerWidget {
  const MySkillsScreen({super.key});

  // Token mirror — see customer profile_tab_screen.dart for rationale.
  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);
  static const Color _mutedText = Color(0xFF727785);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _titleText,
        elevation: 0,
        title: const Text(
          'My Skills',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _brandBlue, size: 26),
            tooltip: 'Add a skill',
            onPressed: () => context.push('/technician/profile/skills/add'),
          ),
        ],
      ),
      body: skillsAsync.when(
        data: (skills) => _SkillsBody(skills: skills),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _brandBlue)),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.read(skillsProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List body — service-grouped sections + pull-to-refresh
// ---------------------------------------------------------------------------

class _SkillsBody extends ConsumerWidget {
  const _SkillsBody({required this.skills});

  final List<TechnicianSkillEntity> skills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skills.isEmpty) {
      // Reachable only via data inconsistency — the BE's last-skill
      // guard prevents the tech from ever dropping to zero through
      // the normal delete flow. Still, the empty state is a CTA, not
      // a dead end.
      return _EmptyState(
        onAdd: () => context.push('/technician/profile/skills/add'),
      );
    }

    // Group by parent service to render section headers. The selector
    // already orders rows by service.name then sub_service.name, so
    // sequential grouping is sufficient — no sort needed here.
    final grouped = <String, List<TechnicianSkillEntity>>{};
    for (final skill in skills) {
      grouped
          .putIfAbsent(skill.subService.service.name, () => [])
          .add(skill);
    }

    return RefreshIndicator(
      color: MySkillsScreen._brandBlue,
      onRefresh: () => ref.read(skillsProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final entry in grouped.entries) ...[
            _SectionHeader(label: entry.key),
            const SizedBox(height: 8),
            for (final skill in entry.value) ...[
              _SkillRow(skill: skill),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header — service name in 10sp uppercase, same as customer profile
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: MySkillsScreen._bodyText,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skill row — tile with SVG icon, name, delete affordance
// ---------------------------------------------------------------------------

class _SkillRow extends ConsumerStatefulWidget {
  const _SkillRow({required this.skill});
  final TechnicianSkillEntity skill;

  @override
  ConsumerState<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends ConsumerState<_SkillRow> {
  bool _removing = false;

  Future<void> _confirmAndRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove skill?'),
        content: Text(
          'Remove "${widget.skill.subService.name}" from your skills? '
          'You can add it back at any time.',
          style: const TextStyle(color: MySkillsScreen._bodyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: MySkillsScreen._bodyText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removing = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(skillsProvider.notifier)
        .removeSkill(subServiceId: widget.skill.subService.id);

    if (mounted) setState(() => _removing = false);
    if (!mounted) return;

    if (result.hasValue) return; // notifier already pruned the list

    final error = result.error;
    if (error is SkillsUnauthorizedFailure) {
      // Session is dead — auth notifier handles the bounce to /login.
      // Fire-and-forget; the notifier is idempotent.
      await ref.read(authProvider.notifier).logout();
      return;
    }
    if (error is SkillsFailure) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MySkillsScreen._brandBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // SVG icon square — same chrome as customer profile menu tiles.
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              IconAssets.path(widget.skill.subService.iconName),
              colorFilter: const ColorFilter.mode(
                MySkillsScreen._brandBlue,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.skill.subService.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MySkillsScreen._titleText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.skill.subService.isFixedPrice) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Fixed-price gig',
                    style: TextStyle(
                      fontSize: 11,
                      color: MySkillsScreen._mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _removing ? null : _confirmAndRemove,
            tooltip: 'Remove this skill',
            icon: _removing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MySkillsScreen._mutedText,
                    ),
                  )
                : const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: MySkillsScreen._mutedText,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — reachable only via data inconsistency
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 56,
              color: MySkillsScreen._mutedText,
            ),
            const SizedBox(height: 12),
            const Text(
              'No skills yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MySkillsScreen._titleText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a skill to start receiving job requests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: MySkillsScreen._bodyText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add a skill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MySkillsScreen._brandBlue,
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

// ---------------------------------------------------------------------------
// Error state — Unauthorized triggers a forced sign-out
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
    if (error is SkillsUnauthorizedFailure) {
      if (!_loggingOut) {
        _loggingOut = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(authProvider.notifier).logout();
        });
      }
      return const Center(
        child: CircularProgressIndicator(color: MySkillsScreen._brandBlue),
      );
    }

    final message = error is SkillsFailure
        ? error.message
        : 'Could not load your skills.';

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
                color: MySkillsScreen._bodyText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MySkillsScreen._brandBlue,
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
