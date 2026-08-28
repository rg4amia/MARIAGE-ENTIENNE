import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Plus Jakarta Sans reproduit la géométrie compacte de Satoshi utilisée par
/// les références, avec des titres très lourds et un corps plus calme.
class AppTextStyles {
  static TextStyle displayLg = GoogleFonts.plusJakartaSans(
    fontSize: 46,
    height: 1.02,
    letterSpacing: -1.8,
    color: AppColors.onBackground,
    fontWeight: FontWeight.w800,
  );

  static TextStyle displayMd = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    height: 1.05,
    letterSpacing: -1.2,
    color: AppColors.onBackground,
    fontWeight: FontWeight.w800,
  );

  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.9,
    color: AppColors.onBackground,
  );

  static TextStyle headlineLgMobile = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.onBackground,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.onBackground,
  );

  static TextStyle titleLg = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: AppColors.onBackground,
  );

  // ── Body (Plus Jakarta Sans — clean readable) ──
  static TextStyle bodyLg = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  static TextStyle bodyMd = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  static TextStyle labelMd = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.onSurfaceVariant,
  );

  // ── Convenience methods with color override ──
  static TextStyle displayMdPrimary = displayMd.copyWith(
    color: AppColors.primary,
  );
  static TextStyle headlineMdPrimary = headlineMd.copyWith(
    color: AppColors.primary,
  );
  static TextStyle headlineLgPrimary = headlineLg.copyWith(
    color: AppColors.primary,
  );
  static TextStyle headlineLgMobilePrimary = headlineLgMobile.copyWith(
    color: AppColors.primary,
  );
  static TextStyle titleLgPrimary = titleLg.copyWith(color: AppColors.primary);
  static TextStyle bodyMdOnVariant = bodyMd.copyWith(
    color: AppColors.onSurfaceVariant,
  );
  static TextStyle labelMdOnVariant = labelMd.copyWith(
    color: AppColors.onSurfaceVariant,
  );
}
