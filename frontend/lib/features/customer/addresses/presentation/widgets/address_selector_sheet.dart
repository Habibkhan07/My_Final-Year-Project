import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/dependency_injection.dart';

class AddressSelectorSheet extends ConsumerWidget {
  const AddressSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3EF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Location',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF151C24),
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Where should we send the technician?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F3F9)),

          // Address list
          Flexible(
            child: addressesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade200),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load addresses.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No saved addresses yet.',
                          style: TextStyle(color: Color(0xFF727785)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) =>
                      _AddressTile(address: addresses[index]),
                );
              },
            ),
          ),

          // Footer — Add New Address
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ElevatedButton(
              onPressed: () => context.push('/addresses/map-picker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: address.isDefault ? const Color(0xFFF0F6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? const Color(0xFFDDE8FB) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: address.isDefault
            ? null 
            : () async {
                try {
                  await ref.read(updateAddressUseCaseProvider).call(
                        id: address.id,
                        isDefault: true,
                      );
                  ref.invalidate(addressesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: address.isDefault ? const Color(0xFF0051AE) : const Color(0xFFF0F3F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(address.label),
            size: 22,
            color: address.isDefault ? Colors.white : const Color(0xFF727785),
          ),
        ),
        title: Text(
          address.label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF151C24),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            address.streetAddress,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Radio<bool>(
          value: true,
          groupValue: address.isDefault,
          activeColor: const Color(0xFF0051AE),
          onChanged: address.isDefault ? null : (_) {
            // Re-trigger the same logic as onTap for accessibility
            ref.read(updateAddressUseCaseProvider).call(
              id: address.id,
              isDefault: true,
            ).then((_) => ref.invalidate(addressesProvider));
          },
        ),
      ),
    );
  }
}
