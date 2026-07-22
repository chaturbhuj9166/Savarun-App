import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  /// Holds the splash briefly, then routes based on auth + onboarding state.
  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // Already signed in → straight to the app.
    if (FirebaseAuth.instance.currentUser != null) {
      context.go(Routes.home);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!mounted) return;
    context.go(seenOnboarding ? Routes.login : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.artCanvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.logoBackground, fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppAssets.logoMark, width: 120),
                const SizedBox(height: 8),
                const Text(
                  'SAVARUN',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI FASHION & STYLE\nPLATFORM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                    color: AppColors.inkMuted,
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
