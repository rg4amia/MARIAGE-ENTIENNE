import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/wedding_theme_repository.dart';
import 'wedding_palette.dart';

class WeddingThemeController extends GetxController {
  WeddingThemeController({WeddingThemeRepository? repository})
    : _repository = repository ?? WeddingThemeRepository();

  final WeddingThemeRepository _repository;
  final Rx<WeddingPalette> palette = WeddingPalette.celestialRomance.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  Future<void> loadForCurrentWedding() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      palette.value = await _repository.getPalette();
    } catch (error) {
      debugPrint('Erreur chargement palette mariage: $error');
      palette.value = WeddingPalette.celestialRomance;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save(WeddingPalette value) async {
    isSaving.value = true;
    try {
      await _repository.updatePalette(value);
      palette.value = value;
    } finally {
      isSaving.value = false;
    }
  }

  void reset() => palette.value = WeddingPalette.celestialRomance;
}
