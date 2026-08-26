import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_media.dart';

/// Admin-side access to guest submissions. Guest uploads are intentionally
/// handled only by the public Supabase guest portal.
class MediaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<GuestMedia>> getMediaByGuestId(String guestId) async {
    final response = await _client
        .from('guest_media_submissions')
        .select()
        .eq('guest_id', guestId)
        .order('submitted_at', ascending: false);
    return (response as List).map((json) => GuestMedia.fromJson(json)).toList();
  }

  Future<GuestMedia?> getValidMediaByGuestId(String guestId) async {
    final response = await _client
        .from('guest_media_submissions')
        .select()
        .eq('guest_id', guestId)
        .eq('client_validated', true)
        .eq('server_validated', true)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response == null ? null : GuestMedia.fromJson(response);
  }

  Future<String> getMediaDownloadUrl(String storagePath, String mediaType) {
    return _client.storage
        .from('guest-media')
        .createSignedUrl(storagePath, 3600);
  }

  @Deprecated('Guest media submission is available only in guest-portal.')
  Future<GuestMedia> submitMedia({
    required String guestId,
    required String mediaType,
    required String storagePath,
    required int durationSeconds,
  }) {
    throw UnsupportedError('Utilisez le portail invité Supabase.');
  }

  @Deprecated('Guest media upload is available only in guest-portal.')
  Future<String> uploadMediaToStorage({
    required String guestId,
    required String mediaType,
    required String filePath,
    required Uint8List fileBytes,
  }) {
    throw UnsupportedError('Utilisez le portail invité Supabase.');
  }
}
