import 'package:get/get.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/models/invitation.dart';
import '../../data/models/guest.dart';

class InvitationsController extends GetxController {
  final InvitationRepository _invitationRepository = InvitationRepository();
  final GuestRepository _guestRepository = GuestRepository();

  final RxList<Invitation> invitations = <Invitation>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    isLoading.value = true;
    try {
      invitations.value = await _invitationRepository.getAllInvitations();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les invitations');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Guest?> getGuestForInvitation(String guestId) async {
    return await _guestRepository.getGuestById(guestId);
  }

  Future<Invitation?> getInvitationForGuest(String guestId) async {
    return await _invitationRepository.getInvitationByGuestId(guestId);
  }
}
