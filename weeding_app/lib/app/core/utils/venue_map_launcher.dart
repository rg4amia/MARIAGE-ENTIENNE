import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_venue.dart';

/// Résout l'URL d'itinéraire d'un lieu : lien Maps saisi, sinon coordonnées,
/// sinon adresse texte.
Uri? venueMapUri(EventVenue venue) {
  final mapsUrl = venue.mapsUrl?.trim();
  if (mapsUrl != null && mapsUrl.isNotEmpty) return Uri.tryParse(mapsUrl);

  String? query;
  if (venue.latitude != null && venue.longitude != null) {
    query = '${venue.latitude},${venue.longitude}';
  } else if (venue.addressLabel.isNotEmpty) {
    query = venue.addressLabel;
  }
  if (query == null) return null;

  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}

/// Ouvre l'itinéraire du lieu dans l'application de cartes du téléphone.
/// Retourne `false` si aucune adresse/lien n'est disponible ou si
/// l'ouverture échoue.
Future<bool> launchVenueMap(EventVenue venue) async {
  final uri = venueMapUri(venue);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
