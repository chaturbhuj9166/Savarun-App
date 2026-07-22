import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'data/analytics_providers.dart';

/// Wardrobe Analytics (Module 2): total items, most-used colours, gap alerts
/// and least-worn items.
class WardrobeAnalyticsScreen extends ConsumerWidget {
  const WardrobeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(wardrobeAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Wardrobe Analytics')),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: AppColors.inkMuted),
                const SizedBox(height: 14),
                const Text(
                  'Could not load analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => ref.invalidate(wardrobeAnalyticsProvider),
                  child: const Center(child: Text('Retry')),
                ),
              ],
            ),
          ),
        ),
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total Items',
                    value: '${a.totalItems}',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    label: 'Categories',
                    value: '${a.categoryCounts.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              title: 'Most Used Colors',
              child: a.colorBreakdown.isEmpty
                  ? const _Hint('Add items to see your colour breakdown.')
                  : Column(
                      children: [
                        Center(
                          child: _ColorDonut(colors: a.colorBreakdown),
                        ),
                        const SizedBox(height: 22),
                        for (var i = 0; i < a.colorBreakdown.length; i++)
                          _ColorRow(
                            entry: a.colorBreakdown[i],
                            total: a.totalItems,
                            color: _paletteAt(i),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _Card(
              title: 'Wardrobe Gap',
              child: a.gapAlerts.isEmpty
                  ? const _Hint('No gaps found — your wardrobe looks balanced.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final alert in a.gapAlerts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.info_outline_rounded,
                                      size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    alert,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _Card(
              title: 'Least Worn Items',
              child: a.leastWorn.isEmpty
                  ? const _Hint('Nothing to declutter yet.')
                  : Column(
                      children: [
                        for (final item in a.leastWorn)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    [item.colorName, item.category]
                                        .where((s) => s.isNotEmpty)
                                        .join(' · '),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.wearCount == 1
                                      ? 'worn once'
                                      : 'worn ${item.wearCount}×',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _paletteAt(int i) {
    const palette = [
      AppColors.primaryDeep,
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.sage,
      AppColors.sand,
      AppColors.lilac,
    ];
    return palette[i % palette.length];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut of the most-used colours, sized by share of the wardrobe.
class _ColorDonut extends StatelessWidget {
  const _ColorDonut({required this.colors});
  final List<ColorCount> colors;

  @override
  Widget build(BuildContext context) {
    final total = colors.fold<int>(0, (sum, c) => sum + c.count);
    final top = colors.first;
    final topShare = total == 0 ? 0 : (top.count / total * 100).round();

    return SizedBox(
      width: 170,
      height: 170,
      child: CustomPaint(
        painter: _DonutPainter(colors: colors, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$topShare%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                top.name,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.colors, required this.total});
  final List<ColorCount> colors;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = size.center(Offset.zero);
    const stroke = 24.0;
    final radius = size.width / 2 - stroke / 2;
    var start = -math.pi / 2;

    for (var i = 0; i < colors.length; i++) {
      final sweep = 2 * math.pi * (colors[i].count / total);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.03,
        false,
        Paint()
          ..color = WardrobeAnalyticsScreen._paletteAt(i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.colors != colors || old.total != total;
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.entry,
    required this.total,
    required this.color,
  });

  final ColorCount entry;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${entry.count}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
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

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
    );
  }
}
