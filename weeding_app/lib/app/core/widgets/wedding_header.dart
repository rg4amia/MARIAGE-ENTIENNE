import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'micro_interactions.dart';

/// Premium gradient header with violet gradient.
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
    final colors = gradientColors ?? const [
      Color(0xFF7A00CC),
      Color(0xFF9D00FF),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 8,
        20,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                TapScale(
                  onTap: onBackPressed ?? () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else
                const SizedBox(width: 40),
            ],
          ),

          if (child != null) ...[
            const SizedBox(height: 20),
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

  const HeaderInfoBanner({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
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
