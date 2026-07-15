import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shop / Affiliate Marketplace.
/// Real brands & products arrive with the Admin Dashboard phase
/// (brand submission → admin approval → products). Until then, empty state.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag_rounded, size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text('Shop is coming soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Brands will list products here once they\'re approved.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
