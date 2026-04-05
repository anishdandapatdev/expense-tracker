import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/controllers/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Email + Password sign-up
  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authControllerProvider.notifier).signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (!mounted) return;
    final authState = ref.read(authControllerProvider);

    if (authState.hasError) {
      final friendlyMsg = _friendlyFirebaseError(authState.error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMsg), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Account created! Please check your email to verify.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      context.go('/login');
    }
  }

  /// Google Sign-In — same flow as the login screen
  void _handleGoogleSignUp() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_friendlyFirebaseError(authState.error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // New Google users land on currency-setup, existing go straight home
      context.go('/currency-setup');
    }
  }

  /// Converts raw Firebase error strings to readable messages
  String _friendlyFirebaseError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email. Try logging in.';
    }
    if (raw.contains('invalid-email')) return 'Please enter a valid email.';
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('channel-error')) {
      return 'Please fill in all fields.';
    }
    return 'Sign-up failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Email ────────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ─────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Sign Up Button ────────────────────────────────────────
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign Up',
                          style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // ── OR Divider ────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style:
                              TextStyle(color: Colors.grey.shade500)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Google Sign-Up Button ─────────────────────────────────
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleSignUp,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Sign up with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Already have account ──────────────────────────────────
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}