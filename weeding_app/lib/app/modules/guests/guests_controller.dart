import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/models/guest.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import '../../data/models/guest_seat.dart';

class GuestsController extends GetxController {
  final GuestRepository _guestRepository = GuestRepository();
  final TableRepository _tableRepository = TableRepository();
  final GuestLinkRepository _linkRepository = GuestLinkRepository();

  final RxList<Guest> guests = <Guest>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = 'all'.obs;
  RealtimeChannel? _guestChanges;

  List<Guest> get filteredGuests {
    var result = guests.toList();

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (g) =>
                g.fullName.toLowerCase().contains(q) ||
                (g.phone?.toLowerCase().contains(q) ?? false) ||
                (g.email?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    // Les filtres portent sur la réponse de présence (RSVP) : c'est ce qui
    // guide le placement à table après confirmation.
    switch (filterStatus.value) {
      case 'pending':
        result = result
            .where((g) => g.status != 'cancelled' && g.rsvpStatus == 'pending')
            .toList();
      case 'confirmed':
        result = result
            .where((g) => g.status != 'cancelled' && g.isRsvpConfirmed)
            .toList();
      case 'declined':
        result = result
            .where((g) => g.status != 'cancelled' && g.rsvpStatus == 'declined')
            .toList();
      case 'cancelled':
        result = result.where((g) => g.status == 'cancelled').toList();
    }

    return result;
  }

  @override
  void onInit() {
    super.onInit();
    loadGuests();
    _guestChanges = Supabase.instance.client
        .channel('admin-guests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'guests',
          callback: (_) => loadGuests(),
        )
        .subscribe();
  }

  @override
  void onClose() {
    final channel = _guestChanges;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.onClose();
  }

  Future<void> loadGuests() async {
    isLoading.value = true;
    try {
      guests.value = await _guestRepository.getAllGuests();
    } catch (e) {
      debugPrint('Erreur chargement invités: $e');
      Get.snackbar('Erreur', 'Impossible de charger les invités');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Guest?> createGuest({
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

      await loadGuests();
      Get.snackbar('Succès', 'Invité ajouté avec succès');
      return guest;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'ajouter l\'invité');
      return null;
    }
  }

  Future<Guest?> updateGuest({
    required String id,
    String? fullName,
    String? phone,
    String? email,
    bool clearPhone = false,
    bool clearEmail = false,
  }) async {
    try {
      final guest = await _guestRepository.updateGuest(
        id: id,
        fullName: fullName,
        phone: phone,
        email: email,
        clearPhone: clearPhone,
        clearEmail: clearEmail,
      );
      await loadGuests();
      return guest;
    } catch (e) {
      debugPrint('Erreur modification invité: $e');
      Get.snackbar('Erreur', 'Impossible de modifier l\'invité');
      return null;
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

  Future<void> setGuestCancelled(String id, {required bool cancelled}) async {
    try {
      await _guestRepository.setGuestCancelled(id, cancelled: cancelled);
      await loadGuests();
      Get.back();
      Get.snackbar(
        'Succès',
        cancelled ? 'Invité annulé et place libérée' : 'Invité réactivé',
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        cancelled
            ? 'Impossible d\'annuler l\'invité'
            : 'Impossible de réactiver l\'invité',
      );
    }
  }

  Future<void> assignSeatToGuest({
    required String guestId,
    required String chairId,
  }) async {
    try {
      // 1. Assign the seat
      await _guestRepository.assignSeat(guestId: guestId, chairId: chairId);

      // 2. Auto-create guest link for QR code
      await _linkRepository.createGuestLink(guestId);

      await loadGuests();
      Get.back();
      Get.snackbar(
        'Succès',
        'Place assignée ! Lien d\'invitation généré automatiquement.',
      );
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

  /// Invités qui n'ont pas encore répondu à l'invitation (annulés exclus).
  List<Guest> get guestsAwaitingRsvp => guests
      .where((g) => g.status != 'cancelled' && g.rsvpStatus == 'pending')
      .toList();

  int get pendingCount => guestsAwaitingRsvp.length;
  int get confirmedCount =>
      guests.where((g) => g.status != 'cancelled' && g.isRsvpConfirmed).length;
  int get declinedCount => guests
      .where((g) => g.status != 'cancelled' && g.rsvpStatus == 'declined')
      .length;
  int get cancelledCount => guests.where((g) => g.status == 'cancelled').length;

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void onFilterChanged(String status) {
    filterStatus.value = status;
  }
}
