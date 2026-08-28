import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WeddingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final Widget? bottom;

  const WeddingAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom != null ? 56 : 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                      color: AppColors.onSurface,
                    )
                  : null,
              title: Text(title, style: AppTextStyles.headlineMd),
              actions: actions,
            ),
            bottom ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleLg),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText!,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dark, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.dark,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: color.computeLuminance() > 0.55
                  ? AppColors.dark
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final bool showOnline;
  final Widget? child;

  const UserAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
    this.backgroundColor,
    this.showOnline = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: AppColors.dark, width: 1.2),
          ),
          child: Center(
            child:
                child ??
                Text(
                  initials,
                  style: AppTextStyles.titleLg.copyWith(
                    color: bgColor.computeLuminance() > 0.48
                        ? AppColors.dark
                        : Colors.white,
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ),
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Gradient? gradient;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.35),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
