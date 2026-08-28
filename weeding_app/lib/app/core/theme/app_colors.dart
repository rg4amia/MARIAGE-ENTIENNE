import 'package:flutter/material.dart';

/// Palette complète autour du violet #9D00FF — luxe, moderne, élégant.
class AppColors {
  // ── Primary — Violet #9D00FF ──
  static const primary = Color(0xFF9D00FF);
  static const primaryDark = Color(0xFF7A00CC);
  static const primaryDarker = Color(0xFF5C0099);
  static const primaryContainer = Color(0xFFD4A0FF);
  static const primaryLight = Color(0xFFC98FFF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF2D004F);

  // ── Secondary — Doré / Ambre (accent chaud) ──
  static const secondary = Color(0xFFFFD966);
  static const secondaryDark = Color(0xFFF5C842);
  static const secondaryContainer = Color(0xFFFFF0C2);
  static const onSecondary = Color(0xFF1A1520);
  static const onSecondaryContainer = Color(0xFF4A3D00);

  // ── Tertiary — Rose-violet doux ──
  static const tertiary = Color(0xFFFF8FBF);
  static const tertiaryContainer = Color(0xFFFFD6EB);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF4A1530);

  // ── Dark / Surface — Fond violet assombri ──
  static const background = Color(0xFFF8F5FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFEDE8F3);
  static const surfaceVariant = Color(0xFFF2EEF8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFBF9FE);
  static const surfaceContainer = Color(0xFFF5F1FA);
  static const surfaceContainerHigh = Color(0xFFEFE9F5);
  static const surfaceContainerHighest = Color(0xFFE8E1F0);

  // ── On Surface ──
  static const onSurface = Color(0xFF1A1520);
  static const onSurfaceVariant = Color(0xFF6E6478);
  static const onBackground = Color(0xFF1A1520);

  // ── Outline ──
  static const outline = Color(0xFF9A8FA6);
  static const outlineVariant = Color(0xFFDDD6E4);

  // ── Error ──
  static const error = Color(0xFFE53935);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Inverse ──
  static const inverseSurface = Color(0xFF1A1520);
  static const inversePrimary = Color(0xFFD4A0FF);

  // ── Accent colors ──
  static const gold = Color(0xFFFFD966);
  static const mint = Color(0xFF9D00FF); // alias
  static const dark = Color(0xFF1A1520); // violet noir

  // ── Status colors ──
  static const statusPending = Color(0xFFFFD966);
  static const statusMediaReceived = Color(0xFFD4A0FF);
  static const statusCardUnlocked = Color(0xFF9D00FF);

  // ── Semantic card colors (dark cards) ──
  static const cardDark = Color(0xFF1A1520);
  static const cardDarkText = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static const primaryFixed = Color(0xFFD4A0FF);
  static const primaryFixedDim = Color(0xFFB86FFF);
  static const secondaryFixed = Color(0xFFFFF0C2);
  static const secondaryFixedDim = Color(0xFFFFE49A);
  static const tertiaryFixed = Color(0xFFFFD6EB);
}
