import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/data/models/platform_admin.dart';

void main() {
  group('AdminOrganization', () {
    Map<String, dynamic> orgJson({
      String status = 'active',
      Object? guests = 12,
      Object? sent = 5,
    }) => {
      'id': 'org-1',
      'name': 'Mariage Awa',
      'slug': 'mariage-awa',
      'owner_email': 'awa@example.ci',
      'plan_id': 'mariage_150',
      'plan_name': 'Mariage 150',
      'status': status,
      'events': 2,
      'members': 3,
      'guests': guests,
      'invitations_sent': sent,
      'created_at': '2026-08-01T10:00:00Z',
    };

    test('traduit les statuts pour l\'exploitant', () {
      expect(AdminOrganization.fromJson(orgJson()).statusLabel, 'Actif');
      expect(
        AdminOrganization.fromJson(orgJson(status: 'past_due')).statusLabel,
        'Impayé',
      );
      expect(
        AdminOrganization.fromJson(orgJson(status: 'suspended')).statusLabel,
        'Suspendu',
      );
    });

    test('distingue les comptes qui ne peuvent plus rien envoyer', () {
      expect(AdminOrganization.fromJson(orgJson()).isBlocked, isFalse);
      expect(
        AdminOrganization.fromJson(orgJson(status: 'trialing')).isBlocked,
        isFalse,
      );
      for (final blocked in ['past_due', 'canceled', 'suspended']) {
        expect(
          AdminOrganization.fromJson(orgJson(status: blocked)).isBlocked,
          isTrue,
          reason: blocked,
        );
      }
    });

    test('accepte les compteurs renvoyés en texte par PostgreSQL', () {
      final org = AdminOrganization.fromJson(
        orgJson(guests: '150', sent: '30'),
      );
      expect(org.guests, 150);
      expect(org.invitationsSent, 30);
    });
  });

  group('AdminEvent', () {
    test('affiche le quota consommé sur la limite du forfait', () {
      final event = AdminEvent.fromJson({
        'id': 'e-1',
        'title': 'Awa & Koffi',
        'slug': 'awa-koffi',
        'organization_id': 'org-1',
        'organization_name': 'Mariage Awa',
        'guests': 120,
        'tables': 15,
        'invitations_sent': 30,
        'max_invitations': 150,
      });

      expect(event.quotaLabel, '30 / 150');
    });

    test('un forfait illimité n\'affiche pas de dénominateur', () {
      final event = AdminEvent.fromJson({
        'id': 'e-2',
        'title': 'Sans limite',
        'slug': 'sans-limite',
        'organization_id': 'org-1',
        'organization_name': 'Mariage Awa',
        'guests': 400,
        'tables': 40,
        'invitations_sent': 380,
        'max_invitations': -1,
      });

      expect(event.quotaLabel, '380 envois');
    });
  });

  group('AdminAccount', () {
    test('repère une inscription jamais menée à son terme', () {
      final account = AdminAccount.fromJson({
        'id': 'u-1',
        'email': 'perdu@example.ci',
        'is_platform_admin': false,
        'created_at': '2026-08-20T09:00:00Z',
        'last_sign_in_at': null,
        'memberships': [],
      });

      expect(account.neverSignedIn, isTrue);
      expect(account.memberships, isEmpty);
    });

    test('rassemble les organisations et le rôle tenu dans chacune', () {
      final account = AdminAccount.fromJson({
        'id': 'u-2',
        'email': 'planner@example.ci',
        'is_platform_admin': true,
        'last_sign_in_at': '2026-08-30T18:00:00Z',
        'memberships': [
          {
            'organization_name': 'Agence Lys',
            'role': 'owner',
            'status': 'active',
          },
          {
            'organization_name': 'Mariage Awa',
            'role': 'planner',
            'status': 'invited',
          },
        ],
      });

      expect(account.isPlatformAdmin, isTrue);
      expect(account.neverSignedIn, isFalse);
      expect(account.memberships.length, 2);
      expect(account.memberships.first.organizationName, 'Agence Lys');
      expect(account.memberships.last.status, 'invited');
    });
  });

  group('AdminAction', () {
    test('résume un changement de forfait avec son motif', () {
      final action = AdminAction.fromJson({
        'action': 'set_plan',
        'target_type': 'organization',
        'actor_email': 'moi@example.ci',
        'details': {
          'from': 'essentiel',
          'to': 'mariage_300',
          'reason': 'Paiement Wave reçu',
        },
        'created_at': '2026-08-31T12:00:00Z',
      });

      expect(action.label, 'Changement de forfait');
      expect(action.summary, 'essentiel → mariage_300 — Paiement Wave reçu');
    });

    test('résume un geste commercial', () {
      final action = AdminAction.fromJson({
        'action': 'grant_invitations',
        'target_type': 'event',
        'details': {'extra': 10, 'reason': 'Incident d\'envoi'},
      });

      expect(action.label, 'Envois offerts');
      expect(action.summary, '+10 envois — Incident d\'envoi');
    });
  });
}
