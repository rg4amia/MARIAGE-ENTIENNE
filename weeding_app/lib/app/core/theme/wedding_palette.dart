import 'package:flutter/material.dart';

/// Polices proposées aux mariés (noms de familles Google Fonts).
class WeddingFonts {
  /// Polices de titres : élégantes, utilisées pour les grands titres et les
  /// prénoms sur la carte d'invitation.
  static const display = <String>[
    'Plus Jakarta Sans',
    'Playfair Display',
    'Cormorant Garamond',
    'Marcellus',
    'Italiana',
    'Great Vibes',
    'Dancing Script',
  ];

  /// Polices de texte : lisibles à petite taille, pour tout le corps de l'app.
  static const body = <String>[
    'Plus Jakarta Sans',
    'Lora',
    'Montserrat',
    'Raleway',
    'Nunito Sans',
    'Work Sans',
  ];

  static const defaultDisplay = 'Plus Jakarta Sans';
  static const defaultBody = 'Plus Jakarta Sans';

  /// Les polices décoratives ne sont lisibles qu'en très grand : on ne les
  /// autorise jamais pour le corps de texte.
  static String sanitizeDisplay(String? value) =>
      display.contains(value) ? value! : defaultDisplay;

  static String sanitizeBody(String? value) =>
      body.contains(value) ? value! : defaultBody;
}

@immutable
class WeddingPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final String displayFont;
  final String bodyFont;

  const WeddingPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    this.displayFont = WeddingFonts.defaultDisplay,
    this.bodyFont = WeddingFonts.defaultBody,
  });

  static const celestialRomance = WeddingPalette(
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFFFFFFF),
    accent: Color(0xFF17131F),
    background: Color(0xFFFAF8FF),
  );

  WeddingPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    String? displayFont,
    String? bodyFont,
  }) {
    return WeddingPalette(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      displayFont: displayFont ?? this.displayFont,
      bodyFont: bodyFont ?? this.bodyFont,
    );
  }

  factory WeddingPalette.fromJson(Map<String, dynamic> json) {
    return WeddingPalette(
      primary: colorFromHex(json['primary_color'] as String?),
      secondary: colorFromHex(
        json['secondary_color'] as String?,
        fallback: celestialRomance.secondary,
      ),
      accent: colorFromHex(
        json['accent_color'] as String?,
        fallback: celestialRomance.accent,
      ),
      background: colorFromHex(
        json['background_color'] as String?,
        fallback: celestialRomance.background,
      ),
      displayFont: WeddingFonts.sanitizeDisplay(json['display_font'] as String?),
      bodyFont: WeddingFonts.sanitizeBody(json['body_font'] as String?),
    );
  }

  Map<String, String> toJson() => {
    'primary_color': colorToHex(primary),
    'secondary_color': colorToHex(secondary),
    'accent_color': colorToHex(accent),
    'background_color': colorToHex(background),
    'display_font': displayFont,
    'body_font': bodyFont,
  };

  static bool isValidHex(String value) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value.trim());
  }

  static Color colorFromHex(String? value, {Color? fallback}) {
    final normalized = value?.trim() ?? '';
    if (!isValidHex(normalized)) {
      return fallback ?? celestialRomance.primary;
    }
    return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
  }

  static String colorToHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeddingPalette &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.accent == accent &&
        other.background == background &&
        other.displayFont == displayFont &&
        other.bodyFont == bodyFont;
  }

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    accent,
    background,
    displayFont,
    bodyFont,
  );
}
