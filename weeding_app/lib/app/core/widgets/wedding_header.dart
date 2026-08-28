import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'micro_interactions.dart';

/// En-tête mobile inspiré des captures : grand bloc vert pour les onglets
/// principaux, composition blanche et typographie XXL pour les sous-pages.
class WeddingHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final Widget? child;
  final List<Color>? gradientColors;
  final bool showBack;

  const WeddingHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.child,
    this.gradientColors,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMainSection = !showBack;
    final background = isMainSection ? AppColors.primary : Colors.white;
    final foreground = background.computeLuminance() > 0.48
        ? AppColors.dark
        : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        isMainSection ? 28 : 20,
      ),
      decoration: BoxDecoration(
        color: background,
        gradient: gradientColors == null
            ? null
            : LinearGradient(colors: gradientColors!),
        borderRadius: isMainSection
            ? const BorderRadius.vertical(bottom: Radius.circular(38))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                TapScale(
                  onTap: onBackPressed ?? () => Navigator.pop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: foreground,
                      size: 19,
                    ),
                  ),
                )
              else if (title.isEmpty)
                const SizedBox.shrink(),
              if (isMainSection && title.isNotEmpty)
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headlineLg.copyWith(color: foreground),
                  ),
                )
              else
                const Spacer(),
              if (trailing != null) trailing! else const SizedBox(width: 40),
            ],
          ),
          if (showBack && title.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              title,
              style: AppTextStyles.displayMd.copyWith(color: foreground),
            ),
          ],
          if (child != null) ...[
            SizedBox(height: isMainSection ? 22 : 16),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Small info banner used inside the header.
class HeaderInfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const HeaderInfoBanner({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dark, width: 1.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.dark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
