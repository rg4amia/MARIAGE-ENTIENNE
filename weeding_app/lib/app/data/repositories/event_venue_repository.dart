import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_venue.dart';

class EventVenueRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> _currentEventId() async {
    final eventId = await _client.rpc('current_event_id');
    if (eventId == null) throw StateError('Aucun mariage actif.');
    return eventId as String;
  }

  Future<List<EventVenue>> getVenues() async {
    final eventId = await _currentEventId();
    final response = await _client
        .from('event_venues')
        .select()
        .eq('event_id', eventId)
        .order('sort_order')
        .order('name');

    return (response as List)
        .map((json) => EventVenue.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<EventVenue> save({
    String? id,
    required String venueType,
    required String name,
    String? addressLine,
    String? city,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? instructions,
    int sortOrder = 0,
  }) async {
    final eventId = await _currentEventId();
    final payload = <String, dynamic>{
      'event_id': eventId,
      'venue_type': venueType,
      'name': name,
      'address_line': addressLine,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'place_provider': mapsUrl?.isNotEmpty == true ? 'manual' : null,
      'maps_url': mapsUrl,
      'instructions': instructions,
      'sort_order': sortOrder,
    };

    final Map<String, dynamic> response;
    if (id == null) {
      response = await _client
          .from('event_venues')
          .insert(payload)
          .select()
          .single();
    } else {
      response = await _client
          .from('event_venues')
          .update(payload)
          .eq('id', id)
          .eq('event_id', eventId)
          .select()
          .single();
    }

    return EventVenue.fromJson(response);
  }

  Future<void> delete(String id) async {
    final eventId = await _currentEventId();
    await _client
        .from('event_venues')
        .delete()
        .eq('id', id)
        .eq('event_id', eventId);
  }
}
