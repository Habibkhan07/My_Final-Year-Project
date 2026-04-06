import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/failures/auth_failure.dart';
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
        error: (error, _) {
          String msg = error.toString();

          if (error is AuthFailure) {
            switch (error) {
              case InvalidInput(:final errors, :final message):
                // Field error first; falls back to server's message
                // (covers both wrong-OTP and SMS-delivery failures on resend)
                msg = errors['otp']?.first ?? message;
                _otpController.clear();

              case ResourcesExpired(:final message):
                // Session fully gone — send back to login
                msg = message;
                ScaffoldMessenger.of(context).clearSnackBars();
                context.go('/login');
                return;

              case ServerError(:final message):
                msg = message;

              default:
                msg = "Verification failed.";
            }
          }

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

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

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: "Enter the 6-digit code sent to\n"),
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

              // 6-digit OTP field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: "000000",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade200,
                    letterSpacing: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
                onChanged: (val) {
                  // Auto-submit when all 6 digits are entered
                  if (val.length == 6) {
                    ref.read(authProvider.notifier).verifyOtp(widget.phoneNumber, val);
                  }
                },
              ),
              const SizedBox(height: 40),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: authAsync.isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
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
                              .verifyOtp(widget.phoneNumber, _otpController.text);
                        },
                        child: const Text(
                          "Verify & Continue",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Expiry countdown — purely informational, not a gate on resend
              timerAsync.when(
                data: (seconds) => seconds != null
                    ? Text(
                        "Code expires in ${seconds}s",
                        style: const TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      )
                    : const Text(
                        "Code has expired",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),

              // Resend button — always available, not gated behind the timer
              TextButton(
                onPressed: authAsync.isLoading
                    ? null
                    : () {
                        // Restart the expiry countdown and request a fresh OTP
                        ref.invalidate(timerProvider);
                        ref.read(authProvider.notifier).requestOtp(widget.phoneNumber);
                      },
                child: const Text(
                  "Resend Code",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
