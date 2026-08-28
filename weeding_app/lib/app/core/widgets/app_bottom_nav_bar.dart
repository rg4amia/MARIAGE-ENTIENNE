import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

/// Dark bottom navigation bar with green accent plus button.
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(24),
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
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0 && !isActive)
                      // Special green plus button for home
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.dark,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        _icons[index],
                        color: isActive
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        _labels[index],
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
