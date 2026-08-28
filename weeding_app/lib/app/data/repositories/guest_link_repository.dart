import 'dart:convert';
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

  /// Generate a random guest token
  String _generateGuestToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (index) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Create a short link for a guest directly in the database
  Future<GuestLink?> createGuestLink(String guestId) async {
    try {
      // Check if link already exists
      final existing = await getLinkByGuestId(guestId);
      if (existing != null) return existing;

      // Generate codes in Flutter
      final shortCode = _generateShortCode();
      final guestToken = _generateGuestToken();

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
