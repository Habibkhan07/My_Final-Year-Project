import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF0051AE), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Addresses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF151C24),
                      ),
                ),
              ],
            ),
          ),

          // Address list
          addressesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Text(
                'Could not load addresses.',
                style: TextStyle(color: Color(0xFF727785)),
              ),
            ),
            data: (addresses) {
              if (addresses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Text(
                    'No saved addresses yet.',
                    style: TextStyle(color: Color(0xFF727785)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFF0F3F9),
                ),
                itemBuilder: (context, index) =>
                    _AddressTile(address: addresses[index]),
              );
            },
          ),

          // Footer — Add New Address
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ElevatedButton.icon(
              onPressed: () =>
                  debugPrint('TODO: Navigate to Map Picker'),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Add New Address',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final CustomerAddressEntity address;

  const _AddressTile({required this.address});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: address.isDefault
              ? const Color(0xFFDDE8FB)
              : const Color(0xFFF0F3F9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.location_on,
          size: 20,
          color: address.isDefault
              ? const Color(0xFF0051AE)
              : const Color(0xFF727785),
        ),
      ),
      title: Row(
        children: [
          Text(
            address.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: address.isDefault
                  ? const Color(0xFF0051AE)
                  : const Color(0xFF151C24),
            ),
          ),
          if (address.isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0051AE),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Default',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          address.streetAddress,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF727785),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
