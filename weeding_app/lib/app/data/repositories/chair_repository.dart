import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chair.dart';

class ChairRepository {
  final SupabaseClient _client = Supabase.instance.client;

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

  Future<Chair?> getChairById(String id) async {
    final response = await _client
        .from('chairs')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Chair.fromJson(response);
  }

  Future<void> updateChairAssignment(String chairId, bool isAssigned) async {
    await _client
        .from('chairs')
        .update({'is_assigned': isAssigned})
        .eq('id', chairId);
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

  Future<void> deleteChairsByTableId(String tableId) async {
    await _client.from('chairs').delete().eq('table_id', tableId);
  }
}
