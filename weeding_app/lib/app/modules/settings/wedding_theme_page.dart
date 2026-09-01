import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/wedding_palette.dart';
import '../../core/theme/wedding_theme_controller.dart';
import '../../core/widgets/wedding_header.dart';

class WeddingThemePage extends StatefulWidget {
  const WeddingThemePage({super.key});

  @override
  State<WeddingThemePage> createState() => _WeddingThemePageState();
}

class _WeddingThemePageState extends State<WeddingThemePage> {
  final _formKey = GlobalKey<FormState>();
  late final WeddingThemeController _themeController;
  late final TextEditingController _primaryController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _accentController;
  late final TextEditingController _backgroundController;
  late WeddingPalette _draft;
  bool _isLoading = true;

  static const _presets = <_PalettePreset>[
    _PalettePreset(
      name: 'Pourpre & blanc',
      description: 'Pourpre intense, blanc lumineux et encre profonde',
      palette: WeddingPalette.celestialRomance,
    ),
    _PalettePreset(
      name: 'Jardin sauge',
      description: 'Vert naturel et champagne',
      palette: WeddingPalette(
        primary: Color(0xFF526B54),
        secondary: Color(0xFF8B6F47),
        accent: Color(0xFFD4AF70),
        background: Color(0xFFF8F6EF),
      ),
    ),
    _PalettePreset(
      name: 'Rose poudré',
      description: 'Romantique, doux et lumineux',
      palette: WeddingPalette(
        primary: Color(0xFF9E4F63),
        secondary: Color(0xFFB87883),
        accent: Color(0xFFD5A76C),
        background: Color(0xFFFFF7F7),
      ),
    ),
    _PalettePreset(
      name: 'Nuit royale',
      description: 'Bleu profond et touches dorées',
      palette: WeddingPalette(
        primary: Color(0xFF203A63),
        secondary: Color(0xFF66507A),
        accent: Color(0xFFC79A3B),
        background: Color(0xFFF7F8FC),
      ),
    ),
    _PalettePreset(
      name: 'Lagune',
      description: 'Turquoise, bleu et sable clair',
      palette: WeddingPalette(
        primary: Color(0xFF006D77),
        secondary: Color(0xFF277DA1),
        accent: Color(0xFFE6A15C),
        background: Color(0xFFF3FAF9),
      ),
    ),
    _PalettePreset(
      name: 'Élégance ivoire',
      description: 'Brun raffiné et champagne',
      palette: WeddingPalette(
        primary: Color(0xFF614C3F),
        secondary: Color(0xFF8A6F5A),
        accent: Color(0xFFB8945B),
        background: Color(0xFFFFFBF3),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _themeController = Get.find<WeddingThemeController>();
    _draft = _themeController.palette.value;
    _primaryController = TextEditingController();
    _secondaryController = TextEditingController();
    _accentController = TextEditingController();
    _backgroundController = TextEditingController();
    _syncControllers();
    _refresh();
  }

  Future<void> _refresh() async {
    await _themeController.loadForCurrentWedding();
    if (!mounted) return;
    setState(() {
      _draft = _themeController.palette.value;
      _syncControllers();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _accentController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _primaryController.text = WeddingPalette.colorToHex(_draft.primary);
    _secondaryController.text = WeddingPalette.colorToHex(_draft.secondary);
    _accentController.text = WeddingPalette.colorToHex(_draft.accent);
    _backgroundController.text = WeddingPalette.colorToHex(_draft.background);
  }

  /// Les palettes proposées ne portent que sur les couleurs : les polices déjà
  /// choisies par les mariés sont conservées.
  void _selectPalette(WeddingPalette palette) {
    setState(() {
      _draft = palette.copyWith(
        displayFont: _draft.displayFont,
        bodyFont: _draft.bodyFont,
      );
      _syncControllers();
    });
  }

  bool _matchesColors(WeddingPalette preset) =>
      preset.primary == _draft.primary &&
      preset.secondary == _draft.secondary &&
      preset.accent == _draft.accent &&
      preset.background == _draft.background;

  void _updateColor(_ColorSlot slot, String value) {
    if (!WeddingPalette.isValidHex(value)) return;
    final color = WeddingPalette.colorFromHex(value);
    setState(() {
      _draft = _draft.copyWith(
        primary: slot == _ColorSlot.primary ? color : null,
        secondary: slot == _ColorSlot.secondary ? color : null,
        accent: slot == _ColorSlot.accent ? color : null,
        background: slot == _ColorSlot.background ? color : null,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final palette = WeddingPalette(
      primary: WeddingPalette.colorFromHex(_primaryController.text),
      secondary: WeddingPalette.colorFromHex(_secondaryController.text),
      accent: WeddingPalette.colorFromHex(_accentController.text),
      background: WeddingPalette.colorFromHex(_backgroundController.text),
      displayFont: _draft.displayFont,
      bodyFont: _draft.bodyFont,
    );

    try {
      await _themeController.save(palette);
      if (!mounted) return;
      Get.back();
      Get.snackbar(
        'Palette enregistrée',
        'Les couleurs du mariage sont maintenant appliquées.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Enregistrement impossible',
        'Vérifiez vos droits puis réessayez.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const WeddingHeader(title: 'Couleurs du mariage'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                      children: [
                        Text('Aperçu', style: AppTextStyles.headlineMd),
                        const SizedBox(height: 12),
                        _ThemePreview(palette: _draft),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Palettes proposées',
                                style: AppTextStyles.headlineMd,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _selectPalette(
                                WeddingPalette.celestialRomance,
                              ),
                              child: const Text('Réinitialiser'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._presets.map(
                          (preset) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PresetTile(
                              preset: preset,
                              selected: _matchesColors(preset.palette),
                              onTap: () => _selectPalette(preset.palette),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Couleurs personnalisées',
                          style: AppTextStyles.headlineMd,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saisissez une couleur au format #RRGGBB.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HexColorField(
                          label: 'Couleur principale',
                          controller: _primaryController,
                          color: _draft.primary,
                          onChanged: (value) =>
                              _updateColor(_ColorSlot.primary, value),
                        ),
                        const SizedBox(height: 12),
                        _HexColorField(
                          label: 'Couleur secondaire',
                          controller: _secondaryController,
                          color: _draft.secondary,
                          onChanged: (value) =>
                              _updateColor(_ColorSlot.secondary, value),
                        ),
                        const SizedBox(height: 12),
                        _HexColorField(
                          label: 'Couleur d’accent',
                          controller: _accentController,
                          color: _draft.accent,
                          onChanged: (value) =>
                              _updateColor(_ColorSlot.accent, value),
                        ),
                        const SizedBox(height: 12),
                        _HexColorField(
                          label: 'Arrière-plan',
                          controller: _backgroundController,
                          color: _draft.background,
                          onChanged: (value) =>
                              _updateColor(_ColorSlot.background, value),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Polices du mariage',
                          style: AppTextStyles.headlineMd,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'La police de titres habille les prénoms et la carte '
                          'd’invitation. La police de texte reste lisible '
                          'partout dans l’application.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FontPicker(
                          label: 'Police de titres',
                          fonts: WeddingFonts.display,
                          selected: _draft.displayFont,
                          sampleText: 'Aïcha & Karim',
                          sampleSize: 24,
                          onSelected: (font) => setState(
                            () => _draft = _draft.copyWith(displayFont: font),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FontPicker(
                          label: 'Police de texte',
                          fonts: WeddingFonts.body,
                          selected: _draft.bodyFont,
                          sampleText: 'Nous célébrons notre mariage',
                          sampleSize: 15,
                          onSelected: (font) => setState(
                            () => _draft = _draft.copyWith(bodyFont: font),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Aperçu de la carte d\'invitation',
                          style: AppTextStyles.headlineMd,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Voici à quoi ressemblera la carte de vos invités '
                          'avec les polices et couleurs choisies.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CardPreview(palette: _draft),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: _isLoading || _themeController.isSaving.value
                  ? null
                  : _save,
              icon: _themeController.isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _themeController.isSaving.value
                    ? 'Enregistrement…'
                    : 'Appliquer ces couleurs',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ColorSlot { primary, secondary, accent, background }

class _PalettePreset {
  final String name;
  final String description;
  final WeddingPalette palette;

  const _PalettePreset({
    required this.name,
    required this.description,
    required this.palette,
  });
}

class _ThemePreview extends StatelessWidget {
  final WeddingPalette palette;

  const _ThemePreview({required this.palette});

  /// L'aperçu doit montrer les polices du brouillon, pas celles déjà
  /// appliquées : on ne peut donc pas passer par [AppTextStyles].
  static TextStyle _font(
    String family,
    double size,
    Color color,
    FontWeight weight,
  ) {
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: size,
        height: 1.25,
        color: color,
        fontWeight: weight,
      );
    } catch (_) {
      return GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: 1.25,
        color: color,
        fontWeight: weight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = palette.primary.computeLuminance() > 0.48
        ? Colors.black
        : Colors.white;
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inkFor(palette), width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: palette.primary),
            child: Text(
              'Aïcha & Karim',
              style: _font(palette.displayFont, 24, onPrimary, FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nous célébrons notre mariage',
                    style: _font(
                      palette.bodyFont,
                      16,
                      AppColors.inkFor(palette),
                      FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.inkFor(palette)),
                    ),
                    child: Text(
                      'Voir l’invitation',
                      style: _font(
                        palette.bodyFont,
                        12,
                        palette.accent.computeLuminance() > 0.48
                            ? Colors.black
                            : Colors.white,
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de police affichant chaque option dans sa propre typographie.
class _FontPicker extends StatelessWidget {
  final String label;
  final List<String> fonts;
  final String selected;
  final String sampleText;
  final double sampleSize;
  final ValueChanged<String> onSelected;

  const _FontPicker({
    required this.label,
    required this.fonts,
    required this.selected,
    required this.sampleText,
    required this.sampleSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        ...fonts.map((font) {
          final isSelected = font == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onSelected(font),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.dark
                          : AppColors.outlineVariant,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sampleText,
                              style: _sample(font),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              font,
                              style: AppTextStyles.labelMd.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.dark
                            : AppColors.outlineVariant,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  TextStyle _sample(String font) {
    try {
      return GoogleFonts.getFont(
        font,
        fontSize: sampleSize,
        height: 1.25,
        color: AppColors.onBackground,
      );
    } catch (_) {
      return AppTextStyles.bodyLg.copyWith(fontSize: sampleSize);
    }
  }
}

class _PresetTile extends StatelessWidget {
  final _PalettePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      preset.palette.primary,
      preset.palette.secondary,
      preset.palette.accent,
      preset.palette.background,
    ];
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 34,
                child: Row(
                  children: colors
                      .map(
                        (color) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              border: Border.all(
                                color: scheme.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      preset.description,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexColorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  const _HexColorField({
    required this.label,
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      maxLength: 7,
      onChanged: onChanged,
      validator: (value) => WeddingPalette.isValidHex(value ?? '')
          ? null
          : 'Utilisez le format #RRGGBB',
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Invitation card preview using draft palette fonts (not applied ones).
class _CardPreview extends StatelessWidget {
  final WeddingPalette palette;

  const _CardPreview({required this.palette});

  static TextStyle _font(
    String family,
    double size,
    Color color,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: size,
        height: height ?? 1.25,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    } catch (_) {
      return GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: height ?? 1.25,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = AppColors.onColorFor(palette.primary);
    final onSecondary = AppColors.onColorFor(palette.secondary);

    return Center(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.12),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge "VOUS ÊTES INVITÉ(E)"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.dark, width: 1.2),
              ),
              child: Text(
                'VOUS ÊTES INVITÉ(E)',
                style: _font(
                  palette.bodyFont,
                  10,
                  onSecondary,
                  FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Guest name (display font)
            Text(
              'Aïcha & Karim',
              style: _font(
                palette.displayFont,
                26,
                onPrimary,
                FontWeight.w800,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Table + Seat info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dark, width: 1.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CardInfoColumn(
                    icon: Icons.table_restaurant_rounded,
                    label: 'TABLE',
                    value: 'Famille',
                    bodyFont: palette.bodyFont,
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    color: palette.accent,
                  ),
                  _CardInfoColumn(
                    icon: Icons.event_seat_rounded,
                    label: 'PLACE',
                    value: '3',
                    bodyFont: palette.bodyFont,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Footer text
            Text(
              '💍 Montrer ce badge à l\'entrée 💍',
              style: _font(
                palette.bodyFont,
                11,
                onPrimary,
                FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String bodyFont;

  const _CardInfoColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.bodyFont,
  });

  static TextStyle _font(
    String family,
    double size,
    Color color,
    FontWeight weight, {
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: size,
        height: 1.25,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: 1.25,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.dark, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: _font(
            bodyFont,
            9,
            AppColors.onSurfaceVariant,
            FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: _font(
            bodyFont,
            16,
            AppColors.dark,
            FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
