import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../domain/failures/auth_failure.dart'; // Import Sealed Class
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the AsyncValue
    final authAsync = ref.watch(authProvider);
    final currentPhone = ref.watch(phoneNumberProvider);

    // 2. Listen for Side Effects (Navigation & Error Handling)
    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenOrNull(
        // SUCCESS CASE
        data: (state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            final phone = ref.read(phoneNumberProvider);
            if (phone.isNotEmpty) {
              context.go('/otp/$phone');
            }
          }
        },

        // ERROR CASE: Switch on Domain Exceptions
        error: (error, _) {
          String msg = error.toString();
          Color color = Colors.redAccent;

          if (error is AuthFailure) {
            switch (error) {
              case InvalidInput(:final errors, :final message):
                // Field error takes priority; fallback to the server's toast message
                // (e.g. Twilio SMS failure has no field errors but has a message)
                msg = errors['phone']?.first ?? message;
                color = Colors.orange;

              case UserAlreadyExists(:final message):
                msg = message;

              case ServerError(:final message):
                msg = message;

              case Unauthorized(:final message):
                msg = message;

              default:
                msg = "Something went wrong. Please try again.";
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
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
                // Branding Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40),

                // Header Text
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
                  "We will send a 6-digit verification code\nto your mobile number.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                // Phone Input Field
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
                    ref
                        .read(phoneNumberProvider.notifier)
                        .updatePhone(phone.completeNumber);
                  },
                ),
                const SizedBox(height: 32),

                // Action Button
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
                            if (currentPhone.isNotEmpty) {
                              ref
                                  .read(authProvider.notifier)
                                  .requestOtp(currentPhone);
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

                // Terms Note
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
