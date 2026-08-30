import 'package:flutter/material.dart';
import 'wedding_palette.dart';

/// Jetons de couleur de l'application.
///
/// Les valeurs ne sont volontairement pas `const` : [applyPalette] les
/// recalcule dès que les mariés changent leurs couleurs, afin que toute
/// l'application (encre, bordures, surfaces, statuts) suive la palette du
/// mariage et pas seulement l'arrière-plan.
///
/// Les valeurs initiales correspondent à [WeddingPalette.celestialRomance].
class AppColors {
  // ── Brand ──
  static Color primary = const Color(0xFF7C3AED);
  static Color primaryDark = const Color(0xFF6D28D9);
  static Color primaryDarker = const Color(0xFF4C1D95);
  static Color primaryContainer = const Color(0xFF8B5CF6);
  static Color primaryLight = const Color(0xFFEDE9FE);
  static Color onPrimary = const Color(0xFFFFFFFF);
  static Color onPrimaryContainer = const Color(0xFFFFFFFF);

  static Color secondary = const Color(0xFFFFFFFF);
  static Color secondaryDark = const Color(0xFFE5E7EB);
  static Color secondaryContainer = const Color(0xFFFFFFFF);
  static Color onSecondary = const Color(0xFF141515);
  static Color onSecondaryContainer = const Color(0xFF141515);

  static Color tertiary = const Color(0xFF141515);
  static Color tertiaryContainer = const Color(0xFFF1EEFF);
  static Color onTertiary = const Color(0xFFFFFFFF);
  static Color onTertiaryContainer = const Color(0xFF141515);

  // ── Surfaces ──
  static Color background = const Color(0xFFFAF8FF);
  static Color surface = const Color(0xFFFFFFFF);
  static Color surfaceBright = const Color(0xFFFFFFFF);
  static Color surfaceDim = const Color(0xFFE3DDF0);
  static Color surfaceVariant = const Color(0xFFF5F2FC);
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow = const Color(0xFFF7F5FD);
  static Color surfaceContainer = const Color(0xFFF0ECF8);
  static Color surfaceContainerHigh = const Color(0xFFE8E1F3);
  static Color surfaceContainerHighest = const Color(0xFFDCD2EA);

  // ── On Surface ──
  static Color onSurface = const Color(0xFF17131F);
  static Color onSurfaceVariant = const Color(0xFF6F687A);
  static Color onBackground = const Color(0xFF17131F);

  // ── Outline ──
  static Color outline = const Color(0xFF17131F);
  static Color outlineVariant = const Color(0xFFD9D2E8);

