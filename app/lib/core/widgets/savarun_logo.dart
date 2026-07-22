import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// The Savarun wordmark: the client's "S" mark followed by the name.
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
    final color = onDark ? AppColors.white : AppColors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.logoMark,
          height: fontSize * 1.1,
          // The mark ships as black artwork; tint it white on dark surfaces.
          color: onDark ? AppColors.white : null,
        ),
        SizedBox(width: fontSize * 0.22),
        Text(
          'SAVARUN',
          style: GoogleFonts.poppins(
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w700,
            letterSpacing: fontSize * 0.09,
            color: color,
          ),
        ),
      ],
    );
  }
}
