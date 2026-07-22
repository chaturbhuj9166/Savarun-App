import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/outfit_analysis.dart';

/// The detailed breakdown behind the Fit Score — the spec's five weighted
/// factors plus everything the vision model detected.
class FullReportScreen extends StatelessWidget {
  const FullReportScreen({super.key, required this.analysis});
  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Full Report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _Card(
            title: 'Score Breakdown',
            child: Column(
              children: [for (final f in a.factors) _FactorRow(factor: f)],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Detected',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.clothingTypes.isNotEmpty) _chips('Items', a.clothingTypes),
                if (a.palette.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _Label('Colors'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    children: [for (final c in a.palette) _Swatch(color: c)],
                  ),
                ],
                const SizedBox(height: 16),
                _row('Pattern', a.pattern),
                _row('Fit', a.fitType),
                if (a.fabric.isNotEmpty) _row('Fabric', a.fabric.join(', ')),
                if (a.accessories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _chips('Accessories', a.accessories),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: _Label(label)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final PaletteColor color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          color.name,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  factor.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${factor.weight}%',
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 26,
                child: Text(
                  '${factor.score}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: factor.score / 100,
              minHeight: 5,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
