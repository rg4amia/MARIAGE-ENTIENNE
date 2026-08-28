import 'package:flutter/material.dart';

/// Palette par défaut : pourpre intense, blanc lumineux et encre profonde.
class AppColors {
  // ── Brand ──
  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFF6D28D9);
  static const primaryDarker = Color(0xFF4C1D95);
  static const primaryContainer = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFEDE9FE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFFFFFFF);
  static const secondaryDark = Color(0xFFE5E7EB);
  static const secondaryContainer = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFF141515);
  static const onSecondaryContainer = Color(0xFF141515);

  static const tertiary = Color(0xFF141515);
  static const tertiaryContainer = Color(0xFFF1EEFF);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF141515);

  // ── Surfaces ──
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFE3DDF0);
  static const surfaceVariant = Color(0xFFF5F2FC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF7F5FD);
  static const surfaceContainer = Color(0xFFF0ECF8);
  static const surfaceContainerHigh = Color(0xFFE8E1F3);
  static const surfaceContainerHighest = Color(0xFFDCD2EA);

  // ── On Surface ──
  static const onSurface = Color(0xFF17131F);
  static const onSurfaceVariant = Color(0xFF6F687A);
  static const onBackground = Color(0xFF17131F);

  // ── Outline ──
  static const outline = Color(0xFF17131F);
  static const outlineVariant = Color(0xFFD9D2E8);

  // ── Error ──
  static const error = Color(0xFFFF4D4D);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDEDE);
  static const onErrorContainer = Color(0xFF780000);

  // ── Inverse ──
  static const inverseSurface = Color(0xFF17131F);
  static const inversePrimary = Color(0xFFC4B5FD);

  // ── Accent colors ──
  static const gold = Color(0xFFE9D5FF);
  static const mint = Color(0xFFA78BFA);
  static const dark = Color(0xFF17131F);

  // ── Status colors ──
  static const statusPending = Color(0xFFE9D5FF);
  static const statusMediaReceived = Color(0xFFA78BFA);
  static const statusCardUnlocked = Color(0xFF17131F);

  // ── Semantic card colors (dark cards) ──
  static const cardDark = Color(0xFF17131F);
  static const cardDarkText = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static const primaryFixed = Color(0xFFEDE9FE);
  static const primaryFixedDim = Color(0xFFC4B5FD);
  static const secondaryFixed = Color(0xFFF5F3FF);
  static const secondaryFixedDim = Color(0xFFE5E7EB);
  static const tertiaryFixed = Color(0xFFF1EEFF);
}
