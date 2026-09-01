import 'package:get/get.dart';
import '../modules/admin/admin_controller.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/tables/tables_controller.dart';
import '../modules/guests/guests_controller.dart';
import '../modules/invitations/invitations_controller.dart';
import '../modules/navigation/main_navigation_controller.dart';
import '../modules/subscription/subscription_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put(MainNavigationController(), permanent: true);

    // Le forfait est consulté depuis la page de garde comme depuis le
    // tableau de bord : il vit aussi longtemps que l'application.
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(),
      fenix: true,
    );

    // La console d'exploitation doit exister avant sa route, puisque son
    // garde-barrière l'interroge pour décider d'ouvrir ou non.
    Get.put<AdminController>(AdminController(), permanent: true);

    // Feature controllers
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<TablesController>(() => TablesController(), fenix: true);
    Get.lazyPut<GuestsController>(() => GuestsController(), fenix: true);
    Get.lazyPut<InvitationsController>(
      () => InvitationsController(),
      fenix: true,
    );
  }
}
