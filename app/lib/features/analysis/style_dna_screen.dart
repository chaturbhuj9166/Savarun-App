import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/outfit_analysis.dart';
import 'widgets/style_dna_view.dart';

/// Standalone Style DNA route (screen 7 in the spec). The result pager shows
/// the same [StyleDnaView] as one of its pages.
class StyleDnaScreen extends StatelessWidget {
  const StyleDnaScreen({super.key, required this.analysis});
  final OutfitAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Style DNA')),
      body: SafeArea(
        top: false,
        child: StyleDnaView(analysis: analysis),
      ),
    );
  }
}
