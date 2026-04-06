import 'package:flutter/material.dart';

class SearchHistoryTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const SearchHistoryTile({
    super.key,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.access_time, color: Colors.grey),
      title: Text(
        query,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.arrow_outward, color: Color(0xFFD1D5DB), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}
