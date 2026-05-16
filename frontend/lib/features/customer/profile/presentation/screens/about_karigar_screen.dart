import 'package:flutter/material.dart';

/// Static "About Karigar" screen — pushed from Profile → About.
///
/// Defensible in viva: every real app has this surface. App version is
/// hardcoded for now (package_info_plus not on pubspec); switching to
/// the real package is a 5-line change post-viva (see flag.md #N).
class AboutKarigarScreen extends StatelessWidget {
  const AboutKarigarScreen({super.key});

  static const String _appVersion = '1.0.0';
  static const String _supportEmail = 'support@karigar.pk';

  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);
  static const Color _mutedText = Color(0xFF727785);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'About Karigar',
          style: TextStyle(
            color: _titleText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand block — circle wordmark stand-in
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2563EB), _brandBlue],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _brandBlue.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Karigar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _titleText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Pakistan's home services marketplace.",
                  style: TextStyle(fontSize: 14, color: _bodyText),
                ),
              ),
              const SizedBox(height: 28),

              _InfoRow(
                icon: Icons.tag_rounded,
                label: 'App version',
                value: 'v$_appVersion',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Contact',
                value: _supportEmail,
              ),
              const SizedBox(height: 32),

              const Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: _bodyText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Karigar connects customers across Pakistan with vetted, "
                "skilled service professionals — plumbers, electricians, "
                "AC technicians, and more. Book by category or describe the "
                "problem in your own words; the platform matches you with a "
                "nearby pro who quotes after an on-site inspection.\n\n"
                "Payments stay cash between you and the technician. The "
                "platform itself only charges the technician a small "
                "commission on completed jobs.\n\n"
                "Karigar started as a final-year computer science project; "
                "v1.0 ships the core booking, tracking, and dispute flows.",
                style: TextStyle(
                  fontSize: 14,
                  color: _bodyText,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '© 2026 Karigar',
                  style: TextStyle(fontSize: 12, color: _mutedText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AboutKarigarScreen._brandBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon,
                color: AboutKarigarScreen._brandBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AboutKarigarScreen._bodyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AboutKarigarScreen._titleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
