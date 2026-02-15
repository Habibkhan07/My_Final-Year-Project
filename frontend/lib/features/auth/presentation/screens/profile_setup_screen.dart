// profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    // Maintain Logic: Listener for Side Effects
    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        data: (state) {
          if (state.successMessage != null && !state.user!.nameRequired) {
            // Show Success Feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/home');
          }
        },
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err.toString().replaceAll('Exception: ', ''),
            ), // Clean Error
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Polished iOS-style back button
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
              // Branding Icon Hub
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                "Create Your Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please enter your details to complete\nyour account registration.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black45,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),

              // Polished First Name Input
              _buildTextField(
                controller: _firstNameController,
                label: "First Name",
                hint: "e.g. John",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),

              // Polished Last Name Input
              _buildTextField(
                controller: _lastNameController,
                label: "Last Name",
                hint: "e.g. Doe",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 48),

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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(authProvider.notifier)
                              .completeSignup(
                                _firstNameController.text,
                                _lastNameController.text,
                              );
                        },
                        child: const Text(
                          "Finish Setup",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable polished TextField to match Login style
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}
