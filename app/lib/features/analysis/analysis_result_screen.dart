import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'models/outfit_analysis.dart';
import 'widgets/fit_score_ring.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key, required this.analysis});
  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Your Outfit Analysis'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go(Routes.home)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(child: FitScoreRing(score: a.fitScore)),
          const SizedBox(height: 8),
          Center(
            child: Text(_scoreLabel(a.fitScore),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(height: 28),

          if (a.summary.isNotEmpty) ...[
            _Card(
              title: 'AI Verdict',
              child: Text(a.summary, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink)),
            ),
            const SizedBox(height: 16),
          ],

          _Card(
            title: 'Score Breakdown',
            child: Column(children: [for (final f in a.factors) _FactorRow(factor: f)]),
          ),
          const SizedBox(height: 16),

          _Card(
            title: 'Detected',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.clothingTypes.isNotEmpty) _chips('Items', a.clothingTypes),
                if (a.palette.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Colors', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final c in a.palette) _swatch(c)]),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _infoPill('Pattern', a.pattern),
                  _infoPill('Fit', a.fitType),
                  if (a.fabric.isNotEmpty) _infoPill('Fabric', a.fabric.join(', ')),
                ]),
                if (a.accessories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _chips('Accessories', a.accessories),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (a.suggestions.isNotEmpty)
            _Card(
              title: 'Suggestions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final s in a.suggestions) _SuggestionRow(s: s)],
              ),
            ),
          const SizedBox(height: 24),

          if (a.styleDna.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => context.push(Routes.styleDna, extra: a),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('View Style DNA'),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go(Routes.home),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analyze Another Outfit'),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int s) {
    if (s >= 85) return 'Excellent — you nailed it!';
    if (s >= 70) return 'Great look 🔥';
    if (s >= 50) return 'Good, with room to level up';
    if (s == 0) return 'Couldn\'t read this outfit';
    return 'Let\'s refine this fit';
  }

  Widget _chips(String label, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _swatch(PaletteColor c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 22, height: 22, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle, border: Border.all(color: AppColors.line))),
        const SizedBox(width: 6),
        Text(c.name, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(factor.name, style: const TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500))),
              Text('${factor.weight}%', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              const SizedBox(width: 10),
              Text('${factor.score}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: factor.score / 100,
              minHeight: 6,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.s});
  final Suggestion s;

  @override
  Widget build(BuildContext context) {
    final icon = s.type == 'add'
        ? Icons.add_circle_outline_rounded
        : (s.type == 'swap' ? Icons.swap_horiz_rounded : Icons.check_circle_outline_rounded);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 18, color: AppColors.accent)),
          const SizedBox(width: 10),
          Expanded(child: Text(s.text, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink))),
        ],
      ),
    );
  }
}
