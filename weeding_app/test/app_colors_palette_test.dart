import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/theme/app_colors.dart';
import 'package:weeding_app/app/core/theme/wedding_palette.dart';

/// Ratio de contraste WCAG entre deux couleurs opaques.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Les palettes proposées dans l'écran « Couleurs du mariage ».
const palettes = <String, WeddingPalette>{
  'Pourpre & blanc': WeddingPalette.celestialRomance,
  'Jardin sauge': WeddingPalette(
    primary: Color(0xFF526B54),
    secondary: Color(0xFF8B6F47),
    accent: Color(0xFFD4AF70),
    background: Color(0xFFF8F6EF),
  ),
  'Rose poudré': WeddingPalette(
    primary: Color(0xFF9E4F63),
    secondary: Color(0xFFB87883),
    accent: Color(0xFFD5A76C),
    background: Color(0xFFFFF7F7),
  ),
  'Nuit royale': WeddingPalette(
    primary: Color(0xFF203A63),
    secondary: Color(0xFF66507A),
    accent: Color(0xFFC79A3B),
    background: Color(0xFFF7F8FC),
  ),
  'Lagune': WeddingPalette(
    primary: Color(0xFF006D77),
    secondary: Color(0xFF277DA1),
    accent: Color(0xFFE6A15C),
    background: Color(0xFFF3FAF9),
  ),
  'Élégance ivoire': WeddingPalette(
    primary: Color(0xFF614C3F),
    secondary: Color(0xFF8A6F5A),
    accent: Color(0xFFB8945B),
    background: Color(0xFFFFFBF3),
  ),
  // Palette par défaut en base (terracotta).
  'Terracotta (défaut SQL)': WeddingPalette(
    primary: Color(0xFFA53C00),
    secondary: Color(0xFF9C4236),
    accent: Color(0xFFBE9A7A),
    background: Color(0xFFFFF8F4),
  ),
};

void main() {
  tearDown(() => AppColors.applyPalette(WeddingPalette.celestialRomance));

  group('AppColors.applyPalette garde des contrastes lisibles', () {
    palettes.forEach((name, palette) {
      test(name, () {
        AppColors.applyPalette(palette);

        // Texte principal sur le fond du mariage : exigence AA renforcée.
        expect(
          contrast(AppColors.onBackground, AppColors.background),
          greaterThanOrEqualTo(7.0),
          reason: '$name : encre illisible sur le fond',
        );

        // Texte secondaire : AA pour du texte normal.
        expect(
          contrast(AppColors.onSurfaceVariant, AppColors.background),
          greaterThanOrEqualTo(4.5),
          reason: '$name : texte secondaire illisible',
        );

        // Libellés des boutons pleins.
        expect(
          contrast(AppColors.onPrimary, AppColors.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$name : libellé illisible sur la couleur principale',
        );

        // Cartes blanches : le texte doit rester lisible dessus.
        expect(
          contrast(AppColors.onSurface, AppColors.surface),
          greaterThanOrEqualTo(7.0),
          reason: '$name : texte illisible sur les cartes',
        );

        // Cartes sombres (accueil) : texte inversé.
        expect(
          contrast(AppColors.cardDarkText, AppColors.cardDark),
          greaterThanOrEqualTo(7.0),
          reason: '$name : texte illisible sur les cartes sombres',
        );

        // Les statuts doivent rester distinguables entre eux.
        expect(
          AppColors.statusPending,
          isNot(equals(AppColors.statusCardUnlocked)),
          reason: '$name : statuts indistinguables',
        );
      });
    });
  });

  test('la palette pilote réellement les jetons', () {
    AppColors.applyPalette(WeddingPalette.celestialRomance);
    final purpleInk = AppColors.dark;

    AppColors.applyPalette(
      const WeddingPalette(
        primary: Color(0xFF614C3F),
        secondary: Color(0xFF8A6F5A),
        accent: Color(0xFFB8945B),
        background: Color(0xFFFFFBF3),
      ),
    );

    expect(AppColors.primary, const Color(0xFF614C3F));
    expect(AppColors.background, const Color(0xFFFFFBF3));
    expect(
      AppColors.dark,
      isNot(equals(purpleInk)),
      reason: "l'encre doit suivre la couleur du mariage",
    );
  });

  test('les polices invalides retombent sur la police par défaut', () {
    expect(WeddingFonts.sanitizeBody('Great Vibes'), 'Plus Jakarta Sans');
    expect(WeddingFonts.sanitizeBody('Comic Sans MS'), 'Plus Jakarta Sans');
    expect(WeddingFonts.sanitizeDisplay('Great Vibes'), 'Great Vibes');
    expect(WeddingFonts.sanitizeDisplay(null), 'Plus Jakarta Sans');
  });
}
