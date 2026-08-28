import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/data/models/event_venue.dart';

void main() {
  test('EventVenue conserve le contrat cartographique fournisseur-neutre', () {
    final venue = EventVenue.fromJson({
      'id': 'venue-1',
      'event_id': 'event-1',
      'venue_type': 'reception',
      'name': 'Palais des Congrès',
      'address_line': 'Boulevard de l’Aéroport',
      'city': 'Abidjan',
      'country_code': 'CI',
      'latitude': 5.2545,
      'longitude': -3.9312,
      'place_provider': 'google',
      'place_id': 'google-place-id',
      'maps_url': 'https://maps.google.com/example',
      'sort_order': 30,
    });

    expect(venue.venueType, 'reception');
    expect(venue.latitude, 5.2545);
    expect(venue.longitude, -3.9312);
    expect(venue.addressLabel, 'Boulevard de l’Aéroport, Abidjan');
  });
}
