import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extraits du projet Stitch "Mariage Entienne".
/// Palette editoriale bordeaux / creme / or.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF570013); // burgundy profond
  static const primaryContainer = Color(0xFF800020); // burgundy
  static const onPrimary = Color(0xFFFFFFFF);

  // Surfaces
  static const surface = Color(0xFFFBF9F1); // creme
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F4EC);
  static const surfaceContainer = Color(0xFFF0EEE6);
  static const surfaceContainerHigh = Color(0xFFEAE8E0);
  static const surfaceContainerHighest = Color(0xFFE4E3DB);

  // Texte
  static const onSurface = Color(0xFF1B1C17);
  static const onSurfaceVariant = Color(0xFF584141);
  static const outline = Color(0xFF8C7071);
  static const outlineVariant = Color(0xFFE0BFBF);

  // Accents
  static const secondary = Color(0xFF735C00); // or fonce
  static const secondaryContainer = Color(0xFFFED65B); // or
  static const tertiary = Color(0xFF352500);

  static const error = Color(0xFFBA1A1A);
}

/// Ombre signature "wedding glow" du design system.
const kWeddingGlow = <BoxShadow>[
  BoxShadow(
    color: Color(0x0F570013), // rgba(87,0,19,0.06)
    blurRadius: 40,
    offset: Offset(0, 12),
  ),
];

/// Gradient editorial bordeaux utilise pour les CTA et heros.
const kEditorialGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryContainer],
);

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.tertiary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onPrimary,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    final body = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.primary,
    );

    final headlineSerif = GoogleFonts.notoSerif(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );

    final textTheme = body.copyWith(
      displayLarge: GoogleFonts.notoSerif(
        textStyle: body.displayLarge,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.notoSerif(
        textStyle: body.displayMedium,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.notoSerif(
        textStyle: body.displaySmall,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.notoSerif(
        textStyle: body.headlineLarge,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.notoSerif(
        textStyle: body.headlineMedium,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.notoSerif(
        textStyle: body.headlineSmall,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.notoSerif(
        textStyle: body.titleLarge,
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      labelSmall: body.labelSmall?.copyWith(
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
      labelMedium: body.labelMedium?.copyWith(
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );

    // Reference le style serif pour eviter l'avertissement d'unused.
    headlineSerif.fontFamily;

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.primary,
        titleTextStyle: GoogleFonts.notoSerif(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1AE0BFBF)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.manrope(color: AppColors.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x33E0BFBF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        labelStyle: GoogleFonts.manrope(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x33E0BFBF),
        thickness: 1,
        space: 32,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.manrope(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    );
  }
}

/// Style label "uppercase tracking" reutilise dans les sections.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle eyebrow(BuildContext context) {
    return GoogleFonts.manrope(
      fontSize: 11,
      letterSpacing: 2.2,
      fontWeight: FontWeight.w700,
      color: AppColors.secondary,
    );
  }

  static TextStyle headline(BuildContext context) {
    return GoogleFonts.notoSerif(
      fontSize: 36,
      height: 1.1,
      letterSpacing: -0.6,
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle italicQuote(BuildContext context) {
    return GoogleFonts.notoSerif(
      fontStyle: FontStyle.italic,
      fontSize: 18,
      color: AppColors.primary.withValues(alpha: 0.7),
    );
  }
}
