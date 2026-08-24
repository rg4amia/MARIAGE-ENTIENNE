import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wedding_table.dart';
import '../models/chair.dart';

class TableRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<WeddingTable>> getAllTables() async {
    final response = await _client
        .from('seating_tables')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => WeddingTable.fromJson(json))
        .toList();
  }

  Future<WeddingTable?> getTableById(String id) async {
    final response = await _client
        .from('seating_tables')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return WeddingTable.fromJson(response);
  }

  Future<WeddingTable> createTable({
    required String name,
    String? description,
    required int capacity,
  }) async {
    // 1. Créer la table
    final tableResponse = await _client
        .from('seating_tables')
        .insert({
          'name': name,
          'description': description,
          'capacity': capacity,
        })
        .select()
        .single();

    final table = WeddingTable.fromJson(tableResponse);

    // 2. Générer automatiquement les chaises
    await _generateChairs(table.id, capacity);

    return table;
  }

  Future<void> updateTable({
    required String id,
    String? name,
    String? description,
    int? capacity,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (capacity != null) updates['capacity'] = capacity;

    await _client
        .from('seating_tables')
        .update(updates)
        .eq('id', id);
  }

  Future<void> deleteTable(String id) async {
    // Les chaises sont supprimées en cascade
    await _client.from('seating_tables').delete().eq('id', id);
  }

  Future<List<Chair>> getChairsByTableId(String tableId) async {
    final response = await _client
        .from('chairs')
        .select()
        .eq('table_id', tableId)
        .order('chair_number');

    return (response as List)
        .map((json) => Chair.fromJson(json))
        .toList();
  }

  Future<List<Chair>> getAvailableChairsByTableId(String tableId) async {
    final response = await _client
        .from('chairs')
        .select()
        .eq('table_id', tableId)
        .eq('is_assigned', false)
        .order('chair_number');

    return (response as List)
        .map((json) => Chair.fromJson(json))
        .toList();
  }

  Future<void> _generateChairs(String tableId, int count) async {
    final chairs = List.generate(
      count,
      (index) => {
        'table_id': tableId,
        'chair_number': index + 1,
        'is_assigned': false,
      },
    );

    await _client.from('chairs').insert(chairs);
  }

  Future<Map<String, int>> getTableStats() async {
    final tables = await getAllTables();
    final totalChairs = tables.fold<int>(0, (sum, t) => sum + t.capacity);

    final chairsResponse = await _client.from('chairs').select('is_assigned');
    final assignedCount = (chairsResponse as List)
        .where((c) => c['is_assigned'] == true)
        .length;

    return {
      'totalTables': tables.length,
      'totalChairs': totalChairs,
      'assignedChairs': assignedCount,
      'freeChairs': totalChairs - assignedCount,
    };
  }
}
