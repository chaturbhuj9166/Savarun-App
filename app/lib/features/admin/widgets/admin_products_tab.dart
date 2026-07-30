import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_service.dart';
import 'admin_scaffold.dart';

class AdminProductsTab extends ConsumerWidget {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsync<List<AdminProduct>>(
      value: ref.watch(adminProductsProvider),
      onRetry: () => ref.invalidate(adminProductsProvider),
      builder: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text('No products yet.',
                style: TextStyle(color: AppColors.inkMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ProductRow(product: products[i]),
        );
      },
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});
  final AdminProduct product;

  Future<void> _run(BuildContext context, WidgetRef ref,
      Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(adminProductsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepoProvider);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${product.brandName} · ₹${product.price}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkMuted)),
                  ],
                ),
              ),
              StatusPill(
                label: product.approved ? 'Approved' : 'Unapproved',
                color:
                    product.approved ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              // Approve / unapprove.
              Expanded(
                child: _Toggle(
                  label: 'Approved',
                  value: product.approved,
                  onChanged: (v) => _run(context, ref,
                      () => repo.setProductApproval(product.id, v)),
                ),
              ),
              // Show / hide.
              Expanded(
                child: _Toggle(
                  label: 'Visible',
                  value: !product.hidden,
                  onChanged: (v) => _run(context, ref,
                      () => repo.setProductHidden(product.id, !v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        const Spacer(),
        Switch(
          value: value,
          activeThumbColor: AppColors.ink,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
