import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/wedding_palette.dart';

class WeddingThemeRepository {
  WeddingThemeRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String?> _currentEventId() async {
    final value = await _client.rpc('current_event_id');
    return value as String?;
  }

  Future<WeddingPalette> getPalette() async {
    final eventId = await _currentEventId();
    if (eventId == null) return WeddingPalette.celestialRomance;

    final response = await _client
        .from('event_branding')
        .select()
        .eq('event_id', eventId)
        .maybeSingle();

    return response == null
        ? WeddingPalette.celestialRomance
        : WeddingPalette.fromJson(response);
  }

  Future<void> updatePalette(WeddingPalette palette) async {
    final eventId = await _currentEventId();
    if (eventId == null) throw StateError('Aucun mariage actif.');

    await _client
        .from('event_branding')
        .update(palette.toJson())
        .eq('event_id', eventId);
  }
}
