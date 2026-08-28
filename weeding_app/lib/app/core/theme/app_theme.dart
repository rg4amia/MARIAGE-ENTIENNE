import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'wedding_palette.dart';

class AppTheme {
  static ThemeData get lightTheme =>
      lightThemeFor(WeddingPalette.celestialRomance);

  static ThemeData lightThemeFor(WeddingPalette palette) {
    final generated = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
    );
    final scheme = generated.copyWith(
      primary: palette.primary,
      onPrimary: _foregroundFor(palette.primary),
      secondary: palette.secondary,
      onSecondary: _foregroundFor(palette.secondary),
      tertiary: palette.accent,
      onTertiary: _foregroundFor(palette.accent),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: Colors.white,
      inversePrimary: palette.primary,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLg,
        displayMedium: AppTextStyles.displayMd,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        titleLarge: AppTextStyles.titleLg,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        labelMedium: AppTextStyles.labelMd,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMd,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.dark, width: 1.35),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.titleLg.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dark,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.dark, width: 1.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.titleLg.copyWith(color: AppColors.dark),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dark,
          textStyle: AppTextStyles.bodyLg.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.dark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.labelMd.copyWith(color: scheme.onSurface),
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.inverseSurface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onInverseSurface,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.dark, width: 1.25),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        titleTextStyle: AppTextStyles.headlineMd,
        contentTextStyle: AppTextStyles.bodyLg.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyLg.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.inverseSurface,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHigh,
        labelStyle: AppTextStyles.labelMd.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),
    );
  }

  static Color _foregroundFor(Color background) {
    return background.computeLuminance() > 0.48 ? Colors.black : Colors.white;
  }
}
