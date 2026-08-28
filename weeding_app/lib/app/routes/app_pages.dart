import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_page.dart';
import '../modules/tables/tables_binding.dart';
import '../modules/tables/table_detail_page.dart';
import '../modules/guests/guests_binding.dart';
import '../modules/guests/guest_detail_page.dart';
import '../modules/invitations/qr_code_page.dart';
import '../modules/invitations/invitations_binding.dart';
import '../modules/invitations/entrance_qr_page.dart';
import '../modules/navigation/main_navigation_controller.dart';
import '../modules/navigation/main_shell_page.dart';
import '../modules/onboarding/workspace_onboarding_binding.dart';
import '../modules/onboarding/workspace_onboarding_page.dart';
import '../modules/venues/venues_binding.dart';
import '../modules/venues/venues_page.dart';

class AppPages {
  static const initial = AppRoutes.login;

  static final routes = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const WorkspaceOnboardingPage(),
      binding: WorkspaceOnboardingBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
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
  ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (!authController.isLoggedIn && route != AppRoutes.login) {
      return const RouteSettings(name: AppRoutes.login);
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
