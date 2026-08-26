import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation.dart';

class InvitationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Invitation>> getAllInvitations() async {
    final response = await _client
        .from('invitations')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => Invitation.fromJson(json)).toList();
  }

  Future<Invitation?> getInvitationByGuestId(String guestId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('guest_id', guestId)
        .maybeSingle();
    return response == null ? null : Invitation.fromJson(response);
  }

  Future<void> updateCardPaths({
    required String id,
    String? pngStoragePath,
    String? pdfStoragePath,
  }) async {
    final updates = <String, dynamic>{};
    if (pngStoragePath != null) updates['png_storage_path'] = pngStoragePath;
    if (pdfStoragePath != null) updates['pdf_storage_path'] = pdfStoragePath;
    if (updates.isNotEmpty) {
      await _client.from('invitations').update(updates).eq('id', id);
    }
  }

  Future<int> getInvitationCount() async {
    final response = await _client.from('invitations').select('id');
    return (response as List).length;
  }

  Future<int> getMediaCount() async {
    final response = await _client.from('guest_media_submissions').select('id');
    return (response as List).length;
  }
}
