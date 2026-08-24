import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_media.dart';

class MediaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<GuestMedia>> getMediaByGuestId(String guestId) async {
    final response = await _client
        .from('guest_media')
        .select()
        .eq('guest_id', guestId)
        .order('submitted_at', ascending: false);

    return (response as List)
        .map((json) => GuestMedia.fromJson(json))
        .toList();
  }

  Future<GuestMedia?> getValidMediaByGuestId(String guestId) async {
    final response = await _client
        .from('guest_media')
        .select()
        .eq('guest_id', guestId)
        .eq('is_valid', true)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return GuestMedia.fromJson(response);
  }

  Future<GuestMedia> submitMedia({
    required String guestId,
    required String mediaType,
    required String storagePath,
    required int durationSeconds,
  }) async {
    final isValid = durationSeconds >= 30;

    final response = await _client
        .from('guest_media')
        .insert({
          'guest_id': guestId,
          'media_type': mediaType,
          'storage_path': storagePath,
          'duration_seconds': durationSeconds,
          'is_valid': isValid,
        })
        .select()
        .single();

    // Si le média est valide, débloquer la carte
    if (isValid) {
      await _client
          .from('guests')
          .update({'status': 'card_unlocked'})
          .eq('id', guestId);

      // Déverrouiller l'invitation
      await _client
          .from('invitations')
          .update({'is_unlocked': true})
          .eq('guest_id', guestId);
    } else {
      await _client
          .from('guests')
          .update({'status': 'media_uploaded'})
          .eq('id', guestId);
    }

    return GuestMedia.fromJson(response);
  }

  Future<String> uploadMediaToStorage({
    required String guestId,
    required String mediaType,
    required String filePath,
    required Uint8List fileBytes,
  }) async {
    final bucket = mediaType == 'audio' ? 'guest-audios' : 'guest-videos';
    final extension = mediaType == 'audio' ? 'm4a' : 'mp4';
    final storagePath = '$guestId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from(bucket).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return storagePath;
  }

  Future<String> getMediaDownloadUrl(String storagePath, String mediaType) async {
    final bucket = mediaType == 'audio' ? 'guest-audios' : 'guest-videos';
    return await _client.storage.from(bucket).createSignedUrl(storagePath, 3600);
  }
}
