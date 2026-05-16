import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../addresses/domain/entities/address_entity.dart';
import '../../../addresses/presentation/providers/dependency_injection.dart';

/// Full-page address management — pushed from the profile menu.
///
/// Same data source as the home-header `AddressSelectorSheet`
/// (`addressesProvider`), same visual chrome (`_AddressTile` semantics),
/// but rendered as a screen so creating a new address feels native
/// (AppBar back, AppBar "+ Add" action) instead of a sheet-over-sheet.
///
/// Creation always pushes to `/addresses/map-picker` — the existing
/// canonical create flow. We never duplicate the map-picker UX.
class CustomerAddressesScreen extends ConsumerWidget {
  const CustomerAddressesScreen({super.key});

  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);
  static const Color _mutedText = Color(0xFF727785);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My addresses',
          style: TextStyle(
            color: _titleText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleText),
        actions: [
          IconButton(
            onPressed: () => context.push('/addresses/map-picker'),
            icon: const Icon(Icons.add_location_alt_outlined),
            color: _brandBlue,
            tooltip: 'Add address',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: addressesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _brandBlue)),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (addresses) {
            if (addresses.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              color: _brandBlue,
              // `refresh().future` returns a future that resolves after
              // the rebuilt provider settles, so the indicator stays
              // visible until the refetch completes. A bare `invalidate`
              // returns immediately and the spinner flashes off mid-fetch.
              onRefresh: () => ref.refresh(addressesProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _AddressRow(address: addresses[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address row — visually identical to AddressSelectorSheet's `_AddressTile`,
// kept as a parallel local widget so the sheet stays untouched.
// ---------------------------------------------------------------------------

class _AddressRow extends ConsumerWidget {
  const _AddressRow({required this.address});
  final CustomerAddressEntity address;

  IconData _icon(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home_rounded;
    if (l.contains('office') || l.contains('work')) return Icons.work_rounded;
    return Icons.location_on_rounded;
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref) async {
    if (address.isDefault) return;
    try {
      await ref
          .read(updateAddressUseCaseProvider)
          .call(id: address.id, isDefault: true);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(address.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(deleteAddressUseCaseProvider).call(address.id);
        ref.invalidate(addressesProvider);
      },
      child: InkWell(
        onTap: () => _setDefault(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CustomerAddressesScreen._brandBlue
                .withValues(alpha: address.isDefault ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: address.isDefault
                  ? CustomerAddressesScreen._brandBlue.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _icon(address.label),
                  color: CustomerAddressesScreen._brandBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: CustomerAddressesScreen._bodyText,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CustomerAddressesScreen._brandBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.streetAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: CustomerAddressesScreen._titleText,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (address.isDefault)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CustomerAddressesScreen._brandBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CustomerAddressesScreen._brandBlue
                    .withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 48,
                color: CustomerAddressesScreen._brandBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saved addresses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: CustomerAddressesScreen._titleText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a location so you can book services\nin one tap.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CustomerAddressesScreen._mutedText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/addresses/map-picker'),
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                label: const Text(
                  'Add an address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomerAddressesScreen._brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: CustomerAddressesScreen._brandBlue
                      .withValues(alpha: 0.4),
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
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
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
                color: CustomerAddressesScreen._bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
