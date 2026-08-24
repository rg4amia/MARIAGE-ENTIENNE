import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles de texte basés sur les fonts stitch : Libre Caslon Text + Plus Jakarta Sans
class AppTextStyles {
  // Display (Libre Caslon Text)
  static TextStyle displayLg = GoogleFonts.libreCaslonText(
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02,
    color: AppColors.onBackground,
  );

  static TextStyle displayMd = GoogleFonts.libreCaslonText(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  // Headlines (Libre Caslon Text)
  static TextStyle headlineLg = GoogleFonts.libreCaslonText(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  static TextStyle headlineLgMobile = GoogleFonts.libreCaslonText(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  static TextStyle headlineMd = GoogleFonts.libreCaslonText(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
  );

  // Title (Plus Jakarta Sans)
  static TextStyle titleLg = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );

  // Body (Plus Jakarta Sans)
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

  // Label (Plus Jakarta Sans)
  static TextStyle labelMd = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    color: AppColors.onSurfaceVariant,
  );

  // Convenience methods with color override
  static TextStyle displayMdPrimary = displayMd.copyWith(color: AppColors.primary);
  static TextStyle headlineMdPrimary = headlineMd.copyWith(color: AppColors.primary);
  static TextStyle headlineLgPrimary = headlineLg.copyWith(color: AppColors.primary);
  static TextStyle headlineLgMobilePrimary = headlineLgMobile.copyWith(color: AppColors.primary);
  static TextStyle titleLgPrimary = titleLg.copyWith(color: AppColors.primary);
  static TextStyle bodyMdOnVariant = bodyMd.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle labelMdOnVariant = labelMd.copyWith(color: AppColors.onSurfaceVariant);
}
