import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/booking_segment.dart';
import '../../domain/entities/customer_booking.dart';
import '../../domain/failures/customer_bookings_failure.dart';
import '../providers/customer_bookings_counts_notifier.dart';
import '../providers/customer_bookings_list_notifier.dart';
import '../providers/customer_bookings_list_state.dart';
import '../providers/selected_segment_notifier.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_card_skeleton.dart';
import '../widgets/bookings_empty_past.dart';
import '../widgets/bookings_empty_upcoming.dart';
import '../widgets/bookings_error_state.dart';
import '../widgets/bookings_offline_banner.dart';
import '../widgets/bookings_segmented_control.dart';

/// The customer-facing **My Bookings** list.
///
/// Reads three providers:
///   * [selectedSegmentProvider] — tab state.
///   * [customerBookingsListProvider] — `AsyncValue<CustomerBookingsListState>`
///     for the active segment.
///   * [customerBookingsCountsProvider] — counts for the segmented-
///     control badges.
///
/// State→render mapping comes from session_4 §7. Every AsyncValue branch
/// renders something visible; no `SizedBox.shrink()` defaults.
///
/// [showBackButton] is `false` when mounted inside the home-screen
/// IndexedStack (the screen is a tab destination — no back arrow), and
/// `true` when reached via direct navigation to `/customer/bookings`
/// (deep link / FCM tap), so the user can pop back.
class CustomerBookingsListScreen extends ConsumerStatefulWidget {
  const CustomerBookingsListScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  ConsumerState<CustomerBookingsListScreen> createState() =>
      _CustomerBookingsListScreenState();
}

class _CustomerBookingsListScreenState
    extends ConsumerState<CustomerBookingsListScreen> {
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
      // Notifier is idempotent on hasMore + isLoadingMore + cursor —
      // safe to call freely on every scroll tick within the threshold.
      ref.read(customerBookingsListProvider.notifier).loadMore();
    }
  }

  Future<void> _refreshAll() async {
    _validationRetried = false;
    await Future.wait([
      ref.read(customerBookingsListProvider.notifier).refresh(),
      ref.read(customerBookingsCountsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Validation auto-refresh: per §7, a CustomerBookingsValidationFailure
    // should self-heal once (the notifier owns cursor/filter state and a
    // refresh drops both). If the retry also fails, the second AsyncError
    // falls through to the server-error UI.
    ref.listen<AsyncValue<CustomerBookingsListState>>(
      customerBookingsListProvider,
      (prev, next) {
        next.whenOrNull(
          error: (e, _) {
            if (e is CustomerBookingsValidationFailure && !_validationRetried) {
              _validationRetried = true;
              ref.read(customerBookingsListProvider.notifier).refresh();
            }
          },
        );
      },
    );

    final segment = ref.watch(selectedSegmentProvider);
    final listAsync = ref.watch(customerBookingsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s3),
            const BookingsSegmentedControl(),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      title: const Text(
        'My Bookings',
        style: TextStyle(
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.50),
        ),
      ),
    );
  }

  /// Maps the AsyncValue + inner state → a widget. Implements every
  /// branch of session_4 §7's table.
  Widget _buildBody(
    AsyncValue<CustomerBookingsListState> async,
    BookingSegment segment,
  ) {
    final hasPrevious = async.value != null;

    // Initial load: pure loading, no previous data → skeleton list.
    if (async.isLoading && !hasPrevious) {
      return _buildSkeletonList();
    }

    // Loading-with-previous (refresh in flight) → render previous data.
    // The RefreshIndicator's spinner is the "we're refreshing" feedback.
    if (async.isLoading && hasPrevious) {
      return _buildContent(async.value!, segment);
    }

    return async.when(
      skipLoadingOnRefresh: true,
      data: (state) => _buildContent(state, segment),
      // Both these branches are unreachable thanks to the guards above
      // but `when` requires them. Skeleton is the safe fallback.
      loading: _buildSkeletonList,
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildContent(CustomerBookingsListState state, BookingSegment segment) {
    if (state.items.isEmpty) {
      return _wrapInScrollable(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: segment == BookingSegment.upcoming
              ? const BookingsEmptyUpcoming()
              : const BookingsEmptyPast(),
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
              ? BookingsOfflineBanner(
                  cachedAt: state.cachedAt!,
                  serverNow: state.serverTime,
                  onRefresh: () =>
                      ref.read(customerBookingsListProvider.notifier).refresh(),
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
              final booking = state.items[index];
              return _CardSlot(
                key: ValueKey(booking.id),
                booking: booking,
                segment: state.segment,
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
              child: BookingCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    Widget widget;
    if (error is CustomerBookingsOfflineNoCache) {
      widget = BookingsErrorState.offline(
        onRetry: () =>
            ref.read(customerBookingsListProvider.notifier).refresh(),
      );
    } else if (error is CustomerBookingsServerFailure ||
        error is CustomerBookingsValidationFailure) {
      // Validation failure reaches here only after the auto-retry above
      // has already fired once and still failed. Same UX as a server
      // error — the user sees a retry button.
      widget = BookingsErrorState.server(
        onRetry: () =>
            ref.read(customerBookingsListProvider.notifier).refresh(),
      );
    } else {
      widget = BookingsErrorState.unknown(
        onRetry: () =>
            ref.read(customerBookingsListProvider.notifier).refresh(),
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
  const _CardSlot({
    super.key,
    required this.booking,
    required this.segment,
    required this.serverTime,
  });

  final CustomerBooking booking;
  final BookingSegment segment;
  final DateTime serverTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: BookingCard(
        booking: booking,
        segment: segment,
        serverTime: serverTime,
      ),
    );
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
