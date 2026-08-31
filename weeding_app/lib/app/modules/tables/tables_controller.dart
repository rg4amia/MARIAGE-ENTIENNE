import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import '../../data/models/guest.dart';

class TablesController extends GetxController {
  final TableRepository _tableRepository = TableRepository();
  final GuestRepository _guestRepository = GuestRepository();
  final GuestLinkRepository _linkRepository = GuestLinkRepository();

  final RxList<WeddingTable> tables = <WeddingTable>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<WeddingTable> get filteredTables {
    if (searchQuery.value.isEmpty) return tables;
    return tables
        .where(
          (t) =>
              t.label.toLowerCase().contains(searchQuery.value.toLowerCase()),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  Future<void> loadTables() async {
    isLoading.value = true;
    try {
      tables.value = await _tableRepository.getAllTables();
    } catch (e) {
      debugPrint('Erreur chargement tables: $e');
      Get.snackbar('Erreur', 'Impossible de charger les tables');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTable({
    required String label,
    required int capacity,
  }) async {
    try {
      await _tableRepository.createTable(label: label, capacity: capacity);
      await loadTables();
      Get.snackbar('Succès', 'Table créée avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la table');
    }
  }

  Future<void> updateTable({required String id, String? label}) async {
    try {
      await _tableRepository.updateTable(id: id, label: label);
      await loadTables();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier la table');
    }
  }

  Future<void> deleteTable(String id) async {
    try {
      await _tableRepository.deleteTable(id);
      await loadTables();
      Get.back();
      Get.snackbar('Succès', 'Table supprimée');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer la table');
    }
  }

  Future<List<Chair>> getChairsForTable(String tableId) async {
    try {
      // Step 1: try fetching existing chairs
      var chairs = await _tableRepository.getChairsByTableId(tableId);

      // Step 2: if none exist yet, try to auto-create them via RPC
      if (chairs.isEmpty) {
        try {
          final table = await _tableRepository.getTableById(tableId);
          if (table != null && table.capacity > 0) {
            await _tableRepository
                .ensureChairsForTable(tableId: tableId)
                .timeout(const Duration(seconds: 5));
            chairs = await _tableRepository.getChairsByTableId(tableId);
          }
        } catch (rpcError) {
          // RPC may fail if user isn't admin or current_event_id is missing.
          // Log and fall through — UI will show an empty state with retry.
          debugPrint('ensureChairsForTable RPC failed: $rpcError');
        }
      }
      return chairs;
    } catch (e, st) {
      debugPrint('getChairsForTable($tableId) failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteChair(String chairId) async {
    try {
      await _tableRepository.deleteChair(chairId);
      await loadTables();
      Get.snackbar('Succès', 'Chaise supprimée');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer cette chaise');
    }
  }

  Future<List<Guest>> getUnassignedGuests() async {
    final allGuests = await _guestRepository.getAllGuests();
    final assignedIds = await _tableRepository.getAssignedGuestIds();
    return allGuests
        .where((g) => g.status != 'cancelled' && !assignedIds.contains(g.id))
        .toList();
  }

  Future<void> assignGuestToChair({
    required String guestId,
    required String chairId,
  }) async {
    try {
      await _guestRepository.assignSeat(guestId: guestId, chairId: chairId);
      await _linkRepository.createGuestLink(guestId);
      await loadTables();
      Get.snackbar('Succès', 'Invité placé avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de placer l\'invité');
    }
  }

  Future<void> unassignGuestFromChair(String guestId) async {
    try {
      await _guestRepository.unassignSeat(guestId);
      await loadTables();
      Get.snackbar('Succès', 'Place libérée');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de libérer la place');
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}
