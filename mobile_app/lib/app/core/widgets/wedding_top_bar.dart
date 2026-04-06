import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// AppBar editorial reutilise sur toutes les pages.
/// Reproduction de la "TopAppBar" du design Stitch :
/// fond creme translucide, titre serif bordeaux, avatar a droite.
class WeddingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const WeddingTopBar({
    super.key,
    this.title = 'Mariage Entienne',
    this.leadingIcon = Icons.menu_rounded,
    this.onLeading,
    this.actions,
    this.showAvatar = true,
  });

  final String title;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final List<Widget>? actions;
  final bool showAvatar;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        boxShadow: kWeddingGlow,
        border: const Border(
          bottom: BorderSide(color: Color(0x14E0BFBF)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              IconButton(
                icon: Icon(leadingIcon, color: AppColors.primary),
                onPressed: onLeading,
                splashRadius: 22,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
              if (showAvatar) ...[
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHighest,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                    gradient: kEditorialGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
