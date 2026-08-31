import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/platform_admin.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/subscription_repository.dart';

class AdminController extends GetxController {
  AdminController({AdminRepository? repository, SubscriptionRepository? plans})
    : _repository = repository ?? AdminRepository(),
      _plans = plans ?? SubscriptionRepository();

  final AdminRepository _repository;
  final SubscriptionRepository _plans;

  /// Décidé par la base, jamais déduit d'un rôle local.
  final RxBool isPlatformAdmin = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString search = ''.obs;

  final RxList<AdminOrganization> organizations = <AdminOrganization>[].obs;
  final RxList<AdminEvent> events = <AdminEvent>[].obs;
  final RxList<AdminAccount> accounts = <AdminAccount>[].obs;
  final RxList<AdminAction> actions = <AdminAction>[].obs;
  final RxList<SubscriptionPlan> availablePlans = <SubscriptionPlan>[].obs;

  /// Vérifie la qualité d'exploitant au démarrage de l'app. Silencieuse :
  /// pour l'immense majorité des comptes la réponse est « non ».
  Future<void> resolveAccess() async {
    try {
      isPlatformAdmin.value = await _repository.isPlatformAdmin();
    } catch (e) {
      debugPrint('Vérification exploitant impossible: $e');
      isPlatformAdmin.value = false;
    }
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final term = search.value;
      final results = await Future.wait([
        _repository.listOrganizations(search: term),
        _repository.listEvents(search: term),
        _repository.listAccounts(search: term),
        _repository.recentActions(),
      ]);
      organizations.value = results[0] as List<AdminOrganization>;
      events.value = results[1] as List<AdminEvent>;
      accounts.value = results[2] as List<AdminAccount>;
      actions.value = results[3] as List<AdminAction>;

      if (availablePlans.isEmpty) {
        availablePlans.value = await _plans.getPlans();
      }
    } catch (e) {
      debugPrint('Chargement console: $e');
      errorMessage.value = _readable(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> setPlan(String organizationId, String planId, String reason) {
    return _run(() => _repository.setOrganizationPlan(
      organizationId: organizationId,
      planId: planId,
      reason: reason,
    ));
  }

  Future<bool> setStatus(String organizationId, String status, String reason) {
    return _run(() => _repository.setOrganizationStatus(
      organizationId: organizationId,
      status: status,
      reason: reason,
    ));
  }

  Future<bool> grantInvitations(String eventId, int extra, String reason) {
    return _run(() => _repository.grantInvitations(
      eventId: eventId,
      extra: extra,
      reason: reason,
    ));
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('Geste exploitant refusé: $e');
      Get.snackbar('Action refusée', _readable(e));
      return false;
    }
  }

  /// Les refus de la console sont préfixés `ADMIN_` et déjà rédigés.
  static String _readable(Object error) {
    final match = RegExp(
      r'ADMIN_[A-Z_]+\s*:\s*(.+?)(?:\r?\n|$)',
    ).firstMatch(error.toString());
    return match?.group(1)?.trim() ?? 'Opération impossible pour le moment.';
  }
}
