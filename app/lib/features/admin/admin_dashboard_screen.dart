import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/admin_service.dart';
import 'widgets/admin_analytics_tab.dart';
import 'widgets/admin_users_tab.dart';
import 'widgets/admin_brands_tab.dart';
import 'widgets/admin_products_tab.dart';
import 'widgets/admin_weights_tab.dart';

/// Admin Dashboard (Module 5). Runs in the same Flutter app — on web for the
/// owner — and is gated by the `admin` custom claim. Non-admins are bounced
/// back home.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _denied(context, 'Could not verify admin access.'),
      data: (ok) {
        if (!ok) {
          return _denied(
              context, 'This area is for Savarun admins only.');
        }
        return const _Dashboard();
      },
    );
  }

  Widget _denied(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 48, color: AppColors.inkMuted),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  static const _tabs = [
    Tab(text: 'Analytics'),
    Tab(text: 'Users'),
    Tab(text: 'Brands'),
    Tab(text: 'Products'),
    Tab(text: 'AI Weights'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            // Centre the tab bar within the same max width as the content so
            // it doesn't stretch across a wide browser window.
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.ink,
                  unselectedLabelColor: AppColors.inkMuted,
                  indicatorColor: AppColors.ink,
                  dividerColor: Colors.transparent,
                  tabs: _tabs,
                ),
              ),
            ),
          ),
        ),
        // Constrain the dashboard body so cards/lists don't span the whole
        // width on desktop — it reads as a proper centred dashboard.
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: const TabBarView(
              children: [
                AdminAnalyticsTab(),
                AdminUsersTab(),
                AdminBrandsTab(),
                AdminProductsTab(),
                AdminWeightsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
