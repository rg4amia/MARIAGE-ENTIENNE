import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'wedding_palette.dart';

/// Typographie de l'application.
///
/// Par défaut Plus Jakarta Sans reproduit la géométrie compacte de Satoshi
/// utilisée par les références. Les mariés peuvent choisir leur propre police
/// de titres et de texte : [applyPalette] régénère alors tous les styles.
///
/// Les styles ne sont pas `final` : ils sont réassignés à chaque changement de
/// palette (couleurs comprises, car la couleur est figée dans le [TextStyle]).
class AppTextStyles {
  static String _displayFamily = WeddingFonts.defaultDisplay;
  static String _bodyFamily = WeddingFonts.defaultBody;

  /// Polices cursives : l'espacement négatif et les graisses lourdes les
  /// rendent illisibles, on les neutralise.
  static const _scriptFonts = <String>{
    'Great Vibes',
    'Dancing Script',
    'Italiana',
  };

  static bool get _displayIsScript => _scriptFonts.contains(_displayFamily);

  static TextStyle displayLg = _display(46, 1.02, -1.8, FontWeight.w800);
  static TextStyle displayMd = _display(36, 1.05, -1.2, FontWeight.w800);
  static TextStyle headlineLg = _display(32, 1.08, -0.9, FontWeight.w800);
  static TextStyle headlineLgMobile = _display(28, 1.08, -0.8, FontWeight.w800);
  static TextStyle headlineMd = _display(24, 1.12, -0.5, FontWeight.w800);

  static TextStyle titleLg = _body(20, 1.2, FontWeight.w700, -0.25);
  static TextStyle bodyLg = _body(16, 24 / 16, FontWeight.w400, null);
  static TextStyle bodyMd = _body(14, 20 / 14, FontWeight.w400, null);
  static TextStyle labelMd = _body(
    12,
    1.3,
    FontWeight.w600,
    0,
    color: AppColors.onSurfaceVariant,
  );

  // ── Convenience variants with color override ──
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

  /// À appeler après [AppColors.applyPalette] : les couleurs de la palette sont
  /// lues au moment de la régénération.
  static void applyPalette(WeddingPalette palette) {
    _displayFamily = WeddingFonts.sanitizeDisplay(palette.displayFont);
    _bodyFamily = WeddingFonts.sanitizeBody(palette.bodyFont);

    displayLg = _display(46, 1.02, -1.8, FontWeight.w800);
    displayMd = _display(36, 1.05, -1.2, FontWeight.w800);
    headlineLg = _display(32, 1.08, -0.9, FontWeight.w800);
    headlineLgMobile = _display(28, 1.08, -0.8, FontWeight.w800);
    headlineMd = _display(24, 1.12, -0.5, FontWeight.w800);

    titleLg = _body(20, 1.2, FontWeight.w700, -0.25);
    bodyLg = _body(16, 24 / 16, FontWeight.w400, null);
    bodyMd = _body(14, 20 / 14, FontWeight.w400, null);
    labelMd = _body(
      12,
      1.3,
      FontWeight.w600,
      0,
      color: AppColors.onSurfaceVariant,
    );

    displayMdPrimary = displayMd.copyWith(color: AppColors.primary);
    headlineMdPrimary = headlineMd.copyWith(color: AppColors.primary);
    headlineLgPrimary = headlineLg.copyWith(color: AppColors.primary);
    headlineLgMobilePrimary = headlineLgMobile.copyWith(
      color: AppColors.primary,
    );
    titleLgPrimary = titleLg.copyWith(color: AppColors.primary);
    bodyMdOnVariant = bodyMd.copyWith(color: AppColors.onSurfaceVariant);
    labelMdOnVariant = labelMd.copyWith(color: AppColors.onSurfaceVariant);
  }

  static TextStyle _display(
    double size,
    double height,
    double letterSpacing,
    FontWeight weight,
  ) {
    return _resolve(
      _displayFamily,
      fontSize: size,
      height: height,
      // Les cursives ont besoin de leur chasse naturelle et de leur graisse
      // d'origine pour rester lisibles.
      letterSpacing: _displayIsScript ? 0 : letterSpacing,
      fontWeight: _displayIsScript ? FontWeight.w400 : weight,
      color: AppColors.onBackground,
    );
  }

  static TextStyle _body(
    double size,
    double height,
    FontWeight weight,
    double? letterSpacing, {
    Color? color,
  }) {
    return _resolve(
      _bodyFamily,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      color: color ?? AppColors.onBackground,
    );
  }

  static TextStyle _resolve(
    String family, {
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (_) {
      // Police inconnue du manifeste : on retombe sur la police par défaut.
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }
}
