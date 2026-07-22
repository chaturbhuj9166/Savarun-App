import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../analysis/data/history_providers.dart';
import '../profile/data/profile_providers.dart';
import '../shop/data/shop_providers.dart';

/// Home — the design's greeting, the big "Analyze Outfit" orb, and a strip of
/// recent analyses.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.name.split(' ').first ?? 'there';
    final photo = profile?.photoURL;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()},',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '$name 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.settings),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.white,
                  backgroundImage:
                      (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                  child: (photo == null || photo.isEmpty)
                      ? const Icon(Icons.person_outline_rounded,
                          size: 20, color: AppColors.inkMuted)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'How do you feel\nabout your outfit today?',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: _AnalyzeOrb(onTap: () => context.push(Routes.camera)),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Analyses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(Routes.outfitHistory),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _RecentStrip(),
          const SizedBox(height: 32),
          const _TrendingBrands(),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// The design's hero: a dark orb sitting on soft drifting blobs. The blobs
/// breathe continuously and the orb dips on press.
class _AnalyzeOrb extends StatefulWidget {
  const _AnalyzeOrb({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AnalyzeOrb> createState() => _AnalyzeOrbState();
}

class _AnalyzeOrbState extends State<_AnalyzeOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _pressed = false;

  static const _size = 280.0;
  static const _orbSize = 168.0;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: _size,
        height: _size,
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, child) {
            // One slow cycle drives both blobs, half a turn apart, so the
            // cluster gently swells and shifts instead of spinning.
            final t = _drift.value * 2 * math.pi;
            final swell = 1 + math.sin(t) * 0.05;

            return Stack(
              alignment: Alignment.center,
              children: [
                _blob(
                  color: AppColors.lilac,
                  diameter: _size * 0.86 * swell,
                  offset: Offset(math.cos(t) * 12 - 18, math.sin(t) * 12),
                  opacity: 0.55,
                ),
                _blob(
                  color: AppColors.white,
                  diameter: _size * 0.78 / swell,
                  offset: Offset(math.cos(t + math.pi) * 14 + 22,
                      math.sin(t + math.pi) * 10),
                  opacity: 0.9,
                ),
                _blob(
                  color: AppColors.primaryLight,
                  diameter: _size * 0.66 * swell,
                  offset: Offset(math.sin(t) * 10, math.cos(t) * 8 + 6),
                  opacity: 0.45,
                ),
                child!,
              ],
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.94 : 1,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: Container(
                  width: _orbSize,
                  height: _orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF232041), Color(0xFF15132B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.28),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.center_focus_weak_rounded,
                          color: AppColors.white, size: 28),
                      SizedBox(height: 12),
                      Text(
                        'ANALYZE',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                        ),
                      ),
                      Text(
                        'OUTFIT',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The design's small sparkle sitting off the orb's right edge.
              const Positioned(
                right: 6,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob({
    required Color color,
    required double diameter,
    required Offset offset,
    required double opacity,
  }) {
    return Transform.translate(
      offset: offset,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip of the user's most recent analyses.
class _RecentStrip extends ConsumerWidget {
  const _RecentStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(outfitHistoryProvider);

    return history.when(
      loading: () => const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox(
        height: 130,
        child: Center(
          child: Text(
            'Could not load history',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Container(
            height: 130,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No analyses yet — tap the orb to start.',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          );
        }

        final shown = items.take(10).toList();
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _RecentCard(entry: shown[i]),
          ),
        );
      },
    );
  }
}

/// "Trending Brands" section from Module 4 — the most-clicked approved
/// products. Hidden entirely until brands have listings.
class _TrendingBrands extends ConsumerWidget {
  const _TrendingBrands();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProductsProvider);

    return trending.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final shown = items.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Brands',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final p = shown[i];
                  return GestureDetector(
                    onTap: () =>
                        context.push(Routes.productDetails, extra: p),
                    child: SizedBox(
                      width: 118,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 118,
                              height: 118,
                              color: AppColors.white,
                              child: p.imageUrl.isEmpty
                                  ? const Icon(Icons.image_outlined,
                                      color: AppColors.inkMuted)
                                  : Image.network(
                                      p.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.inkMuted),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '₹${p.price}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.analysis.imageUrl;

    return GestureDetector(
      onTap: () =>
          context.push(Routes.analysisResult, extra: entry.analysis),
      child: SizedBox(
        width: 96,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 96,
                height: 130,
                color: AppColors.surface,
                child: (url != null && url.isNotEmpty)
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.checkroom_rounded,
                          color: AppColors.inkMuted,
                        ),
                      )
                    : const Icon(Icons.checkroom_rounded,
                        color: AppColors.inkMuted),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.analysis.fitScore}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
