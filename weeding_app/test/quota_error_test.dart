import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/core/utils/quota_error.dart';

void main() {
  group('QuotaRefusal.tryParse', () {
    test('reconnaît le refus d\'envoi et garde la phrase française', () {
      final refusal = QuotaRefusal.tryParse(
        'PostgrestException(message: QUOTA_INVITATIONS: Les 30 invitations '
        'du forfait Essentiel sont envoyées. Choisissez un pack pour '
        'continuer., code: P0001)',
      );

      expect(refusal, isNotNull);
      expect(refusal!.kind, 'INVITATIONS');
      expect(refusal.message, startsWith('Les 30 invitations du forfait'));
      expect(refusal.isSubscriptionLapsed, isFalse);
      expect(refusal.actionLabel, 'Voir les forfaits');
    });

    test('reconnaît le quota d\'invités', () {
      final refusal = QuotaRefusal.tryParse(
        'QUOTA_GUESTS: Le forfait Mariage 150 est limité à 150 invités.',
      );

      expect(refusal!.kind, 'GUESTS');
      expect(refusal.message, endsWith('limité à 150 invités.'));
    });

    test('reconnaît le quota de collaborateurs', () {
      final refusal = QuotaRefusal.tryParse(
        'QUOTA_COLLABORATORS: Le forfait Mariage 150 autorise 1 personne(s) '
        'sur l\'espace.',
      );

      expect(refusal!.kind, 'COLLABORATORS');
      expect(refusal.title, 'Limite du forfait atteinte');
    });

    test('un forfait inactif propose de réactiver, pas d\'acheter', () {
      final refusal = QuotaRefusal.tryParse(
        'QUOTA_SUBSCRIPTION: Le forfait Planner n\'est plus actif. '
        'Réactivez-le pour envoyer vos invitations.',
      );

      expect(refusal!.isSubscriptionLapsed, isTrue);
      expect(refusal.title, 'Forfait inactif');
      expect(refusal.actionLabel, 'Réactiver');
    });

    test('s\'arrête à la première ligne, sans le contexte PL/pgSQL', () {
      final refusal = QuotaRefusal.tryParse(
        'QUOTA_INVITATIONS: Quota atteint.\n'
        'CONTEXT: PL/pgSQL function enforce_invitation_quota() line 28',
      );

      expect(refusal!.message, 'Quota atteint.');
    });

    test('une erreur réseau n\'est pas un refus de quota', () {
      expect(QuotaRefusal.tryParse('SocketException: Failed host lookup'),
          isNull);
      expect(QuotaRefusal.tryParse(null), isNull);
    });
  });
}
