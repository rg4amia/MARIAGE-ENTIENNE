import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/tables/tables_page.dart';
import '../modules/tables/tables_binding.dart';
import '../modules/tables/table_detail_page.dart';
import '../modules/guests/guests_page.dart';
import '../modules/guests/guests_binding.dart';
import '../modules/guests/guest_detail_page.dart';
import '../modules/invitations/qr_code_page.dart';
import '../modules/invitations/invitations_page.dart';
import '../modules/invitations/invitations_binding.dart';
import '../modules/settings/settings_page.dart';
import '../modules/guest_access/guest_access_page.dart';
import '../modules/guest_access/guest_access_binding.dart';

class AppPages {
  static const initial = AppRoutes.login;

  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tables,
      page: () => const TablesPage(),
      binding: TablesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tableDetail,
      page: () => const TableDetailPage(),
      binding: TablesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.guests,
      page: () => const GuestsPage(),
      binding: GuestsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.guestDetail,
      page: () => const GuestDetailPage(),
      binding: GuestsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.invitations,
      page: () => const InvitationsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.qrCode,
      page: () => const QrCodePage(),
      binding: InvitationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      middlewares: [AuthMiddleware()],
    ),

    // Public routes (no auth required)
    GetPage(
      name: AppRoutes.guestAccess,
      page: () => const GuestAccessPage(),
      binding: GuestAccessBinding(),
    ),
  ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (!authController.isLoggedIn &&
        route != AppRoutes.login &&
        route != AppRoutes.register &&
        route != AppRoutes.guestAccess) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
