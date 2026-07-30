import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'data/shop_providers.dart';

/// Brand submission (Module 4). A user applies to list their brand; once the
/// admin approves it, they can add products. This screen shows their existing
/// submissions and lets them apply / add a product.
class SellOnSavarunScreen extends ConsumerWidget {
  const SellOnSavarunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(myBrandsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Sell on Savarun')),
      body: brands.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Could not load your brands.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkMuted)),
          ),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'List your brand',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit your brand for review. Once our team approves it, you can '
              'add products that appear in the Marketplace.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _submitBrand(context, ref),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Apply with a Brand'),
            ),
            const SizedBox(height: 28),
            if (list.isNotEmpty) ...[
              const Text('Your Brands',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final b in list) _BrandRow(brand: b),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitBrand(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final siteController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apply with a Brand',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Brand name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: siteController,
              keyboardType: TextInputType.url,
              decoration:
                  const InputDecoration(hintText: 'Website (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit for Review'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await ref.read(shopRepoProvider).submitBrand(
            name: name,
            website: siteController.text.trim(),
          );
      ref.invalidate(myBrandsProvider);
      messenger.showSnackBar(
          const SnackBar(content: Text('Submitted for review ✨')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not submit: $e')));
    }
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.brand});
  final MyBrand brand;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (brand.status) {
      'approved' => ('Approved', AppColors.success),
      'rejected' => ('Rejected', AppColors.danger),
      _ => ('Pending review', AppColors.warning),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              brand.name,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
