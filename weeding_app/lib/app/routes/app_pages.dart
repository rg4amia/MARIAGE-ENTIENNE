import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/admin/admin_console_page.dart';
import '../modules/admin/admin_controller.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/tables/tables_binding.dart';
import '../modules/tables/table_detail_page.dart';
import '../modules/guests/guests_binding.dart';
import '../modules/guests/guest_detail_page.dart';
import '../modules/invitations/qr_code_page.dart';
import '../modules/invitations/invitations_binding.dart';
import '../modules/invitations/entrance_qr_page.dart';
import '../modules/navigation/main_navigation_controller.dart';
import '../modules/navigation/main_shell_page.dart';
import '../modules/onboarding/splash_page.dart';
import '../modules/onboarding/welcome_page.dart';
import '../modules/onboarding/workspace_onboarding_binding.dart';
import '../modules/onboarding/workspace_onboarding_page.dart';
import '../modules/subscription/plans_page.dart';
import '../modules/venues/venues_binding.dart';
import '../modules/venues/venues_page.dart';
import '../modules/settings/wedding_theme_page.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomePage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    // Consultable sans compte : le visiteur doit pouvoir juger le prix avant
    // de s'inscrire.
    GetPage(
      name: AppRoutes.plans,
      page: () => const PlansPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const WorkspaceOnboardingPage(),
      binding: WorkspaceOnboardingBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () =>
          const MainShellPage(initialIndex: MainNavigationController.homeTab),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.tables,
      page: () =>
          const MainShellPage(initialIndex: MainNavigationController.tablesTab),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.tableDetail,
      page: () => const TableDetailPage(),
      binding: TablesBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.guests,
      page: () =>
          const MainShellPage(initialIndex: MainNavigationController.guestsTab),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.guestDetail,
      page: () => const GuestDetailPage(),
      binding: GuestsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.invitations,
      page: () => const MainShellPage(
        initialIndex: MainNavigationController.invitationsTab,
      ),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.qrCode,
      page: () => const QrCodePage(),
      binding: InvitationsBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.entranceQr,
      page: () => const EntranceQrPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.venues,
      page: () => const VenuesPage(),
      binding: VenuesBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const MainShellPage(
        initialIndex: MainNavigationController.settingsTab,
      ),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.weddingTheme,
      page: () => const WeddingThemePage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    // La console n'est qu'une commodité d'affichage : c'est la base qui
    // refuse chaque appel à qui n'exploite pas la plateforme.
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminConsolePage(),
      middlewares: [AuthMiddleware(), PlatformAdminMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}

/// Referme la console sur un compte ordinaire qui atteindrait `/admin`.
class PlatformAdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AdminController>()) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return Get.find<AdminController>().isPlatformAdmin.value
        ? null
        : const RouteSettings(name: AppRoutes.home);
  }
}

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Sans session, on renvoie sur la page de garde et non sur le formulaire
    // de connexion : un visiteur qui découvre le produit doit d'abord voir ce
    // qu'on lui propose.
    if (!authController.isLoggedIn &&
        !AppRoutes.publicRoutes.contains(route)) {
      return const RouteSettings(name: AppRoutes.welcome);
    }

    if (authController.isLoggedIn &&
        authController.isInitialized.value &&
        authController.profile.value == null &&
        route != AppRoutes.onboarding) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }

    return null;
  }
}
