import 'package:get/get.dart';

import '../modules/guest_access/guest_access_page.dart';
import '../modules/guest_access/recording_page.dart';
import '../modules/home/home_page.dart';
import '../modules/qr_scan/qr_scan_page.dart';
import '../modules/tables/tables_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
    GetPage(name: AppRoutes.qrScanner, page: () => const QrScanPage()),
    GetPage(name: AppRoutes.tables, page: () => const TablesPage()),
    GetPage(
      name: AppRoutes.guestPattern,
      page: () => GuestAccessPage(token: Get.parameters['token'] ?? ''),
    ),
    GetPage(
      name: AppRoutes.recordingPattern,
      page: () => RecordingPage(token: Get.parameters['token'] ?? ''),
    ),
  ];
}
