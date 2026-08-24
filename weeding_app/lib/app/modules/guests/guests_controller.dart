import 'package:get/get.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/models/guest.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import '../../data/models/guest_seat.dart';

class GuestsController extends GetxController {
  final GuestRepository _guestRepository = GuestRepository();
  final TableRepository _tableRepository = TableRepository();
  final InvitationRepository _invitationRepository = InvitationRepository();

  final RxList<Guest> guests = <Guest>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = 'all'.obs;

  List<Guest> get filteredGuests {
    var result = guests.toList();

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where((g) =>
              g.fullName.toLowerCase().contains(q) ||
              (g.phone?.toLowerCase().contains(q) ?? false) ||
              (g.email?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (filterStatus.value != 'all') {
      result = result.where((g) => g.status == filterStatus.value).toList();
    }

    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadGuests();
  }

  Future<void> loadGuests() async {
    isLoading.value = true;
    try {
      guests.value = await _guestRepository.getAllGuests();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les invités');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGuest({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    try {
      final guest = await _guestRepository.createGuest(
        fullName: fullName,
        phone: phone,
        email: email,
      );

      // Créer automatiquement une invitation
      await _invitationRepository.createInvitation(guestId: guest.id);

      await loadGuests();
      Get.back();
      Get.snackbar('Succès', 'Invité ajouté avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'ajouter l\'invité');
    }
  }

  Future<void> updateGuest({
    required String id,
    String? fullName,
    String? phone,
    String? email,
  }) async {
    try {
      await _guestRepository.updateGuest(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
      );
      await loadGuests();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier l\'invité');
    }
  }

  Future<void> deleteGuest(String id) async {
    try {
      await _guestRepository.deleteGuest(id);
      await loadGuests();
      Get.back();
      Get.snackbar('Succès', 'Invité supprimé');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer l\'invité');
    }
  }

  Future<void> assignSeatToGuest({
    required String guestId,
    required String tableId,
    required String chairId,
  }) async {
    try {
      await _guestRepository.assignSeat(
        guestId: guestId,
        tableId: tableId,
        chairId: chairId,
      );
      await loadGuests();
      Get.back();
      Get.snackbar('Succès', 'Place assignée avec succès');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }

  Future<void> unassignGuestSeat(String guestId) async {
    try {
      await _guestRepository.unassignSeat(guestId);
      await loadGuests();
      Get.snackbar('Succès', 'Place libérée');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de libérer la place');
    }
  }

  Future<GuestSeat?> getGuestSeat(String guestId) async {
    return await _guestRepository.getGuestSeat(guestId);
  }

  Future<List<WeddingTable>> getAllTables() async {
    return await _tableRepository.getAllTables();
  }

  Future<List<Chair>> getAvailableChairs(String tableId) async {
    return await _tableRepository.getAvailableChairsByTableId(tableId);
  }

  int get pendingCount => guests.where((g) => g.status == 'pending').length;
  int get confirmedCount => guests.where((g) => g.status != 'pending').length;

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void onFilterChanged(String status) {
    filterStatus.value = status;
  }
}
