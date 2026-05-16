import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/icon_assets.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/available_sub_service_entity.dart';
import '../../domain/failures/skills_failure.dart';
import '../providers/dependency_injection.dart';
import '../providers/skills_notifier.dart';

// ---------------------------------------------------------------------------
// File-level visual tokens
// ---------------------------------------------------------------------------
//
// Mirrored verbatim from the customer profile feature for visual
// consistency. When the design-system pass lands these collapse into
// a shared token set; until then this file pins to the same literal
// hex as `ProfileTabScreen` and `AddressSelectorSheet`.
const Color _brandBlue = Color(0xFF0051AE);
const Color _titleText = Color(0xFF151C24);
const Color _bodyText = Color(0xFF424753);
const Color _mutedText = Color(0xFF727785);

/// Pushed from the My Skills screen's `+` action.
///
/// Two-step picker: pick a Service, then pick one of its sub-services.
/// Sub-services the tech already has are filtered out client-side so
/// the user is never offered a guaranteed-409 path.
///
/// Visual chrome matches the My Skills screen — same brand-blue
/// tokens, same tile geometry. The picker is a transient screen so
/// service-tree responses aren't cached; the catalog is small and
/// changes rarely.
class AddSkillScreen extends ConsumerStatefulWidget {
  const AddSkillScreen({super.key});

  @override
  ConsumerState<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends ConsumerState<AddSkillScreen> {
  AvailableServiceEntity? _selectedService;
  bool _saving = false;

  /// Future is read once per build; we cache it as a field so widget
  /// rebuilds (e.g. when `_selectedService` flips) don't restart the
  /// network call.
  Future<List<AvailableServiceEntity>>? _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = ref
        .read(listAvailableServicesUseCaseProvider)
        .call();
  }

  Future<void> _onSubServiceTap(AvailableSubServiceEntity sub) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final result = await ref
        .read(skillsProvider.notifier)
        .addSkill(subServiceId: sub.id);

    if (mounted) setState(() => _saving = false);
    if (!mounted) return;

