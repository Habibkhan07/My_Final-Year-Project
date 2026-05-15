import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/scheduled_job.dart';
import '../../domain/entities/scheduled_job_segment.dart';
import '../../domain/entities/scheduled_jobs_counts.dart';
import '../../domain/failures/scheduled_jobs_failure.dart';
import '../providers/scheduled_jobs_counts_notifier.dart';
import '../providers/scheduled_jobs_list_notifier.dart';
import '../providers/scheduled_jobs_list_state.dart';
import '../providers/selected_schedule_segment_notifier.dart';
import '../widgets/scheduled_job_card.dart';
import '../widgets/scheduled_job_card_skeleton.dart';
import '../widgets/scheduled_jobs_empty_past.dart';
import '../widgets/scheduled_jobs_empty_upcoming.dart';
import '../widgets/scheduled_jobs_error_state.dart';
import '../widgets/scheduled_jobs_hero_header.dart';
import '../widgets/scheduled_jobs_offline_banner.dart';
import '../widgets/scheduled_jobs_segmented_control.dart';

/// The technician-facing **Schedule** screen.
///
/// Audience-flipped counterpart of `CustomerBookingsListScreen`. Same
/// state→render contract:
///   * [selectedScheduleSegmentProvider] — tab state.
///   * [scheduledJobsListProvider] — `AsyncValue<ScheduledJobsListState>`
///     for the active segment.
///   * [scheduledJobsCountsProvider] — counts for the segmented-control
///     badges.
///
/// Every AsyncValue branch renders something visible; no
/// `SizedBox.shrink()` defaults.
///
/// [showBackButton] is `false` when mounted inside the dashboard's
/// IndexedStack (no back arrow — tab destination), `true` when reached
/// via direct navigation to `/technician/schedule` (deep link / FCM tap).
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  static const double _loadMoreThreshold = 320;
  static const Duration _bannerAnimDuration = Duration(milliseconds: 200);

  final ScrollController _scrollController = ScrollController();
  bool _validationRetried = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    if (remaining < _loadMoreThreshold) {
      ref.read(scheduledJobsListProvider.notifier).loadMore();
    }
  }

  Future<void> _refreshAll() async {
    _validationRetried = false;
    await Future.wait([
      ref.read(scheduledJobsListProvider.notifier).refresh(),
      ref.read(scheduledJobsCountsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Validation auto-refresh: a ScheduledJobsValidationFailure should
    // self-heal once (the notifier owns cursor/filter state and a refresh
    // drops both). Second failure falls through to the server-error UI.
    ref.listen<AsyncValue<ScheduledJobsListState>>(
      scheduledJobsListProvider,
      (prev, next) {
        next.whenOrNull(
          error: (e, _) {
            if (e is ScheduledJobsValidationFailure && !_validationRetried) {
              _validationRetried = true;
              ref.read(scheduledJobsListProvider.notifier).refresh();
            }
          },
        );
      },
    );

    final segment = ref.watch(selectedScheduleSegmentProvider);
    final listAsync = ref.watch(scheduledJobsListProvider);
    final countsAsync = ref.watch(scheduledJobsCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          ScheduledJobsHeroHeader(
            title: 'Schedule',
            subtitle: _subtitleFromCounts(countsAsync),
            onBack: widget.showBackButton
                ? () => Navigator.of(context).maybePop()
                : null,
          ),
          const SizedBox(height: AppSpacing.s3),
          const ScheduledJobsSegmentedControl(),
          const SizedBox(height: AppSpacing.s4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppColors.primary,
              child: _buildBody(listAsync, segment),
            ),
          ),
        ],
      ),
    );
  }

  String? _subtitleFromCounts(AsyncValue<ScheduledJobsCounts> countsAsync) {
    return countsAsync.whenOrNull(
      data: (c) => '${c.upcoming} upcoming · ${c.past} past',
    );
  }

  Widget _buildBody(
    AsyncValue<ScheduledJobsListState> async,
    ScheduledJobSegment segment,
  ) {
    final hasPrevious = async.value != null;

    if (async.isLoading && !hasPrevious) {
      return _buildSkeletonList();
    }
    if (async.isLoading && hasPrevious) {
      return _buildContent(async.value!, segment);
    }

    return async.when(
      skipLoadingOnRefresh: true,
      data: (state) => _buildContent(state, segment),
      loading: _buildSkeletonList,
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildContent(
    ScheduledJobsListState state,
    ScheduledJobSegment segment,
  ) {
    if (state.items.isEmpty) {
      return _wrapInScrollable(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: segment == ScheduledJobSegment.upcoming
              ? const ScheduledJobsEmptyUpcoming()
              : const ScheduledJobsEmptyPast(),
        ),
      );
    }

    final showOfflineBanner = state.isStaleCache && state.cachedAt != null;
    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);

    return Column(
      children: [
        AnimatedSize(
          duration: _bannerAnimDuration,
          curve: Curves.easeOut,
          child: showOfflineBanner
              ? ScheduledJobsOfflineBanner(
                  cachedAt: state.cachedAt!,
                  serverNow: state.serverTime,
                  onRefresh: () =>
                      ref.read(scheduledJobsListProvider.notifier).refresh(),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s8,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const _PaginationFooter();
              }
              final job = state.items[index];
              return _CardSlot(
                key: ValueKey(job.id),
                job: job,
                serverTime: state.serverTime,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return _wrapInScrollable(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s8,
        ),
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.s3),
              child: ScheduledJobCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    Widget widget;
    if (error is ScheduledJobsOfflineNoCache) {
      widget = ScheduledJobsErrorState.offline(
        onRetry: () =>
            ref.read(scheduledJobsListProvider.notifier).refresh(),
      );
    } else if (error is ScheduledJobsServerFailure ||
        error is ScheduledJobsValidationFailure) {
      widget = ScheduledJobsErrorState.server(
        onRetry: () =>
            ref.read(scheduledJobsListProvider.notifier).refresh(),
      );
    } else {
      widget = ScheduledJobsErrorState.unknown(
        onRetry: () =>
            ref.read(scheduledJobsListProvider.notifier).refresh(),
      );
    }
    return _wrapInScrollable(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: widget,
      ),
    );
  }

  /// RefreshIndicator requires a scrollable child. Empty / skeleton /
  /// error states are not scrollable lists, so wrap them in a
  /// SingleChildScrollView with `AlwaysScrollableScrollPhysics` so the
  /// pull-to-refresh gesture is still recognised.
  Widget _wrapInScrollable({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

class _CardSlot extends StatelessWidget {
  const _CardSlot({super.key, required this.job, required this.serverTime});

  final ScheduledJob job;
  final DateTime serverTime;

  @override
  Widget build(BuildContext context) {
    return ScheduledJobCard(job: job, serverTime: serverTime);
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
