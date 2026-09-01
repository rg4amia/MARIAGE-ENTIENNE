import 'package:get/get.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is registered as permanent in AppBinding.
    // Avoid re-registering it here — the fenix:true factory can be lost
    // during route transitions, causing "AuthController not found" on
    // pages that call Get.find<AuthController>() (e.g. SettingsPage).
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
