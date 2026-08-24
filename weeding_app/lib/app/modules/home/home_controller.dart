import 'package:get/get.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/models/profile.dart';
import '../auth/auth_controller.dart';

class HomeController extends GetxController {
  final GuestRepository _guestRepository = GuestRepository();
  final TableRepository _tableRepository = TableRepository();
  final InvitationRepository _invitationRepository = InvitationRepository();

  final RxInt totalGuests = 0.obs;
  final RxInt totalTables = 0.obs;
  final RxInt totalChairs = 0.obs;
  final RxInt totalMedia = 0.obs;
  final RxInt pendingGuests = 0.obs;
  final RxInt mediaUploaded = 0.obs;
  final RxInt cardUnlocked = 0.obs;
  final RxBool isLoading = false.obs;

  Profile? get currentProfile => Get.find<AuthController>().profile.value;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;

    try {
      final guestStats = await _guestRepository.getGuestStats();
      final tableStats = await _tableRepository.getTableStats();
      final mediaCount = await _invitationRepository.getMediaCount();

      totalGuests.value = guestStats['total'] ?? 0;
      pendingGuests.value = guestStats['pending'] ?? 0;
      mediaUploaded.value = guestStats['mediaUploaded'] ?? 0;
      cardUnlocked.value = guestStats['cardUnlocked'] ?? 0;

      totalTables.value = tableStats['totalTables'] ?? 0;
      totalChairs.value = tableStats['totalChairs'] ?? 0;

      totalMedia.value = mediaCount;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les statistiques',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
