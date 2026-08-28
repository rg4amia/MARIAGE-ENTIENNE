import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles de texte inspirés Satoshi : Poppins Bold pour les titres,
/// Poppins Medium pour les labels, Plus Jakarta Sans pour le body.
class AppTextStyles {
  // ── Display (Poppins Bold — Satoshi Bold equivalent) ──
  static TextStyle displayLg = GoogleFonts.poppins(
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02,
    color: AppColors.onBackground,
    fontWeight: FontWeight.w800,
  );

  static TextStyle displayMd = GoogleFonts.poppins(
    fontSize: 36,
    height: 44 / 36,
    letterSpacing: -0.01,
    color: AppColors.onBackground,
    fontWeight: FontWeight.w700,
  );

  // ── Headlines (Poppins Bold) ──
  static TextStyle headlineLg = GoogleFonts.poppins(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01,
    color: AppColors.onBackground,
  );

  static TextStyle headlineLgMobile = GoogleFonts.poppins(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.01,
    color: AppColors.onBackground,
  );

  static TextStyle headlineMd = GoogleFonts.poppins(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
  );

  // ── Titles (Poppins SemiBold) ──
  static TextStyle titleLg = GoogleFonts.poppins(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
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

  // ── Labels (Poppins Medium — Satoshi Medium equivalent) ──
  static TextStyle labelMd = GoogleFonts.poppins(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
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
