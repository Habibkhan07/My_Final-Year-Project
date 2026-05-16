import 'package:flutter/material.dart';

/// Static Terms & Privacy screen — pushed from Profile → About.
///
/// Project-grade text, not lawyer-grade. Defensible in viva as "v1.1
/// swaps in counsel-reviewed copy" — a normal answer for an FYP build.
class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  static const Color _brandBlue = Color(0xFF0051AE);
  static const Color _titleText = Color(0xFF151C24);
  static const Color _bodyText = Color(0xFF424753);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(
            color: _titleText,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleText),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: const [
            _LegalSection(
              title: 'Terms of service',
              paragraphs: [
                "Karigar is a marketplace. We connect customers with "
                    "independent service technicians; we do not perform the "
                    "services ourselves. Technicians are responsible for the "
                    "quality, safety, and outcome of the work they deliver.",
                "Payment for any service is settled in cash directly between "
                    "the customer and the technician at the time of the job. "
                    "Karigar does not handle customer payments and is not a "
                    "party to that transaction.",
                "An inspection fee of Rs. 500 applies to every visit. If the "
                    "customer accepts the technician's quote, the inspection "
                    "fee is deducted from the final bill. If the customer "
                    "declines the quote, the customer pays the Rs. 500 fee "
                    "in cash for the visit.",
                "Disputes between customers and technicians can be filed "
                    "through the in-app dispute flow once a job is marked "
                    "complete. Karigar's role in disputes is limited to "
                    "facilitation and decision; we are not a court or "
                    "regulatory body.",
              ],
            ),
            SizedBox(height: 20),
            _LegalSection(
              title: 'Privacy policy',
              paragraphs: [
                "We collect the minimum information needed to operate the "
                    "platform: your phone number (for sign-in), your name, "
                    "and the addresses you save for booking. Your live "
                    "location is used only while a technician is en route, "
                    "and only between you and the assigned technician.",
                "We do not collect, store, or transmit payment card data. "
                    "All payment for services is cash between you and the "
                    "technician. Technician payouts are processed through "
                    "JazzCash; we do not store payment credentials beyond "
                    "the bank reference needed for withdrawal.",
                "Your phone number is the auth identity and cannot be "
                    "changed in-app without re-verification. Your name and "
                    "addresses can be updated or deleted at any time from "
                    "the profile settings.",
                "Account deletion and data export will be available in a "
                    "future release. Until then, contact support to request "
                    "removal of your account and data.",
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Last updated: May 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF727785),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TermsAndPrivacyScreen._brandBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: TermsAndPrivacyScreen._brandBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...paragraphs.expand((p) => [
                Text(
                  p,
                  style: const TextStyle(
                    fontSize: 14,
                    color: TermsAndPrivacyScreen._bodyText,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
              ]),
        ],
      ),
    );
  }
}
