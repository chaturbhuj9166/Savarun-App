import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The design's Fit Score visual: soft overlapping pastel blobs with the score
/// sitting in the middle. Animates up from 0 when it first appears.
class ScoreBlob extends StatefulWidget {
  const ScoreBlob({super.key, required this.score, this.size = 250});

  final int score;
  final double size;

  @override
  State<ScoreBlob> createState() => _ScoreBlobState();
}

class _ScoreBlobState extends State<ScoreBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Stack(
              children: [
                _blob(s, AppColors.sage, 0.62, const Alignment(-0.55, -0.5)),
                _blob(s, AppColors.primaryDeep, 0.58, const Alignment(0.6, -0.35)),
                _blob(s, AppColors.primaryLight, 0.70, const Alignment(0.15, 0.5)),
                _blob(s, AppColors.lilac, 0.50, const Alignment(-0.5, 0.55)),
              ],
            ),
          ),
          // White inner disc so the number stays readable over the blobs.
          Container(
            width: s * 0.56,
            height: s * 0.56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.82),
            ),
          ),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final shown = (widget.score * _c.value).round();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$shown',
                    style: TextStyle(
                      fontSize: s * 0.24,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: s * 0.06,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _blob(double s, Color color, double scale, Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        width: s * scale,
        height: s * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.35),
            ],
          ),
        ),
      ),
    );
  }
}
