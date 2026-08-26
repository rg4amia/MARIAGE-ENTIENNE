import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

/// Floating pill-shaped bottom navigation bar with animated indicator.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.guests,
    AppRoutes.tables,
    AppRoutes.invitations,
    AppRoutes.settings,
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.group_rounded,
    Icons.table_restaurant_rounded,
    Icons.qr_code_2_rounded,
    Icons.settings_rounded,
  ];

  static const _labels = [
    'Accueil',
    'Invités',
    'Tables',
    'Invitations',
    'Plus',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () {
                if (index != currentIndex) {
                  Get.offAllNamed(_routes[index]);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 8,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[index],
                      color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        _labels[index],
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
