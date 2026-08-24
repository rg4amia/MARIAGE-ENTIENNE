import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_link.dart';

class GuestLinkRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a short link for a guest via RPC
  Future<GuestLink?> createGuestLink(String guestId) async {
    try {
      final response = await _client.rpc('create_guest_link', params: {
        'p_guest_id': guestId,
      });

      if (response == null) return null;

      final data = response as Map<String, dynamic>;
      return GuestLink(
        id: data['id'] as String,
        shortCode: data['short_code'] as String,
        guestToken: data['guest_token'] as String,
        guestId: guestId,
      );
    } catch (e) {
      // Fallback: create directly via insert
      return _createGuestLinkDirect(guestId);
    }
  }

  /// Direct creation (fallback if RPC not available)
  Future<GuestLink?> _createGuestLinkDirect(String guestId) async {
    try {
      // Get guest token
      final guestResponse = await _client
          .from('guests')
          .select('qr_token')
          .eq('id', guestId)
          .single();

      final guestToken = guestResponse['qr_token'] as String;

      // Generate unique short code
      final shortCode = _generateShortCode();

      // Insert link
      final response = await _client
          .from('guest_links')
          .insert({
            'short_code': shortCode,
            'guest_token': guestToken,
            'guest_id': guestId,
            'is_active': true,
          })
          .select()
          .single();

      return GuestLink.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get existing link for a guest
  Future<GuestLink?> getLinkByGuestId(String guestId) async {
    final response = await _client
        .from('guest_links')
        .select()
        .eq('guest_id', guestId)
        .maybeSingle();

    if (response == null) return null;
    return GuestLink.fromJson(response);
  }

  /// Get link by short code
  Future<GuestLink?> getLinkByShortCode(String shortCode) async {
    final response = await _client
        .from('guest_links')
        .select()
        .eq('short_code', shortCode)
        .maybeSingle();

    if (response == null) return null;
    return GuestLink.fromJson(response);
  }

  /// Toggle link active state
  Future<void> toggleLink(String linkId, bool isActive) async {
    await _client
        .from('guest_links')
        .update({'is_active': isActive})
        .eq('id', linkId);
  }

  /// Get all links with guest info (admin)
  Future<List<GuestLink>> getAllLinks() async {
    final response = await _client
        .from('guest_links')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GuestLink.fromJson(json))
        .toList();
  }

  /// Get link statistics
  Future<Map<String, int>> getLinkStats() async {
    final response = await _client.from('guest_links').select('scan_count, is_active');
    final list = response as List;

    int totalLinks = list.length;
    int activeLinks = list.where((l) => l['is_active'] == true).length;
    int totalScans = list.fold(0, (sum, l) => sum + ((l['scan_count'] ?? 0) as int));
    int scannedAtLeastOnce = list.where((l) => (l['scan_count'] ?? 0) > 0).length;

    return {
      'totalLinks': totalLinks,
      'activeLinks': activeLinks,
      'totalScans': totalScans,
      'scannedAtLeastOnce': scannedAtLeastOnce,
    };
  }

  String _generateShortCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[random % chars.length];
    }
    return code;
  }
}
