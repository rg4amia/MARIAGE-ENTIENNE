import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/guest.dart';
import '../models/guest_seat.dart';

class GuestRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Guest>> getAllGuests() async {
    final response = await _client
        .from('guests')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Guest.fromJson(json))
        .toList();
  }

  Future<Guest?> getGuestById(String id) async {
    final response = await _client
        .from('guests')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Guest.fromJson(response);
  }

  Future<Guest?> getGuestByToken(String token) async {
    final response = await _client
        .from('guests')
        .select()
        .eq('qr_token', token)
        .maybeSingle();

    if (response == null) return null;
    return Guest.fromJson(response);
  }

  Future<Guest> createGuest({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final qrToken = _generateQrToken(fullName);

    final response = await _client
        .from('guests')
        .insert({
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'qr_token': qrToken,
          'status': 'pending',
        })
        .select()
        .single();

    return Guest.fromJson(response);
  }

  Future<void> updateGuest({
    required String id,
    String? fullName,
    String? phone,
    String? email,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (status != null) updates['status'] = status;

    await _client.from('guests').update(updates).eq('id', id);
  }

  Future<void> deleteGuest(String id) async {
    await _client.from('guests').delete().eq('id', id);
  }

  Future<int> getGuestCount() async {
    final response = await _client.from('guests').select('id');
    return (response as List).length;
  }

  Future<Map<String, int>> getGuestStats() async {
    final response = await _client.from('guests').select('status');
    final list = response as List;

    int pending = 0;
    int mediaUploaded = 0;
    int cardUnlocked = 0;

    for (final item in list) {
      switch (item['status']) {
        case 'pending':
          pending++;
          break;
        case 'media_uploaded':
          mediaUploaded++;
          break;
        case 'card_unlocked':
          cardUnlocked++;
          break;
      }
    }

    return {
      'total': list.length,
      'pending': pending,
      'mediaUploaded': mediaUploaded,
      'cardUnlocked': cardUnlocked,
    };
  }

  // --- Seat Assignment ---

  Future<GuestSeat?> getGuestSeat(String guestId) async {
    final response = await _client
        .from('guest_seats')
        .select()
        .eq('guest_id', guestId)
        .maybeSingle();

    if (response == null) return null;
    return GuestSeat.fromJson(response);
  }

  Future<void> assignSeat({
    required String guestId,
    required String tableId,
    required String chairId,
  }) async {
    // 1. Vérifier que la chaise n'est pas déjà assignée
    final chairResponse = await _client
        .from('chairs')
        .select('is_assigned')
        .eq('id', chairId)
        .single();

    if (chairResponse['is_assigned'] == true) {
      throw Exception('Cette chaise est déjà assignée');
    }

    // 2. Si le guest avait déjà une place, libérer l'ancienne
    await unassignSeat(guestId);

    // 3. Insérer la nouvelle attribution
    await _client.from('guest_seats').insert({
      'guest_id': guestId,
      'table_id': tableId,
      'chair_id': chairId,
    });

    // 4. Marquer la chaise comme assignée
    await _client
        .from('chairs')
        .update({'is_assigned': true})
        .eq('id', chairId);
  }

  Future<void> unassignSeat(String guestId) async {
    // 1. Trouver l'ancienne attribution
    final oldSeat = await getGuestSeat(guestId);
    if (oldSeat == null) return;

    // 2. Libérer la chaise
    await _client
        .from('chairs')
        .update({'is_assigned': false})
        .eq('id', oldSeat.chairId);

    // 3. Supprimer l'attribution
    await _client.from('guest_seats').delete().eq('guest_id', guestId);
  }

  String _generateQrToken(String fullName) {
    final slug = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    final shortId = _uuid.v4().substring(0, 12);
    return '$slug-$shortId';
  }
}
