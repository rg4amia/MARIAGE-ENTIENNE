import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/utils/whatsapp_helper.dart';
import 'package:weeding_app/app/data/models/guest.dart';
import 'package:weeding_app/app/data/repositories/wedding_settings_repository.dart';

void main() {
  // `SupabaseConfig.guestPortalUrl` lit dotenv : on le charge vide pour que
  // le repli s'applique en test.
  setUpAll(dotenv.testLoad);

  final guest = Guest(
    id: 'guest-1',
    fullName: 'Stephanie K.',
    qrToken: 'token-abc',
  );

  group('Invitation message', () {
    test('contains the new invitation text with settings', () {
      final settings = WeddingSettings(
        title: 'Mariage Kodjo et Marie Ange',
        brideName: 'Tiemele Marie Ange',
        groomName: 'Mawule Kodjo',
        eventDate: DateTime(2026, 11, 14),
        rsvpDeadline: DateTime(2026, 11, 5),
      );

      final message = invitationMessageForGuest(
        guest: guest,
        settings: settings,
      );

      // En-tête du couple.
      expect(message, contains('💍 *Wedding Mawule Kodjo ET Tiemele Marie Ange*'));
      // Versets.
      expect(message, contains('Éphésiens 5, 25'));
      expect(message, contains('Cantique des Cantiques 6, 3'));
      // Formule personnelle.
      expect(message, contains('Cher(e) *Stephanie K.*,'));
      // Cérémonie : date avec jour de la semaine, horaire et lieu.
      expect(
        message,
        contains(
          'le *samedi 14 novembre 2026* à *16 heures*, '
          'à la *Quasi-Paroisse Sacré-Cœur d\'Akandjé*',
        ),
      );
      // Réception.
      expect(
        message,
        contains(
          'suivie d\'une réception à *18 heures* à l\'*Espace JML Jouse*',
        ),
      );
      // RSVP avec « 1er ».
      expect(
        message,
        contains('Confirmation de présence souhaitée au plus tard le 5 novembre 2026.'),
      );
      // Lien personnel de l'invité.
      expect(message, contains('token=token-abc'));
      // Signature.
      expect(message, contains('Avec amour et gratitude,'));
      expect(message, contains('Mawule Kodjo & Tiemele Marie Ange 🥂'));
    });

    test('falls back to the invitation dates and couple without settings', () {
      final message = invitationMessageForGuest(guest: guest);

      expect(
        message,
        contains('le *samedi 14 novembre 2026* à *16 heures*'),
      );
      expect(
        message,
        contains('au plus tard le 5 novembre 2026.'),
      );
      expect(message, contains('*Kodjo & Marie Ange* vous convient'));
      expect(message, contains('Kodjo & Marie Ange 🥂'));
    });
  });
}
