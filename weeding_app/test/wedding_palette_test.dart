import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/theme/app_theme.dart';
import 'package:weeding_app/app/core/theme/wedding_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeddingPalette', () {
    test('convertit une palette Supabase et la sérialise en HEX majuscule', () {
      final palette = WeddingPalette.fromJson(const {
        'primary_color': '#112233',
        'secondary_color': '#aabbcc',
        'accent_color': '#445566',
        'background_color': '#fefefe',
      });

      expect(palette.primary, const Color(0xFF112233));
      expect(palette.toJson()['secondary_color'], '#AABBCC');
      expect(palette.toJson()['background_color'], '#FEFEFE');
    });

    test('remplace une valeur invalide par la couleur Celestial Romance', () {
      final palette = WeddingPalette.fromJson(const {
        'primary_color': 'rouge',
        'secondary_color': '#9C4236',
        'accent_color': '#BE9A7A',
        'background_color': '#FFF8F4',
      });

      expect(palette.primary, WeddingPalette.celestialRomance.primary);
      expect(WeddingPalette.isValidHex('#12ABef'), isTrue);
      expect(WeddingPalette.isValidHex('#123'), isFalse);
    });

    test('alimente le thème global avec les quatre couleurs du mariage', () {
      const palette = WeddingPalette(
        primary: Color(0xFF123456),
        secondary: Color(0xFF654321),
        accent: Color(0xFFD4AF37),
        background: Color(0xFFFFFDF7),
      );

      final theme = AppTheme.lightThemeFor(palette);

      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.secondary, palette.secondary);
      expect(theme.colorScheme.tertiary, palette.accent);
      expect(theme.scaffoldBackgroundColor, palette.background);
    });
  });
}
