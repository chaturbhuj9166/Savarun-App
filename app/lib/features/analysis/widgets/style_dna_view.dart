import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/outfit_analysis.dart';

/// Style DNA, laid out as in the design: a soft blob cluster sized by the
/// style split, a dotted legend, and the dominant style underneath.
///
/// Shared by the result pager and the standalone Style DNA route.
class StyleDnaView extends StatelessWidget {
  const StyleDnaView({super.key, required this.analysis});

  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final dna = analysis.styleDna;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const Center(
          child: Text(
            'Style DNA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(child: _DnaBlobs(slices: dna)),
        const SizedBox(height: 32),
        for (final s in dna) _LegendRow(slice: s),
        const SizedBox(height: 24),
        if (dna.isNotEmpty) ...[
          const Center(
            child: Text(
              'Dominant Style',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              dna.first.style,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Each style becomes a blob whose size follows its percentage.
class _DnaBlobs extends StatelessWidget {
  const _DnaBlobs({required this.slices});
  final List<StyleSlice> slices;

  static const _spots = [
    Alignment(-0.35, -0.45),
    Alignment(0.5, -0.2),
    Alignment(-0.1, 0.5),
    Alignment(0.55, 0.55),
    Alignment(-0.6, 0.35),
  ];

  @override
  Widget build(BuildContext context) {
    const size = 230.0;

    return SizedBox(
      width: size,
      height: size,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Stack(
          children: [
            for (var i = 0; i < slices.length; i++)
              Align(
                alignment: _spots[i % _spots.length],
                // Clamp so a 5% style is still visible and 100% doesn't fill
                // the whole box.
                child: _blob(
                  size * (0.32 + (slices[i].percent / 100) * 0.45),
                  slices[i].color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double d, Color color) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.92),
            color.withValues(alpha: 0.4),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice});
  final StyleSlice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              slice.style,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${slice.percent}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
