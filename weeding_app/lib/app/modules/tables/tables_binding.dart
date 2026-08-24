import 'package:get/get.dart';
import 'tables_controller.dart';

class TablesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TablesController>(() => TablesController());
  }
}
