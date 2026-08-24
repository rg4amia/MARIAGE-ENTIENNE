import 'package:get/get.dart';
import 'guest_access_controller.dart';

class GuestAccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuestAccessController>(() => GuestAccessController());
  }
}
