import 'package:flutter/material.dart';

/// Palette « Celestial Romance » : ivoire, terracotta, saumon et or chaud.
class AppColors {
  // ── Primary — Terracotta ──
  static const primary = Color(0xFFA53C00);
  static const primaryDark = Color(0xFF7E2C00);
  static const primaryDarker = Color(0xFF652200);
  static const primaryContainer = Color(0xFFFF7A3D);
  static const primaryLight = Color(0xFFFFB598);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF652200);

  // ── Secondary — Saumon ──
  static const secondary = Color(0xFF9C4236);
  static const secondaryDark = Color(0xFF7D2B21);
  static const secondaryContainer = Color(0xFFFF8F7E);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF76261C);

  // ── Tertiary — Or chaud ──
  static const tertiary = Color(0xFF76583D);
  static const tertiaryContainer = Color(0xFFBE9A7A);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF4B321A);

  // ── Surfaces — Ivoire chaud ──
  static const background = Color(0xFFFFF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBright = Color(0xFFFFF8F4);
  static const surfaceDim = Color(0xFFE1D8D3);
  static const surfaceVariant = Color(0xFFEAE1DB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFBF2EC);
  static const surfaceContainer = Color(0xFFF5ECE6);
  static const surfaceContainerHigh = Color(0xFFEFE6E1);
  static const surfaceContainerHighest = Color(0xFFEAE1DB);

  // ── On Surface ──
  static const onSurface = Color(0xFF1F1B18);
  static const onSurfaceVariant = Color(0xFF584239);
  static const onBackground = Color(0xFF1F1B18);

  // ── Outline ──
  static const outline = Color(0xFF8C7167);
  static const outlineVariant = Color(0xFFDFC0B4);

  // ── Error ──
  static const error = Color(0xFFE53935);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Inverse ──
  static const inverseSurface = Color(0xFF34302C);
  static const inversePrimary = Color(0xFFFFB598);

  // ── Accent colors ──
  static const gold = Color(0xFFBE9A7A);
  static const mint = Color(0xFFA53C00); // alias historique
  static const dark = Color(0xFF34302C);

  // ── Status colors ──
  static const statusPending = Color(0xFFFFAAA0);
  static const statusMediaReceived = Color(0xFFBE9A7A);
  static const statusCardUnlocked = Color(0xFFFF7A3D);

  // ── Semantic card colors (dark cards) ──
  static const cardDark = Color(0xFF34302C);
  static const cardDarkText = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static const primaryFixed = Color(0xFFFFDBCD);
  static const primaryFixedDim = Color(0xFFFFB598);
  static const secondaryFixed = Color(0xFFFFDAD4);
  static const secondaryFixedDim = Color(0xFFFFB4A8);
  static const tertiaryFixed = Color(0xFFFFDCBF);
}
