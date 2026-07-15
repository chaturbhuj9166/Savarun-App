import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Temporary text-based wordmark for Savarun.
///
/// TODO(logo): Replace with the real logo asset once provided.
/// Just swap the build() body to an Image.asset('assets/images/logo.png').
class SavarunLogo extends StatelessWidget {
  const SavarunLogo({
    super.key,
    this.fontSize = 34,
    this.onDark = false,
  });

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    );

    if (onDark) {
      return Text('SAVARUN', style: style.copyWith(color: AppColors.white));
    }

    // Gradient wordmark on light backgrounds.
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
      child: Text('SAVARUN', style: style.copyWith(color: Colors.white)),
    );
  }
}
