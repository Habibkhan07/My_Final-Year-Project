import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryBrowseTile extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final VoidCallback onTap;

  const CategoryBrowseTile({
    super.key,
    required this.name,
    this.iconUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: iconUrl != null
            ? CachedNetworkImage(
                imageUrl: iconUrl!,
                width: 24,
                height: 24,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.category, size: 24),
              )
            : const Icon(Icons.category, size: 24, color: Color(0xFF6B7280)),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
