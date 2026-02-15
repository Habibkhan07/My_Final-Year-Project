import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Maintain Logic: Watch the AsyncValue
    final authAsync = ref.watch(authProvider);

    // 2. Maintain Logic: Listener for Side Effects
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenOrNull(
        // login_screen.dart
        data: (state) {
          if (state.successMessage != null) {
            // 1. Show the success bar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green, // This makes it green!
                behavior: SnackBarBehavior.floating,
              ),
            );

            // 2. Navigate
            final phone = ref.read(phoneNumberProvider);
            if (phone.isNotEmpty) {
              context.go('/otp/$phone');
            }
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Polished Visual: Branding Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(
                      alpha: 0.1,
                    ), // New High Standard
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40),

                // Updated Header Text
                const Text(
                  "Start with your phone no",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We will send a 4-digit verification code\nto your mobile number.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                // Polished Input Field
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: const TextStyle(color: Colors.black54),
                    hintText: '300 1234567',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  initialCountryCode: 'PK',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (phone) {
                    ref.read(phoneNumberProvider.notifier).state =
                        phone.completeNumber;
                  },
                ),
                const SizedBox(height: 32),

                // Polished Action Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: authAsync.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final phone = ref.read(phoneNumberProvider);
                            if (phone.isNotEmpty) {
                              ref.read(authProvider.notifier).requestOtp(phone);
                            }
                          },
                          child: const Text(
                            "Send Verification Code",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Secondary Polished Note
                const Text(
                  "By continuing, you agree to our Terms of Service",
                  style: TextStyle(fontSize: 12, color: Colors.black26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
