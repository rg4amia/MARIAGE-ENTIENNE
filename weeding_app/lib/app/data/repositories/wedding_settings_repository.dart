import 'package:supabase_flutter/supabase_flutter.dart';

class WeddingSettings {
  final String title;
  final String brideName;
  final String groomName;
  final String? location;
  final DateTime? eventDate;

  /// Date limite pour que les invités confirment leur présence.
  final DateTime? rsvpDeadline;

  /// Cérémonie religieuse et réception : lieu et heure (« HH:MM »).
  final String? ceremonyVenue;
  final String? ceremonyTime;
  final String? receptionVenue;
  final String? receptionTime;

  WeddingSettings({
    required this.title,
    required this.brideName,
    required this.groomName,
    this.location,
    this.eventDate,
    this.rsvpDeadline,
    this.ceremonyVenue,
    this.ceremonyTime,
    this.receptionVenue,
    this.receptionTime,
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
      rsvpDeadline: json['rsvp_deadline'] != null
          ? DateTime.parse(json['rsvp_deadline'] as String)
          : null,
      ceremonyVenue: json['ceremony_venue'] as String?,
      ceremonyTime: json['ceremony_time'] as String?,
      receptionVenue: json['reception_venue'] as String?,
      receptionTime: json['reception_time'] as String?,
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
    DateTime? rsvpDeadline,
    bool clearRsvpDeadline = false,
    String? ceremonyVenue,
    String? ceremonyTime,
    String? receptionVenue,
    String? receptionTime,
  }) async {
    final eventId = await _client.rpc('current_event_id');
    if (eventId == null) throw Exception('Event not found');

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (brideName != null) updates['bride_name'] = brideName;
    if (groomName != null) updates['groom_name'] = groomName;
    if (location != null) updates['location'] = location;
    if (eventDate != null) {
      updates['event_date'] = eventDate.toUtc().toIso8601String();
    }
    if (rsvpDeadline != null) {
      updates['rsvp_deadline'] = rsvpDeadline.toUtc().toIso8601String();
    }
    if (clearRsvpDeadline) {
      updates['rsvp_deadline'] = null;
    }
    // Chaîne vide = retour aux valeurs par défaut (NULL en base).
    String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
    if (ceremonyVenue != null) {
      updates['ceremony_venue'] = orNull(ceremonyVenue);
    }
    if (ceremonyTime != null) updates['ceremony_time'] = orNull(ceremonyTime);
    if (receptionVenue != null) {
      updates['reception_venue'] = orNull(receptionVenue);
    }
    if (receptionTime != null) {
      updates['reception_time'] = orNull(receptionTime);
    }
    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('wedding_events').update(updates).eq('id', eventId);
  }
}
