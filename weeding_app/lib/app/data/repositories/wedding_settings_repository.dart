import 'package:supabase_flutter/supabase_flutter.dart';

class WeddingSettings {
  final String title;
  final String brideName;
  final String groomName;
  final String? location;
  final DateTime? eventDate;

  WeddingSettings({
    required this.title,
    required this.brideName,
    required this.groomName,
    this.location,
    this.eventDate,
  });

  factory WeddingSettings.fromJson(Map<String, dynamic> json) {
    return WeddingSettings(
      title: json['title'] as String? ?? '',
      brideName: json['bride_name'] as String? ?? '',
      groomName: json['groom_name'] as String? ?? '',
      location: json['location'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
    );
  }
}

class WeddingSettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current wedding event settings
  Future<WeddingSettings?> getSettings() async {
    try {
      final eventId = await _client.rpc('current_event_id');
      if (eventId == null) return null;

      final response = await _client
          .from('wedding_events')
          .select()
          .eq('id', eventId)
          .maybeSingle();

      if (response == null) return null;
      return WeddingSettings.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update wedding event settings
  Future<void> updateSettings({
    String? title,
    String? brideName,
    String? groomName,
    String? location,
    DateTime? eventDate,
  }) async {
    final eventId = await _client.rpc('current_event_id');
    if (eventId == null) throw Exception('Event not found');

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (brideName != null) updates['bride_name'] = brideName;
    if (groomName != null) updates['groom_name'] = groomName;
    if (location != null) updates['location'] = location;
    if (eventDate != null) updates['event_date'] = eventDate.toUtc().toIso8601String();
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('wedding_events')
        .update(updates)
        .eq('id', eventId);
  }
}
