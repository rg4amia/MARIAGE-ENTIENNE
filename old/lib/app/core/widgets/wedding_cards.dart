import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Carte avec ombre "wedding glow" et bordure subtile.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: kWeddingGlow,
      ),
      child: child,
    );
  }
}

/// Carte de statistique style "Bento" du tableau de bord.
class StatBentoCard extends StatelessWidget {
  const StatBentoCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.progress,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final double? progress;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? null
        : AppColors.surfaceContainerLowest;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        gradient: highlighted ? kEditorialGradient : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? Colors.transparent
              : AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: kWeddingGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: highlighted
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.secondary,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: highlighted ? Colors.white : AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.notoSerif(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? Colors.white : AppColors.primary,
                  height: 1,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    suffix!,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: highlighted
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.outline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 4,
                backgroundColor: highlighted
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(
                  highlighted ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton primaire avec gradient "editorial".
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
      decoration: BoxDecoration(
        gradient: kEditorialGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33570013),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 10),
            Icon(icon, color: Colors.white, size: 18),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

/// Petit chip "eyebrow" en haut des sections (uppercase, lettre-espace).
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 11,
        letterSpacing: 2.4,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.secondary,
      ),
    );
  }
}

/// Separateur editorial avec initiales centrales (E & M).
class EditorialDivider extends StatelessWidget {
  const EditorialDivider({super.key, this.initials = 'E & M'});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              initials,
              style: GoogleFonts.notoSerif(
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
                fontSize: 22,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.outlineVariant)),
        ],
      ),
    );
  }
}
