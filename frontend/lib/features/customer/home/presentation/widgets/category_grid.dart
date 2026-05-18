import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/home_feed_entity.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/icon_assets.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart';
import '../../../../customer/addresses/presentation/widgets/address_selector_sheet.dart';

// Cards rendered inline in the home row. Anything beyond this is reachable
// via the "See all" sheet — keeps the home feed scannable while not hiding
// catalog growth from the user.
const int _kInlineCategoryCount = 4;

class CategoryGrid extends ConsumerWidget {
  final List<CategoryEntity> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) return const SizedBox.shrink();

    // Check for a valid location before allowing navigation to discovery
    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final hasAddress = defaultAddressAsync.value != null;
    // Only surface "See all" when there is actually more to see — never
    // tease the user with a button that opens an identical view.
    final hasOverflow = categories.length > _kInlineCategoryCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "What do you need help with?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (hasOverflow)
                TextButton(
                  onPressed: () =>
                      _openAllCategoriesSheet(context, hasAddress, categories),
                  child: const Text(
                    "See all",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.take(_kInlineCategoryCount).map((category) {
              return Expanded(
                child: _CategoryTile(
                  category: category,
                  hasAddress: hasAddress,
                  onPickAddress: () => _openAddressSheet(context),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Helpers (file-private so the home shell stays uncluttered) ────────

  void _openAllCategoriesSheet(
    BuildContext context,
    bool hasAddress,
    List<CategoryEntity> all,
  ) {
    // Same location intercept as the inline tiles — opening the sheet
    // is meaningless if we can't navigate onward.
    if (!hasAddress) {
      _openAddressSheet(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Allow drag-to-dismiss / pop on backdrop tap, both default.
      builder: (_) => _AllCategoriesSheet(categories: all),
    );
  }

  void _openAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressSelectorSheet(),
    );
  }
}

// ─── Inline tile (extracted so the sheet can reuse the same visual) ──

class _CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  final bool hasAddress;
  final VoidCallback onPickAddress;

  const _CategoryTile({
    required this.category,
    required this.hasAddress,
    required this.onPickAddress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!hasAddress) {
          onPickAddress();
          return;
        }
        context.push(
          Uri(
            path: '/discovery',
            queryParameters: {
              'title': category.name,
              'serviceId': category.id.toString(),
            },
          ).toString(),
        );
      },
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SvgPicture.asset(
              IconAssets.path(category.iconName),
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── "See all" sheet ──────────────────────────────────────────────────
//
// Foodpanda-style category picker. Drag-to-resize via
// [DraggableScrollableSheet] so the user can expand to fill the screen
// on long catalogs or collapse to a glance. Tapping a tile pops the
// sheet first, then navigates so the home reappears beneath the
// destination on back — no "bottom sheet over discovery" stack.

class _AllCategoriesSheet extends StatelessWidget {
  final List<CategoryEntity> categories;

  const _AllCategoriesSheet({required this.categories});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle — Material-style 40×4 pill.
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Browse categories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF151C24),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (tileContext, i) {
                    final cat = categories[i];
                    return GestureDetector(
                      onTap: () {
                        // Pop the sheet first so the navigation stack
                        // ends up at: Home → Discovery (not Home →
                        // Sheet → Discovery, which would leave the
                        // sheet hidden behind discovery on back).
                        Navigator.of(sheetContext).pop();
                        tileContext.push(
                          Uri(
                            path: '/discovery',
                            queryParameters: {
                              'title': cat.name,
                              'serviceId': cat.id.toString(),
                            },
                          ).toString(),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              IconAssets.path(cat.iconName),
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
