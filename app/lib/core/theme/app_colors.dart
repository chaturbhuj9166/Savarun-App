import 'package:flutter/material.dart';

/// Savarun palette, taken from the client's approved UI design.
///
/// Design language: warm cream canvas, white cards, near-black primary
/// actions, and purple/sage/sand used only as accents (blobs, charts, chips).
class AppColors {
  AppColors._();

  // ── Canvas & surfaces ──
  /// Warm off-white page background used across the app.
  static const Color canvas = Color(0xFFF6F4F0);
  static const Color white = Color(0xFFFFFFFF);
  /// Fill for inputs, chips and soft tiles.
  static const Color surface = Color(0xFFF1EFEA);
  /// Matches the backdrop baked into the brand artwork, so the splash and
  /// onboarding screens have no visible seam around the illustrations.
  static const Color artCanvas = Color(0xFFF5F5F6);
  static const Color line = Color(0xFFE8E4DE);

  // ── Ink (text + primary actions) ──
  /// Near-black used for primary buttons and headings.
  static const Color ink = Color(0xFF111214);
  static const Color inkSoft = Color(0xFF3A3A41);
  static const Color inkMuted = Color(0xFF8B8B93);

  // ── Accents ──
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDeep = Color(0xFF3D3574);
  static const Color primaryLight = Color(0xFFB9AEE8);
  static const Color sage = Color(0xFFA9C4A0);
  static const Color sand = Color(0xFFE9DFD2);
  static const Color lilac = Color(0xFFDCD6F5);

  // ── Status ──
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFE0A44A);
  static const Color danger = Color(0xFFE05B4C);

  /// Soft purple→sage blend used by the Fit Score meter and hero blobs.
  static const LinearGradient scoreGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary, primaryLight],
  );

  /// Pastel blob gradient for onboarding / empty-state artwork.
  static const LinearGradient blobGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lilac, sand, sage],
  );

  /// Kept for the analyzer hero — deep purple orb from the design.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary],
  );
}