    if (result.hasValue) {
      // Pop back to My Skills — the notifier already merged the new
      // row into the cached list, so the screen rebuilds without a
      // second round-trip.
      router.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Added "${sub.name}" to your skills')),
        );
      return;
    }

    final error = result.error;
    if (error is SkillsDuplicateFailure) {
      // Should never happen — the picker filters client-side — but
      // the backend is the source of truth, so handle it cleanly.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('"${sub.name}" is already in your skills.')),
        );
      return;
    }
    if (error is SkillsCategoryNotAllowedFailure) {
      // Defence-in-depth landing: the picker only renders services
      // the tech holds a TechnicianServiceLicense row for, so this
      // branch fires on stale picker cache or a mid-flight admin
      // revocation of a license row. The copy is intentionally
      // neutral — no "contact support" hand-wave, because the
      // platform has no support endpoint to back that up.
      final body = error.serviceName.isNotEmpty
          ? '${error.serviceName} is not in the categories you chose '
              'at onboarding.'
          : error.message;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(body)));
      return;
    }
    if (error is SkillsUnauthorizedFailure) {
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
    final selectedService = _selectedService;
    // Watch the current skills so we can filter out duplicates from
    // the picker. The provider is keepAlive=true so a fresh read here
    // is free if it was already warm from the My Skills screen.
    final existingIds = ref
            .watch(skillsProvider)
            .value
            ?.map((s) => s.subService.id)
            .toSet() ??
        const <int>{};

    // PopScope intercepts the Android hardware back button when the
    // user is on Step 2 (sub-service list), so back returns to Step 1
    // (service grid) instead of popping the whole route. Without this,
    // a tech who picked a service then changed their mind has to tap
    // the AppBar arrow — the system back button silently skips the
    // intermediate step.
    return PopScope(
      canPop: selectedService == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selectedService != null) {
          setState(() => _selectedService = null);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _titleText,
          elevation: 0,
          title: Text(
            selectedService == null ? 'Pick a Service' : 'Pick a Skill',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              // Stepping back from sub-service → service. From service
              // selection or no selection → pop the route.
              if (_selectedService != null) {
                setState(() => _selectedService = null);
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: FutureBuilder<List<AvailableServiceEntity>>(
          future: _servicesFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: _brandBlue),
              );
            }
            if (snap.hasError) {
              return _AddSkillErrorState(
                error: snap.error!,
                onRetry: () => setState(() {
                  _servicesFuture =
                      ref.read(listAvailableServicesUseCaseProvider).call();
                }),
              );
            }
            final services = snap.data ?? const [];
            if (services.isEmpty) {
              // Should be unreachable: the category set is derived
              // from the tech's current skills, and the BE enforces
              // ``>= 1`` skill via the LastSkillRequiredError guard.
              // Defensive empty state in case the contract drifts.
              return const _NoActiveCategoriesState();
            }

            if (selectedService == null) {
              // Pre-filter services whose every sub-service is already
              // in the tech's skill set — saves them tapping a dead-end
              // tile that lands on "you already have everything here."
              // The filter is best-effort: if `skillsProvider` hasn't
              // resolved yet, `existingIds` is empty and every service
              // is shown (correct fallback — let the user proceed).
              final addable = existingIds.isEmpty
                  ? services
                  : services
                      .where((s) => s.subServices
                          .any((sub) => !existingIds.contains(sub.id)))
                      .toList(growable: false);
              if (addable.isEmpty) {
                return const _AllSkillsCoveredState();
              }
              return _ServiceGrid(
                services: addable,
                onPick: (s) => setState(() => _selectedService = s),
              );
            }
            return _SubServiceList(
              service: selectedService,
              alreadyHaveIds: existingIds,
              saving: _saving,
              onPick: _onSubServiceTap,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Service grid
// ---------------------------------------------------------------------------

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services, required this.onPick});

  final List<AvailableServiceEntity> services;
  final void Function(AvailableServiceEntity) onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: services.length,
      itemBuilder: (_, i) {
        final s = services[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onPick(s),
          child: Container(
            decoration: BoxDecoration(
              color: _brandBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _brandBlue.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: SvgPicture.asset(
                    IconAssets.path(s.iconName),
                    colorFilter: const ColorFilter.mode(
                      _brandBlue,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _titleText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Sub-service list (filtered against existing skills)
// ---------------------------------------------------------------------------

class _SubServiceList extends StatelessWidget {
  const _SubServiceList({
    required this.service,
    required this.alreadyHaveIds,
    required this.saving,
    required this.onPick,
  });

  final AvailableServiceEntity service;
  final Set<int> alreadyHaveIds;
  final bool saving;
  final void Function(AvailableSubServiceEntity) onPick;

  @override
  Widget build(BuildContext context) {
    final available =
        service.subServices.where((s) => !alreadyHaveIds.contains(s.id)).toList(
              growable: false,
            );

    if (available.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: _mutedText,
              ),
              const SizedBox(height: 12),
              Text(
                'You already have every sub-service under ${service.name}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _bodyText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: available.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final sub = available[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: saving ? null : () => onPick(sub),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _brandBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      IconAssets.path(sub.iconName),
                      colorFilter: const ColorFilter.mode(
                        _brandBlue,
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
                          sub.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _titleText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sub.isFixedPrice) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Fixed-price gig',
                            style: TextStyle(
                              fontSize: 11,
                              color: _mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: _mutedText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Error / empty states for the picker
// ---------------------------------------------------------------------------

/// Error state for the picker's service-tree fetch.
///
/// `Unauthorized` triggers a forced sign-out via `authProvider.notifier
/// .logout()` (idempotent), matching the My Skills + Profile tab pattern.
/// Without this, the picker's "Retry" button would loop forever on a
/// dead token instead of bouncing the user to /login.
class _AddSkillErrorState extends ConsumerStatefulWidget {
  const _AddSkillErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  ConsumerState<_AddSkillErrorState> createState() => _AddSkillErrorStateState();
}

class _AddSkillErrorStateState extends ConsumerState<_AddSkillErrorState> {
  // Guards against rebuild loops: the logout() call can take a few
  // frames to settle, and during that window FutureBuilder might
  // rebuild this widget. Without the latch, we'd fire logout twice
  // (the auth notifier guards re-entry, but we shouldn't rely on it).
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
        child: CircularProgressIndicator(color: _brandBlue),
      );
    }

    final message = error is SkillsFailure
        ? error.message
        : 'Could not load the service list.';
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
              style: const TextStyle(fontSize: 14, color: _bodyText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
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

/// Defensive state for "tech has zero onboarded categories". Should be
/// unreachable in practice — the onboarding finalize service requires
/// at least one skill and auto-creates a `TechnicianServiceLicense`
/// row for each parent service those skills sit under, so every
/// approved tech has a non-empty license set. Reachable only via
/// out-of-band admin intervention (manually deleting every license
/// row for a tech).
///
/// Copy is honest about the cause without promising a self-serve
/// fix the platform doesn't have a flow for.
///
/// Distinct from `_AllSkillsCoveredState` — that fires when the tech
/// IS in categories but has already added every available sub-service
/// under them.
class _NoActiveCategoriesState extends StatelessWidget {
  const _NoActiveCategoriesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: _mutedText),
            SizedBox(height: 12),
            Text(
              'No categories enabled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _titleText,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your account has no service categories enabled. An '
              'admin needs to enable them before you can add skills.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _bodyText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reached when every service in the tech's active categories has had
/// every sub-service added already — i.e. the picker has nothing left
/// to offer because the tech is already comprehensive within their
/// approved scope. Distinct from `_NoActiveCategoriesState` (the
/// category set itself is empty, which should be unreachable).
class _AllSkillsCoveredState extends StatelessWidget {
  const _AllSkillsCoveredState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 48, color: _mutedText),
            SizedBox(height: 12),
            Text(
              "You're already qualified for every available skill.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
