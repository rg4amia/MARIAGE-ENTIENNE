import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';
import '../auth/auth_controller.dart';

class WorkspaceOnboardingController extends GetxController {
  final AuthRepository _repository = AuthRepository();

  final organizationNameController = TextEditingController();
  final eventTitleController = TextEditingController();
  final brideNameController = TextEditingController();
  final groomNameController = TextEditingController();
  final Rxn<DateTime> eventDate = Rxn<DateTime>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final fullName =
        Get.find<AuthController>().user.value?.userMetadata?['full_name']
            ?.toString() ??
        '';
    if (fullName.isNotEmpty) {
      organizationNameController.text = 'Mariage de $fullName';
    }
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    eventTitleController.dispose();
    brideNameController.dispose();
    groomNameController.dispose();
    super.onClose();
  }

  void selectDate(DateTime date) => eventDate.value = date;

  Future<void> createWorkspace() async {
    final organizationName = organizationNameController.text.trim();
    final eventTitle = eventTitleController.text.trim();
    final brideName = brideNameController.text.trim();
    final groomName = groomNameController.text.trim();

    if ([
      organizationName,
      eventTitle,
      brideName,
      groomName,
    ].any((value) => value.isEmpty)) {
      Get.snackbar(
        'Informations incomplètes',
        'Renseignez l’organisation, le mariage et les deux mariés.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      await _repository.createSaasWorkspace(
        organizationName: organizationName,
        eventTitle: eventTitle,
        brideName: brideName,
        groomName: groomName,
        eventDate: eventDate.value,
      );

      final authController = Get.find<AuthController>();
      await authController.refreshProfile();
      if (authController.profile.value == null) {
        throw StateError('Le profil SaaS n’a pas été créé.');
      }

      Get.offAllNamed(AppRoutes.home);
      Get.snackbar(
        'Votre espace est prêt',
        'Bienvenue sur Mon Mariage !',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Création impossible',
        _messageFor(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _messageFor(Object error) {
    final message = error.toString();
    if (message.contains('already belongs to an organization')) {
      return 'Ce compte appartient déjà à une organisation.';
    }
    if (message.contains('Authentication required')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    if (message.contains('Organization name is required')) {
      return 'Le nom de l\'organisation est requis.';
    }
    if (message.contains('Wedding title and couple names are required')) {
      return 'Le titre et les noms des mariés sont requis.';
    }
    if (message.contains('Default SaaS plan is unavailable')) {
      return 'Erreur de configuration : forfait par défaut introuvable.';
    }
    // Exposer le message brut pour faciliter le débogage
    debugPrint('[WorkspaceOnboarding] createWorkspace error: $error');
    return message.length > 120 ? '${message.substring(0, 120)}…' : message;
  }
}
