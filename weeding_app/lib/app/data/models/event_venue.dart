class EventVenue {
  final String id;
  final String eventId;
  final String venueType;
  final String name;
  final String? addressLine;
  final String? city;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final String? placeProvider;
  final String? placeId;
  final String? mapsUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? instructions;
  final int sortOrder;

  const EventVenue({
    required this.id,
    required this.eventId,
    required this.venueType,
    required this.name,
    this.addressLine,
    this.city,
    this.countryCode = 'CI',
    this.latitude,
    this.longitude,
    this.placeProvider,
    this.placeId,
    this.mapsUrl,
    this.startsAt,
    this.endsAt,
    this.instructions,
    this.sortOrder = 0,
  });

  factory EventVenue.fromJson(Map<String, dynamic> json) {
    return EventVenue(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      venueType: json['venue_type'] as String,
      name: json['name'] as String,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String? ?? 'CI',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeProvider: json['place_provider'] as String?,
      placeId: json['place_id'] as String?,
      mapsUrl: json['maps_url'] as String?,
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
      instructions: json['instructions'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  String get addressLabel {
    return [
      addressLine,
      city,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
  }
}
