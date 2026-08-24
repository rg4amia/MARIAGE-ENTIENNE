import 'package:get/get.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';

class TablesController extends GetxController {
  final TableRepository _tableRepository = TableRepository();

  final RxList<WeddingTable> tables = <WeddingTable>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<WeddingTable> get filteredTables {
    if (searchQuery.value.isEmpty) return tables;
    return tables
        .where((t) => t.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
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
      Get.snackbar('Erreur', 'Impossible de charger les tables');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTable({
    required String name,
    String? description,
    required int capacity,
  }) async {
    try {
      await _tableRepository.createTable(
        name: name,
        description: description,
        capacity: capacity,
      );
      await loadTables();
      Get.back();
      Get.snackbar('Succès', 'Table créée avec succès');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la table');
    }
  }

  Future<void> updateTable({
    required String id,
    String? name,
    String? description,
    int? capacity,
  }) async {
    try {
      await _tableRepository.updateTable(
        id: id,
        name: name,
        description: description,
        capacity: capacity,
      );
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
    return await _tableRepository.getChairsByTableId(tableId);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }
}