  // ── Error (sémantique : ne suit pas la palette du mariage) ──
  static const error = Color(0xFFFF4D4D);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDEDE);
  static const onErrorContainer = Color(0xFF780000);

  // ── Inverse ──
  static Color inverseSurface = const Color(0xFF17131F);
  static Color inversePrimary = const Color(0xFFC4B5FD);

  // ── Accent colors ──
  static Color gold = const Color(0xFFE9D5FF);
  static Color mint = const Color(0xFFA78BFA);

  /// Encre du mariage : bordures, textes forts et boutons pleins.
  static Color dark = const Color(0xFF17131F);

  // ── Status colors ──
  static Color statusPending = const Color(0xFF7C3AED);
  static Color statusMediaReceived = const Color(0xFFA78BFA);
  static Color statusCardUnlocked = const Color(0xFF17131F);

  // ── Semantic card colors (dark cards) ──
  static Color cardDark = const Color(0xFF17131F);
  static Color cardDarkText = const Color(0xFFFFFFFF);

  // ── Legacy aliases (keep existing references working) ──
  static Color primaryFixed = const Color(0xFFEDE9FE);
  static Color primaryFixedDim = const Color(0xFFC4B5FD);
  static Color secondaryFixed = const Color(0xFFF5F3FF);
  static Color secondaryFixedDim = const Color(0xFFE5E7EB);
  static Color tertiaryFixed = const Color(0xFFF1EEFF);

  /// Recalcule tous les jetons à partir des 4 couleurs choisies par les mariés.
  ///
  /// L'encre ([dark]) est dérivée de la couleur principale plutôt que fixée en
  /// noir : un mariage brun obtient une encre brun profond, un mariage turquoise
  /// une encre bleu-nuit, ce qui garde l'ensemble cohérent.
  static void applyPalette(WeddingPalette palette) {
    const white = Color(0xFFFFFFFF);
    final hardestSurface = _hardestSurface(palette);
    final ink = inkFor(palette);

    primary = palette.primary;
    primaryDark = _relativeShade(palette.primary, 0.80);
    primaryDarker = _relativeShade(palette.primary, 0.58);
    primaryContainer = _relativeShade(palette.primary, 1.18);
    primaryLight = _shade(palette.primary, 0.94, maxSaturation: 0.55);
    onPrimary = _onColor(palette.primary);
    onPrimaryContainer = _onColor(primaryContainer);

    secondary = palette.secondary;
    secondaryDark = _relativeShade(palette.secondary, 0.88);
    secondaryContainer = _mix(white, palette.secondary, 0.35);
    onSecondary = _onColor(palette.secondary);
    onSecondaryContainer = _onColor(secondaryContainer);

    tertiary = palette.accent;
    tertiaryContainer = _shade(palette.accent, 0.94, maxSaturation: 0.55);
    onTertiary = _onColor(palette.accent);
    onTertiaryContainer = _onColor(tertiaryContainer);

    background = palette.background;
    surface = white;
    surfaceBright = white;
    surfaceContainerLowest = white;
    surfaceContainerLow = _mix(white, palette.background, 0.60);
    surfaceVariant = _mix(palette.background, palette.primary, 0.04);
    surfaceContainer = _mix(palette.background, palette.primary, 0.07);
    surfaceContainerHigh = _mix(palette.background, palette.primary, 0.14);
    surfaceContainerHighest = _mix(palette.background, palette.primary, 0.22);
    surfaceDim = _mix(palette.background, palette.primary, 0.17);

    onSurface = ink;
    onBackground = ink;
    onSurfaceVariant = _ensureContrast(
      _shade(palette.primary, 0.45, maxSaturation: 0.12),
      hardestSurface,
      4.5,
    );

    outline = ink;
    outlineVariant = _mix(ink, palette.background, 0.82);

    inverseSurface = ink;
    inversePrimary = _shade(palette.primary, 0.78, maxSaturation: 0.60);

    gold = palette.accent;
    mint = _shade(palette.primary, 0.68, maxSaturation: 0.55);
    dark = ink;

    statusPending = palette.primary;
    statusMediaReceived = palette.accent;
    statusCardUnlocked = ink;

    cardDark = ink;
    cardDarkText = _onColor(ink);

    primaryFixed = primaryLight;
    primaryFixedDim = inversePrimary;
    secondaryFixed = _mix(white, palette.secondary, 0.25);
    secondaryFixedDim = secondaryDark;
    tertiaryFixed = tertiaryContainer;
  }

  /// Noir ou blanc selon ce qui reste lisible sur [background].
  static Color onColorFor(Color background) => _onColor(background);

  /// Encre dérivée d'une palette sans l'appliquer globalement : permet aux
  /// aperçus d'afficher le rendu du brouillon avant enregistrement.
  static Color inkFor(WeddingPalette palette) => _ensureContrast(
    _shade(palette.primary, 0.10, maxSaturation: 0.45),
    _hardestSurface(palette),
    7.0,
  );

  /// Le texte sombre se pose sur les cartes blanches comme sur le fond du
  /// mariage : c'est la moins lumineuse des deux qui contraint le contraste,
  /// la satisfaire garantit l'autre.
  static Color _hardestSurface(WeddingPalette palette) {
    const white = Color(0xFFFFFFFF);
    return palette.background.computeLuminance() < white.computeLuminance()
        ? palette.background
        : white;
  }

  /// Retient l'encre ou le blanc selon le meilleur ratio de contraste réel
  /// (WCAG). Un simple seuil de luminance choisit du blanc sur des couleurs
  /// moyennes, ce qui descend sous le contraste AA.
  static Color _onColor(Color background) {
    const ink = Color(0xFF17131F);
    final luminance = background.computeLuminance();
    final againstInk = (luminance + 0.05) / (ink.computeLuminance() + 0.05);
    final againstWhite = 1.05 / (luminance + 0.05);
    return againstInk >= againstWhite ? ink : const Color(0xFFFFFFFF);
  }

  /// Ramène [color] à une luminosité absolue, en bridant la saturation pour
  /// éviter les teintes criardes sur les palettes très vives.
  static Color _shade(Color color, double lightness, {double? maxSaturation}) {
    final hsl = HSLColor.fromColor(color);
    final saturation = maxSaturation == null
        ? hsl.saturation
        : (hsl.saturation < maxSaturation ? hsl.saturation : maxSaturation);
    return hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor();
  }

  /// Éclaircit (> 1) ou assombrit (< 1) [color] proportionnellement, ce qui
  /// préserve mieux le caractère d'une couleur que des paliers absolus.
  static Color _relativeShade(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// Ratio de contraste WCAG entre deux couleurs opaques.
  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Décale progressivement [foreground] jusqu'à atteindre [target] sur
  /// [background]. Une luminosité HSL fixe ne suffit pas : à luminosité égale
  /// un vert est bien plus lumineux qu'un bleu, donc le contraste varie selon
  /// la teinte choisie par les mariés.
  static Color _ensureContrast(
    Color foreground,
    Color background,
    double target,
  ) {
    final shouldDarken = background.computeLuminance() > 0.5;
    var hsl = HSLColor.fromColor(foreground);
    var candidate = foreground;
    var guard = 0;
    while (_contrast(candidate, background) < target && guard++ < 60) {
      final next = shouldDarken ? hsl.lightness - 0.02 : hsl.lightness + 0.02;
      if (next <= 0 || next >= 1) break;
      hsl = hsl.withLightness(next);
      candidate = hsl.toColor();
    }
    return candidate;
  }
}
