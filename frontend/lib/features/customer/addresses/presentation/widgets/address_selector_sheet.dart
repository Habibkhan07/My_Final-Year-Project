import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/dependency_injection.dart';
import 'package:frontend/features/booking/presentation/widgets/modal_bottom_sheet_layout.dart';

class AddressSelectorSheet extends ConsumerWidget {
  const AddressSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return ModalBottomSheetLayout(
      title: 'Select Location',
      footer: ElevatedButton(
        onPressed: () => context.push('/addresses/map-picker'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0051AE),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF0051AE).withOpacity(0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined, size: 20),
            SizedBox(width: 12),
            Text(
              'Add New Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAVED ADDRESSES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color(0xFF424753),
            ),
          ),
          const SizedBox(height: 16),
          addressesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0051AE)),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade200,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load addresses.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            data: (addresses) {
              if (addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0051AE).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: const Color(0xFF0051AE).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No saved addresses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF151C24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add a location to quickly book services.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF727785),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _AddressTile(address: addresses[index]),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  final CustomerAddressEntity address;

  const _AddressTile({required this.address});

  IconData _getIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('home')) return Icons.home_rounded;
    if (l.contains('office') || l.contains('work')) return Icons.work_rounded;
    return Icons.location_on_rounded;
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
        onTap: address.isDefault
            ? null
            : () async {
                try {
                  await ref
                      .read(updateAddressUseCaseProvider)
                      .call(id: address.id, isDefault: true);
                  ref.invalidate(addressesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(
              0xFF0051AE,
            ).withOpacity(address.isDefault ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: address.isDefault
                  ? const Color(0xFF0051AE).withOpacity(0.2)
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
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(address.label),
                  color: const Color(0xFF0051AE),
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
                            color: Color(0xFF424753),
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
                              color: const Color(0xFF0051AE),
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
                        color: Color(0xFF151C24),
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
                  color: Color(0xFF0051AE),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
