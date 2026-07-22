import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import 'data/shop_providers.dart';

/// Product Details. Per the spec this is an affiliate marketplace — there is
/// no cart or checkout; the button records the click and hands the user off to
/// the brand's own website.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _busy = false;

  Future<void> _openBrandSite() async {
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(shopRepoProvider)
          .resolveAffiliateUrl(widget.product.id);
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Product Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 300,
              width: double.infinity,
              color: AppColors.white,
              child: p.imageUrl.isEmpty
                  ? const Icon(Icons.image_outlined,
                      size: 48, color: AppColors.inkMuted)
                  : Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.inkMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.brandName,
            style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Text(
            '₹${p.price}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (p.category.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.category,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              p.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _busy ? null : _openBrandSite,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  )
                : const Text('Buy on Brand Site'),
          ),
          const SizedBox(height: 12),
          const Text(
            'You will be taken to the brand’s website to complete the purchase.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
