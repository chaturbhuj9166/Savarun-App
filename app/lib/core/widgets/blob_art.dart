import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft pastel "3D blob" artwork used on the splash and onboarding screens,
/// matching the abstract shapes in the approved design.
///
/// [variant] picks a different arrangement so each onboarding slide feels
/// distinct without needing image assets.
class BlobArt extends StatelessWidget {
  const BlobArt({super.key, this.variant = 0, this.size = 260});

  final int variant;
  final double size;

  static const _sets = <List<_Blob>>[
    [
      _Blob(AppColors.sand, 0.72, Alignment(-0.35, -0.45)),
      _Blob(AppColors.sage, 0.55, Alignment(0.55, -0.15)),
      _Blob(AppColors.primary, 0.60, Alignment(0.05, 0.50)),
      _Blob(AppColors.lilac, 0.42, Alignment(-0.60, 0.55)),
    ],
    [
      _Blob(AppColors.lilac, 0.80, Alignment(0.20, -0.35)),
      _Blob(AppColors.sage, 0.50, Alignment(-0.55, 0.10)),
      _Blob(AppColors.sand, 0.62, Alignment(0.45, 0.45)),
    ],
    [
      _Blob(AppColors.sage, 0.75, Alignment(-0.30, 0.25)),
      _Blob(AppColors.sand, 0.58, Alignment(0.40, -0.40)),
      _Blob(AppColors.primaryLight, 0.52, Alignment(0.35, 0.50)),
    ],
    [
      _Blob(AppColors.primary, 0.55, Alignment(-0.40, -0.30)),
      _Blob(AppColors.sand, 0.70, Alignment(0.35, 0.20)),
      _Blob(AppColors.sage, 0.45, Alignment(-0.25, 0.55)),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final blobs = _sets[variant % _sets.length];

    return SizedBox(
      width: size,
      height: size,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Stack(
          children: [
            for (final b in blobs)
              Align(
                alignment: b.align,
                child: Container(
                  width: size * b.scale,
                  height: size * b.scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        b.color.withValues(alpha: 0.95),
                        b.color.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Blob {
  const _Blob(this.color, this.scale, this.align);
  final Color color;
  final double scale;
  final Alignment align;
}

/// Black circular "next" button from the onboarding screens.
class CircleArrowButton extends StatelessWidget {
  const CircleArrowButton({
    super.key,
    required this.onPressed,
    this.size = 56,
    this.icon = Icons.arrow_forward_rounded,
  });

  final VoidCallback onPressed;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: AppColors.white, size: size * 0.4),
        ),
      ),
    );
  }
}
