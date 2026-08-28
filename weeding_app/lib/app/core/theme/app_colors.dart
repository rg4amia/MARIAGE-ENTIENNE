import 'package:flutter/material.dart';

/// Palette issue des références mobiles : vert électrique, jaune solaire,
/// noir profond et surfaces blanches/gris très clair.
class AppColors {
  // ── Brand ──
  static const primary = Color(0xFF32FFAA);
  static const primaryDark = Color(0xFF10D98A);
  static const primaryDarker = Color(0xFF087D55);
  static const primaryContainer = Color(0xFF32FFAA);
  static const primaryLight = Color(0xFFB9FFE2);
  static const onPrimary = Color(0xFF141515);
  static const onPrimaryContainer = Color(0xFF141515);

  static const secondary = Color(0xFFFFE86E);
  static const secondaryDark = Color(0xFFE8C92F);
  static const secondaryContainer = Color(0xFFFFE86E);
  static const onSecondary = Color(0xFF141515);
  static const onSecondaryContainer = Color(0xFF141515);

  static const tertiary = Color(0xFF141515);
  static const tertiaryContainer = Color(0xFFE9E9E7);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF141515);

  // ── Surfaces ──
  static const background = Color(0xFFF7F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFD7D7D3);
  static const surfaceVariant = Color(0xFFF0F0EE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4F2);
  static const surfaceContainer = Color(0xFFEDEDEB);
  static const surfaceContainerHigh = Color(0xFFE5E5E2);
  static const surfaceContainerHighest = Color(0xFFDCDCD8);

  // ── On Surface ──
  static const onSurface = Color(0xFF141515);
  static const onSurfaceVariant = Color(0xFF777974);
  static const onBackground = Color(0xFF141515);

  // ── Outline ──
  static const outline = Color(0xFF141515);
  static const outlineVariant = Color(0xFFD6D6D2);

  // ── Error ──
  static const error = Color(0xFFFF4D4D);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDEDE);
  static const onErrorContainer = Color(0xFF780000);

  // ── Inverse ──
  static const inverseSurface = Color(0xFF141515);
  static const inversePrimary = Color(0xFF32FFAA);

  // ── Accent colors ──
  static const gold = Color(0xFFFFE86E);
  static const mint = Color(0xFF32FFAA);
  static const dark = Color(0xFF141515);

  // ── Status colors ──
  static const statusPending = Color(0xFFFFE86E);
  static const statusMediaReceived = Color(0xFF32FFAA);
  static const statusCardUnlocked = Color(0xFF141515);

  // ── Semantic card colors (dark cards) ──
  static const cardDark = Color(0xFF141515);
  static const cardDarkText = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static const primaryFixed = Color(0xFFB9FFE2);
  static const primaryFixedDim = Color(0xFF75FFC5);
  static const secondaryFixed = Color(0xFFFFF5B8);
  static const secondaryFixedDim = Color(0xFFFFE86E);
  static const tertiaryFixed = Color(0xFFE9E9E7);
}
