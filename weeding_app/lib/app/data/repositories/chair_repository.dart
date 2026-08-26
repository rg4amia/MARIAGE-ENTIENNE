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
    return (response as List).map((json) => Chair.fromJson(json)).toList();
  }

  Future<Chair?> getChairById(String id) async {
    final response = await _client
        .from('chairs')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : Chair.fromJson(response);
  }

  Future<List<Chair>> getAvailableChairsByTableId(String tableId) async {
    final response = await _client
        .from('chairs')
        .select()
        .eq('table_id', tableId)
        .isFilter('guest_id', null)
        .order('chair_number');
    return (response as List).map((json) => Chair.fromJson(json)).toList();
  }
}
