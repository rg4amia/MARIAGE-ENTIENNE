import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wedding_table.dart';
import '../models/chair.dart';

class TableRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<WeddingTable>> getAllTables() async {
    final response = await _client
        .from('seating_tables')
        .select('*, chairs(count)')
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final chairs = json['chairs'] as List?;
      final assignedCount = chairs?.isNotEmpty == true
          ? (chairs!.first['count'] as int?) ?? 0
          : 0;
      return WeddingTable.fromJson({
        ...json,
        'assigned_seats': assignedCount,
      });
    }).toList();
  }

  Future<WeddingTable?> getTableById(String id) async {
    final response = await _client
        .from('seating_tables')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : WeddingTable.fromJson(response);
  }

  Future<WeddingTable> createTable({
    required String label,
    required int capacity,
  }) async {
    final response = await _client.rpc(
      'create_seating_table',
      params: {'p_label': label, 'p_capacity': capacity},
    );
    return WeddingTable.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateTable({required String id, String? label}) async {
    if (label != null) {
      await _client
          .from('seating_tables')
          .update({'label': label})
          .eq('id', id);
    }
  }

  Future<void> deleteTable(String id) async {
    await _client.rpc('delete_seating_table', params: {'p_table_id': id});
  }

  Future<List<Chair>> getChairsByTableId(String tableId) async {
    final response = await _client
        .from('chairs')
        .select('*, guests(full_name)')
        .eq('table_id', tableId)
        .order('chair_number');
    return (response as List).map((json) => Chair.fromJson(json)).toList();
  }

  Future<List<Chair>> getAvailableChairsByTableId(String tableId) async {
    final response = await _client
        .from('chairs')
        .select('*, guests(full_name)')
        .eq('table_id', tableId)
        .isFilter('guest_id', null)
        .order('chair_number');
    return (response as List).map((json) => Chair.fromJson(json)).toList();
  }

  Future<Map<String, int>> getTableStats() async {
    final tables = await getAllTables();
    final totalChairs = tables.fold<int>(
      0,
      (sum, table) => sum + table.capacity,
    );
    final chairs = await _client.from('chairs').select('guest_id') as List;
    final assignedChairs = chairs
        .where((chair) => chair['guest_id'] != null)
        .length;
    return {
      'totalTables': tables.length,
      'totalChairs': totalChairs,
      'assignedChairs': assignedChairs,
      'freeChairs': totalChairs - assignedChairs,
    };
  }
}
