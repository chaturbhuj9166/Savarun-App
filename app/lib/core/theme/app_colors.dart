import 'package:flutter/material.dart';

/// Savarun brand palette.
/// Primary purple is taken from the spec's branding (header + wordmark).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5546C9);
  static const Color primaryLight = Color(0xFF8B7CF0);
  static const Color accent = Color(0xFFFF7AC6); // fashion-y pink accent

  // Neutrals
  static const Color ink = Color(0xFF1A1A2E); // near-black text
  static const Color inkMuted = Color(0xFF6B6B80);
  static const Color line = Color(0xFFE7E7F0);
  static const Color surface = Color(0xFFF7F7FB);
  static const Color white = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1B044);
  static const Color danger = Color(0xFFE74C3C);

  // Fit score ring gradient (low → high)
  static const Color scoreLow = Color(0xFFE74C3C);
  static const Color scoreMid = Color(0xFFF1B044);
  static const Color scoreHigh = Color(0xFF2ECC71);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
}
