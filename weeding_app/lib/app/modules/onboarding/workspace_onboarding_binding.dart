import 'package:get/get.dart';
import 'workspace_onboarding_controller.dart';

class WorkspaceOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkspaceOnboardingController>(
      () => WorkspaceOnboardingController(),
    );
  }
}
