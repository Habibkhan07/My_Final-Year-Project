import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/failures/auth_failure.dart'; // Import Sealed Class
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final timerAsync = ref.watch(timerProvider);

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenOrNull(
        // ERROR HANDLING
        error: (error, _) {
          String msg = error.toString();

          if (error is AuthFailure) {
            switch (error) {
              case InvalidInput(:final errors):
                // Backend sends {"otp": ["Invalid OTP"]}
                msg = errors['otp']?.first ?? "Invalid OTP code.";
                _otpController.clear(); // Clear for retry

              case ResourcesExpired(:final message):
                msg = message; // "Session expired"
                context.go('/login'); // Redirect to login
                return;

              case ServerError(:final message):
                msg = message;

              default:
                msg = "Verification failed.";
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Branding Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                "Verify Phone",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Phone Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: "Enter the 4-digit code sent to\n"),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 4-Digit Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: "0000",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade200,
                    letterSpacing: 24,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) {
                  if (val.length == 4) {
                    ref
                        .read(authProvider.notifier)
                        .verifyOtp(widget.phoneNumber, val);
                  }
                },
              ),
              const SizedBox(height: 40),

              // Verify Button
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(authProvider.notifier)
                              .verifyOtp(
                                widget.phoneNumber,
                                _otpController.text,
                              );
                        },
                        child: const Text(
                          "Verify & Continue",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Timer & Resend Logic
              timerAsync.when(
                data: (seconds) {
                  if (seconds == null) {
                    return TextButton(
                      onPressed: authAsync.isLoading
                          ? null
                          : () {
                              ref.invalidate(timerProvider);
                              ref
                                  .read(authProvider.notifier)
                                  .requestOtp(widget.phoneNumber);
                            },
                      child: const Text(
                        "Resend Code",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                  return Text(
                    "Resend code in ${seconds}s",
                    style: const TextStyle(
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
