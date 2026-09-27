import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation bar for the 5 main tabs: Home, Bucks, Add, Goals,
/// Profile — matching the dark bar with a highlighted active icon seen
/// in the mockups. The "Add" icon (index 2) always renders as an
/// elevated circle since it's the primary action.
class MainNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.pets_rounded, label: 'Bucks'),
    _NavItem(icon: Icons.add_rounded, label: 'Add'),
    _NavItem(icon: Icons.flag_rounded, label: 'Goals'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B2A), // dark navy bar from the mockup
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final isCenter = index == 2;
            final isActive = index == currentIndex;
            return _NavButton(
              item: _items[index],
              isActive: isActive,
              isCenter: isCenter,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.isCenter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The center "Add" button is always emphasized (filled circle),
    // regardless of whether it's the active tab.
    final showFilledCircle = isCenter || isActive;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          width: isCenter ? 52 : 44,
          height: isCenter ? 52 : 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: showFilledCircle ? AppTheme.primary : Colors.transparent,
          ),
          child: Icon(
            item.icon,
            color: showFilledCircle ? Colors.white : Colors.white60,
            size: isCenter ? 28 : 24,
          ),
        ),
      ),
    );
  }
}
