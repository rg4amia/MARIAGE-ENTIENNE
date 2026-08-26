import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';
import '../models/entrance_qr.dart';

class EntranceRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<EntranceQr> getOrCreate({bool rotate = false}) async {
    final response = await _client.rpc(
      'manage_entrance_qr',
      params: {
        'p_guest_portal_url': SupabaseConfig.guestPortalUrl,
        'p_rotate': rotate,
      },
    );
    return EntranceQr.fromJson(response as Map<String, dynamic>);
  }
}
