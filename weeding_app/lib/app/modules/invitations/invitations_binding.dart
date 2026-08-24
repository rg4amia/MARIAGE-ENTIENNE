import 'package:get/get.dart';
import 'invitations_controller.dart';

class InvitationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvitationsController>(() => InvitationsController());
  }
}
