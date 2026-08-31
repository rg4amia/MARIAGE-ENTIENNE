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

  /// Enregistre un envoi côté base. C'est cet appel — et non le partage
  /// système — qui consomme le quota du forfait : la base refuse elle-même
  /// l'envoi de trop avec une erreur `QUOTA_*`.
  Future<Map<String, dynamic>> recordDelivery({
    required String invitationId,
    String channel = 'whatsapp',
    String? destination,
  }) async {
    final response = await _client.rpc(
      'record_invitation_delivery',
      params: {
        'p_invitation_id': invitationId,
        'p_channel': channel,
        'p_destination': destination,
      },
    );
    return Map<String, dynamic>.from(response as Map);
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
