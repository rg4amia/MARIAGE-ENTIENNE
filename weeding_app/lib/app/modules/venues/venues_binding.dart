import 'package:get/get.dart';
import 'venues_controller.dart';

class VenuesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VenuesController>(() => VenuesController());
  }
}
