import 'package:flutter/material.dart';

class SuggestionResultTile extends StatelessWidget {
  final String title;
  final String categoryName;
  final VoidCallback onTap;

  const SuggestionResultTile({
    super.key,
    required this.title,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            TextSpan(
              text: ' • $categoryName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.arrow_outward, color: Color(0xFFD1D5DB), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
