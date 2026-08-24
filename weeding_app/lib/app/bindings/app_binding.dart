import 'package:get/get.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/tables/tables_controller.dart';
import '../modules/guests/guests_controller.dart';
import '../modules/invitations/invitations_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);

    // Feature controllers
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<TablesController>(() => TablesController(), fenix: true);
    Get.lazyPut<GuestsController>(() => GuestsController(), fenix: true);
    Get.lazyPut<InvitationsController>(() => InvitationsController(), fenix: true);
  }
}
