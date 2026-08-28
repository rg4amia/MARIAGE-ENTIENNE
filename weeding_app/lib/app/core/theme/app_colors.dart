import 'package:flutter/material.dart';

/// Palette inspirée du design system moderne : vert menthe, jaune, noir profond.
class AppColors {
  // ── Primary — Mint Green ──
  static const primary = Color(0xFF32FFAA);
  static const primaryDark = Color(0xFF1AE893);
  static const primaryContainer = Color(0xFFA3FFD4);
  static const onPrimary = Color(0xFF141515);
  static const onPrimaryContainer = Color(0xFF003822);

  // ── Secondary — Yellow ──
  static const secondary = Color(0xFFFFE86E);
  static const secondaryDark = Color(0xFFF5D94A);
  static const secondaryContainer = Color(0xFFFFF3B0);
  static const onSecondary = Color(0xFF141515);
  static const onSecondaryContainer = Color(0xFF3D3600);

  // ── Tertiary — Warm neutral ──
  static const tertiary = Color(0xFFE8E0D8);
  static const tertiaryContainer = Color(0xFFF5EFE9);
  static const onTertiary = Color(0xFF141515);
  static const onTertiaryContainer = Color(0xFF4A4540);

  // ── Dark / Surface — Near-black ──
  static const background = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFECEAE7);
  static const surfaceVariant = Color(0xFFF0EEEB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFAF9F7);
  static const surfaceContainer = Color(0xFFF4F3F0);
  static const surfaceContainerHigh = Color(0xFFEEEDEA);
  static const surfaceContainerHighest = Color(0xFFE8E7E4);

  // ── On Surface ──
  static const onSurface = Color(0xFF141515);
  static const onSurfaceVariant = Color(0xFF6B6A67);
  static const onBackground = Color(0xFF141515);

  // ── Outline ──
  static const outline = Color(0xFF9E9D99);
  static const outlineVariant = Color(0xFFDCDBD8);

  // ── Error ──
  static const error = Color(0xFFE53935);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Inverse ──
  static const inverseSurface = Color(0xFF141515);
  static const inversePrimary = Color(0xFF32FFAA);

  // ── Accent colors ──
  static const gold = Color(0xFFFFE86E);
  static const mint = Color(0xFF32FFAA);
  static const dark = Color(0xFF141515);

  // ── Status colors ──
  static const statusPending = Color(0xFFFFE86E);
  static const statusMediaReceived = Color(0xFFB0A8FF);
  static const statusCardUnlocked = Color(0xFF32FFAA);

  // ── Semantic card colors (dark cards) ──
  static const cardDark = Color(0xFF141515);
  static const cardDarkText = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static const primaryFixed = Color(0xFFA3FFD4);
  static const primaryFixedDim = Color(0xFF6BFFBE);
  static const secondaryFixed = Color(0xFFFFF3B0);
  static const secondaryFixedDim = Color(0xFFFFD98A);
  static const tertiaryFixed = Color(0xFFF5EFE9);
}
