import 'package:get/get.dart';
import 'guests_controller.dart';

class GuestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuestsController>(() => GuestsController());
  }
}
