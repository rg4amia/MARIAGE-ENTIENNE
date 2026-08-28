import 'package:flutter/foundation.dart';
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

    return (response as List).map((json) => Guest.fromJson(json)).toList();
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
    final eventId = await _client.rpc('current_event_id');
    if (eventId == null) {
      throw StateError('Aucun événement associé à cet administrateur');
    }

    final response = await _client
        .from('guests')
        .insert({
          'event_id': eventId,
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'qr_token': qrToken,
          'status': 'draft',
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
    await _client.rpc('delete_guest', params: {'p_guest_id': id});
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
        case 'draft':
        case 'pending_media':
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
        .from('chairs')
        .select(
          'id, guest_id, table_id, chair_number, created_at, seating_tables(label)',
        )
        .eq('guest_id', guestId)
        .maybeSingle();

    if (response == null) return null;
    return GuestSeat.fromJson(response);
  }

  Future<void> assignSeat({
    required String guestId,
    required String chairId,
  }) async {
    try {
      // First, unassign any existing seat for this guest
      await _client
          .from('chairs')
          .update({'guest_id': null})
          .eq('guest_id', guestId);

      // Assign the new chair
      await _client
          .from('chairs')
          .update({'guest_id': guestId})
          .eq('id', chairId);

      // Update guest status to 'pending_media' if it's still 'draft'
      await _client
          .from('guests')
          .update({'status': 'pending_media'})
          .eq('id', guestId)
          .eq('status', 'draft');
    } catch (e) {
      debugPrint('Erreur assignation place: $e');
      rethrow;
    }
  }

  Future<void> unassignSeat(String guestId) async {
    await _client
        .from('chairs')
        .update({'guest_id': null})
        .eq('guest_id', guestId);
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
