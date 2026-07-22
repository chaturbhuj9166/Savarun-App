import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';
import '../social/explore_screen.dart';
import '../wardrobe/wardrobe_screen.dart';
import 'home_screen.dart';

/// Main app shell with the design's minimal icon-only bottom navigation.
/// The centre "Wardrobe" slot is the highlighted tab, matching the design.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    ShopScreen(),
    WardrobeScreen(),
    ExploreScreen(),
    ProfileScreen(),
  ];

  static const _icons = [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.checkroom_rounded,
    Icons.search_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _icons.length; i++)
                  _NavIcon(
                    icon: _icons[i],
                    selected: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected tab gets the design's soft pill behind the icon.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 23,
          color: selected ? AppColors.ink : AppColors.inkMuted,
        ),
      ),
    );
  }
}
