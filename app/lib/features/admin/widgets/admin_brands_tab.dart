import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_service.dart';
import 'admin_scaffold.dart';

class AdminBrandsTab extends ConsumerWidget {
  const AdminBrandsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsync<List<AdminBrand>>(
      value: ref.watch(adminBrandsProvider),
      onRetry: () => ref.invalidate(adminBrandsProvider),
      builder: (brands) {
        if (brands.isEmpty) {
          return const Center(
            child: Text('No brand applications yet.',
                style: TextStyle(color: AppColors.inkMuted)),
          );
        }
        // Pending first, so the admin sees what needs action.
        final sorted = [...brands]..sort((a, b) {
            int rank(String s) => s == 'pending' ? 0 : (s == 'approved' ? 1 : 2);
            return rank(a.status).compareTo(rank(b.status));
          });
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _BrandRow(brand: sorted[i]),
        );
      },
    );
  }
}

class _BrandRow extends ConsumerWidget {
  const _BrandRow({required this.brand});
  final AdminBrand brand;

  Future<void> _decide(
      BuildContext context, WidgetRef ref, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepoProvider).decideBrand(brand.id, approve);
      ref.invalidate(adminBrandsProvider);
      messenger.showSnackBar(SnackBar(
          content: Text('Brand ${approve ? 'approved' : 'rejected'}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (brand.status) {
      'approved' => ('Approved', AppColors.success),
      'rejected' => ('Rejected', AppColors.danger),
      _ => ('Pending', AppColors.warning),
    };

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(brand.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              StatusPill(label: label, color: color),
            ],
          ),
          const SizedBox(height: 10),
          // Who submitted this brand.
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 15, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  brand.ownerContact != null
                      ? '${brand.ownerName} · ${brand.ownerContact}'
                      : brand.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.inkMuted),
                ),
              ),
            ],
          ),
          if (brand.website != null && brand.website!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: 15, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    brand.website!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                ),
              ],
            ),
          ],
          if (brand.status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decide(context, ref, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decide(context, ref, true),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
