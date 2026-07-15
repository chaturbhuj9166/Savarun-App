import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/savarun_logo.dart';
import 'data/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Router redirect sends us to Home once the auth state updates.
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
    } catch (e) {
      _showError('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const SavarunLogo(fontSize: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to analyze your style',
                    style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
                  ),
                  const Spacer(flex: 2),
                  _SocialButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Continue with Google',
                    onTap: _busy ? null : _google,
                  ),
                  const SizedBox(height: 14),
                  _SocialButton(
                    icon: Icons.phone_rounded,
                    label: 'Continue with Phone',
                    onTap: _busy ? null : () => context.push(Routes.phoneLogin),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: AppColors.ink),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
