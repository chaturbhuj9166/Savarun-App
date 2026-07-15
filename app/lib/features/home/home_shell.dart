import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';
import '../wardrobe/wardrobe_screen.dart';
import 'home_screen.dart';

/// Main app shell with bottom navigation.
/// Center "Camera" tab is the primary action (AI Outfit Analyzer).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Real tab pages. Index 2 (Camera) is handled separately as a push.
  static const _pages = [
    HomeScreen(),
    WardrobeScreen(),
    SizedBox.shrink(), // camera placeholder slot (never shown)
    ShopScreen(),
    ProfileScreen(),
  ];

  static const _tabs = [
    _TabItem(Icons.home_rounded, 'Home'),
    _TabItem(Icons.checkroom_rounded, 'Wardrobe'),
    _TabItem(Icons.camera_alt_rounded, 'Camera'),
    _TabItem(Icons.shopping_bag_rounded, 'Shop'),
    _TabItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          // Center "Camera" tab opens the AI Outfit Analyzer flow instead
          // of switching to a tab page.
          if (i == 2) {
            context.push(Routes.camera);
            return;
          }
          setState(() => _index = i);
        },
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon, color: AppColors.inkMuted),
              selectedIcon: Icon(t.icon, color: AppColors.primary),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
