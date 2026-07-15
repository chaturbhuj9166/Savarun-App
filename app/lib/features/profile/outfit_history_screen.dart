import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Past AI outfit analyses. Real history appears once the AI Analyzer is
/// wired (needs the OpenAI key). Until then, empty state.
class OutfitHistoryScreen extends StatelessWidget {
  const OutfitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Outfit History')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.history_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('No analyses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Your analyzed outfits and Fit Scores will appear here.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
