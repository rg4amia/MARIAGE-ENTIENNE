import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_venue.dart';
import '../../data/repositories/event_venue_repository.dart';

class VenuesController extends GetxController {
  final EventVenueRepository _repository = EventVenueRepository();

  final RxList<EventVenue> venues = <EventVenue>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVenues();
  }

  Future<void> loadVenues() async {
    isLoading.value = true;
    try {
      venues.assignAll(await _repository.getVenues());
    } catch (error) {
      debugPrint('Erreur chargement lieux: $error');
      Get.snackbar('Erreur', 'Impossible de charger les lieux du mariage.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveVenue({
    EventVenue? venue,
    required String venueType,
    required String name,
    String? addressLine,
    String? city,
    String? latitude,
    String? longitude,
    String? mapsUrl,
    String? instructions,
  }) async {
    if (name.trim().length < 2) {
      Get.snackbar('Nom requis', 'Donnez un nom précis à ce lieu.');
      return false;
    }

    final parsedLatitude = _parseCoordinate(latitude);
    final parsedLongitude = _parseCoordinate(longitude);
    if ((parsedLatitude == null) != (parsedLongitude == null)) {
      Get.snackbar(
        'Coordonnées incomplètes',
        'La latitude et la longitude doivent être renseignées ensemble.',
      );
      return false;
    }
    if (parsedLatitude != null &&
        (parsedLatitude < -90 || parsedLatitude > 90)) {
      Get.snackbar(
        'Latitude invalide',
        'La latitude doit être entre -90 et 90.',
      );
      return false;
    }
    if (parsedLongitude != null &&
        (parsedLongitude < -180 || parsedLongitude > 180)) {
      Get.snackbar(
        'Longitude invalide',
        'La longitude doit être entre -180 et 180.',
      );
      return false;
    }

    isSaving.value = true;
    try {
      await _repository.save(
        id: venue?.id,
        venueType: venueType,
        name: name.trim(),
        addressLine: _nullIfEmpty(addressLine),
        city: _nullIfEmpty(city),
        latitude: parsedLatitude,
        longitude: parsedLongitude,
        mapsUrl: _nullIfEmpty(mapsUrl),
        instructions: _nullIfEmpty(instructions),
        sortOrder: venue?.sortOrder ?? venues.length * 10,
      );
      await loadVenues();
      Get.snackbar('Lieu enregistré', 'Les informations ont été mises à jour.');
      return true;
    } catch (error) {
      debugPrint('Erreur sauvegarde lieu: $error');
      Get.snackbar('Erreur', 'Impossible d’enregistrer ce lieu.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteVenue(EventVenue venue) async {
    try {
      await _repository.delete(venue.id);
      venues.removeWhere((item) => item.id == venue.id);
      Get.snackbar('Lieu supprimé', venue.name);
    } catch (error) {
      debugPrint('Erreur suppression lieu: $error');
      Get.snackbar(
        'Suppression impossible',
        'Ce lieu est peut-être utilisé par le plan de salle.',
      );
    }
  }

  Future<void> openMap(EventVenue venue) async {
    final uri = _mapUri(venue);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Itinéraire indisponible',
        'Ajoutez une adresse ou un lien Maps.',
      );
    }
  }

  Uri? _mapUri(EventVenue venue) {
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

  double? _parseCoordinate(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
