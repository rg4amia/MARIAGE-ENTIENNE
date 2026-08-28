import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

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

  static const _labels = [
    'Accueil',
    'Invités',
    'Tables',
    'Invitations',
    'Plus',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(24),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 14 : 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[index],
                      color: isActive
                          ? scheme.primary
                          : scheme.onInverseSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        _labels[index],
                        style: AppTextStyles.labelMd.copyWith(
                          color: scheme.primary,
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
