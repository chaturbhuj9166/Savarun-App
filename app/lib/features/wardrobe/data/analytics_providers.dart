import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

/// One entry of the most-used colour breakdown.
class ColorCount {
  const ColorCount(this.name, this.count);
  final String name;
  final int count;
}

/// A rarely-worn wardrobe item, surfaced so the user can declutter.
class LeastWornItem {
  const LeastWornItem({
    required this.id,
    required this.category,
    required this.colorName,
    required this.wearCount,
  });

  final String id;
  final String category;
  final String colorName;
  final int wearCount;
}

/// Wardrobe Analytics (Module 2) as returned by `GET /api/wardrobe/analytics`.
class WardrobeAnalytics {
  const WardrobeAnalytics({
    required this.totalItems,
    required this.colorBreakdown,
    required this.categoryCounts,
    required this.gapAlerts,
    required this.leastWorn,
  });

  final int totalItems;
  final List<ColorCount> colorBreakdown;
  final Map<String, int> categoryCounts;
  final List<String> gapAlerts;
  final List<LeastWornItem> leastWorn;

  factory WardrobeAnalytics.fromJson(Map<String, dynamic> d) {
    return WardrobeAnalytics(
      totalItems: (d['totalItems'] ?? 0) as int,
      colorBreakdown: (d['colorBreakdown'] as List? ?? [])
          .map((c) => ColorCount(c['name'] ?? '', (c['count'] ?? 0) as int))
          .toList(),
      categoryCounts: {
        for (final e in (d['categoryCounts'] as Map? ?? {}).entries)
          e.key.toString(): (e.value ?? 0) as int,
      },
      gapAlerts: List<String>.from(d['gapAlerts'] ?? const []),
      leastWorn: (d['leastWorn'] as List? ?? [])
          .map((i) => LeastWornItem(
                id: i['id'] ?? '',
                category: i['category'] ?? '',
                colorName: i['colorName'] ?? '',
                wearCount: (i['wearCount'] ?? 0) as int,
              ))
          .toList(),
    );
  }
}

final wardrobeAnalyticsProvider =
    FutureProvider.autoDispose<WardrobeAnalytics>((ref) async {
  const client = ApiClient();
  final json = await client.get(AppConfig.wardrobeAnalyticsEndpoint);
  return WardrobeAnalytics.fromJson(json['data'] as Map<String, dynamic>);
});
