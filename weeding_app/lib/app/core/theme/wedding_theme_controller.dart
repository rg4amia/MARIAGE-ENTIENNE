import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/wedding_theme_repository.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'wedding_palette.dart';

class WeddingThemeController extends GetxController {
  WeddingThemeController({WeddingThemeRepository? repository})
    : _repository = repository ?? WeddingThemeRepository();

  final WeddingThemeRepository _repository;
  final Rx<WeddingPalette> palette = WeddingPalette.celestialRomance.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apply(palette.value);
  }

  Future<void> loadForCurrentWedding() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      _apply(await _repository.getPalette());
    } catch (error) {
      debugPrint('Erreur chargement palette mariage: $error');
      _apply(WeddingPalette.celestialRomance);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save(WeddingPalette value) async {
    isSaving.value = true;
    try {
      await _repository.updatePalette(value);
      _apply(value);
    } finally {
      isSaving.value = false;
    }
  }

  void reset() => _apply(WeddingPalette.celestialRomance);

  /// Propage la palette aux jetons statiques avant de notifier les widgets :
  /// `AppColors`/`AppTextStyles` sont lus pendant le `build`, ils doivent donc
  /// être à jour au moment où l'`Obx` racine reconstruit l'application.
  void _apply(WeddingPalette value) {
    AppColors.applyPalette(value);
    AppTextStyles.applyPalette(value);
    palette.value = value;
  }
}
