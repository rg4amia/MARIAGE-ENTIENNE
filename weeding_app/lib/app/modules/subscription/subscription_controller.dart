import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/subscription_repository.dart';

class SubscriptionController extends GetxController {
  SubscriptionController({SubscriptionRepository? repository})
    : _repository = repository ?? SubscriptionRepository();

  final SubscriptionRepository _repository;

  final Rxn<SubscriptionOverview> overview = Rxn<SubscriptionOverview>();
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPlans = false.obs;

  /// Forfait courant, rechargé après chaque envoi d'invitation pour que le
  /// quota affiché ne mente jamais sur ce qui reste.
  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      overview.value = await _repository.getOverview();
    } catch (error) {
      debugPrint('Erreur chargement forfait: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPlans() async {
    if (isLoadingPlans.value || plans.isNotEmpty) return;
    isLoadingPlans.value = true;
    try {
      plans.assignAll(await _repository.getPlans());
    } catch (error) {
      debugPrint('Erreur chargement forfaits: $error');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  void clear() {
    overview.value = null;
    plans.clear();
  }

  /// Packs mariage, dans l'ordre de prix : ce que voit un couple.
  List<SubscriptionPlan> get weddingPacks =>
      plans.where((plan) => plan.isWeddingPack).toList();

  /// Abonnements récurrents : ce que voit un wedding planner.
  List<SubscriptionPlan> get subscriptions =>
      plans.where((plan) => !plan.isWeddingPack).toList();

  String? get currentPlanId => overview.value?.plan.id;
}
