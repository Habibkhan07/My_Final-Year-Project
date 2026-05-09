import 'package:flutter/material.dart';

class ModalBottomSheetLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;

  const ModalBottomSheetLayout({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2C6D6).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151C24),
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF0051AE)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE7EFF9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: child,
            ),
          ),

          // Footer
          if (footer != null)
            Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC2C6D6).withOpacity(0.15),
                  ),
                ),
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}
