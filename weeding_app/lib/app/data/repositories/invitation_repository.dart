import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/invitation.dart';

class InvitationRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Invitation>> getAllInvitations() async {
    final response = await _client
        .from('invitations')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Invitation.fromJson(json))
        .toList();
  }

  Future<Invitation?> getInvitationByGuestId(String guestId) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('guest_id', guestId)
        .maybeSingle();

    if (response == null) return null;
    return Invitation.fromJson(response);
  }

  Future<Invitation> createInvitation({
    required String guestId,
  }) async {
    final invitationCode = 'INV-${DateTime.now().year}-${_uuid.v4().substring(0, 6).toUpperCase()}';

    final response = await _client
        .from('invitations')
        .insert({
          'guest_id': guestId,
          'invitation_code': invitationCode,
          'is_unlocked': false,
        })
        .select()
        .single();

    return Invitation.fromJson(response);
  }

  Future<void> updateInvitation({
    required String id,
    String? qrCodeUrl,
    String? cardUrl,
    bool? isUnlocked,
  }) async {
    final updates = <String, dynamic>{};
    if (qrCodeUrl != null) updates['qr_code_url'] = qrCodeUrl;
    if (cardUrl != null) updates['card_url'] = cardUrl;
    if (isUnlocked != null) updates['is_unlocked'] = isUnlocked;

    await _client.from('invitations').update(updates).eq('id', id);
  }

  Future<void> deleteInvitation(String id) async {
    await _client.from('invitations').delete().eq('id', id);
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
