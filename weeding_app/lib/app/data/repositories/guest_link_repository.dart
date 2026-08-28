import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_link.dart';

class GuestLinkRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Generate a random short code
  String _generateShortCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final result = StringBuffer();
    for (var i = 0; i < 8; i++) {
      result.write(chars[random.nextInt(chars.length)]);
    }
    return result.toString();
  }

  /// Create a short link for a guest directly in the database
  Future<GuestLink?> createGuestLink(String guestId) async {
    try {
      // Check if link already exists
      final existing = await getLinkByGuestId(guestId);
      if (existing != null) return existing;

      // Reuse the canonical guest token. A second random token would not be
      // resolvable by the invitation portal.
      final shortCode = _generateShortCode();
      final guest = await _client
          .from('guests')
          .select('qr_token')
          .eq('id', guestId)
          .single();
      final guestToken = (guest['qr_token'] as String?)?.trim();
      if (guestToken == null || guestToken.isEmpty) return null;

      // Insert directly into the database
      final response = await _client
          .from('guest_links')
          .insert({
            'guest_id': guestId,
            'short_code': shortCode,
            'guest_token': guestToken,
            'is_active': true,
            'scan_count': 0,
          })
          .select()
          .single();

      return GuestLink.fromJson(response);
    } catch (e) {
      debugPrint('Erreur création guest link: $e');
      return null;
    }
  }

  /// Get existing link for a guest
  Future<GuestLink?> getLinkByGuestId(String guestId) async {
    try {
      return await _fetchLinkByGuestId(guestId);
    } on PostgrestException catch (error) {
      // PGRST303 means PostgREST rejected the cached JWT before the query
      // reached the database. A new token fixes a transient clock skew or a
      // token issued while the emulator was offline.
      if (!_isFutureJwt(error)) rethrow;

      try {
        final refreshed = await _client.auth.refreshSession();
        if (refreshed.session == null) {
          throw AuthException('Session Supabase invalide');
        }
        return await _fetchLinkByGuestId(guestId);
      } catch (_) {
        // Do not keep retrying a token that the API considers invalid. Local
        // sign-out clears only the persisted session and keeps server data.
        await _client.auth.signOut();
        rethrow;
      }
    }
  }

  Future<GuestLink?> _fetchLinkByGuestId(String guestId) async {
    final response = await _client
        .from('guest_links')
        .select()
        .eq('guest_id', guestId)
        .maybeSingle();

    if (response == null) return null;
    return GuestLink.fromJson(response);
  }

  bool _isFutureJwt(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST303' || message.contains('jwt issued at future');
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

    return (response as List).map((json) => GuestLink.fromJson(json)).toList();
  }

  /// Get link statistics
  Future<Map<String, int>> getLinkStats() async {
    final response = await _client
        .from('guest_links')
        .select('scan_count, is_active');
    final list = response as List;

    int totalLinks = list.length;
    int activeLinks = list.where((l) => l['is_active'] == true).length;
    int totalScans = list.fold(
      0,
      (sum, l) => sum + ((l['scan_count'] ?? 0) as int),
    );
    int scannedAtLeastOnce = list
        .where((l) => (l['scan_count'] ?? 0) > 0)
        .length;

    return {
      'totalLinks': totalLinks,
      'activeLinks': activeLinks,
      'totalScans': totalScans,
      'scannedAtLeastOnce': scannedAtLeastOnce,
    };
  }
}
