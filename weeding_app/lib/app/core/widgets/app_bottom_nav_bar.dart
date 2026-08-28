import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Barre unique de navigation de l'espace administrateur.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const _icons = [
    Icons.home_rounded,
    Icons.group_rounded,
    Icons.table_restaurant_rounded,
    Icons.qr_code_2_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.dark, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () {
                if (index != currentIndex) {
                  onTabSelected(index);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _icons[index],
                  color: isActive
                      ? AppColors.onPrimary
                      : Colors.white.withValues(alpha: 0.88),
                  size: 24,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
