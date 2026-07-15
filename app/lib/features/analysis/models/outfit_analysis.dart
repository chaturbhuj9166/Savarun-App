import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// One weighted factor that feeds the Fit Score.
class ScoreFactor {
  const ScoreFactor({required this.name, required this.score, required this.weight});
  final String name; // display name e.g. "Trend Match"
  final int score; // 0..100
  final int weight; // weight as a percentage for display
}

/// One slice of the Style DNA breakdown.
class StyleSlice {
  const StyleSlice({required this.style, required this.percent, required this.color});
  final String style;
  final int percent;
  final Color color;
}

/// A colour detected in the outfit.
class PaletteColor {
  const PaletteColor(this.name, this.hex);
  final String name;
  final String hex;
  Color get color {
    final h = hex.replaceFirst('#', '');
    return Color(int.tryParse('FF$h', radix: 16) ?? 0xFF9E9E9E);
  }
}

/// A piece of AI feedback.
class Suggestion {
  const Suggestion(this.type, this.text);
  final String type; // add | swap | keep
  final String text;
}

/// The full result of analyzing one outfit photo (from the backend).
class OutfitAnalysis {
  const OutfitAnalysis({
    required this.fitScore,
    required this.factors,
    required this.styleDna,
    required this.clothingTypes,
    required this.palette,
    required this.pattern,
    required this.fabric,
    required this.fitType,
    required this.accessories,
    required this.summary,
    required this.suggestions,
    this.imageUrl,
  });

  final int fitScore;
  final List<ScoreFactor> factors;
  final List<StyleSlice> styleDna;
  final List<String> clothingTypes;
  final List<PaletteColor> palette;
  final String pattern;
  final List<String> fabric;
  final String fitType;
  final List<String> accessories;
  final String summary;
  final List<Suggestion> suggestions;
  final String? imageUrl;

  static const _dnaColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.primaryLight,
    Color(0xFF00B8A9),
    Color(0xFFF6A700),
  ];

  static const _factorLabels = {
    'trendMatch': 'Trend Match',
    'colorHarmony': 'Color Harmony',
    'styleConsistency': 'Style Consistency',
    'silhouetteBalance': 'Silhouette Balance',
    'accessories': 'Accessories',
  };

  factory OutfitAnalysis.fromJson(Map<String, dynamic> d) {
    final breakdown = (d['breakdown'] as List? ?? []).map((b) {
      final key = b['factor'] as String? ?? '';
      return ScoreFactor(
        name: _factorLabels[key] ?? key,
        score: (b['score'] ?? 0) as int,
        weight: (b['weight'] ?? 0) as int,
      );
    }).toList();

    final dna = <StyleSlice>[];
    final rawDna = d['styleDna'] as List? ?? [];
    for (var i = 0; i < rawDna.length; i++) {
      final s = rawDna[i];
      dna.add(StyleSlice(
        style: s['category'] ?? '',
        percent: (s['percentage'] ?? 0) as int,
        color: _dnaColors[i % _dnaColors.length],
      ));
    }

    final det = (d['detection'] as Map?) ?? {};
    final fb = (d['feedback'] as Map?) ?? {};

    return OutfitAnalysis(
      fitScore: (d['fitScore'] ?? 0) as int,
      factors: breakdown,
      styleDna: dna,
      clothingTypes: List<String>.from(det['clothingTypes'] ?? const []),
      palette: (det['colorPalette'] as List? ?? [])
          .map((c) => PaletteColor(c['name'] ?? '', c['hex'] ?? '#9E9E9E'))
          .toList(),
      pattern: det['pattern'] ?? 'other',
      fabric: List<String>.from(det['fabric'] ?? const []),
      fitType: det['fitType'] ?? 'other',
      accessories: List<String>.from(det['accessories'] ?? const []),
      summary: fb['summary'] ?? '',
      suggestions: (fb['suggestions'] as List? ?? [])
          .map((s) => Suggestion(s['type'] ?? 'keep', s['text'] ?? ''))
          .toList(),
      imageUrl: d['imageUrl'],
    );
  }
}
