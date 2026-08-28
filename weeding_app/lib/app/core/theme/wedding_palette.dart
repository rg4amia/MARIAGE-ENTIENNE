import 'package:flutter/material.dart';

@immutable
class WeddingPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;

  const WeddingPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
  });

  static const celestialRomance = WeddingPalette(
    primary: Color(0xFF32FFAA),
    secondary: Color(0xFFFFE86E),
    accent: Color(0xFF141515),
    background: Color(0xFFF7F7F5),
  );

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
    );
  }

  Map<String, String> toJson() => {
    'primary_color': colorToHex(primary),
    'secondary_color': colorToHex(secondary),
    'accent_color': colorToHex(accent),
    'background_color': colorToHex(background),
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
    return other is WeddingPalette &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.accent == accent &&
        other.background == background;
  }

  @override
  int get hashCode => Object.hash(primary, secondary, accent, background);
}
