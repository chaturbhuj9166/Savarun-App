import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_service.dart';
import 'admin_scaffold.dart';

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsync<AdminAnalytics>(
      value: ref.watch(adminAnalyticsProvider),
      onRetry: () => ref.invalidate(adminAnalyticsProvider),
      builder: (a) {
        final maxWeight = a.trendingStyles.isEmpty
            ? 1.0
            : a.trendingStyles.first.weight.toDouble();
        final maxClicks = a.topProducts.isEmpty
            ? 1
            : a.topProducts.first.clicks;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Total Users',
                    value: '${a.totalUsers}',
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Stat(
                    label: 'Active Today',
                    value: '${a.dailyActiveUsers}',
                    icon: Icons.bolt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trending Styles This Week',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (a.trendingStyles.isEmpty)
                    const Text('No analyses yet.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.inkMuted))
                  else
                    for (final s in a.trendingStyles)
                      _Bar(
                        label: s.category,
                        fraction: s.weight / maxWeight,
                        trailing: s.weight.toStringAsFixed(0),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Most-Clicked Products',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (a.topProducts.isEmpty)
                    const Text('No affiliate clicks yet.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.inkMuted))
                  else
                    for (final p in a.topProducts)
                      _Bar(
                        label: p.name,
                        fraction: maxClicks == 0 ? 0 : p.clicks / maxClicks,
                        trailing: '${p.clicks}',
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.label, required this.fraction, required this.trailing});
  final String label;
  final double fraction;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Text(trailing,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary), 
            ),
          ),
        ],
      ),
    );
  }
}
